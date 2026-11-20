import '../app_constants/firestore_collections.dart';
import 'startup_enums.dart';
import 'team_member.dart';

/// A founder's startup, stored in startups/{id}.
class Startup {
  const Startup({
    required this.id,
    required this.founderId,
    required this.name,
    required this.description,
    required this.sector,
    required this.stage,
    required this.commerceModel,
    required this.location,
    required this.lookingFor,
    this.foundedYear,
    this.websiteUrl,
    this.fundingRequirement,
    this.sectorOther,
    this.otherSectors = const [],
    this.commerceModelOther,
    this.isPublic = false,
    this.logoData,
    this.createdAt,
    this.updatedAt,
    this.problem = '',
    this.solution = '',
    this.customers = '',
    this.advantage = '',
    this.marketSize,
    this.team = const [],
    this.capital,
    this.revenueYear1,
    this.revenueYear2,
    this.revenueYear3,
    this.valuation,
    this.revenueThisYear,
    this.monthlyBurn,
    this.revenueModel = '',
    this.raisedInRound,
    this.partnerTypes = const [],
    this.supportTypes = const [],
    this.memberRoles = const {},
    this.isClosed = false,
    this.closedAt,
    this.isArchived = false,
  });

  final String id;
  final String founderId;
  final String name;

  /// The brief description, stored in the description field.
  final String description;
  final Sector sector;
  final StartupStage stage;
  final CommerceModel commerceModel;
  final StartupLocation location;
  final int? foundedYear;
  final String? websiteUrl;
  final Set<LookingFor> lookingFor;

  /// In SAR.
  final int? fundingRequirement;

  /// What the founder typed when they chose "Other".
  final String? sectorOther;

  final List<String> otherSectors;
  final String? commerceModelOther;

  static const datasetFounderId = 'crunchbase-dataset';

  /// The sector as shown to people: the typed text for "Other".
  String get sectorLabel =>
      _otherOr(sector == Sector.other, sectorOther, sector.label);

  /// Every sector, the main one first (what the startup page lists).
  List<String> get sectorLabels => [
    sectorLabel,
    for (final o in otherSectors)
      if (o != sectorLabel) o,
  ];

  /// The stage as shown to people.
  String get stageLabel => stage.label;

  String get commerceModelLabel => _otherOr(
    commerceModel == CommerceModel.other,
    commerceModelOther,
    commerceModel.shortLabel,
  );

  /// A Looking for choice as shown to people.
  String lookingForLabelOf(LookingFor item) => item.label;

  static String _otherOr(bool isOther, String? typed, String fallback) {
    final text = (typed ?? '').trim();
    return isOther && text.isNotEmpty ? text : fallback;
  }

  static String? _otherToStore(bool isOther, String? typed) {
    final text = (typed ?? '').trim();
    return isOther && text.isNotEmpty ? text : null;
  }

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

  final String? logoData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String problem;
  final String solution;
  final String customers;
  final String advantage;

  /// Target market size in SAR per year.
  final int? marketSize;
  final List<TeamMember> team;

  final int? capital;
  final int? revenueYear1;
  final int? revenueYear2;
  final int? revenueYear3;

  /// Current company valuation.
  final int? valuation;

  /// Revenue earned so far this financial year (0 allowed).
  final int? revenueThisYear;

  final int? monthlyBurn;

  final String revenueModel;

  /// The part of the funding round already committed (0 allowed).
  final int? raisedInRound;

  final List<String> partnerTypes;
  final List<String> supportTypes;

  /// Co-founders and team members by uid: 'coFounder' or 'member'.
  final Map<String, String> memberRoles;

  /// The uids in memberRoles (what "My startups" queries on).
  List<String> get memberIds => memberRoles.keys.toList();

  /// The joined co-founders (stored as coFounderIds too, for the rules).
  List<String> get coFounderIds => [
    for (final e in memberRoles.entries)
      if (e.value == 'coFounder') e.key,
  ];

  /// A closed startup: permanent, read only, kept in everyone's account.
  final bool isClosed;

  final DateTime? closedAt;

  /// A startup imported from the dataset (Crunchbase), not made in the app.
  final bool isArchived;

  bool get hasOwner => founderId.isNotEmpty;

  bool get isListed => isPublic && !isClosed;

  bool get isInHub => isPublic;

  /// The name on uid's team card (fallback when there is none).
  String nameOf(String uid, {String fallback = ''}) {
    for (final m in team) {
      if (m.uid == uid && m.name.trim().isNotEmpty) return m.name.trim();
    }
    return fallback;
  }

  /// Longest text in the Problem / solution / growth fields and team bios.
  static const longTextMax = 1000;

  /// Longest "Who are your target customers?" answer.
  static const customersMax = 250;

  static const problemMax = 350;
  static const solutionMax = 350;

