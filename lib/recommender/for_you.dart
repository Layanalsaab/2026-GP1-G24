/// For You: a content-based recommender that adapts to bookmarks.
///
/// Every startup and investor is described by the same three attributes the
/// matching uses (sector, stage, commerce model). A person's "taste" starts
/// as their onboarding answers and moves toward what they bookmark: recent
/// bookmarks count more, old ones fade, and more bookmarks mean more pull.
/// It is separate from Matches and never changes its order or its percent.
library;

import 'dart:math' as math;

import '../models/investment_ticket.dart';
import '../models/investor_criteria.dart';
import '../models/investor_profile.dart';
import '../models/startup.dart';
import 'knowledge_filter.dart'
    show modelValue, sectorValue, stageValue, ticketMin;

/// The same attribute weights as the matching.
const Map<String, double> groupWeights = {
  'sector': 0.41,
  'stage': 0.29,
  'model': 0.18,
};

/// A startup's other sectors count the same as its main one.
const double otherSectorWeight = 1;

/// A bookmark counts half as much after this many days, but never less than
/// [oldestBookmarkWeight]: past bookmarks keep counting.
const double halfLifeDays = 90;
const double oldestBookmarkWeight = 0.4;

/// The most the bookmarks can pull the taste away from the onboarding answers.
const double maxLearnedShare = 0.6;

/// How fast the pull grows: with this many fresh bookmarks it is half of the
/// maximum.
const double _halfPullBookmarks = 2;

const int defaultLimit = 20;

/// An open ticket counts this much more than a bookmark when it shapes the
/// taste: it is what the investor wants right now.
const double ticketStrength = 1.5;

/// Added to a score when an investor's open ticket takes the startup's amount
/// and also its sector and stage, or only its amount.
const double ticketFitBonus = 0.3;
const double ticketAmountBonus = 0.1;

/// Slots at the end of the list kept for items unlike the rest.
const int exploreSlots = 2;

/// Attribute -> weight, per group ('sector', 'stage', 'model').
typedef Vec = Map<String, double>;

/// What something is made of: a startup, an investor's interests or a taste.
class Features {
  const Features(this.groups);

  final Map<String, Vec> groups;

  static const empty = Features({});

  bool get isEmpty => groups.values.every((v) => v.isEmpty);
}

// ---------------------------------------------------------------- features

Vec _clean(Vec v) => v..remove('other');

String? _modelOf(String label) {
  final known = modelValue[label];
  if (known != null) return known;
  final short = RegExp(r'\(([^)]+)\)').firstMatch(label)?.group(1) ?? label;
  final value = short.trim().toLowerCase();
  return modelValue.containsValue(value) ? value : null;
}

Vec _ones(Iterable<String> labels, String? Function(String) toValue) => _clean({
  for (final l in labels)
    if (toValue(l) != null) toValue(l)!: 1.0,
});

Features startupFeatures(Startup s) {
  final sectors = <String, double>{s.sector.value: 1};
  for (final label in s.otherSectors) {
    final v = sectorValue[label];
    if (v != null) sectors.putIfAbsent(v, () => otherSectorWeight);
  }
  return Features({
    'sector': _clean(sectors),
    'stage': _clean({s.stage.value: 1}),
    'model': _clean({s.businessModel.value: 1}),
  });
}

Features investorFeatures(InvestorProfile i) => Features({
  'sector': _ones(i.sectors, (l) => sectorValue[l]),
  'stage': _ones(i.stages, (l) => stageValue[l]),
  'model': _ones(i.commerceModels, _modelOf),
});

Features criteriaFeatures(InvestorCriteria c) => Features({
  'sector': _ones(c.sectors, (l) => sectorValue[l]),
  'stage': _ones(c.stages, (l) => stageValue[l]),
  'model': _ones(c.commerceModels, _modelOf),
});

Features ticketFeatures(InvestmentTicket t) => Features({
  'sector': _ones(t.sectors, (l) => sectorValue[l]),
  'stage': _ones(t.stages, (l) => stageValue[l]),
  'model': <String, double>{},
});

/// Several features added up.
Features combine(Iterable<Features> all) {
  final sum = {for (final g in groupWeights.keys) g: <String, double>{}};
  for (final f in all) {
    for (final g in groupWeights.keys) {
      f.groups[g]?.forEach((k, w) => sum[g]![k] = (sum[g]![k] ?? 0) + w);
    }
  }
  return Features(sum);
}

