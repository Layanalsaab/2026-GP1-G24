import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/auth_failure.dart';
import '../../models/startup.dart';
import '../../models/team_member.dart';
import '../firebase_services/auth_service.dart';
import '../firebase_services/firestore_service.dart';
import '../firebase_services/storage_service.dart';
import 'funding_round_repository.dart';

/// Reads and writes the `startups` collection and the startups' logos in
/// Storage. Screens and view models never touch Firebase directly.
///
/// Every method throws [AuthException] on failure (network, permission, ...).
class StartupRepository {
  StartupRepository({
    AuthService? auth,
    FirestoreService? firestore,
    StorageService? storage,
    FundingRoundRepository? rounds,
  }) : _auth = auth ?? AuthService(),
       _firestore = firestore ?? FirestoreService(),
       _storage = storage ?? StorageService(),
       _roundsOverride = rounds;

  /// The app-wide instance. Tests replace it with a fake.
  static StartupRepository instance = StartupRepository();

  final AuthService _auth;
  final FirestoreService _firestore;
  final StorageService _storage;
  final FundingRoundRepository? _roundsOverride;

  /// Read when used, so a test can replace FundingRoundRepository.instance.
  FundingRoundRepository get _rounds =>
      _roundsOverride ?? FundingRoundRepository.instance;

  static const _collection = FirestoreCollections.startups;

  /// The signed-in founder's uid, straight from FirebaseAuth.
  String get _founderId {
    final uid = _auth.currentAccount?.uid;
    if (uid == null) throw const AuthException(AuthFailure.permissionDenied);
    return uid;
  }

  /// Saves only the team list of a startup (somebody accepted an invitation
  /// while the startup was private, so the team fixes their card).
  Future<void> setTeam(String startupId, List<TeamMember> team) =>
      _firestore.updateDocument(_collection, startupId, {
        StartupFields.team: [for (final m in team) m.toMap()],
        StartupFields.updatedAt: _firestore.serverTimestamp(),
      });

  /// One startup by id, or null when it doesn't exist (any more).
  Future<Startup?> fetchById(String id) async {
    final data = await _firestore.getDocument(_collection, id);
    return Startup.fromMap(id, data);
  }

  /// The signed-in founder's startups, most recently edited first.
  Future<List<Startup>> fetchMyStartups() async {
    final docs = await _firestore.queryWhereEqual(
      _collection,
      StartupFields.founderId,
      _founderId,
    );
    final startups = [
      for (final doc in docs) ?Startup.fromMap(doc.id, doc.data),
    ];
    // Sorted here instead of with orderBy: a founder has a handful of
    // startups, and this avoids needing a composite Firestore index.
    startups.sort((a, b) => _editedAt(b).compareTo(_editedAt(a)));
    return startups;
  }

  /// The startups the signed-in user belongs to as a co-founder or team
  /// member (not the ones they founded), most recently edited first. The
  /// membership lives in each startup document (`memberIds`), so a deleted
  /// startup simply stops being returned.
  Future<List<Startup>> fetchMemberStartups() async {
    final uid = _founderId;
    final docs = await _firestore.queryWhereArrayContains(
      _collection,
      StartupFields.memberIds,
      uid,
    );
    final startups = [
      for (final doc in docs) ?Startup.fromMap(doc.id, doc.data),
    ];
    startups.sort((a, b) => _editedAt(b).compareTo(_editedAt(a)));
    return startups;
  }

  /// "Leave startup": removes ONLY the signed-in user's own membership (their
  /// uid from `memberIds` and `memberRoles`). The security rules allow a
  /// member to change nothing else.
  Future<void> leave(Startup startup) async {
    final uid = _founderId;
    await _firestore.updateDocument(_collection, startup.id, {
      StartupFields.memberIds: _firestore.arrayRemove([uid]),
      '${StartupFields.memberRoles}.$uid': _firestore.deleteField(),
    });
  }

  /// "My name carries over": after [uid] changed their name on Edit profile,
  /// every team card of theirs in the startups they founded shows the new
  /// one. A member is theirs when it is linked to [uid], or (not linked yet)
  /// when it carried their old name; it is linked from then on.
  Future<void> syncMemberName({
    required String uid,
    required String oldName,
    required String newName,
  }) async {
    final old = oldName.trim().toLowerCase();
    for (final startup in await fetchMyStartups()) {
      var changed = false;
      final team = [
        for (final m in startup.team)
          if (m.uid == uid ||
              (m.uid == null && m.name.trim().toLowerCase() == old))
            () {
              changed = changed || m.name != newName || m.uid != uid;
              return m.copyWith(name: newName, uid: uid);
            }()
          else
            m,
      ];
      if (!changed) continue;
      await _firestore.updateDocument(_collection, startup.id, {
        StartupFields.team: [for (final m in team) m.toMap()],
        StartupFields.updatedAt: _firestore.serverTimestamp(),
      });
    }
  }

