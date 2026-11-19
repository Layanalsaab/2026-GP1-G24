import '../app_constants/firestore_collections.dart';

/// An investor's answers to the sign-up questions (steps 3 and 4,
/// docs/06 §3-4). Stored as flat fields on `users/{uid}` (see [toFields]),
/// with the same names as the `investors` collection, and used for matching
/// (docs/08 §4).
class InvestorCriteria {
  const InvestorCriteria({
    this.yearsInvesting,
    this.dealsCount,
    this.ticketBand,
    this.roundMin,
    this.roundMax,
    this.sectors = const [],
    this.sectorsOther,
    this.stages = const [],
    this.commerceModels = const [],
    this.commerceModelsOther,
    this.lookFor = '',
  });

  // ---- Fixed answer lists (exact copy) ----
  static const yearsOptions = [
    'Less than 1 year',
    '1–3 years',
    '4–6 years',
    '7–9 years',
    '10+ years',
  ];
  static const dealsOptions = ['0', '1–3', '4–6', '7–9', '10+'];
  static const ticketOptions = [
    'Under SAR 100K',
    'SAR 100K – 500K',
    'SAR 500K – 1M',
    'SAR 1M – 5M',
    'Over SAR 5M',
    'Other',
  ];
  static const stageOptions = [
    'Pre-seed',
    'Seed',
    'Series A',
    'Series B',
    'Series C',
  ];

  /// Longest "What do you look for in a startup?" text.
  static const lookForMax = 1000;

  /// "0", "1–5", "6–15" or "16+": how many startups they invested in.
  final String? dealsCount;

  /// "Less than 1 year" ... "10+ years" (one of [yearsOptions]).
  final String? yearsInvesting;

  /// "SAR 500K – 1M" (K for thousands, M for millions): the round size per
  /// startup; empty when it was not asked (no startups invested in yet).
  String get roundSizeLabel {
    String short(int n) {
      String trim(double v) =>
          v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
      if (n >= 1000000) return '${trim(n / 1000000)}M';
      if (n >= 1000) return '${trim(n / 1000)}K';
      return '$n';
    }

    if (roundMin == null || roundMax == null) return '';
    return 'SAR ${short(roundMin!)} – ${short(roundMax!)}';
  }

  /// One of [ticketOptions].
  final String? ticketBand;

  /// Round sizes they like to join, in SAR. Both optional.
  final int? roundMin;
  final int? roundMax;

  final List<String> sectors;
  final String? sectorsOther;
  final List<String> stages;

  /// Full commerce-model labels, e.g. "Business-to-Business (B2B)".
  final List<String> commerceModels;
  final String? commerceModelsOther;
  final String lookFor;

  /// "B2B, B2C": the commerce models with their short names; the typed text
  /// replaces "Other".
  String get commerceModelsShort {
    final other = (commerceModelsOther ?? '').trim();
    final shown = [
      for (final m in commerceModels)
        if (m == 'Other')
          if (other.isNotEmpty) other else 'Other'
        else
          RegExp(r'\(([^)]+)\)$').firstMatch(m)?.group(1) ?? m,
    ];
    return shown.join(', ');
  }

  /// "SAR 100K – 500K".
  String? get ticketLabel => ticketBand;

  /// "Pre-seed – Seed" or one stage.
  String get stageRange {
    if (stages.isEmpty) return '';
    return stages.length > 1
        ? '${stages.first} – ${stages.last}'
        : stages.first;
  }

  /// The answers as flat Firestore fields of the investor's document
  /// (`investmentsCount`, `ticketSize`, `roundSizeMin`, `roundSizeMax`, `preferredSectors`,
  /// `preferredStages`, `preferredCommerceModels`, `lookingFor`, and the
  /// typed "Other" texts).
  Map<String, Object?> toFields() => {
    UserFields.investmentsCount: dealsCount,
    UserFields.yearsInvesting: yearsInvesting,
    UserFields.ticketSize: ticketBand,
    UserFields.roundSizeMin: roundMin,
    UserFields.roundSizeMax: roundMax,
    UserFields.preferredSectors: sectors,
    UserFields.sectorsOther: sectors.contains('Other') ? sectorsOther : null,
    UserFields.preferredStages: stages,
    UserFields.preferredCommerceModels: commerceModels,
    UserFields.preferredCommerceModelsOther: commerceModels.contains('Other')
        ? commerceModelsOther
        : null,
    UserFields.lookingFor: lookFor,
  };