  /// Longest brief description.
  static const descriptionMax = 150;
  static const nameMax = 40;
  static const websiteMax = 100;

  /// The three years of expected revenue, oldest first (null when unset).
  List<int?> get expectedRevenue => [revenueYear1, revenueYear2, revenueYear3];

  bool get seeksFunding => lookingFor.contains(LookingFor.funding);

  /// The brief description.
  String get briefDescription => description.trim();

  String get summary => briefDescription.replaceAll(RegExp(r'\s+'), ' ');

  /// Initials for the logo placeholder (Figma: "Rafeeq Health" -> "RH").
  String get initials => initialsOf(name);

  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    return words
        .take(2)
        .map((w) => String.fromCharCode(w.runes.first).toUpperCase())
        .join();
  }

  /// The editable fields, as stored in Firestore.
  Map<String, Object?> toMap() => {
    StartupFields.founderId: founderId,
    StartupFields.name: name,
    StartupFields.description: description,
    StartupFields.sector: sector.value,
    StartupFields.otherSectors: otherSectors,
    StartupFields.sectorOther: _otherToStore(
      sector == Sector.other,
      sectorOther,
    ),
    StartupFields.stage: stage.value,
    StartupFields.commerceModel: commerceModel.value,
    StartupFields.commerceModelOther: _otherToStore(
      commerceModel == CommerceModel.other,
      commerceModelOther,
    ),
    StartupFields.location: location.value,
    StartupFields.foundedYear: foundedYear,
    StartupFields.websiteUrl: websiteUrl,
    StartupFields.lookingFor: [
      for (final item in LookingFor.values)
        if (lookingFor.contains(item)) item.value,
    ],
    StartupFields.fundingRequirement: fundingRequirement,
    StartupFields.isPublic: isPublic,
    if (logoData != null) StartupFields.logoData: logoData,
    StartupFields.problem: problem,
    StartupFields.solution: solution,
    StartupFields.customers: customers,
    StartupFields.advantage: advantage,
    StartupFields.marketSize: marketSize,
    StartupFields.team: [for (final m in team) m.toMap()],
    StartupFields.capital: capital,
    StartupFields.revenueYear1: revenueYear1,
    StartupFields.revenueYear2: revenueYear2,
    StartupFields.revenueYear3: revenueYear3,
    StartupFields.valuation: valuation,
    StartupFields.revenueThisYear: revenueThisYear,
    StartupFields.monthlyBurn: monthlyBurn,
    StartupFields.revenueModel: revenueModel,
    StartupFields.raisedInRound: raisedInRound,
    StartupFields.partnerTypes: partnerTypes,
    StartupFields.supportTypes: supportTypes,
    StartupFields.memberIds: memberIds,
    StartupFields.memberRoles: memberRoles,
    StartupFields.coFounderIds: coFounderIds,
    StartupFields.status: isClosed
        ? StartupFields.statusClosed
        : StartupFields.statusActive,
    if (closedAt != null) StartupFields.closedAt: closedAt,
    StartupFields.isArchived: isArchived,
  };

  static Startup? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final sector = Sector.fromValue(data[StartupFields.sector]);
    final stage = StartupStage.fromValue(data[StartupFields.stage]);
    final model = CommerceModel.fromValue(data[StartupFields.commerceModel]);
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
      description: (data[StartupFields.description] as String?) ?? '',
      sector: sector,
      sectorOther: _otherFromMap(data[StartupFields.sectorOther]),
      otherSectors: [
        if (data[StartupFields.otherSectors] is List)
          for (final v in data[StartupFields.otherSectors] as List)
            if (v is String && v.trim().isNotEmpty) v.trim(),
      ],
      stage: stage,
      commerceModel: model,
      commerceModelOther: _otherFromMap(data[StartupFields.commerceModelOther]),
      location: location,
      foundedYear: (data[StartupFields.foundedYear] as num?)?.toInt(),
      websiteUrl: data[StartupFields.websiteUrl] as String?,
      lookingFor: {
        if (rawLookingFor is List)
          for (final raw in rawLookingFor) ?LookingFor.fromValue(raw),
      },
      fundingRequirement: (data[StartupFields.fundingRequirement] as num?)
          ?.toInt(),
      isPublic: data[StartupFields.isPublic] == true,
      logoData: data[StartupFields.logoData] as String?,
      createdAt: data[StartupFields.createdAt] as DateTime?,
      updatedAt: data[StartupFields.updatedAt] as DateTime?,
      problem: (data[StartupFields.problem] as String?) ?? '',
      solution: (data[StartupFields.solution] as String?) ?? '',
      customers: (data[StartupFields.customers] as String?) ?? '',
      advantage: (data[StartupFields.advantage] as String?) ?? '',
      marketSize: (data[StartupFields.marketSize] as num?)?.toInt(),
      team: [
        if (data[StartupFields.team] is List)
          for (final raw in data[StartupFields.team] as List)
            ?TeamMember.fromMap(raw),
      ],
      capital: (data[StartupFields.capital] as num?)?.toInt(),
      revenueYear1: (data[StartupFields.revenueYear1] as num?)?.toInt(),
      revenueYear2: (data[StartupFields.revenueYear2] as num?)?.toInt(),
      revenueYear3: (data[StartupFields.revenueYear3] as num?)?.toInt(),
      valuation: (data[StartupFields.valuation] as num?)?.toInt(),
      revenueThisYear: (data[StartupFields.revenueThisYear] as num?)?.toInt(),
      monthlyBurn: (data[StartupFields.monthlyBurn] as num?)?.toInt(),
      revenueModel: (data[StartupFields.revenueModel] as String?) ?? '',
      raisedInRound: (data[StartupFields.raisedInRound] as num?)?.toInt(),
      partnerTypes: _strings(data[StartupFields.partnerTypes]),
      supportTypes: _strings(data[StartupFields.supportTypes]),
      memberRoles: _roles(data[StartupFields.memberRoles]),
      isClosed: data[StartupFields.status] == StartupFields.statusClosed,
      closedAt: data[StartupFields.closedAt] as DateTime?,
      isArchived: data[StartupFields.isArchived] == true,
    );
  }

  /// A copy with the given fields replaced.
  Startup copyWith({
    String? id,
    String? founderId,
    String? name,
    String? description,
    Sector? sector,
    StartupStage? stage,
    CommerceModel? commerceModel,
    StartupLocation? location,
    int? foundedYear,
    String? websiteUrl,
    Set<LookingFor>? lookingFor,
    int? fundingRequirement,
    String? logoData,
    bool clearLogo = false,
    bool clearFunding = false,
    bool? isPublic,
    String? sectorOther,
    List<String>? otherSectors,
    String? commerceModelOther,
    String? problem,
    String? solution,
    String? customers,
    String? advantage,
    int? marketSize,
    List<TeamMember>? team,
    int? capital,
    int? revenueYear1,
    int? revenueYear2,
    int? revenueYear3,
    int? valuation,
    int? revenueThisYear,
    int? monthlyBurn,
    String? revenueModel,
    int? raisedInRound,
    List<String>? partnerTypes,
    List<String>? supportTypes,
    Map<String, String>? memberRoles,
    bool? isClosed,
    DateTime? closedAt,
  }) => Startup(
    id: id ?? this.id,
    founderId: founderId ?? this.founderId,
    name: name ?? this.name,
    description: description ?? this.description,
    sector: sector ?? this.sector,
    sectorOther: sectorOther ?? this.sectorOther,
    otherSectors: otherSectors ?? this.otherSectors,
    stage: stage ?? this.stage,
    commerceModel: commerceModel ?? this.commerceModel,
    commerceModelOther: commerceModelOther ?? this.commerceModelOther,
    location: location ?? this.location,
    foundedYear: foundedYear ?? this.foundedYear,
    websiteUrl: websiteUrl ?? this.websiteUrl,
    lookingFor: lookingFor ?? this.lookingFor,
    fundingRequirement: clearFunding
        ? null
        : (fundingRequirement ?? this.fundingRequirement),
    isPublic: isPublic ?? this.isPublic,
    logoData: clearLogo ? null : (logoData ?? this.logoData),
    createdAt: createdAt,
    updatedAt: updatedAt,
    problem: problem ?? this.problem,
    solution: solution ?? this.solution,
    customers: customers ?? this.customers,
    advantage: advantage ?? this.advantage,
    marketSize: marketSize ?? this.marketSize,
    team: team ?? this.team,
    capital: capital ?? this.capital,
    revenueYear1: revenueYear1 ?? this.revenueYear1,
    revenueYear2: revenueYear2 ?? this.revenueYear2,
    revenueYear3: revenueYear3 ?? this.revenueYear3,
    valuation: valuation ?? this.valuation,
    revenueThisYear: revenueThisYear ?? this.revenueThisYear,
    monthlyBurn: monthlyBurn ?? this.monthlyBurn,
    revenueModel: revenueModel ?? this.revenueModel,
    raisedInRound: clearFunding ? null : (raisedInRound ?? this.raisedInRound),
    partnerTypes: partnerTypes ?? this.partnerTypes,
    supportTypes: supportTypes ?? this.supportTypes,
    memberRoles: memberRoles ?? this.memberRoles,
    isClosed: isClosed ?? this.isClosed,
    closedAt: closedAt ?? this.closedAt,
    isArchived: isArchived,
  );

  static List<String> _strings(Object? raw) => [
    if (raw is List)
      for (final v in raw)
        if (v is String && v.trim().isNotEmpty) v,
  ];
}