  /// Saves a new startup and returns it as stored. [startup.id] and
  /// [startup.founderId] are ignored: both are assigned here. With Funding
  /// ticked, its Round 1 is opened in the same write.
  Future<Startup> create(Startup startup, {File? logo}) async {
    final founderId = _founderId;
    final id = _firestore.newDocumentId(_collection);
    // Upload first: if it fails, nothing has been written yet.
    final logoUrl = logo == null
        ? null
        : await _uploadLogo(founderId, id, logo);
    final toSave = startup.copyWith(
      id: id,
      founderId: founderId,
      logoUrl: logoUrl,
    );
    try {
      // Funding ticked: Round 1 opens in the same write.
      final roundWrites = await _rounds.writesFor(id, toSave, isNew: true);
      final startupData = {
        ...toSave.toMap(),
        StartupFields.createdAt: _firestore.serverTimestamp(),
        StartupFields.updatedAt: _firestore.serverTimestamp(),
      };
      if (roundWrites.isEmpty) {
        await _firestore.setDocument(_collection, id, startupData);
      } else {
        await _firestore.commit([
          FirestoreWrite.set(_collection, id, startupData),
          ...roundWrites,
        ]);
      }
    } catch (_) {
      // Don't leave an orphan logo behind when the document wasn't saved.
      if (logoUrl != null) await _deleteLogoQuietly(logoUrl);
      rethrow;
    }
    return toSave;
  }

  /// Saves changes to an existing startup.
  ///
  /// Pass [newLogo] to replace the logo, or [removeLogo] to clear it. The old
  /// logo file is deleted only after the document points at the new one.
  ///
  /// The funding rounds follow the Funding answers in the same write: Funding
  /// ticked opens a round (or updates the open one), unticked closes it.
  Future<Startup> update(
    Startup startup, {
    File? newLogo,
    bool removeLogo = false,
  }) async {
    // Logos live under the founder's folder, whoever (co-founder) uploads.
    final founderId = startup.founderId;
    final oldLogoUrl = startup.logoUrl;
    var updated = startup;
    if (newLogo != null) {
      updated = startup.copyWith(
        logoUrl: await _uploadLogo(founderId, startup.id, newLogo),
      );
    } else if (removeLogo) {
      updated = startup.copyWith(clearLogo: true);
    }

    // The open round follows the Funding answers (opened, updated or
    // closed), in the same write as the startup.
    final roundWrites = await _rounds.writesFor(startup.id, updated);
    final startupData = {
      ...updated.toMap(),
      StartupFields.updatedAt: _firestore.serverTimestamp(),
    };
    if (roundWrites.isEmpty) {
      await _firestore.updateDocument(_collection, startup.id, startupData);
    } else {
      await _firestore.commit([
        FirestoreWrite.update(_collection, startup.id, startupData),
        ...roundWrites,
      ]);
    }

    final logoChanged = oldLogoUrl != null && oldLogoUrl != updated.logoUrl;
    if (logoChanged) await _deleteLogoQuietly(oldLogoUrl);
    return updated;
  }

  /// Deletes every startup of the signed-in founder (used when the account
  /// is deleted, so nothing of theirs stays public).
  Future<void> deleteAllMine() async {
    final mine = await fetchMyStartups();
    for (final s in mine) {
      await delete(s);
    }
  }

  /// Deletes the startup, its funding rounds and its logo. Every membership goes with it (the
  /// members are stored inside the startup document), so it disappears from
  /// every team member's My Startups. Other people's bookmarks of it are
  /// dropped the next time they open Bookmarks (the bookmark repository
  /// removes a bookmark whose startup no longer exists).
  Future<void> delete(Startup startup) async {
    final logoUrl = startup.logoUrl;
    // Logo first: if that fails we stop, and the startup is still intact for
    // the founder to retry. (A missing logo file counts as deleted.)
    if (logoUrl != null) await _storage.deleteByUrl(logoUrl);
    // Its funding rounds first: Firestore doesn't delete a subcollection
    // with its document, and the rules read the startup to allow it.
    final roundDeletes = await _rounds.deletesFor(startup.id);
    if (roundDeletes.isNotEmpty) await _firestore.commit(roundDeletes);
    await _firestore.deleteDocument(_collection, startup.id);
  }

  Future<String> _uploadLogo(String founderId, String startupId, File logo) {
    // A new file name per upload, so cached images never show an old logo.
    final fileName = 'logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return _storage.uploadFile(
      path: StoragePaths.startupLogo(founderId, startupId, fileName),
      file: logo,
      contentType: 'image/jpeg',
    );
  }

  Future<void> _deleteLogoQuietly(String url) async {
    try {
      await _storage.deleteByUrl(url);
    } catch (e) {
      // Cleanup only: the startup itself was saved correctly.
      debugPrint('Could not delete old logo: $e');
    }
  }

  /// A just-saved document may have no server timestamp yet; treat it as new.
  DateTime _editedAt(Startup s) => s.updatedAt ?? s.createdAt ?? DateTime.now();
}
