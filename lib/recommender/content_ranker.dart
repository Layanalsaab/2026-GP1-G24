/// Matching, part 2: score, order and explanation (content-based). Part 1
/// (documents and hard filters) is knowledge_filter.dart. Python reference:
/// matching_v2.py.
///
/// Rules (team decisions, 9 Nov 2026):
/// - Score: weighted cosine, sector 0.41, stage 0.29, commerce model 0.18,
///   divided by the weights used (0.88), so sector counts 47%, stage 33%
///   and commerce model 20%. Each part is 1 / sqrt(number of picks) when the
///   startup's value is picked, else 0. A match on one of the startup's
///   OTHER sectors counts half ([otherSectorFactor]). A blank part is
///   skipped and the weights are shared out again.
/// - Ticket (the investor's Wallet): sector and stage come from the ticket,
///   the commerce model from the investor's profile, plus a fourth part,
///   round fit (weight 0.12): how much of what the round still needs the
///   ticket's maximum can cover (1 when it covers all of it). A ticket's
///   weights add up to 1.0 (sector 41%, stage 29%, model 18%, fit 12%);
///   the profile matches don't have the fit part (still 47% / 33% / 20%).
/// - Founder's open round: investors with an open ticket that fits come
///   first (group 1, scored by their best ticket), then everyone else on
///   their profile (group 2). Each investor appears once.
/// - Order inside each group: exact matches, then close matches (only the
///   sector or only the stage misses), each by score; then the name.
///   No boosts and no lead tie-break. City / region is not used.
library;

import 'dart:math' as math;

import 'knowledge_filter.dart';

const Map<String, double> weights = {
  'sector': 0.41,
  'stage': 0.29,
  'model': 0.18,
  // Tickets only: how much of what the round still needs the ticket covers.
  'fit': 0.12,
};

/// How many investors a round's Matches can hold (the screen shows fewer).
const int topN = 20;

/// How much a match on one of a startup's OTHER sectors counts compared with
/// a match on its main sector (1.0). Ticking every sector therefore never
/// beats a startup whose main sector fits.
const double otherSectorFactor = 0.5;

final Map<String, String> _stageLabel = {
  for (final e in stageValue.entries) e.value: e.key,
};

/// "b2b" -> "B2B", "other" -> "Other".
final Map<String, String> _modelShort = {
  for (final e in modelValue.entries)
    e.value: e.key.contains('(')
        ? e.key.substring(e.key.indexOf('(') + 1, e.key.length - 1)
        : e.key,
};

/// One line of a match's explanation, shown at the top of a profile opened
/// from a match: "Sector · Fintech" (fits, green bar) or "Commerce model ·
/// B2C" with "they prefer B2B" (differs, gold bar).
class MatchRow {
  const MatchRow(this.label, this.value, {required this.fits, this.note});

  final String label;
  final String value;
  final bool fits;

  /// The smaller text after the value ("they prefer B2B").
  final String? note;

  @override
  String toString() =>
      '${fits ? '+' : '-'} $label · $value${note == null ? '' : ' ($note)'}';
}

/// One match: a startup (a ticket's matches) or an investor (a round's
/// matches).
class MatchResult {
  const MatchResult({
    required this.id,
    required this.name,
    required this.score,
    required this.percent,
    required this.rows,
    this.close = false,
    this.ticketId,
    this.remaining = 0,
  });

  /// The startup id (ticket) or investor id (round).
  final String id;
  final String name;

  /// 0-1, what the list is sorted by.
  final double score;

  /// Shown on the card and in the explanation, at most 100.
  final int percent;

  /// The explanation: one row per criterion.
  final List<MatchRow> rows;

  /// Only the sector or only the stage misses; listed after the exact ones.
  final bool close;

  /// Round matches: the investor's open ticket that fits (group 1), or null
  /// when the match comes from their profile (group 2).
  final String? ticketId;

  /// Ticket matches: what the startup's round still needs (SAR).
  final int remaining;

  bool get viaTicket => ticketId != null;
}

// ----------------------------------------------------------------- score

double? _overlap(Set<String> chosen, String? value) {
  if (chosen.isEmpty || value == null || value.isEmpty) return null;
  return (chosen.contains(value) ? 1.0 : 0.0) / math.sqrt(chosen.length);
}

