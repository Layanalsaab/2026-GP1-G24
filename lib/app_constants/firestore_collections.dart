/// Firestore collection and field names, written once.
class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
  static const startups = 'startups';
}

class UserFields {
  UserFields._();

  static const role = 'role';
  static const fullName = 'fullName';
  static const email = 'email';
  static const createdAt = 'createdAt';

  // Added when a founder finishes onboarding.
  static const onboardingCompleted = 'onboardingCompleted';
  static const sector = 'sector';
  static const stage = 'stage';
  static const city = 'city';
}

/// Fields of a `startups/{startupId}` document. firestore.rules uses the same
/// names, so change both together.
class StartupFields {
  StartupFields._();

  static const founderId = 'founderId';
  static const name = 'name';
  static const tagline = 'tagline';
  static const description = 'description';
  static const sector = 'sector';
  static const stage = 'stage';
  static const businessModel = 'businessModel';
  static const location = 'location';
  static const foundedYear = 'foundedYear';
  static const websiteUrl = 'websiteUrl';
  static const lookingFor = 'lookingFor';
  static const fundingRequirement = 'fundingRequirement';
  static const isPublic = 'isPublic';
  static const logoUrl = 'logoUrl';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
}

/// Firebase Storage folders. storage.rules uses the same paths.
class StoragePaths {
  StoragePaths._();

  /// `startup_logos/{founderId}/{startupId}/{fileName}`
  static String startupLogo(
    String founderId,
    String startupId,
    String fileName,
  ) => 'startup_logos/$founderId/$startupId/$fileName';
}
