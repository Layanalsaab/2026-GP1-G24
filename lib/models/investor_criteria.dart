import '../app_constants/firestore_collections.dart';

/// An investor's answers to the sign-up questions (steps 3 and 4,
/// docs/06 §3-4). Stored as flat fields on `users/{uid}` (see [toFields]),
/// with the same names as the `investors` collection, and used for matching
/// (docs/08 §4).
class InvestorCriteria {
  const InvestorCriteria({
    this.dealsCount,
    this.hasLedRound,
    this.roundsLed,
    this.coInvest,
    this.ticketBand,
    this.ticketOther,
    this.roundMin,
    this.roundMax,
    this.sectors = const [],
    this.sectorsOther,
    this.stages = const [],
    this.stagesOther,
    this.commerceModels = const [],
    this.commerceModelsOther,
    this.lookFor = '',
  });

  // ---- Fixed answer lists (exact copy) ----
  static const dealsOptions = ['0', '1–5', '6–15', '16+'];
  static const roundsLedOptions = ['1–2', '3–5', '6+'];
  static const coInvestOptions = ['Preferably', 'Possibly', 'Never'];
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
    'Other',
  ];

  /// Longest "What do you look for in a startup?" text.
  static const lookForMax = 1000;

  /// "0", "1–5", "6–15" or "16+": how many startups they invested in.
  final String? dealsCount;
  final bool? hasLedRound;

  /// Only when [hasLedRound] is true. Optional.
  final String? roundsLed;

  /// "Preferably", "Possibly" or "Never".
  final String? coInvest;

  /// One of [ticketOptions]. "Other" uses [ticketOther].
  final String? ticketBand;
  final String? ticketOther;

  /// Round sizes they like to join, in SAR. Both optional.
  final int? roundMin;
  final int? roundMax;

  final List<String> sectors;
  final String? sectorsOther;
  final List<String> stages;
  final String? stagesOther;

  /// Full commerce-model labels, e.g. "Business-to-Business (B2B)".
  final List<String> commerceModels;
  final String? commerceModelsOther;
  final String lookFor;

  /// "SAR 100K – 500K", or the typed text for "Other".
  String? get ticketLabel {
    if (ticketBand == null) return null;
    if (ticketBand == 'Other') {
      final t = (ticketOther ?? '').trim();
      return t.isEmpty ? 'Other' : t;
    }
    return ticketBand;
  }

  /// "Pre-seed – Seed" or one stage; the typed text replaces "Other".
  String get stageRange {
    final shown = [
      for (final s in stages)
        if (s == 'Other' && (stagesOther ?? '').trim().isNotEmpty)
          stagesOther!.trim()
        else
          s,
    ];
    if (shown.isEmpty) return '';
    return shown.length > 1 ? '${shown.first} – ${shown.last}' : shown.first;
  }

  /// The answers as flat Firestore fields of the investor's document
  /// (`investmentsCount`, `hasLedRound`, `roundsLed`, `coInvest`,
  /// `ticketSize`, `roundSizeMin`, `roundSizeMax`, `preferredSectors`,
  /// `preferredStages`, `preferredCommerceModels`, `lookingFor`, and the
  /// typed "Other" texts).
  Map<String, Object?> toFields() => {
    UserFields.investmentsCount: dealsCount,
    UserFields.hasLedRound: hasLedRound,
    UserFields.roundsLed: hasLedRound == true ? roundsLed : null,
    UserFields.coInvest: coInvest,
    UserFields.ticketSize: ticketBand,
    UserFields.ticketSizeOther: ticketBand == 'Other' ? ticketOther : null,
    UserFields.roundSizeMin: roundMin,
    UserFields.roundSizeMax: roundMax,
    UserFields.preferredSectors: sectors,
    UserFields.sectorsOther: sectors.contains('Other') ? sectorsOther : null,
    UserFields.preferredStages: stages,
    UserFields.preferredStagesOther: stages.contains('Other')
        ? stagesOther
        : null,
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
      UserFields.hasLedRound,
      UserFields.coInvest,
      UserFields.ticketSize,
      UserFields.preferredSectors,
      UserFields.preferredStages,
      UserFields.preferredCommerceModels,
      UserFields.lookingFor,
    ].any((k) => d[k] != null);
    if (!hasAny) return null;
    return InvestorCriteria(
      dealsCount: d[UserFields.investmentsCount] as String?,
      hasLedRound: d[UserFields.hasLedRound] as bool?,
      roundsLed: d[UserFields.roundsLed] as String?,
      coInvest: d[UserFields.coInvest] as String?,
      ticketBand: d[UserFields.ticketSize] as String?,
      ticketOther: d[UserFields.ticketSizeOther] as String?,
      roundMin: (d[UserFields.roundSizeMin] as num?)?.toInt(),
      roundMax: (d[UserFields.roundSizeMax] as num?)?.toInt(),
      sectors: _strings(d[UserFields.preferredSectors]),
      sectorsOther: d[UserFields.sectorsOther] as String?,
      stages: _strings(d[UserFields.preferredStages]),
      stagesOther: d[UserFields.preferredStagesOther] as String?,
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
    'hasLedRound': hasLedRound,
    'roundsLed': hasLedRound == true ? roundsLed : null,
    'coInvest': coInvest,
    'ticketBand': ticketBand,
    'ticketOther': ticketBand == 'Other' ? ticketOther : null,
    'roundMin': roundMin,
    'roundMax': roundMax,
    'sectors': sectors,
    'sectorsOther': sectors.contains('Other') ? sectorsOther : null,
    'stages': stages,
    'stagesOther': stages.contains('Other') ? stagesOther : null,
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
      hasLedRound: raw['hasLedRound'] as bool?,
      roundsLed: raw['roundsLed'] as String?,
      coInvest: raw['coInvest'] as String?,
      ticketBand: raw['ticketBand'] as String?,
      ticketOther: raw['ticketOther'] as String?,
      roundMin: (raw['roundMin'] as num?)?.toInt(),
      roundMax: (raw['roundMax'] as num?)?.toInt(),
      sectors: _strings(raw['sectors']),
      sectorsOther: raw['sectorsOther'] as String?,
      stages: _strings(raw['stages']),
      stagesOther: raw['stagesOther'] as String?,
      commerceModels: _strings(raw['commerceModels']),
      commerceModelsOther: raw['commerceModelsOther'] as String?,
      lookFor: (raw['lookFor'] as String?) ?? '',
    );
  }

  InvestorCriteria copyWith({
    String? dealsCount,
    bool? hasLedRound,
    String? roundsLed,
    String? coInvest,
    String? ticketBand,
    String? ticketOther,
    int? roundMin,
    int? roundMax,
    List<String>? sectors,
    String? sectorsOther,
    List<String>? stages,
    String? stagesOther,
    List<String>? commerceModels,
    String? commerceModelsOther,
    String? lookFor,
  }) => InvestorCriteria(
    dealsCount: dealsCount ?? this.dealsCount,
    hasLedRound: hasLedRound ?? this.hasLedRound,
    roundsLed: roundsLed ?? this.roundsLed,
    coInvest: coInvest ?? this.coInvest,
    ticketBand: ticketBand ?? this.ticketBand,
    ticketOther: ticketOther ?? this.ticketOther,
    roundMin: roundMin ?? this.roundMin,
    roundMax: roundMax ?? this.roundMax,
    sectors: sectors ?? this.sectors,
    sectorsOther: sectorsOther ?? this.sectorsOther,
    stages: stages ?? this.stages,
    stagesOther: stagesOther ?? this.stagesOther,
    commerceModels: commerceModels ?? this.commerceModels,
    commerceModelsOther: commerceModelsOther ?? this.commerceModelsOther,
    lookFor: lookFor ?? this.lookFor,
  );
}
