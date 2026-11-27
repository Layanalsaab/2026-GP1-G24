/// For You: a content-based recommender that adapts to bookmarks.
library;

import 'dart:math' as math;

import '../helpers/other_check.dart';
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

const double halfLifeDays = 90;
const double oldestBookmarkWeight = 0.4;

/// The most the bookmarks can pull the taste away from the onboarding answers.
const double maxLearnedShare = 0.6;

/// How fast the pull grows: with this many fresh bookmarks it is half of the maximum.
const double _halfPullBookmarks = 2;

const int defaultLimit = 20;

const double ticketStrength = 1.5;

/// How far one unit of "Not interested" pushes the taste away (as the server).
const double dislikeWeight = 0.2;

const double ticketFitBonus = 0.3;
const double ticketAmountBonus = 0.1;

/// Slots at the end of the list kept for items unlike the rest.
const int exploreSlots = 2;

/// Calibration (Steck, "Calibrated Recommendations", RecSys 2018), as the
/// server: relevance against closeness to the user's sector mix, and the
/// smoothing of the list's mix.
const double calibrationWeight = 0.5;
const double calibrationAlpha = 0.01;
const double calibrationTie = 1e-9;

/// Attribute -> weight, per group ('sector', 'stage', 'model').
typedef Vec = Map<String, double>;

/// What something is made of: a startup, an investor's interests or a taste.
class Features {
  const Features(this.groups);

  final Map<String, Vec> groups;

  static const empty = Features({});

  bool get isEmpty => groups.values.every((v) => v.isEmpty);
}

/// What an "Other" answer counts as: the written text ("other:spacetech"), or an existing
/// option when the text repeats one (as the backend does). The app always asks for a name,
/// so nothing written gives no value (only old imported data can lack one).
String? _written(String? text, Map<String, String> options) {
  final t = (text ?? '').trim();
  final key = t.isEmpty ? '' : OtherCheck.key(t);
  if (key.isEmpty || key == 'other') return null;
  for (final e in options.entries) {
    if (e.key != 'Other' && OtherCheck.key(e.key) == key) return e.value;
  }
  return 'other:$key';
}

String? _sectorOf(String label, [String? written]) => label == 'Other'
    ? _written(written, sectorValue)
    : sectorValue[label] ?? _written(label, sectorValue);

String? _writtenModel(String? text) {
  final known = _modelOf((text ?? '').trim());
  return known != null && known != 'other' ? known : _written(text, modelValue);
}

String? _modelAnswer(String label, [String? written]) => label == 'Other'
    ? _writtenModel(written)
    : _modelOf(label) ?? _writtenModel(label);

/// The answers that give a value, each counted once.
Vec _ones(Iterable<String?> values) => {for (final v in values) ?v: 1.0};

Vec _stages(Iterable<String> labels) => _ones([
  for (final l in labels)
    if (stageValue[l] != 'other') stageValue[l],
]);

String? _modelOf(String label) {
  final known = modelValue[label];
  if (known != null) return known;
  final short = RegExp(r'\(([^)]+)\)').firstMatch(label)?.group(1) ?? label;
  final value = short.trim().toLowerCase();
  return modelValue.containsValue(value) ? value : null;
}

/// A startup: "Other" counts as what the founder wrote ("other" when nothing was written).
/// A startup's main sector as the features write it (a typed Other answer
/// included).
String? startupMainSector(Startup s) => s.sector.value == 'other'
    ? _written(s.sectorOther, sectorValue)
    : s.sector.value;

/// Calibration counts a startup by its main sector only, so ticking many
/// sectors does not make it look like a perfect mix (as the server).
Vec startupCalibrationSectors(Startup s) => {?startupMainSector(s): 1};

Features startupFeatures(Startup s) {
  final main = startupMainSector(s);
  final sectors = <String, double>{?main: 1};
  for (final label in s.otherSectors) {
    final value = _sectorOf(label);
    if (value != null) sectors.putIfAbsent(value, () => otherSectorWeight);
  }
  final model = s.commerceModel.value == 'other'
      ? _writtenModel(s.commerceModelOther)
      : s.commerceModel.value;
  return Features({
    'sector': sectors,
    'stage': _ones([if (s.stage.value != 'other') s.stage.value]),
    'model': _ones([model]),
  });
}

Features investorFeatures(InvestorProfile i) => Features({
  'sector': _ones(i.sectors.map(_sectorOf)),
  'stage': _stages(i.stages),
  'model': _ones(i.commerceModels.map(_modelAnswer)),
});

