import '../app_constants/firestore_collections.dart';
import 'startup_enums.dart';

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
  });

  final String id;
  final String founderId;
  final String name;

  /// Legacy, optional. The form no longer asks for it, but older documents
  /// may have one. Use [summary] wherever a short line is shown.
  final String? tagline;
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

  bool get seeksFunding => lookingFor.contains(LookingFor.funding);

  /// Longest short line shown on a card, in characters.
  static const summaryMaxLength = 100;

  /// The short line for cards: the legacy [tagline] when there is one,
  /// otherwise the first sentence of the description (cut at a word
  /// boundary with "…" when it is longer than [summaryMaxLength]).
  String get summary {
    final line = (tagline ?? '').trim();
    return line.isNotEmpty ? line : firstSentence(description);
  }

  /// First sentence of [text], on one line and at most [summaryMaxLength].
  static String firstSentence(String text) {
    final flat = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (flat.isEmpty) return '';
    final end = RegExp(r'[.!?؟]+(\s|$)').firstMatch(flat);
    var sentence = end == null ? flat : flat.substring(0, end.end).trim();
    if (sentence.length <= summaryMaxLength) return sentence;
    sentence = sentence.substring(0, summaryMaxLength);
    final lastSpace = sentence.lastIndexOf(' ');
    if (lastSpace > summaryMaxLength ~/ 2) {
      sentence = sentence.substring(0, lastSpace);
    }
    return '${sentence.replaceFirst(RegExp(r'[\s.,;:!?-]+$'), '')}…';
  }

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
    StartupFields.fundingRequirement: seeksFunding ? fundingRequirement : null,
    StartupFields.isPublic: isPublic,
    StartupFields.logoUrl: logoUrl,
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
    );
  }

  /// [clearLogo] sets [logoUrl] to null (copyWith can't express that otherwise).
  Startup copyWith({
    String? id,
    String? founderId,
    String? logoUrl,
    bool clearLogo = false,
    bool? isPublic,
    String? sectorOther,
    String? stageOther,
    String? businessModelOther,
    String? lookingForOther,
  }) => Startup(
    id: id ?? this.id,
    founderId: founderId ?? this.founderId,
    name: name,
    tagline: tagline,
    description: description,
    sector: sector,
    sectorOther: sectorOther ?? this.sectorOther,
    stage: stage,
    stageOther: stageOther ?? this.stageOther,
    businessModel: businessModel,
    businessModelOther: businessModelOther ?? this.businessModelOther,
    location: location,
    foundedYear: foundedYear,
    websiteUrl: websiteUrl,
    lookingFor: lookingFor,
    lookingForOther: lookingForOther ?? this.lookingForOther,
    fundingRequirement: fundingRequirement,
    isPublic: isPublic ?? this.isPublic,
    logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
