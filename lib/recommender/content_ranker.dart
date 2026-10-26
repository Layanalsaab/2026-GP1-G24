/// Matches tab, part 2: score, explanations and ranking
/// (content-based). Part 1 (documents and hard filters) is
/// knowledge_filter.dart. Python reference: matching_v2.py.
///
/// Rules (matchmaking-attributes-v1, adapted to the app's screens):
/// - Score: weighted cosine, sector 0.41, stage 0.29, commerce model 0.18,
///   divided by the weights used (0.88), so sector counts 47%, stage 33%
///   and commerce model 20%. City / region is not used anywhere in the
///   matching (team decision, 26 Oct 2026). The score is the same in both
///   directions.
/// - No boosts: the order is the match score alone on both sides (team
///   decision, 26 Oct 2026: no activity, region or lead boost).
/// - Founder side tie-break (equal scores only, see [leadFit]): a startup
///   that wants a lead investor gets investors who have led a round first;
///   one that doesn't gets co-investors first (Preferably, then Possibly).
/// - Order: exact matches first (every hard filter passes), then close
///   matches (sector OR stage fits, ticket and round size still fit), each
///   group by score. Close cards start their reasons with "Close match".
/// - Eligibility: an investor's Matches show only public startups that are
///   raising (an open funding round); the others stay in Hub, For You and
///   Search (team decision, 26 Oct 2026).
/// - Ties (equal scores only): on the founder side, [leadFit]. Then the
///   name. Crunchbase rank is not used (team decision, 26 Oct 2026).
library;

import 'dart:math' as math;

import 'knowledge_filter.dart';

const Map<String, double> weights = {
  'sector': 0.41,
  'stage': 0.29,
  'model': 0.18,
};
const int topN = 20;

final Map<String, String> _sectorLabel = {
  for (final e in sectorValue.entries) e.value: e.key,
};
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

/// One card on the Matches tab.
class MatchResult {
  const MatchResult({
    required this.id,
    required this.name,
    required this.score,
    required this.rankScore,
    required this.percent,
    required this.reasons,
    required this.label,
    this.leadFit = 0,
    this.close = false,
  });

  /// The startup id (investor's Matches) or investor id (founder's Matches).
  final String id;
  final String name;

  /// 0-1, the same in both directions.
  final double score;

  /// What the list is sorted by: the same as [score] (there are no boosts).
  final double rankScore;

  /// Shown on the card, at most 100.
  final int percent;

  /// Why it matched, e.g. "Same sector (Fintech)", "Seed stage".
  final List<String> reasons;

  /// Investor's Matches: "Raising SAR 2M".
  /// Founder's Matches: the investor's ticket size.
  final String label;

  /// Founder's Matches: how well the investor fits the startup's lead
  /// answer ([leadFit]); breaks ties only. 0 on the investor's Matches.
  final int leadFit;

  /// A close match (sector or stage differs), listed after the exact ones.
  final bool close;
}

double? _overlap(Set<String> chosen, String? value) {
  if (chosen.isEmpty || value == null || value.isEmpty) return null;
  return (chosen.contains(value) ? 1.0 : 0.0) / math.sqrt(chosen.length);
}

/// Per-attribute overlaps; null = blank, skipped by [weightedScore].
Map<String, double?> scoreParts(MatchInvestor i, MatchStartup s) => {
  'sector': _overlap(i.sectors, s.sector),
  'stage': _overlap(i.stages, s.stage),
  'model': _overlap(i.models, s.businessModel),
};

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

String cardLabel(MatchStartup s) => s.isRaising
    ? 'Raising SAR ${_amount(s.fundingRequirement!)}'
    : 'Not raising now';

List<String> reasonsForInvestor(MatchInvestor i, MatchStartup s) {
  return [
    if (isClose(i, s)) 'Close match',
    if (i.sectors.contains(s.sector))
      'Same sector (${_sectorLabel[s.sector] ?? s.sector})',
    if (i.stages.contains(s.stage)) '${_stageLabel[s.stage] ?? s.stage} stage',
    if (i.models.contains(s.businessModel))
      _modelShort[s.businessModel] ?? s.businessModel!,
    if (ticketFits(i, s) == true) 'Fits your ticket',
  ];
}

