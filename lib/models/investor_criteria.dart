/// An investor's answers to the sign-up questions (steps 3 and 4,
/// docs/06 §3-4). Stored as a map in `users/{uid}.investorCriteria` and used
/// for matching (docs/08 §4).
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