// ------------------------------------------------------------------- maths

Vec _unit(Vec v) {
  final norm = math.sqrt(v.values.fold<double>(0, (a, w) => a + w * w));
  return norm == 0
      ? <String, double>{}
      : {for (final e in v.entries) e.key: e.value / norm};
}

double _cosine(Vec a, Vec b) {
  if (a.isEmpty || b.isEmpty) return 0;
  var dot = 0.0;
  a.forEach((k, w) => dot += w * (b[k] ?? 0));
  final na = math.sqrt(a.values.fold<double>(0, (s, w) => s + w * w));
  final nb = math.sqrt(b.values.fold<double>(0, (s, w) => s + w * w));
  return na == 0 || nb == 0 ? 0 : dot / (na * nb);
}

/// Weighted cosine over the groups both sides have (like the matching score).
double similarity(Features a, Features b) {
  var total = 0.0;
  var used = 0.0;
  for (final g in groupWeights.keys) {
    final x = a.groups[g] ?? const <String, double>{};
    final y = b.groups[g] ?? const <String, double>{};
    if (x.isEmpty || y.isEmpty) continue;
    total += groupWeights[g]! * _cosine(x, y);
    used += groupWeights[g]!;
  }
  return used == 0 ? 0 : total / used;
}

// ------------------------------------------------------------------- taste

/// Something the person bookmarked (or an open ticket), and when. [strength]
/// is how much more than a bookmark it counts.
class Signal {
  const Signal(this.features, this.at, {this.strength = 1});

  final Features features;
  final DateTime at;
  final double strength;
}

class Taste {
  Taste._(this.features, this.learnedShare, this.signals);

  /// The person's onboarding answers pulled toward their bookmarks.
  final Features features;

  /// 0 = only the onboarding answers, up to [maxLearnedShare].
  final double learnedShare;
  final List<Signal> signals;

  bool get isEmpty => features.isEmpty;

  factory Taste.build(
    Features base,
    List<Signal> signals, {
    required DateTime now,
  }) {
    final weights = [
      for (final s in signals)
        s.strength *
            math.max(
              oldestBookmarkWeight,
              math
                  .pow(
                    0.5,
                    math.max(0, now.difference(s.at).inHours) /
                        24 /
                        halfLifeDays,
                  )
                  .toDouble(),
            ),
    ];
    final fresh = weights.fold<double>(0, (a, w) => a + w);
    final share = maxLearnedShare * fresh / (fresh + _halfPullBookmarks);

    final groups = <String, Vec>{};
    for (final g in groupWeights.keys) {
      final learned = <String, double>{};
      for (var i = 0; i < signals.length; i++) {
        _unit(signals[i].features.groups[g] ?? const {})
            .forEach((k, w) => learned[k] = (learned[k] ?? 0) + w * weights[i]);
      }
      final from = _unit(base.groups[g] ?? const {});
      final toward = _unit(learned);
      if (toward.isEmpty) {
        groups[g] = from;
      } else if (from.isEmpty) {
        groups[g] = toward;
      } else {
        groups[g] = {
          for (final k in {...from.keys, ...toward.keys})
            k: (1 - share) * (from[k] ?? 0) + share * (toward[k] ?? 0),
        };
      }
    }
    return Taste._(Features(groups), signals.isEmpty ? 0 : share, signals);
  }
}

// --------------------------------------------------------------- recommend

class Candidate<T> {
  const Candidate(this.item, this.name, this.features, this.mainSector);

  final T item;
  final String name;
  final Features features;
  final String? mainSector;
}

class Pick<T> {
  const Pick(this.item, this.score);

  final T item;
  final double score;
}

/// The best [limit] candidates for [taste]; see [recommendBest].
List<Pick<T>> recommend<T>(
  Taste taste,
  List<Candidate<T>> candidates, {
  int limit = defaultLimit,
}) => recommendBest([taste], candidates, limit: limit);