Features criteriaFeatures(InvestorCriteria c) => Features({
  'sector': _ones([for (final l in c.sectors) _sectorOf(l, c.sectorsOther)]),
  'stage': _stages(c.stages),
  'model': _ones([
    for (final l in c.commerceModels) _modelAnswer(l, c.commerceModelsOther),
  ]),
});

Features ticketFeatures(InvestmentTicket t) => Features({
  'sector': _ones(t.sectors.map(_sectorOf)),
  'stage': _stages(t.stages),
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

/// Something the person bookmarked (or an open ticket), and when.
class Signal {
  const Signal(this.features, this.at, {this.strength = 1, this.sectors});

  final Features features;
  final DateTime at;
  final double strength;

  /// The sectors it adds to the calibration target (a startup: its main sector
  /// only); null: its sector feature.
  final Vec? sectors;
}

class Taste {
  Taste._(this.features, this.learnedShare, this.signals, this.target);

  /// The sector mix the list should follow (calibration): the base's sectors
  /// blended with the sectors of bookmarks and tickets by the learned share.
  /// Null when there are no sectors.
  final Vec? target;

  /// The person's onboarding answers pulled toward their bookmarks.
  final Features features;

  /// 0 = only the onboarding answers, up to maxLearnedShare.
  final double learnedShare;
  final List<Signal> signals;

  bool get isEmpty => features.isEmpty;

  /// signals: bookmarks and open tickets (pull toward); dislikes: "Not
  /// interested" marks (push away, weight [dislikeWeight]), as the server.
  factory Taste.build(
    Features base,
    List<Signal> signals, {
    List<Signal> dislikes = const [],
    required DateTime now,
  }) {
    double decayed(Signal s) =>
        s.strength *
        math.max(
          oldestBookmarkWeight,
          math
              .pow(
                0.5,
                math.max(0, now.difference(s.at).inHours) / 24 / halfLifeDays,
              )
              .toDouble(),
        );
    final weights = [for (final s in signals) decayed(s)];
    final dislikeWeights = [for (final s in dislikes) decayed(s)];
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
      final unwanted = <String, double>{};
      for (var i = 0; i < dislikes.length; i++) {
        _unit(dislikes[i].features.groups[g] ?? const {}).forEach(
          (k, w) => unwanted[k] = (unwanted[k] ?? 0) + w * dislikeWeights[i],
        );
      }
      final away = _unit(unwanted);
      final blended = groups[g]!;
      if (away.isNotEmpty && blended.values.any((w) => w != 0)) {
        // Below zero means "not wanted at all": dropped, as the server clips
        // at 0 (and skips a group left with nothing).
        groups[g] = {
          for (final k in {...blended.keys, ...away.keys})
            if ((blended[k] ?? 0) - dislikeWeight * (away[k] ?? 0) case final w
                when w > 0)
              k: w,
        };
      }
    }
    return Taste._(
      Features(groups),
      signals.isEmpty ? 0 : share,
      signals,
      _target(base, signals, weights, share),
    );
  }

  static Vec? _target(
    Features base,
    List<Signal> likes,
    List<double> weights,
    double share,
  ) {
    final baseSectors = base.groups['sector'];
    final fromBase = _mixOf(baseSectors);
    final liked = <String, double>{};
    var total = 0.0;
    for (var i = 0; i < likes.length; i++) {
      final mix = _mixOf(
        _inside(
          likes[i].sectors ?? likes[i].features.groups['sector'],
          baseSectors,
        ),
      );
      if (mix == null || weights[i] <= 0) continue;
      mix.forEach((k, v) => liked[k] = (liked[k] ?? 0) + weights[i] * v);
      total += weights[i];
    }
    final fromLikes = total > 0
        ? {for (final e in liked.entries) e.key: e.value / total}
        : null;
    if (fromBase == null) return fromLikes;
    if (fromLikes == null) return fromBase;
    return {
      for (final k in {...fromBase.keys, ...fromLikes.keys})
        k: (1 - share) * (fromBase[k] ?? 0) + share * (fromLikes[k] ?? 0),
    };
  }
}

/// Only the [within] sectors of v when it has some of them (else all of v's).
Vec? _inside(Vec? v, Vec? within) {
  if (v == null || within == null) return v;
  final inside = {
    for (final e in v.entries)
      if ((within[e.key] ?? 0) > 0 && e.value != 0) e.key: e.value,
  };
  return inside.isNotEmpty ? inside : v;
}

/// A sector vector as shares that add up to 1 (null when it has no sector).
Vec? _mixOf(Vec? v) {
  if (v == null) return null;
  final total = v.values.fold<double>(0, (a, w) => a + w);
  return total > 0 ? {for (final e in v.entries) e.key: e.value / total} : null;
}

class Candidate<T> {
  const Candidate(
    this.item,
    this.name,
    this.features,
    this.mainSector, {
    this.sectors,
  });

  final T item;
  final String name;
  final Features features;
  final String? mainSector;

  /// The sectors it counts as in calibration (a startup: its main sector
  /// only); null: its sector feature.
  final Vec? sectors;
}

class Pick<T> {
  const Pick(this.item, this.score);

  final T item;
  final double score;
}

/// The best limit candidates for taste; see recommendBest.
List<Pick<T>> recommend<T>(
  Taste taste,
  List<Candidate<T>> candidates, {
  int limit = defaultLimit,
}) => recommendBest([taste], candidates, limit: limit);

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

  final places = math.max(0, limit - exploreSlots);
  final targets = [
    for (final t in tastes)
      if (t.target case final v? when v.isNotEmpty) v,
  ];
  final main = targets.isEmpty
      ? scored.take(places).toList()
      : _calibrated(scored, _average(targets), places);
  final rest = [
    for (final e in scored)
      if (!main.contains(e)) e,
  ];
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

double ticketBonus(Startup s, Iterable<InvestmentTicket> tickets) {
  final need = _raising(s);
  if (need == null || tickets.isEmpty) return 0;
  if (ticketFits(s, tickets)) return ticketFitBonus;
  return tickets.any((t) => _inRange(t, need)) ? ticketAmountBonus : 0;
}

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

/// The onboarding amount check of the matching.
bool sizesFit(Startup s, {String? ticketBand, int? roundMin, int? roundMax}) {
  final need = s.fundingRequirement ?? 0;
  if (!s.seeksFunding || need <= 0) return true;
  final min = ticketMin[ticketBand ?? ''];
  if (min != null && min > need) return false;
  if (roundMin != null && need < roundMin) return false;
  if (roundMax != null && need > roundMax) return false;
  return true;
}

Vec _average(List<Vec> all) {
  final sum = <String, double>{};
  for (final v in all) {
    v.forEach((k, w) => sum[k] = (sum[k] ?? 0) + w);
  }
  return {for (final e in sum.entries) e.key: e.value / all.length};
}

/// Steck's greedy calibration, exactly as the server: each place goes to the
/// candidate with the best (1 - w) * score - w * KL(target || the list's mix
/// with it), the mix smoothed by alpha. Ties go to the earliest candidate.
List<E> _calibrated<E extends ({Candidate c, double score, int fits})>(
  List<E> order,
  Vec target,
  int places,
) {
  final wanted = {
    for (final e in target.entries)
      if (e.value > 0) e.key: e.value,
  };
  if (wanted.isEmpty || order.isEmpty || places <= 0) {
    return order.take(math.max(0, places)).toList();
  }
  // An item's sectors outside the target do not count when it has some
  // inside it: an investor's list means "sectors I accept", not a mix.
  final mixes = [
    for (final e in order)
      _mixOf(_inside(e.c.sectors ?? e.c.features.groups['sector'], wanted)) ??
          const <String, double>{},
  ];
  final counts = <String, double>{};
  final left = List<int>.generate(order.length, (i) => i);
  final chosen = <E>[];
  final steps = math.min(places, order.length);
  for (var size = 1; size <= steps; size++) {
    final values = <int, double>{};
    for (final i in left) {
      var kl = 0.0;
      wanted.forEach((g, p) {
        final q = ((counts[g] ?? 0) + (mixes[i][g] ?? 0)) / size;
        final smoothed = (1 - calibrationAlpha) * q + calibrationAlpha * p;
        kl += p * math.log(p / smoothed);
      });
      values[i] =
          (1 - calibrationWeight) * order[i].score - calibrationWeight * kl;
    }
    // Values this close count as equal, so ties follow the order given, not
    // rounding noise (as the server).
    final top = values.values.reduce(math.max);
    final best = left.firstWhere((i) => values[i]! >= top - calibrationTie);
    chosen.add(order[best]);
    mixes[best].forEach((g, w) => counts[g] = (counts[g] ?? 0) + w);
    left.remove(best);
  }
  return chosen;
}
