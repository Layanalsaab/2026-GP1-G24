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
    this.isPublic = false,
    this.logoUrl,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String founderId;
  final String name;
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

  /// False by default, so an unfinished profile is never exposed.
  final bool isPublic;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get seeksFunding => lookingFor.contains(LookingFor.funding);

  /// First letter of the name, for the logo placeholder.
  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    // runes, not [0], so a name starting with a non-Latin letter stays whole.
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  /// The editable fields, as stored in Firestore. Timestamps are added by the
  /// repository with server time, so they are not included here.
  Map<String, Object?> toMap() => {
    StartupFields.founderId: founderId,
    StartupFields.name: name,
    StartupFields.tagline: tagline,
    StartupFields.description: description,
    StartupFields.sector: sector.value,
    StartupFields.stage: stage.value,
    StartupFields.businessModel: businessModel.value,
    StartupFields.location: location.value,
    StartupFields.foundedYear: foundedYear,
    StartupFields.websiteUrl: websiteUrl,
    // Stored in enum order so the same choices always produce the same list.
    StartupFields.lookingFor: [
      for (final item in LookingFor.values)
        if (lookingFor.contains(item)) item.value,
    ],
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
      stage: stage,
      businessModel: model,
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
  }) => Startup(
    id: id ?? this.id,
    founderId: founderId ?? this.founderId,
    name: name,
    tagline: tagline,
    description: description,
    sector: sector,
    stage: stage,
    businessModel: businessModel,
    location: location,
    foundedYear: foundedYear,
    websiteUrl: websiteUrl,
    lookingFor: lookingFor,
    fundingRequirement: fundingRequirement,
    isPublic: isPublic ?? this.isPublic,
    logoUrl: clearLogo ? null : (logoUrl ?? this.logoUrl),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