/// A sector part: the main sector counts in full, another of the startup's
/// sectors [otherSectorFactor] of that. [picks] is how many sectors were
/// picked; null when there are none (or the startup has no sector).
double? _sector(int picks, bool main, bool other, MatchStartup s) {
  if (picks == 0 || s.sector == null || s.sector!.isEmpty) return null;
  if (main) return 1 / math.sqrt(picks);
  if (other) return otherSectorFactor / math.sqrt(picks);
  return 0;
}

/// Per-part overlaps of a profile; null = blank, skipped by [weightedScore].
Map<String, double?> scoreParts(MatchInvestor i, MatchStartup s) => {
  'sector': _sector(
    i.sectors.length,
    i.sectors.contains(s.sector),
    sharesOtherSector(i, s),
    s,
  ),
  'stage': _overlap(i.stages, s.stage),
  'model': _overlap(i.models, s.businessModel),
};

/// Per-part overlaps of a ticket: sector and stage from [t], the commerce
/// model from the investor's profile ([models]).
Map<String, double?> ticketScoreParts(
  MatchTicket t,
  Set<String> models,
  MatchStartup s,
) => {
  'sector': _sector(
    t.sectors.length,
    ticketSectorFits(t, s),
    ticketSharesOtherSector(t, s),
    s,
  ),
  'stage': _overlap(t.stages, s.stage),
  'model': _overlap(models, s.businessModel),
  'fit': roundFit(t, s),
};

/// How much of what the round still needs the ticket's maximum can cover:
/// 1 when it covers all of it, 0.25 when it covers a quarter. Null when
/// the startup isn't raising (the part is skipped).
double? roundFit(MatchTicket t, MatchStartup s) {
  final left = s.remaining;
  if (left <= 0) return null;
  return math.min(1.0, t.amountMax / left);
}

/// "covers up to 7%" (what [roundFit] shows), "covers under 1%" below 1%.
String _covers(MatchTicket t, MatchStartup s) {
  final pct = ((roundFit(t, s) ?? 0) * 100).round();
  return pct < 1 ? 'covers under 1%' : 'covers up to $pct%';
}

double weightedScore(Map<String, double?> parts) {
  var total = 0.0;
  var used = 0.0;
  parts.forEach((key, value) {
    if (value == null) return;
    total += weights[key]! * value;
    used += weights[key]!;
  });
  return used == 0 ? 0.0 : total / used;
}

int _percent(double x) => math.min(100, (x * 100).round());

// ----------------------------------------------------------- explanation

String _amount(int sar) {
  String short(double v) {
    final tenths = (v * 10).round();
    return tenths % 10 == 0
        ? '${tenths ~/ 10}'
        : '${tenths ~/ 10}.${tenths % 10}';
  }

  if (sar >= 1000000) return '${short(sar / 1000000)}M';
  if (sar >= 1000) return '${short(sar / 1000)}K';
  return short(sar.toDouble());
}

String _sar(int amount) => 'SAR ${_amount(amount)}';

/// "Fintech, AI +2": at most three, then "+N".
String _list(Iterable<String> items) {
  final all = items.toList();
  if (all.length <= 3) return all.join(', ');
  return '${all.take(3).join(', ')} +${all.length - 3}';
}

String _stage(String? v) => _stageLabel[v] ?? v ?? '';
String _model(String? v) => _modelShort[v] ?? v ?? '';

/// The sector row. [picks] are the investor's / ticket's sectors as
/// labels; [whose] starts the note ("your ticket", "they invest in").
MatchRow _sectorRow(
  MatchStartup s, {
  required bool main,
  required String? other,
  required List<String> picks,
  required String whose,
}) {
  if (main) return MatchRow('Sector', s.sectorLabel, fits: true);
  if (other != null) {
    return MatchRow(
      'Sector',
      other,
      fits: true,
      note: 'one of its other sectors',
    );
  }
  return MatchRow(
    'Sector',
    s.sectorLabel,
    fits: false,
    note: '$whose ${_list(picks)}',
  );
}

