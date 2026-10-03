import '../../app_constants/firestore_collections.dart';
import '../../models/app_user.dart';
import '../firebase_services/firestore_service.dart';

/// Reads and writes the `users` collection (document id = Auth UID).
class UserRepository {
  UserRepository({FirestoreService? firestore})
      : _firestore = firestore ?? FirestoreService();

  /// The app-wide instance. Tests replace it with a fake.
  static UserRepository instance = UserRepository();

  final FirestoreService _firestore;

  Future<void> createProfile({
    required String uid,
    required AccountRole role,
    required String fullName,
    required String email,
  }) =>
      _firestore.setDocument(FirestoreCollections.users, uid, {
        UserFields.role: role.value,
        UserFields.fullName: fullName,
        UserFields.email: email,
        UserFields.createdAt: _firestore.serverTimestamp(),
      });

  /// Null when the profile is missing or has no valid role.
  Future<AppUser?> getProfile(String uid) async {
    final data = await _firestore.getDocument(FirestoreCollections.users, uid);
    return AppUser.fromMap(uid, data);
  }

  /// Saves a founder's onboarding answers and marks onboarding as done.
  Future<void> saveFounderOnboarding({
    required String uid,
    required String sector,
    required String stage,
    required String city,
  }) =>
      _firestore.updateDocument(FirestoreCollections.users, uid, {
        UserFields.sector: sector,
        UserFields.stage: stage,
        UserFields.city: city,
        UserFields.onboardingCompleted: true,
      });
}
