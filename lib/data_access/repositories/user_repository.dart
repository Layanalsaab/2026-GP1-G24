import 'dart:io';

import '../../app_constants/firestore_collections.dart';
import '../../models/app_user.dart';
import '../../models/auth_failure.dart';
import '../../models/investor_criteria.dart';
import '../firebase_services/firestore_service.dart';
import '../device_services/image_fit.dart';

/// Reads and writes the users collection (document id = Auth UID).
class UserRepository {
  UserRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  /// The app-wide instance.
  static UserRepository instance = UserRepository();

  final FirestoreService _firestore;

  /// Creates the users/{uid} document.
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
      if (gain != null && gain.trim().isNotEmpty)
        UserFields.lookingFor: gain.trim(),
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

  Future<String> uploadProfilePhoto(String uid, File photo) async {
    final data = await ImageFit.base64Of(photo);
    final d = await _firestore.getDocument(FirestoreCollections.users, uid);
    await _firestore.setDocument(FirestoreCollections.publicProfiles, uid, {
      'fullName': d?[UserFields.fullName] ?? '',
      'role': d?[UserFields.role] == 'investor' ? 'investor' : 'founder',
      'photoData': data,
      'updatedAt': _firestore.serverTimestamp(),
    }, merge: true);
    return data;
  }

  /// Removes the profile photo: the photoData field is deleted.
  Future<void> removeProfilePhoto(String uid) async {
    try {
      await _firestore.updateDocument(
        FirestoreCollections.publicProfiles,
        uid,
        {'photoData': _firestore.deleteField()},
      );
    } on AuthException catch (e) {
      // No public profile yet means there is no photo to remove.
      if (e.failure != AuthFailure.notFound) rethrow;
    }
  }

  /// Null when the profile is missing or has no valid role.
  Future<AppUser?> getProfile(String uid) async {
    final data = await _firestore.getDocument(FirestoreCollections.users, uid);
    final user = AppUser.fromMap(uid, data);
    if (user == null) return null;
    try {
      final pub = await _firestore.getDocument(
        FirestoreCollections.publicProfiles,
        uid,
      );
      final photo = (pub?['photoData'] as String?)?.trim();
      if (photo != null && photo.isNotEmpty) {
        return user.copyWith(photoData: photo);
      }
    } catch (_) {
      // No photo shown: the initials are the default.
    }
    return user;
  }

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
        UserFields.yearsInvesting: keep(UserFields.yearsInvesting),
        UserFields.sectorsOther: keep(UserFields.sectorsOther),
        UserFields.preferredCommerceModelsOther: keep(
          UserFields.preferredCommerceModelsOther,
        ),
        UserFields.emailPublic: d[UserFields.emailPublic] == true,
        UserFields.phonePublic: d[UserFields.phonePublic] == true,
        if (d[UserFields.emailPublic] == true)
          UserFields.email: keep(UserFields.email),
        if (d[UserFields.phonePublic] == true)
          UserFields.phone: keep(UserFields.phone),
        UserFields.roundSizeMin: keep(UserFields.roundSizeMin),
        UserFields.roundSizeMax: keep(UserFields.roundSizeMax),
        UserFields.preferredCommerceModels: keep(
          UserFields.preferredCommerceModels,
        ),
        UserFields.linkedin: keep(UserFields.linkedin),
        UserFields.valueOffered: keep(UserFields.valueOffered),
        UserFields.lookingFor: keep(UserFields.lookingFor),
        UserFields.title: 'Angel Investor',
        UserFields.isArchived: false,
        UserFields.createdAt:
            keep(UserFields.createdAt) ?? _firestore.serverTimestamp(),
      };
      await _firestore.setDocument(FirestoreCollections.investors, uid, doc);
    } catch (_) {
    }
  }

  /// Marks a founder's onboarding as finished (after their first startup).
  Future<void> completeOnboarding(String uid) => _firestore.updateDocument(
    FirestoreCollections.users,
    uid,
    {UserFields.onboardingCompleted: true},
  );

  /// Saves the fields a user can change on the Edit profile screen.
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
        UserFields.lookingFor: gain,
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

  Future<void> _refreshPublishedInvestor(String uid) async {
    try {
      final existing = await _firestore.getDocument(
        FirestoreCollections.investors,
        uid,
      );
      if (existing != null) await _publishInvestor(uid);
    } catch (_) {}
  }

  Future<void> deleteProfile(String uid) async {
    try {
      await _firestore.deleteDocument(FirestoreCollections.investors, uid);
    } catch (_) {
      // Not an investor, or already gone.
    }
    await _firestore.deleteDocument(FirestoreCollections.users, uid);
  }
}