/// The best [limit] candidates for several tastes (a founder's startups, one
/// taste each). A candidate is scored against every taste it is [allowed] for
/// and keeps only its best score, so a person with two different startups
/// gets good picks for both. Equal best scores: the candidate that fits more
/// of the tastes goes first, then the name. Candidates nothing fits are left
/// out. The last [exploreSlots] places go to the best ones from a sector not
/// already in the list, so it isn't all the same.
List<Pick<T>> recommendBest<T>(
  List<Taste> tastes,
  List<Candidate<T>> candidates, {
  bool Function(Candidate<T> candidate, int taste)? allowed,
  double Function(Candidate<T> candidate, int taste)? bonus,
  int limit = defaultLimit,
}) {
  final scored = <({Candidate<T> c, double score, int fits})>[];
  for (final c in candidates) {
    var best = 0.0;
    var fits = 0;
    for (var i = 0; i < tastes.length; i++) {
      if (tastes[i].isEmpty || !(allowed?.call(c, i) ?? true)) continue;
      final base = similarity(tastes[i].features, c.features);
      if (base <= 0) continue;
      fits++;
      best = math.max(best, base + (bonus?.call(c, i) ?? 0));
    }
    if (best > 0) scored.add((c: c, score: best, fits: fits));
  }
  scored.sort((a, b) {
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byFits = b.fits.compareTo(a.fits);
    return byFits != 0 ? byFits : a.c.name.compareTo(b.c.name);
  });

  final main = scored.take(math.max(0, limit - exploreSlots)).toList();
  final rest = scored.skip(main.length).toList();
  final sectors = {for (final e in main) e.c.mainSector};
  final picked = [...main];
  for (final e in rest) {
    if (picked.length >= limit) break;
    if (!sectors.contains(e.c.mainSector)) {
      picked.add(e);
      sectors.add(e.c.mainSector);
    }
  }
  for (final e in rest) {
    if (picked.length >= limit) break;
    if (!picked.contains(e)) picked.add(e);
  }

  return [for (final e in picked) Pick(e.c.item, e.score)];
}

bool _inRange(InvestmentTicket t, int amount) =>
    amount >= t.amountMin && amount <= t.amountMax;

/// The amount a startup is raising (its open round), or null when it isn't.
int? _raising(Startup s) {
  final need = s.fundingRequirement ?? 0;
  return s.seeksFunding && need > 0 ? need : null;
}

/// True when one of the [tickets] takes the startup's amount, sector and
/// stage (a ticket with no sector or no stage chosen takes any).
bool ticketFits(Startup s, Iterable<InvestmentTicket> tickets) {
  final need = _raising(s);
  if (need == null) return false;
  final sectors = {s.sector.label, s.sectorLabel, ...s.sectorLabels};
  final stages = {s.stage.label, s.stageLabel};
  return tickets.any(
    (t) =>
        _inRange(t, need) &&
        (t.sectors.isEmpty || t.sectors.any(sectors.contains)) &&
        (t.stages.isEmpty || t.stages.any(stages.contains)),
  );
}

/// What the investor's open tickets add to a startup's score: a full fit
/// counts most, an amount that is only inside a ticket's range a little.
double ticketBonus(Startup s, Iterable<InvestmentTicket> tickets) {
  final need = _raising(s);
  if (need == null || tickets.isEmpty) return 0;
  if (ticketFits(s, tickets)) return ticketFitBonus;
  return tickets.any((t) => _inRange(t, need)) ? ticketAmountBonus : 0;
}

/// The amount check: the onboarding answers (see [sizesFit]) still count, and
/// an open ticket that takes the startup's amount, sector and stage (see
/// [ticketFits]) also makes it fit.
bool amountFits(
  Startup s, {
  Iterable<InvestmentTicket> tickets = const [],
  String? ticketBand,
  int? roundMin,
  int? roundMax,
}) =>
    sizesFit(
      s,
      ticketBand: ticketBand,
      roundMin: roundMin,
      roundMax: roundMax,
    ) ||
    ticketFits(s, tickets);

/// The onboarding amount check of the matching. It only fails when the
/// startup is raising and its amount is outside what the investor takes; an
/// answer that is missing is not checked.
bool sizesFit(Startup s, {String? ticketBand, int? roundMin, int? roundMax}) {
  final need = s.fundingRequirement ?? 0;
  if (!s.seeksFunding || need <= 0) return true;
  final min = ticketMin[ticketBand ?? ''];
  if (min != null && min > need) return false;
  if (roundMin != null && need < roundMin) return false;
  if (roundMax != null && need > roundMax) return false;
  return true;
}
