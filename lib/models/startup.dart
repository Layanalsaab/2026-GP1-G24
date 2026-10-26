import '../app_constants/firestore_collections.dart';
import 'startup_enums.dart';
import 'team_member.dart';

/// A founder's startup, stored in `startups/{id}`.
///
/// Plain Dart: no Firebase types. Timestamps arrive as [DateTime] because
/// FirestoreService converts them when reading.
class Startup {
  const Startup({
    required this.id,
    required this.founderId,
    required this.name,
    required this.description,
    required this.sector,
    required this.stage,
    required this.businessModel,
    required this.location,
    required this.lookingFor,
    this.tagline,
    this.foundedYear,
    this.websiteUrl,
    this.fundingRequirement,
    this.sectorOther,
    this.stageOther,
    this.businessModelOther,
    this.lookingForOther,
    this.isPublic = false,
    this.logoUrl,
    this.createdAt,
    this.updatedAt,
    this.problem = '',
    this.solution = '',
    this.customers = '',
    this.advantage = '',
    this.tam,
    this.sam,
    this.som,
    this.team = const [],
    this.growth = '',
    this.capital,
    this.revenueYear1,
    this.revenueYear2,
    this.revenueYear3,
    this.valuation,
    this.wantsLeadInvestor,
    this.revenueThisYear,
    this.monthlyBurn,
    this.businessModelText = '',
    this.raisedInRound,
    this.partnerTypes = const [],
    this.supportTypes = const [],
    this.memberRoles = const {},
  });

  final String id;
  final String founderId;
  final String name;

  /// Legacy, optional. The form no longer asks for it (it was merged into the
  /// brief description), but older documents may still have one.
  final String? tagline;

  /// The brief description, stored in the `description` field. Required,
  /// at most [descriptionMax] characters.
  final String description;
  final Sector sector;
  final StartupStage stage;
  final BusinessModel businessModel;
  final StartupLocation location;
  final int? foundedYear;
  final String? websiteUrl;
  final Set<LookingFor> lookingFor;

  /// In SAR. Only set when [lookingFor] contains [LookingFor.funding].
  final int? fundingRequirement;

  /// What the founder typed when they chose "Other". Only kept (and only
  /// meaningful) while the matching value is `other`.
  final String? sectorOther;
  final String? stageOther;
  final String? businessModelOther;

  /// What the founder typed when they ticked "Other" in Looking for.
  final String? lookingForOther;

  /// Longest "Other" text, in characters (firestore.rules uses the same).
  static const otherMaxLength = 40;

  /// The sector as shown to people: the typed text for "Other".
  String get sectorLabel =>
      _otherOr(sector == Sector.other, sectorOther, sector.label);

  /// The stage as shown to people: the typed text for "Other".
  String get stageLabel =>
      _otherOr(stage == StartupStage.other, stageOther, stage.label);

  /// The commerce model as shown on cards and the profile ("B2C"), or the
  /// typed text for "Other".
  String get businessModelLabel => _otherOr(
    businessModel == BusinessModel.other,
    businessModelOther,
    businessModel.shortLabel,
  );

  /// A Looking for choice as shown to people: the typed text for "Other".
  String lookingForLabelOf(LookingFor item) => item == LookingFor.other
      ? _otherOr(true, lookingForOther, item.label)
      : item.label;

  static String _otherOr(bool isOther, String? typed, String fallback) {
    final text = (typed ?? '').trim();
    return isOther && text.isNotEmpty ? text : fallback;
  }

  static String? _otherToStore(bool isOther, String? typed) {
    final text = (typed ?? '').trim();
    return isOther && text.isNotEmpty ? text : null;
  }

  /// A Firestore map of uid -> role as a plain map (anything else is ignored).
  static Map<String, String> _roles(Object? raw) => raw is Map
      ? {
          for (final e in raw.entries)
            if (e.key is String && e.value is String)
              e.key as String: e.value as String,
        }
      : const {};

  static String? _otherFromMap(Object? raw) {
    if (raw is! String) return null;
    final text = raw.trim();
    return text.isEmpty ? null : text;
  }

  /// False by default, so an unfinished profile is never exposed.
  final bool isPublic;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ---- Step 2: Problem & solution (each at most [longTextMax]) ----
  final String problem;
  final String solution;
  final String customers;
  final String advantage;

  // ---- Step 3: Market & team ----

