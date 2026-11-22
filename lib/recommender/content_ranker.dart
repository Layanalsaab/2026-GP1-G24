/// Matching, part 2: score, order and explanation (content-based).
library;

import 'dart:math' as math;

import 'knowledge_filter.dart';

const Map<String, double> weights = {
  'sector': 0.41,
  'stage': 0.29,
  'model': 0.18,
  'fit': 0.12,
};

/// How many investors a round's Matches can hold (the screen shows fewer).
const int topN = 20;

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

/// One match: a startup (a ticket's matches) or an investor (a round's matches).
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
    this.fit,
    this.activity = -1,
    this.picks = 0,
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

  final String? ticketId;

  /// Ticket matches: what the startup's round still needs (SAR).
  final int remaining;

  /// Tie-breakers for equal scores (PDF 1.7): how much of the round the
  /// ticket covers (null for profile matches), the investor's activity rank
  /// (MatchInvestor.activity) and their sector + stage picks (fewer first).
  final double? fit;
  final int activity;
  final int picks;

  bool get viaTicket => ticketId != null;
}

/// Met (1) or not met (0); null = blank, skipped by weightedScore.
double? _overlap(Set<String> chosen, String? value) {
  if (chosen.isEmpty || value == null || value.isEmpty) return null;
  return chosen.contains(value) ? 1.0 : 0.0;
}

/// Met (1), partly met through another sector (0.5) or not met (0).
double? _sector(int picks, bool main, bool other, MatchStartup s) {
  if (picks == 0 || s.sector == null || s.sector!.isEmpty) return null;
  if (main) return 1;
  if (other) return otherSectorFactor;
  return 0;
}

/// Per-part overlaps of a profile; null = blank, skipped by weightedScore.
Map<String, double?> scoreParts(MatchInvestor i, MatchStartup s) => {
  'sector': _sector(
    i.sectors.length,
    i.sectors.contains(s.sector),
    sharesOtherSector(i, s),
    s,
  ),
  'stage': _overlap(i.stages, s.stage),
  'model': _overlap(i.models, s.commerceModel),
};

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
  'model': _overlap(models, s.commerceModel),
  'fit': roundFit(t, s),
};

double? roundFit(MatchTicket t, MatchStartup s) {
  final left = s.remaining;
  if (left <= 0) return null;
  return math.min(1.0, t.amountMax / left);
}

/// "covers up to 7%" (what roundFit shows), "covers under 1%" below 1%.
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

/// The sector row.
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
  if (models.isEmpty || s.commerceModel == null) return null;
  if (models.contains(s.commerceModel)) {
    return MatchRow('Commerce model', _model(s.commerceModel), fits: true);
  }
  final picked = [
    for (final v in modelValue.values)
      if (models.contains(v)) _model(v),
  ];
  return MatchRow(
    'Commerce model',
    _model(s.commerceModel),
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

/// Higher first, ignoring differences below 1e-9.
int _higher(double a, double b) => (b * 1e9).round().compareTo((a * 1e9).round());

int _byScore(MatchResult a, MatchResult b) => _higher(a.score, b.score);

/// Equal scores: round fit, then activity, then fewer picks, then name and id.
int _compare(MatchResult a, MatchResult b) {
  for (final c in [
    _byScore(a, b),
    _higher(a.fit ?? 0, b.fit ?? 0),
    b.activity.compareTo(a.activity),
    a.picks.compareTo(b.picks),
    a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  ]) {
    if (c != 0) return c;
  }
  return a.id.compareTo(b.id);
}

/// The ticket to show for an investor: exact beats close, then the higher
/// score, then the higher round fit, then the smaller ticket id.
bool _betterTicket(MatchResult m, MatchResult best) {
  if (best.close != m.close) return !m.close;
  for (final c in [_byScore(m, best), _higher(m.fit ?? 0, best.fit ?? 0)]) {
    if (c != 0) return c < 0;
  }
  return m.ticketId!.compareTo(best.ticketId!) < 0;
}

/// Exact matches first, then close ones, each sorted.
List<MatchResult> _ordered(List<MatchResult> all) {
  final exact = [for (final m in all) if (!m.close) m]..sort(_compare);
  final close = [for (final m in all) if (m.close) m]..sort(_compare);
  return [...exact, ...close];
}

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
    fit: roundFit(t, s),
  );
}

/// A ticket's matches in the Wallet, best first: listed (public, not closed) startups that are raising.
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

/// The investors matched to a founder's open round, best first.
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
        fit: roundFit(t, startup),
        activity: i.activity,
        picks: t.picks,
      );
      if (best == null || _betterTicket(m, best)) best = m;
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
        activity: i.activity,
        picks: i.picks,
      ),
    );
  }
  return [
    ..._ordered(viaTicket),
    ..._ordered(viaProfile),
  ].take(limit).toList();
}
