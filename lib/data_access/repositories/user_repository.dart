import 'dart:io';

import '../../app_constants/firestore_collections.dart';
import '../../models/app_user.dart';
import '../../models/auth_failure.dart';
import '../firebase_services/firestore_service.dart';
import '../firebase_services/storage_service.dart';

/// Reads and writes the `users` collection (document id = Auth UID).
class UserRepository {
  UserRepository({FirestoreService? firestore, StorageService? storage})
    : _firestore = firestore ?? FirestoreService(),
      _storage = storage ?? StorageService();

  /// The app-wide instance. Tests replace it with a fake.
  static UserRepository instance = UserRepository();

  final FirestoreService _firestore;
  final StorageService _storage;

  /// Creates the `users/{uid}` document. [phone] is the 9 digits without
  /// +966; empty / null values are not stored.
  ///
  /// The extended fields (phone, city, bio, sectorsOfInterest) need the
  /// current Firestore rules. If the rules in use reject them (permission
  /// denied), the document is created again with only the four core fields
  /// (role, fullName, email, createdAt), so sign-up never fails because the
  /// rules have not been published yet.
  Future<void> createProfile({
    required String uid,
    required AccountRole role,
    required String fullName,
    required String email,
    String? phone,
    String? city,
    String? bio,
    List<String> sectorsOfInterest = const [],
  }) async {
    final core = <String, Object?>{
      UserFields.role: role.value,
      UserFields.fullName: fullName,
      UserFields.email: email,
      UserFields.createdAt: _firestore.serverTimestamp(),
    };
    final extra = <String, Object?>{
      if (phone != null && phone.trim().isNotEmpty)
        UserFields.phone: phone.trim(),
      if (city != null && city.trim().isNotEmpty) UserFields.city: city.trim(),
      if (bio != null && bio.trim().isNotEmpty) UserFields.bio: bio.trim(),
      if (sectorsOfInterest.isNotEmpty)
        UserFields.sectorsOfInterest: List.of(sectorsOfInterest),
    };
    if (extra.isEmpty) {
      await _firestore.setDocument(FirestoreCollections.users, uid, core);
      return;
    }
    try {
      await _firestore.setDocument(FirestoreCollections.users, uid, {
        ...core,
        ...extra,
      });
    } on AuthException catch (e) {
      if (e.failure != AuthFailure.permissionDenied) rethrow;
      await _firestore.setDocument(FirestoreCollections.users, uid, core);
    }
  }

  /// Uploads [photo] to `users/{uid}/profile.jpg` and stores its download URL
  /// in the profile. Returns the URL. Needs the signed-in user to be [uid].
  Future<String> uploadProfilePhoto(String uid, File photo) async {
    final url = await _storage.uploadFile(
      path: StoragePaths.userProfilePhoto(uid),
      file: photo,
      contentType: 'image/jpeg',
    );
    await _firestore.updateDocument(FirestoreCollections.users, uid, {
      UserFields.photoUrl: url,
    });
    return url;
  }

  /// Removes the profile photo: the file (a missing file counts as removed)
  /// and the `photoUrl` field.
  Future<void> removeProfilePhoto(String uid, String photoUrl) async {
    await _storage.deleteByUrl(photoUrl);
    await _firestore.updateDocument(FirestoreCollections.users, uid, {
      UserFields.photoUrl: null,
    });
  }

  /// Null when the profile is missing or has no valid role.
  Future<AppUser?> getProfile(String uid) async {
    final data = await _firestore.getDocument(FirestoreCollections.users, uid);
    return AppUser.fromMap(uid, data);
  }

  /// Saves an investor's edited investment criteria (PBI 22).
  Future<void> updateInvestmentCriteria({
    required String uid,
    required List<String> sectors,
    required List<String> stages,
    required String ticketSize,
  }) => _firestore.updateDocument(FirestoreCollections.users, uid, {
    UserFields.preferredSectors: sectors,
    UserFields.preferredStages: stages,
    UserFields.ticketSize: ticketSize,
  });

  /// Saves the fields a user can change on the Edit profile screen. The
  /// email and role never change here. [phone] is the 9 digits without +966.
  /// A null [city] leaves the stored city as it is.
  ///
  /// If the Firestore rules in use don't know `phone` / `sectorsOfInterest`
  /// yet, the write is denied; then the fields they do accept (name, bio,
  /// city) are saved so the user's edit is not lost.
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    required String bio,
    required String phone,
    required List<String> sectorsOfInterest,
    String? city,
  }) async {
    try {
      await _firestore.updateDocument(FirestoreCollections.users, uid, {
        UserFields.fullName: fullName,
        UserFields.bio: bio,
        UserFields.phone: phone,
        UserFields.sectorsOfInterest: sectorsOfInterest,
        UserFields.city: ?city,
      });
    } on AuthException catch (e) {
      if (e.failure != AuthFailure.permissionDenied) rethrow;
      await _firestore.updateDocument(FirestoreCollections.users, uid, {
        UserFields.fullName: fullName,
        UserFields.bio: bio,
        UserFields.city: ?city,
      });
    }
  }

  /// Deletes the user's profile document (used when deleting the account).
  Future<void> deleteProfile(String uid) =>
      _firestore.deleteDocument(FirestoreCollections.users, uid);
}
