/// Firestore collection and field names, written once.
class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
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

  // Added when a user edits their account.
  static const bio = 'bio';

  // Added when an investor finishes onboarding (their investment criteria).
  static const preferredSectors = 'preferredSectors';
  static const preferredStages = 'preferredStages';
  static const ticketSize = 'ticketSize';
}
