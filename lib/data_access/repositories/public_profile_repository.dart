import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/app_user.dart';
import '../../models/public_profile.dart';
import '../../models/team_member.dart';
import 'startup_repository.dart';
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

  static final Map<String, (String, String?, DateTime)> _nameCache = {};
  static const _nameTtl = Duration(minutes: 2);

  /// The CURRENT name and photo of [uids] (from their public profiles), so a
  /// team card follows the person's Edit profile. A person with no profile is
  /// simply missing from the result. Cached for two minutes; best effort.
  Future<Map<String, ({String name, String? photoData})>> liveOf(
    Iterable<String> uids,
  ) async {
    final now = DateTime.now();
    final out = <String, ({String name, String? photoData})>{};
    final missing = <String>[];
    for (final uid in uids.toSet()) {
      final hit = _nameCache[uid];
      if (hit != null && now.difference(hit.$3) < _nameTtl) {
        out[uid] = (name: hit.$1, photoData: hit.$2);
      } else {
        missing.add(uid);
      }
    }
    await Future.wait([
      for (final uid in missing)
        () async {
          try {
            final data = await _firestore.getDocument(_col, uid);
            final name = data?['fullName'];
            if (name is String && name.trim().isNotEmpty) {
              final photo = (data?['photoData'] as String?)?.trim();
              final url = photo == null || photo.isEmpty ? null : photo;
              out[uid] = (name: name.trim(), photoData: url);
              _nameCache[uid] = (name.trim(), url, now);
            }
          } catch (_) {
            // Keep what is stored on the card.
          }
        }(),
    ]);
    return out;
  }

  /// Forget the cached names (after I change my own name).
  static void forgetNames() => _nameCache.clear();

  /// The startups of [profile], each with the person's role there.
  ///
  /// A profile stores only the ids of the startups it MAY belong to (written
  /// by its owner when they join, create or leave one). Each is then read ONE
  /// BY ONE (a private startup loads only for people on its team, so a
  /// stranger never sees it) and kept only if the person really is its
  /// founder, a member or on its team list; the role comes from the startup,
  /// so a stale id never shows a startup the person has left.
  ///
  /// [alsoCheck] is a startup to test too (the one the profile was opened
  /// from), so a person is listed there even before their own list caught up.
  Future<List<ProfileStartupRef>> startupsOf(
    PublicProfile profile, {
    String? alsoCheck,
  }) async {
    final ids = <String>{for (final r in profile.startups) r.id, ?alsoCheck};
    final found = await Future.wait([
      for (final id in ids) _roleIn(id, profile.id),
    ]);
    return [for (final r in found) ?r];
  }

  Future<ProfileStartupRef?> _roleIn(String startupId, String personId) async {
    try {
      final s = await StartupRepository.instance.fetchById(startupId);
      if (s == null) return null;
      TeamMember? card;
      for (final m in s.team) {
        if (m.uid == personId) card = m;
      }
      final String? role;
      if (s.founderId == personId || (card?.isFounder ?? false)) {
        role = 'founder';
      } else if (s.memberRoles[personId] == 'coFounder' ||
          ((card?.coFounder ?? false) && !(card?.invited ?? false))) {
        role = 'coFounder';
      } else if (s.memberRoles.containsKey(personId) ||
          (card != null && !card.invited)) {
        role = 'member';
      } else {
        role = null;
      }
      if (role == null) return null;
      return ProfileStartupRef(id: s.id, name: s.name, role: role, startup: s);
    } catch (_) {
      // Not allowed to read it (a private startup) or not there any more.
      return null;
    }
  }

  /// Saves the ids of MY startups (founded, or joined) on my public profile,
  /// so other people's profile view of me can list them. Best effort, and it
  /// only updates a profile that exists (it never brings a deleted one back).
  Future<void> refreshMyStartups(String uid) async {
    try {
      final mine = await StartupRepository.instance.fetchMyStartups();
      final joined = await StartupRepository.instance.fetchMemberStartups();
      final refs = <ProfileStartupRef>[
        for (final s in mine)
          ProfileStartupRef(id: s.id, name: s.name, role: 'founder'),
        for (final s in joined)
          ProfileStartupRef(
            id: s.id,
            name: s.name,
            role: s.memberRoles[uid] == 'coFounder' ? 'coFounder' : 'member',
          ),
      ];
      await _firestore.updateDocument(_col, uid, {
        'startups': [for (final r in refs.take(30)) r.toMap()],
        'updatedAt': _firestore.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Could not refresh the startups on my profile: $e');
    }
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