MatchRow _stageRow(MatchStartup s, Set<String> stages, String whose) {
  if (stages.contains(s.stage)) {
    return MatchRow('Stage', _stage(s.stage), fits: true);
  }
  final picked = [
    for (final v in stageValue.values)
      if (stages.contains(v)) _stage(v),
  ];
  return MatchRow(
    'Stage',
    _stage(s.stage),
    fits: false,
    note: '$whose ${_list(picked)}',
  );
}

/// Null when the investor has no commerce models (the part is skipped).
MatchRow? _modelRow(MatchStartup s, Set<String> models, String whose) {
  if (models.isEmpty || s.businessModel == null) return null;
  if (models.contains(s.businessModel)) {
    return MatchRow('Commerce model', _model(s.businessModel), fits: true);
  }
  final picked = [
    for (final v in modelValue.values)
      if (models.contains(v)) _model(v),
  ];
  return MatchRow(
    'Commerce model',
    _model(s.businessModel),
    fits: false,
    note: '$whose ${_list(picked)}',
  );
}

String? _otherSectorHit(MatchStartup s, Set<String> picks) {
  for (final v in s.otherSectors) {
    if (picks.contains(v)) return sectorLabelOf[v];
  }
  return null;
}

/// An investor looking at a startup from their ticket.
List<MatchRow> ticketRows(MatchTicket t, Set<String> models, MatchStartup s) {
  final main = ticketSectorFits(t, s);
  final range = '${_sar(t.amountMin)}–${_amount(t.amountMax)}';
  return [
    _sectorRow(
      s,
      main: main,
      other: main ? null : _otherSectorHit(s, t.sectorValues),
      picks: t.sectors,
      whose: 'your ticket:',
    ),
    _stageRow(s, t.stages, 'your ticket:'),
    ?_modelRow(s, models, 'you prefer'),
    MatchRow(
      'Amount',
      '${_sar(s.remaining)} left',
      fits: ticketAmountFits(t, s),
      note: t.amountMax >= s.remaining
          ? 'within your ticket $range'
          : 'your ticket $range ${_covers(t, s)}',
    ),
  ];
}

/// A founder looking at an investor who has an open ticket that fits.
List<MatchRow> roundTicketRows(
  MatchTicket t,
  Set<String> models,
  MatchStartup s,
) {
  final main = ticketSectorFits(t, s);
  return [
    _sectorRow(
      s,
      main: main,
      other: main ? null : _otherSectorHit(s, t.sectorValues),
      picks: t.sectors,
      whose: 'their ticket:',
    ),
    _stageRow(s, t.stages, 'their ticket:'),
    ?_modelRow(s, models, 'they prefer'),
    MatchRow(
      'Their ticket',
      '${_sar(t.amountMin)}–${_amount(t.amountMax)}',
      fits: ticketAmountFits(t, s),
      note: t.amountMax >= s.remaining
          ? '${_sar(s.remaining)} left in your round'
          : '${_sar(s.remaining)} left in your round · ${_covers(t, s)}',
    ),
  ];
}

/// A founder looking at an investor matched on their profile.
List<MatchRow> profileRows(MatchInvestor i, MatchStartup s) {
  final main = i.sectors.contains(s.sector);
  return [
    _sectorRow(
      s,
      main: main,
      other: main ? null : _otherSectorHit(s, i.sectors),
      picks: [
        for (final e in sectorValue.entries)
          if (i.sectors.contains(e.value)) e.key,
      ],
      whose: 'they invest in',
    ),
    _stageRow(s, i.stages, 'they invest in'),
    ?_modelRow(s, i.models, 'they prefer'),
    if (ticketFits(i, s) != null)
      MatchRow(
        'Ticket size',
        i.ticketSize!,
        fits: ticketFits(i, s)!,
        note: '${_sar(s.remaining)} left in your round',
      ),
    if (roundSizeFits(i, s) != null)
      MatchRow(
        'Round size',
        [
          if (i.roundSizeMin != null) _sar(i.roundSizeMin!),
          if (i.roundSizeMax != null) _sar(i.roundSizeMax!),
        ].join('–'),
        fits: roundSizeFits(i, s)!,
        note: 'your round is ${_sar(s.fundingRequirement!)}',
      ),
  ];
}

// ----------------------------------------------------------------- order