List<String> reasonsForFounder(MatchInvestor i, MatchStartup s) {
  return [
    if (isClose(i, s)) 'Close match',
    if (i.sectors.contains(s.sector))
      'Invests in ${_sectorLabel[s.sector] ?? s.sector}',
    if (i.stages.contains(s.stage))
      'Backs ${_stageLabel[s.stage] ?? s.stage} startups',
    if (i.models.contains(s.businessModel))
      'Likes ${_modelShort[s.businessModel] ?? s.businessModel}',
    if (ticketFits(i, s) == true) 'Ticket fits your funding need',
  ];
}

/// The one-line reason on a Matches card. The card shows one line only, so
/// it names the two main fits (sector, stage): "Same sector & stage",
/// "Close match · same sector". The commerce model still counts in the
/// percent; the full list is [MatchResult.reasons].
String shortReason(MatchInvestor i, MatchStartup s) {
  final sector = i.sectors.contains(s.sector);
  if (isClose(i, s)) return 'Close match · same ${sector ? 'sector' : 'stage'}';
  return 'Same sector & stage';
}

int _percent(double x) => math.min(100, (x * 100).round());

/// Founder side tie-break: wants a lead -> 1 for an investor who has led a
/// round; doesn't want one -> 2 for co-invest "Preferably", 1 "Possibly";
/// no answer -> 0 for everyone. Higher comes first among equal scores.
int leadFit(MatchInvestor i, MatchStartup s) => switch (s.wantsLeadInvestor) {
  true => i.hasLedRound == true ? 1 : 0,
  false => switch (i.coInvest) {
    'Preferably' => 2,
    'Possibly' => 1,
    _ => 0,
  },
  null => 0,
};

int _compare(MatchResult a, MatchResult b) {
  final byScore = (b.rankScore * 1e9).round().compareTo(
    (a.rankScore * 1e9).round(),
  );
  if (byScore != 0) return byScore;
  if (a.leadFit != b.leadFit) return b.leadFit.compareTo(a.leadFit);
  final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
  return byName != 0 ? byName : a.id.compareTo(b.id);
}

/// Exact matches first, then close ones, each sorted; the first [limit].
List<MatchResult> _fill(
  List<MatchResult> exact,
  List<MatchResult> close,
  int limit,
) {
  exact.sort(_compare);
  close.sort(_compare);
  return [...exact, ...close].take(limit).toList();
}

/// An investor's Matches: public startups that are raising (an open funding
/// round), so every card can be invested in now.
List<MatchResult> matchesForInvestor(
  MatchInvestor investor,
  List<MatchStartup> startups, {
  int limit = topN,
}) {
  if (!investor.interestsComplete) return const [];
  final exact = <MatchResult>[];
  final close = <MatchResult>[];
  for (final s in startups) {
    if (!s.isPublic || !s.isRaising) continue;
    final isExact = failedFilters(investor, s).isEmpty;
    if (!isExact && !isClose(investor, s)) continue;
    final score = weightedScore(scoreParts(investor, s));
    (isExact ? exact : close).add(
      MatchResult(
        id: s.id,
        name: s.name,
        score: score,
        rankScore: score,
        percent: _percent(score),
        reasons: reasonsForInvestor(investor, s),
        label: cardLabel(s),
        close: !isExact,
      ),
    );
  }
  return _fill(exact, close, limit);
}

/// A founder's Matches for one of their startups (public or private).
List<MatchResult> matchesForStartup(
  MatchStartup startup,
  List<MatchInvestor> investors, {
  int limit = topN,
}) {
  final exact = <MatchResult>[];
  final close = <MatchResult>[];
  for (final i in investors) {
    if (!i.interestsComplete) continue;
    final isExact = failedFilters(i, startup).isEmpty;
    if (!isExact && !isClose(i, startup)) continue;
    final score = weightedScore(scoreParts(i, startup));
    (isExact ? exact : close).add(
      MatchResult(
        id: i.id,
        name: i.name,
        score: score,
        rankScore: score,
        percent: _percent(score),
        reasons: reasonsForFounder(i, startup),
        label: i.ticketSize ?? '',
        leadFit: leadFit(i, startup),
        close: !isExact,
      ),
    );
  }
  return _fill(exact, close, limit);
}