  /// Market size in SAR per year: TAM (whole market), SAM (the part you can
  /// serve) and SOM (the share you expect to win). All optional.
  final int? tam;
  final int? sam;
  final int? som;
  final List<TeamMember> team;

  // ---- Step 4: Funding & goals (SAR) ----
  final String growth;
  final int? capital;
  final int? revenueYear1;
  final int? revenueYear2;
  final int? revenueYear3;

  /// Current company valuation. Required, 0 is allowed.
  final int? valuation;

  /// "Are you looking for a lead investor?" (Yes / No). Null until answered.
  final bool? wantsLeadInvestor;

  /// Revenue earned so far this financial year (0 allowed).
  final int? revenueThisYear;

  /// Money lost each month: monthly costs minus monthly revenue (0 allowed).
  final int? monthlyBurn;

  /// "Explain your business model": how the startup makes money.
  final String businessModelText;

  /// The part of the funding round already committed (0 allowed).
  final int? raisedInRound;

  /// What kind of partner / support the startup looks for ("Other" is stored
  /// as the text the founder typed).
  final List<String> partnerTypes;
  final List<String> supportTypes;

  /// Co-founders and team members by uid: `'coFounder'` or `'member'`. The
  /// founder is [founderId], never in this map.
  final Map<String, String> memberRoles;

  /// The uids in [memberRoles] (what "My startups" queries on).
  List<String> get memberIds => memberRoles.keys.toList();

  /// Longest text in the Problem / solution / growth fields and team bios.
  static const longTextMax = 1000;

  /// Longest "Who are your target customers?" answer.
  static const customersMax = 250;

  /// Longest "What problem does your startup solve?" / "What is your
  /// solution?" answer.
  static const problemMax = 350;
  static const solutionMax = 350;

  /// Longest brief description.
  static const descriptionMax = 150;
  static const nameMax = 40;
  static const websiteMax = 100;
  static const firstFoundedYear = 1900;

  /// The three years of expected revenue, oldest first (null when unset).
  List<int?> get expectedRevenue => [revenueYear1, revenueYear2, revenueYear3];

  bool get hasBusinessDetails =>
      customers.isNotEmpty ||
      tam != null ||
      sam != null ||
      som != null ||
      growth.isNotEmpty;

  bool get seeksFunding => lookingFor.contains(LookingFor.funding);

  /// The brief description. Startups saved before the form had a single
  /// brief description may have only the old one-line pitch: it stands in
  /// when the description is empty.
  String get briefDescription {
    final text = description.trim();
    return text.isNotEmpty ? text : (tagline ?? '').trim();
  }

  /// The text for cards and lists: the brief description on one flowing
  /// text (line breaks collapsed). The widgets clamp it to 2 lines.
  String get summary => briefDescription.replaceAll(RegExp(r'\s+'), ' ');

  /// Initials for the logo placeholder (Figma: "Rafeeq Health" -> "RH").
  String get initials => initialsOf(name);