int _byScore(MatchResult a, MatchResult b) =>
    (b.score * 1e9).round().compareTo((a.score * 1e9).round());

int _compare(MatchResult a, MatchResult b) {
  final byScore = _byScore(a, b);
  if (byScore != 0) return byScore;
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  return byName != 0 ? byName : a.id.compareTo(b.id);
}

/// Exact matches first, then close ones, each sorted.
List<MatchResult> _ordered(List<MatchResult> all) {
  final exact = [for (final m in all) if (!m.close) m]..sort(_compare);
  final close = [for (final m in all) if (m.close) m]..sort(_compare);
  return [...exact, ...close];
}

// --------------------------------------------------------------- tickets

/// One ticket against one startup, or null when they don't match (the
/// ticket isn't open, the startup isn't listed or raising, or more than the
/// sector or the stage misses).
MatchResult? matchTicket(MatchTicket t, Set<String> models, MatchStartup s) {
  if (!t.isOpen || !s.isListed || !s.isRaising) return null;
  final failed = failedTicketFilters(t, s);
  final exact = failed.isEmpty;
  if (!exact && !isCloseForTicket(t, s)) return null;
  final score = weightedScore(ticketScoreParts(t, models, s));
  return MatchResult(
    id: s.id,
    name: s.name,
    score: score,
    percent: _percent(score),
    rows: ticketRows(t, models, s),
    close: !exact,
    remaining: s.remaining,
  );
}

/// A ticket's matches in the Wallet, best first: listed (public, not
/// closed) startups that are raising. [models] are the investor's profile
/// commerce models. All of them unless [limit] is given.
List<MatchResult> matchesForTicket(
  MatchTicket ticket,
  Set<String> models,
  List<MatchStartup> startups, {
  int? limit,
}) {
  final all = [
    for (final s in startups) ?matchTicket(ticket, models, s),
  ];
  final out = _ordered(all);
  return limit == null ? out : out.take(limit).toList();
}

// ---------------------------------------------------------------- rounds

/// The investors matched to a founder's open round, best first. [startup]
/// carries the round (stage = the round type, fundingRequirement = its
/// amount, raisedInRound = what it raised); it may be private. A closed
/// startup, or one that isn't raising, gets nothing.
///
/// Group 1: investors with an open ticket that fits (their best ticket).
/// Group 2: every other investor, on their profile. Each investor once.
List<MatchResult> matchesForStartup(
  MatchStartup startup,
  List<MatchInvestor> investors, {
  List<MatchTicket> tickets = const [],
  int limit = topN,
}) {
  if (startup.isClosed || !startup.isRaising) return const [];
  final ticketsOf = <String, List<MatchTicket>>{};
  for (final t in tickets) {
    if (t.isOpen) (ticketsOf[t.investorId] ??= []).add(t);
  }
  final viaTicket = <MatchResult>[];
  final viaProfile = <MatchResult>[];
  for (final i in investors) {
    MatchResult? best;
    for (final t in ticketsOf[i.id] ?? const <MatchTicket>[]) {
      final exact = failedTicketFilters(t, startup).isEmpty;
      if (!exact && !isCloseForTicket(t, startup)) continue;
      final score = weightedScore(ticketScoreParts(t, i.models, startup));
      final m = MatchResult(
        id: i.id,
        name: i.name,
        score: score,
        percent: _percent(score),
        rows: roundTicketRows(t, i.models, startup),
        close: !exact,
        ticketId: t.id,
      );
      if (best == null ||
          (best.close && !m.close) ||
          (best.close == m.close && _byScore(m, best) < 0)) {
        best = m;
      }
    }
    if (best != null) {
      viaTicket.add(best);
      continue;
    }
    if (!i.interestsComplete) continue;
    final exact = failedFilters(i, startup).isEmpty;
    if (!exact && !isClose(i, startup)) continue;
    final score = weightedScore(scoreParts(i, startup));
    viaProfile.add(
      MatchResult(
        id: i.id,
        name: i.name,
        score: score,
        percent: _percent(score),
        rows: profileRows(i, startup),
        close: !exact,
      ),
    );
  }
  return [
    ..._ordered(viaTicket),
    ..._ordered(viaProfile),
  ].take(limit).toList();
}
