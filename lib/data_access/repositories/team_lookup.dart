import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/app_user.dart';
import '../firebase_services/firestore_service.dart';
import 'public_profile_repository.dart';

/// A registered account found by e-mail: what a team member is linked to.
class TeamAccount {
  const TeamAccount({
    required this.uid,
    required this.name,
    this.isFounder = true,
  });

  final String uid;
  final String name;

  /// False for an investor account: investors can't join a startup's team.
  final bool isFounder;
}

/// Finds a registered Start.sa account by e-mail (case-insensitive) when a
/// founder adds a team member.
///
/// It reads `emailIndex/{email}`: one small document per account (the uid,
/// the name and the role) that the account's owner publishes after verifying
/// the e-mail. Nobody can list the index, so accounts can't be scraped.
class TeamLookup {
  // ignore: prefer_initializing_formals
  const TeamLookup({FirestoreService? firestore}) : _firestore = firestore;

  /// The app-wide instance. Tests replace it.
  static TeamLookup instance = const TeamLookup();

  final FirestoreService? _firestore;

  FirestoreService get _db => _firestore ?? FirestoreService();

  Future<TeamAccount?> findByEmail(String email) async {
    final key = email.trim().toLowerCase();
    if (key.isEmpty) return null;
    try {
      final data = await _db.getDocument(FirestoreCollections.emailIndex, key);
      final uid = data?['uid'];
      if (data == null || uid is! String) return null;
      return TeamAccount(
        uid: uid,
        name: (data['fullName'] as String?) ?? '',
        isFounder: data['role'] != 'investor',
      );
    } catch (e) {
      debugPrint('E-mail lookup failed: $e');
      return null;
    }
  }

  /// Publishes (or refreshes) my entry, so teams can find me by e-mail.
  /// Called after a verified log in and when my name changes. Best effort.
  Future<void> publish(AppUser user, {required bool emailVerified}) async {
    if (!emailVerified || user.email.trim().isEmpty) return;
    try {
      await _db.setDocument(
        FirestoreCollections.emailIndex,
        user.email.trim().toLowerCase(),
        {
          'uid': user.uid,
          'fullName': user.fullName,
          'role': user.isInvestor ? 'investor' : 'founder',
          'updatedAt': _db.serverTimestamp(),
        },
      );
      // The always-public face of a founder, for team profiles.
      await PublicProfileRepository.instance.publish(user);
      if (user.isFounder) {
        await PublicProfileRepository.instance.refreshMyStartups(user.uid);
      }
    } catch (e) {
      debugPrint('Could not publish the e-mail index entry: $e');
    }
  }

  /// Removes my entry and my public profile when my account is deleted, so
  /// nobody finds or opens a person who no longer exists. Best effort.
  Future<void> remove({required String uid, required String email}) async {
    final key = email.trim().toLowerCase();
    try {
      if (key.isNotEmpty) {
        await _db.deleteDocument(FirestoreCollections.emailIndex, key);
      }
    } catch (e) {
      debugPrint('Could not remove the e-mail index entry: $e');
    }
    try {
      await _db.deleteDocument(FirestoreCollections.publicProfiles, uid);
    } catch (e) {
      debugPrint('Could not remove the public profile: $e');
    }
  }
}
