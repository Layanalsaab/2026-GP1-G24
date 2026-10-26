import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/app_user.dart';
import '../../models/public_profile.dart';
import '../firebase_services/firestore_service.dart';

/// Public profiles (`publicProfiles/{id}`): the always-public face of an
/// account, read when somebody taps a person (a team member, a founder).
///
/// The e-mail and the phone are in a profile only when that one is Public;
/// the real ones stay in the private `users/{uid}` document.
class PublicProfileRepository {
  PublicProfileRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  /// The app-wide instance. Tests replace it with a fake.
  static PublicProfileRepository instance = PublicProfileRepository();

  final FirestoreService _firestore;

  static const _col = FirestoreCollections.publicProfiles;

  /// One profile by id, or null when there is none (or it can't be read).
  Future<PublicProfile?> get(String id) async {
    try {
      return PublicProfile.fromMap(id, await _firestore.getDocument(_col, id));
    } catch (e) {
      debugPrint('Could not read the profile $id: $e');
      return null;
    }
  }

  /// The startups of [profile]: the ones stored on a sample profile, plus the
  /// startups of a real account (founded by it, or where it is a member).
  /// Private startups the viewer may not read simply don't come back.
  Future<List<ProfileStartupRef>> startupsOf(PublicProfile profile) async {
    final byId = {for (final r in profile.startups) r.id: r};
    try {
      final founded = await _firestore.queryWhereEqual(
        FirestoreCollections.startups,
        StartupFields.founderId,
        profile.id,
      );
      for (final d in founded) {
        final name = d.data[StartupFields.name];
        if (name is String) {
          byId[d.id] = ProfileStartupRef(id: d.id, name: name, role: 'founder');
        }
      }
      final member = await _firestore.queryWhereArrayContains(
        FirestoreCollections.startups,
        StartupFields.memberIds,
        profile.id,
      );
      for (final d in member) {
        final name = d.data[StartupFields.name];
        final roles = d.data[StartupFields.memberRoles];
        if (name is String) {
          byId[d.id] = ProfileStartupRef(
            id: d.id,
            name: name,
            role: roles is Map && roles[profile.id] == 'coFounder'
                ? 'coFounder'
                : 'member',
          );
        }
      }
    } catch (e) {
      debugPrint('Could not list the startups of ${profile.id}: $e');
    }
    return byId.values.toList();
  }

  /// Publishes (or refreshes) a founder's own public profile. The e-mail and
  /// the phone are written only while they are Public and removed when not.
  /// Best effort: a failure never blocks the user.
  Future<void> publish(AppUser user) async {
    if (!user.isFounder) return;
    try {
      await _firestore.setDocument(_col, user.uid, {
        'fullName': user.fullName,
        'role': 'founder',
        'city': user.city ?? '',
        'bio': user.bio,
        'sectorsOfInterest': user.sectorsOfInterest,
        if ((user.sectorsOther ?? '').trim().isNotEmpty)
          'sectorsOther': user.sectorsOther,
        'linkedinUrl': user.linkedin ?? '',
        'photoUrl': user.photoUrl ?? '',
        'emailPublic': user.emailPublic,
        'phonePublic': user.phonePublic,
        'email': user.emailPublic ? user.email : _firestore.deleteField(),
        'phone': user.phonePublic && (user.phone ?? '').isNotEmpty
            ? user.phone
            : _firestore.deleteField(),
        'updatedAt': _firestore.serverTimestamp(),
      }, merge: true);
    } catch (e) {
      debugPrint('Could not publish the public profile: $e');
    }
  }
}