  /// First letter of the first two words, upper-cased; "?" for an empty name.
  /// Static so the form can show initials while the name is being typed.
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    // runes, not [0], so a word starting with a non-Latin letter stays whole.
    return words
        .take(2)
        .map((w) => String.fromCharCode(w.runes.first).toUpperCase())
        .join();
  }

  /// The editable fields, as stored in Firestore. Timestamps are added by the
  /// repository with server time, so they are not included here.
  Map<String, Object?> toMap() => {
    StartupFields.founderId: founderId,
    StartupFields.name: name,
    StartupFields.tagline: tagline,
    StartupFields.description: description,
    StartupFields.sector: sector.value,
    StartupFields.sectorOther: _otherToStore(
      sector == Sector.other,
      sectorOther,
    ),
    StartupFields.stage: stage.value,
    StartupFields.stageOther: _otherToStore(
      stage == StartupStage.other,
      stageOther,
    ),
    StartupFields.businessModel: businessModel.value,
    StartupFields.businessModelOther: _otherToStore(
      businessModel == BusinessModel.other,
      businessModelOther,
    ),
    StartupFields.location: location.value,
    StartupFields.foundedYear: foundedYear,
    StartupFields.websiteUrl: websiteUrl,
    // Stored in enum order so the same choices always produce the same list.
    StartupFields.lookingFor: [
      for (final item in LookingFor.values)
        if (lookingFor.contains(item)) item.value,
    ],
    StartupFields.lookingForOther: _otherToStore(
      lookingFor.contains(LookingFor.other),
      lookingForOther,
    ),
    // Required (> 0) by the Funding & goals step, whatever is ticked.
    StartupFields.fundingRequirement: fundingRequirement,
    StartupFields.isPublic: isPublic,
    StartupFields.logoUrl: logoUrl,
    StartupFields.problem: problem,
    StartupFields.solution: solution,
    StartupFields.customers: customers,
    StartupFields.advantage: advantage,
    StartupFields.tam: tam,
    StartupFields.sam: sam,
    StartupFields.som: som,
    StartupFields.team: [for (final m in team) m.toMap()],
    StartupFields.growth: growth,
    StartupFields.capital: capital,
    StartupFields.revenueYear1: revenueYear1,
    StartupFields.revenueYear2: revenueYear2,
    StartupFields.revenueYear3: revenueYear3,
    StartupFields.valuation: valuation,
    StartupFields.wantsLeadInvestor: wantsLeadInvestor,
    StartupFields.revenueThisYear: revenueThisYear,
    StartupFields.monthlyBurn: monthlyBurn,
    StartupFields.businessModelText: businessModelText,
    StartupFields.raisedInRound: raisedInRound,
    StartupFields.partnerTypes: partnerTypes,
    StartupFields.supportTypes: supportTypes,
    StartupFields.memberIds: memberIds,
    StartupFields.memberRoles: memberRoles,
  };

  /// Returns null when a required field is missing or holds an unknown value,
  /// so one malformed document never crashes the list.
  static Startup? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final sector = Sector.fromValue(data[StartupFields.sector]);
    final stage = StartupStage.fromValue(data[StartupFields.stage]);
    final model = BusinessModel.fromValue(data[StartupFields.businessModel]);
    final location = StartupLocation.fromValue(data[StartupFields.location]);
    final founderId = data[StartupFields.founderId];
    final name = data[StartupFields.name];
    if (sector == null ||
        stage == null ||
        model == null ||
        location == null ||
        founderId is! String ||
        name is! String) {
      return null;
    }
    final rawLookingFor = data[StartupFields.lookingFor];
    return Startup(
      id: id,
      founderId: founderId,
      name: name,
      tagline: data[StartupFields.tagline] as String?,
      description: (data[StartupFields.description] as String?) ?? '',
      sector: sector,
      sectorOther: _otherFromMap(data[StartupFields.sectorOther]),
      stage: stage,
      stageOther: _otherFromMap(data[StartupFields.stageOther]),
      businessModel: model,
      businessModelOther: _otherFromMap(data[StartupFields.businessModelOther]),
      location: location,
      foundedYear: (data[StartupFields.foundedYear] as num?)?.toInt(),
      websiteUrl: data[StartupFields.websiteUrl] as String?,
      lookingFor: {
        if (rawLookingFor is List)
          for (final raw in rawLookingFor) ?LookingFor.fromValue(raw),
      },
      lookingForOther: _otherFromMap(data[StartupFields.lookingForOther]),
      fundingRequirement: (data[StartupFields.fundingRequirement] as num?)
          ?.toInt(),
      isPublic: data[StartupFields.isPublic] == true,
      logoUrl: data[StartupFields.logoUrl] as String?,
      createdAt: data[StartupFields.createdAt] as DateTime?,
      updatedAt: data[StartupFields.updatedAt] as DateTime?,
      problem: (data[StartupFields.problem] as String?) ?? '',
      solution: (data[StartupFields.solution] as String?) ?? '',
      customers: (data[StartupFields.customers] as String?) ?? '',
      advantage: (data[StartupFields.advantage] as String?) ?? '',
      tam: (data[StartupFields.tam] as num?)?.toInt(),
      sam: (data[StartupFields.sam] as num?)?.toInt(),
      som: (data[StartupFields.som] as num?)?.toInt(),
      team: [
        if (data[StartupFields.team] is List)
          for (final raw in data[StartupFields.team] as List)
            ?TeamMember.fromMap(raw),
      ],
      growth: (data[StartupFields.growth] as String?) ?? '',
      capital: (data[StartupFields.capital] as num?)?.toInt(),
      revenueYear1: (data[StartupFields.revenueYear1] as num?)?.toInt(),
      revenueYear2: (data[StartupFields.revenueYear2] as num?)?.toInt(),
      revenueYear3: (data[StartupFields.revenueYear3] as num?)?.toInt(),
      valuation: (data[StartupFields.valuation] as num?)?.toInt(),
      wantsLeadInvestor: data[StartupFields.wantsLeadInvestor] as bool?,
      revenueThisYear: (data[StartupFields.revenueThisYear] as num?)?.toInt(),
      monthlyBurn: (data[StartupFields.monthlyBurn] as num?)?.toInt(),
      businessModelText:
          (data[StartupFields.businessModelText] as String?) ?? '',
      raisedInRound: (data[StartupFields.raisedInRound] as num?)?.toInt(),
      partnerTypes: _strings(data[StartupFields.partnerTypes]),
      supportTypes: _strings(data[StartupFields.supportTypes]),
      memberRoles: _roles(data[StartupFields.memberRoles]),
    );
  }

  /// A copy with the given fields replaced. [clearLogo] sets [logoUrl] to
  /// null (copyWith can't express that otherwise). [clearFunding] empties the
  /// funding answers (amount, lead investor, already raised): a closed round.
  Startup copyWith({
    String? id,
    String? founderId,
    String? name,
    String? tagline,
    String? description,
    Sector? sector,
    StartupStage? stage,
    BusinessModel? businessModel,
    StartupLocation? location,
    int? foundedYear,
    String? websiteUrl,
    Set<LookingFor>? lookingFor,
    int? fundingRequirement,
    String? logoUrl,
    bool clearLogo = false,
    bool clearFunding = false,
    bool? isPublic,
    String? sectorOther,
    String? stageOther,
    String? businessModelOther,
    String? lookingForOther,
    String? problem,
    String? solution,
    String? customers,
    String? advantage,
    int? tam,
    int? sam,
    int? som,
    List<TeamMember>? team,
    String? growth,
    int? capital,
    int? revenueYear1,
    int? revenueYear2,
    int? revenueYear3,
    int? valuation,
    bool? wantsLeadInvestor,
    int? revenueThisYear,
    int? monthlyBurn,
    String? businessModelText,
    int? raisedInRound,
    List<String>? partnerTypes,
    List<String>? supportTypes,
    Map<String, String>? memberRoles,
  }) => Startup(
    id: id ?? this.id,
    founderId: founderId ?? this.founderId,
    name: name ?? this.name,
    tagline: tagline ?? this.tagline,
    description: description ?? this.description,
    sector: sector ?? this.sector,
    sectorOther: sectorOther ?? this.sectorOther,
    stage: stage ?? this.stage,
    stageOther: stageOther ?? this.stageOther,
    businessModel: businessModel ?? this.businessModel,
    businessModelOther: businessModelOther ?? this.businessModelOther,
    location: location ?? this.location,
    foundedYear: foundedYear ?? this.foundedYear,
    websiteUrl: websiteUrl ?? this.websiteUrl,
    lookingFor: lookingFor ?? this.lookingFor,
    lookingForOther: lookingForOther ?? this.lookingForOther,
    fundingRequirement: clearFunding
        ? null
        : (fundingRequirement ?? this.fundingRequirement),
    isPublic: isPublic ?? this.isPublic,
    logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
    createdAt: createdAt,
    updatedAt: updatedAt,
    problem: problem ?? this.problem,
    solution: solution ?? this.solution,
    customers: customers ?? this.customers,
    advantage: advantage ?? this.advantage,
    tam: tam ?? this.tam,
    sam: sam ?? this.sam,
    som: som ?? this.som,
    team: team ?? this.team,
    growth: growth ?? this.growth,
    capital: capital ?? this.capital,
    revenueYear1: revenueYear1 ?? this.revenueYear1,
    revenueYear2: revenueYear2 ?? this.revenueYear2,
    revenueYear3: revenueYear3 ?? this.revenueYear3,
    valuation: valuation ?? this.valuation,
    wantsLeadInvestor: clearFunding
        ? null
        : (wantsLeadInvestor ?? this.wantsLeadInvestor),
    revenueThisYear: revenueThisYear ?? this.revenueThisYear,
    monthlyBurn: monthlyBurn ?? this.monthlyBurn,
    businessModelText: businessModelText ?? this.businessModelText,
    raisedInRound: clearFunding ? null : (raisedInRound ?? this.raisedInRound),
    partnerTypes: partnerTypes ?? this.partnerTypes,
    supportTypes: supportTypes ?? this.supportTypes,
    memberRoles: memberRoles ?? this.memberRoles,
  );

  static List<String> _strings(Object? raw) => [
    if (raw is List)
      for (final v in raw)
        if (v is String && v.trim().isNotEmpty) v,
  ];
}