  /// Reads [toFields] back from a user / investor document. Null when the
  /// document holds none of the investor answers.
  static InvestorCriteria? fromFields(Map<String, dynamic> d) {
    final hasAny = [
      UserFields.investmentsCount,
      UserFields.yearsInvesting,
      UserFields.ticketSize,
      UserFields.preferredSectors,
      UserFields.preferredStages,
      UserFields.preferredCommerceModels,
      UserFields.lookingFor,
    ].any((k) => d[k] != null);
    if (!hasAny) return null;
    return InvestorCriteria(
      dealsCount: d[UserFields.investmentsCount] as String?,
      yearsInvesting: d[UserFields.yearsInvesting] as String?,
      ticketBand: d[UserFields.ticketSize] as String?,
      roundMin: (d[UserFields.roundSizeMin] as num?)?.toInt(),
      roundMax: (d[UserFields.roundSizeMax] as num?)?.toInt(),
      sectors: _strings(d[UserFields.preferredSectors]),
      sectorsOther: d[UserFields.sectorsOther] as String?,
      stages: _strings(d[UserFields.preferredStages]),
      commerceModels: _strings(d[UserFields.preferredCommerceModels]),
      commerceModelsOther:
          d[UserFields.preferredCommerceModelsOther] as String?,
      lookFor: (d[UserFields.lookingFor] as String?) ?? '',
    );
  }

  /// The old single-map form (kept so documents saved before the flat fields
  /// still load).
  Map<String, Object?> toMap() => {
    'dealsCount': dealsCount,
    'yearsInvesting': yearsInvesting,
    'ticketBand': ticketBand,
    'roundMin': roundMin,
    'roundMax': roundMax,
    'sectors': sectors,
    'sectorsOther': sectors.contains('Other') ? sectorsOther : null,
    'stages': stages,
    'commerceModels': commerceModels,
    'commerceModelsOther': commerceModels.contains('Other')
        ? commerceModelsOther
        : null,
    'lookFor': lookFor,
  };

  static List<String> _strings(Object? v) =>
      v is List ? v.whereType<String>().toList() : const [];

  static InvestorCriteria? fromMap(Object? raw) {
    if (raw is! Map) return null;
    return InvestorCriteria(
      dealsCount: raw['dealsCount'] as String?,
      yearsInvesting: raw['yearsInvesting'] as String?,
      ticketBand: raw['ticketBand'] as String?,
      roundMin: (raw['roundMin'] as num?)?.toInt(),
      roundMax: (raw['roundMax'] as num?)?.toInt(),
      sectors: _strings(raw['sectors']),
      sectorsOther: raw['sectorsOther'] as String?,
      stages: _strings(raw['stages']),
      commerceModels: _strings(raw['commerceModels']),
      commerceModelsOther: raw['commerceModelsOther'] as String?,
      lookFor: (raw['lookFor'] as String?) ?? '',
    );
  }

  InvestorCriteria copyWith({
    String? yearsInvesting,
    String? dealsCount,
    String? ticketBand,
    int? roundMin,
    int? roundMax,
    List<String>? sectors,
    String? sectorsOther,
    List<String>? stages,
    List<String>? commerceModels,
    String? commerceModelsOther,
    String? lookFor,
  }) => InvestorCriteria(
    yearsInvesting: yearsInvesting ?? this.yearsInvesting,
    dealsCount: dealsCount ?? this.dealsCount,
    ticketBand: ticketBand ?? this.ticketBand,
    roundMin: roundMin ?? this.roundMin,
    roundMax: roundMax ?? this.roundMax,
    sectors: sectors ?? this.sectors,
    sectorsOther: sectorsOther ?? this.sectorsOther,
    stages: stages ?? this.stages,
    commerceModels: commerceModels ?? this.commerceModels,
    commerceModelsOther: commerceModelsOther ?? this.commerceModelsOther,
    lookFor: lookFor ?? this.lookFor,
  );
}
