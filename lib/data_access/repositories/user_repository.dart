import 'dart:io';

import '../../app_constants/firestore_collections.dart';
import '../../models/app_user.dart';
import '../../models/auth_failure.dart';
import '../../models/investor_criteria.dart';
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
    String? sectorsOther,
    String? linkedin,
    String? gain,
    String? valueOffered,
    bool emailPublic = false,
    bool phonePublic = false,
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
      if (sectorsOther != null && sectorsOther.trim().isNotEmpty)
        UserFields.sectorsOther: sectorsOther.trim(),
      if (linkedin != null && linkedin.trim().isNotEmpty)
        UserFields.linkedin: linkedin.trim(),
      if (gain != null && gain.trim().isNotEmpty) UserFields.gain: gain.trim(),
      if (valueOffered != null && valueOffered.trim().isNotEmpty)
        UserFields.valueOffered: valueOffered.trim(),
      // Private is the default, so only a public choice is stored.
      if (emailPublic) UserFields.emailPublic: true,
      if (phonePublic) UserFields.phonePublic: true,
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

  /// Saves the investor's answers to sign-up steps 3 and 4 and marks their
  /// onboarding as finished, then publishes them to the `investors` list so
  /// founders can find them.
  Future<void> saveInvestorOnboarding({
    required String uid,
    required InvestorCriteria criteria,
    String? valueOffered,
  }) async {
    await _firestore.updateDocument(FirestoreCollections.users, uid, {
      ...criteria.toFields(),
      if (valueOffered != null) UserFields.valueOffered: valueOffered.trim(),
      UserFields.onboardingCompleted: true,
    });
    await _publishInvestor(uid);
  }

  /// Copies the public part of an investor's profile (never the email or
  /// phone) to `investors/{uid}`, with the same field names. Founders are not
  /// listed. A failure here never blocks the account.
  Future<void> _publishInvestor(String uid) async {
    try {
      final d = await _firestore.getDocument(FirestoreCollections.users, uid);
      if (d == null || d[UserFields.role] != 'investor') return;
      Object? keep(String k) => d[k];
      final doc = <String, Object?>{
        UserFields.role: 'investor',
        UserFields.fullName: keep(UserFields.fullName),
        UserFields.city: keep(UserFields.city),
        UserFields.bio: keep(UserFields.bio),
        UserFields.preferredSectors: keep(UserFields.preferredSectors),
        UserFields.preferredStages: keep(UserFields.preferredStages),
        UserFields.ticketSize: keep(UserFields.ticketSize),
        UserFields.investmentsCount: keep(UserFields.investmentsCount),
        UserFields.hasLedRound: keep(UserFields.hasLedRound),
        UserFields.roundsLed: keep(UserFields.roundsLed),
        UserFields.coInvest: keep(UserFields.coInvest),
        UserFields.roundSizeMin: keep(UserFields.roundSizeMin),
        UserFields.roundSizeMax: keep(UserFields.roundSizeMax),
        UserFields.preferredCommerceModels: keep(
          UserFields.preferredCommerceModels,
        ),
        UserFields.linkedin: keep(UserFields.linkedin),
        UserFields.valueOffered: keep(UserFields.valueOffered),
        UserFields.lookingFor: keep(UserFields.lookingFor),
        UserFields.title: 'Investor',
        UserFields.photoUrl: keep(UserFields.photoUrl),
        UserFields.createdAt:
            keep(UserFields.createdAt) ?? _firestore.serverTimestamp(),
      };
      await _firestore.setDocument(FirestoreCollections.investors, uid, doc);
    } catch (_) {
      // The profile itself is saved; the public listing can be retried.
    }
  }

  /// Marks a founder's onboarding as finished (after their first startup).
  Future<void> completeOnboarding(String uid) => _firestore.updateDocument(
    FirestoreCollections.users,
    uid,
    {UserFields.onboardingCompleted: true},
  );

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
    String? sectorsOther,
    String? linkedin,
    String? gain,
    String? valueOffered,
    bool? emailPublic,
    bool? phonePublic,
  }) async {
    try {
      await _firestore.updateDocument(FirestoreCollections.users, uid, {
        UserFields.fullName: fullName,
        UserFields.bio: bio,
        UserFields.phone: phone,
        UserFields.sectorsOfInterest: sectorsOfInterest,
        UserFields.city: ?city,
        UserFields.sectorsOther: sectorsOther,
        UserFields.linkedin: linkedin,
        UserFields.gain: gain,
        UserFields.valueOffered: valueOffered,
        UserFields.emailPublic: ?emailPublic,
        UserFields.phonePublic: ?phonePublic,
      });
      await _refreshPublishedInvestor(uid);
    } on AuthException catch (e) {
      if (e.failure != AuthFailure.permissionDenied) rethrow;
      await _firestore.updateDocument(FirestoreCollections.users, uid, {
        UserFields.fullName: fullName,
        UserFields.bio: bio,
        UserFields.city: ?city,
      });
    }
  }

  /// Re-publishes an investor's public copy after they edited their profile
  /// (founders have none).
  Future<void> _refreshPublishedInvestor(String uid) async {
    try {
      final existing = await _firestore.getDocument(
        FirestoreCollections.investors,
        uid,
      );
      if (existing != null) await _publishInvestor(uid);
    } catch (_) {}
  }

  /// Deletes the user's profile document and their public investor listing
  /// (used when deleting the account).
  Future<void> deleteProfile(String uid) async {
    try {
      await _firestore.deleteDocument(FirestoreCollections.investors, uid);
    } catch (_) {
      // Not an investor, or already gone.
    }
    await _firestore.deleteDocument(FirestoreCollections.users, uid);
  }
}
