import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/auth_failure.dart';
import '../../models/startup.dart';
import '../../models/startup_enums.dart';
import '../../models/team_member.dart';
import '../firebase_services/auth_service.dart';
import '../firebase_services/firestore_service.dart';
import '../device_services/image_fit.dart';
import 'funding_round_repository.dart';
import 'invitation_repository.dart';
import 'public_profile_repository.dart';
import 'ticket_repository.dart';

/// Reads and writes the `startups` collection and the startups' logos in
/// Storage. Screens and view models never touch Firebase directly.
///
/// Every method throws [AuthException] on failure (network, permission, ...).
class StartupRepository {
  StartupRepository({
    AuthService? auth,
    FirestoreService? firestore,
    FundingRoundRepository? rounds,
  }) : _auth = auth ?? AuthService(),
       _firestore = firestore ?? FirestoreService(),
       _roundsOverride = rounds;

  /// The app-wide instance. Tests replace it with a fake.
  static StartupRepository instance = StartupRepository();

  /// Bumps after the signed-in user created, saved, deleted or left a
  /// startup, so screens that keep a copy (Matches "for" list) reload it.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  final AuthService _auth;
  final FirestoreService _firestore;
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
    final startup = Startup.fromMap(id, data);
    return startup == null ? null : await _withLiveNames(startup);
  }

  /// A joined person's card shows their CURRENT account name and photo (it follows
  /// Edit profile), not the one typed when they were invited. Sample startups
  /// and cards not linked to an account keep what is stored. Best effort.
  Future<Startup> _withLiveNames(Startup s) async {
    try {
      if (s.founderId == 'crunchbase-dataset') return s;
      final uids = {
        for (final m in s.team)
          if (m.uid != null && !m.invited) m.uid!,
      };
      if (uids.isEmpty) return s;
      final live = await PublicProfileRepository.instance.liveOf(uids);
      if (live.isEmpty) return s;
      return s.copyWith(
        team: [
          for (final m in s.team)
            live[m.uid] == null
                ? m
                : m.copyWith(
                    name: live[m.uid]!.name,
                    photoData: live[m.uid]!.photoData,
                  ),
        ],
      );
    } catch (_) {
      return s;
    }
  }

  /// The signed-in founder's startups, most recently edited first.
  Future<List<Startup>> fetchMyStartups() async {
    final docs = await _firestore.queryWhereEqual(
      _collection,
      StartupFields.founderId,
      _founderId,
    );
    final startups = [
      for (final doc in docs)
        if (Startup.fromMap(doc.id, doc.data) case final s?)
          await _withLiveNames(s),
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
      for (final doc in docs)
        if (Startup.fromMap(doc.id, doc.data) case final s?)
          await _withLiveNames(s),
    ];
    startups.sort((a, b) => _editedAt(b).compareTo(_editedAt(a)));
    return startups;
  }

  /// My public profile lists my startups (so other people see them on my
  /// profile): keep that list in step. Best effort, never blocks.
  void _refreshMyProfile() {
    try {
      unawaited(PublicProfileRepository.instance.refreshMyStartups(_founderId));
    } catch (_) {
      // Not signed in (or not a founder account): nothing to refresh.
    }
  }

  /// "Leave startup": removes ONLY the signed-in user's own membership: their
  /// uid from `memberIds`, `memberRoles` and `coFounderIds`, and their card
  /// from the team list (`teamMembers`), so they are not shown on the Team tab
  /// any more. The security rules allow a member to change nothing else.
  ///
  /// [keepFounderName]: the person who created the startup (after handing it
  /// over) stays on the team as "Founder (former)".
  ///
  /// Two special cases:
  /// - the OWNER of a closed startup may leave it: nobody owns it afterwards
  ///   (it can't be reopened), and the team keeps it;
  /// - the last person on a closed startup nobody owns: it is deleted.
  Future<void> leave(Startup startup, {bool keepFounderName = false}) async {
    final uid = _founderId;
    final keep = keepFounderName && uid == startup.originalFounderId;
    final rest = [
      for (final m in startup.team)
        if (m.uid != uid) m.toMap(),
    ];
    final hadCard = rest.length != startup.team.length;
    if (startup.founderId == uid) {
      // An active startup is handed over or deleted, never left behind.
      if (!startup.isClosed) {
        throw const AuthException(AuthFailure.permissionDenied);
      }
      await _firestore.updateDocument(_collection, startup.id, {
        StartupFields.founderId: '',
        // Older startups get who created them now (it never changes).
        StartupFields.foundedBy: startup.originalFounderId,
        if (hadCard) StartupFields.team: rest,
        if (keep) StartupFields.formerFounderId: uid,
      });
    } else if (!startup.hasOwner &&
        startup.isClosed &&
        startup.memberIds.length == 1 &&
        startup.memberRoles.containsKey(uid)) {
      await _deleteDocumentAndRounds(startup);
    } else {
      await _firestore.updateDocument(_collection, startup.id, {
        StartupFields.memberIds: _firestore.arrayRemove([uid]),
        '${StartupFields.memberRoles}.$uid': _firestore.deleteField(),
        StartupFields.coFounderIds: _firestore.arrayRemove([uid]),
        if (hadCard) StartupFields.team: rest,
        if (keep) StartupFields.formerFounderId: uid,
      });
    }
    changes.value++;
    _refreshMyProfile();
  }

  /// Leaves every startup the signed-in user is a co-founder / team member of
  /// (used when the account is deleted). Stops at the first failure, so the
  /// account is never deleted while it is still on a team.
  Future<void> leaveAll() async {
    final mine = await fetchMemberStartups();
    for (final s in mine) {
      await leave(s);
    }
  }

  /// Gives [startup] to the joined co-founder [newOwnerId]. The current owner
  /// stays on the team as a co-founder (and keeps their title: the person who
  /// created the startup is always its "Founder"), and can leave afterwards.
  /// Returns the startup as stored.
  Future<Startup> transferOwnership(Startup startup, String newOwnerId) async {
    final me = _founderId;
    if (startup.founderId != me ||
        startup.isClosed ||
        startup.memberRoles[newOwnerId] != 'coFounder') {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    final roles = {...startup.memberRoles}..remove(newOwnerId);
    roles[me] = 'coFounder';
    final moved = startup.copyWith(
      founderId: newOwnerId,
      foundedBy: startup.originalFounderId,
      memberRoles: roles,
    );
    await _firestore.updateDocument(_collection, startup.id, {
      ...moved.toMap(),
      StartupFields.updatedAt: _firestore.serverTimestamp(),
    });
    changes.value++;
    _refreshMyProfile();
    return moved;
  }

  /// Closes [startup] (its owner, with no co-founder on it): hidden from
  /// Start.sa and read only, kept for its team. Pending invitations are
  /// cancelled and the open round ends (Funding is unticked in the same
  /// write). Returns the startup as stored.
  Future<Startup> close(Startup startup) async {
    if (startup.founderId != _founderId ||
        startup.isClosed ||
        startup.coFounderIds.isNotEmpty) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    await InvitationRepository.instance.cancelAllFor(startup);
    return update(
      startup.copyWith(
        isClosed: true,
        lookingFor: {...startup.lookingFor}..remove(LookingFor.funding),
        clearFunding: true,
        // Nobody can join a closed startup.
        team: [
          for (final m in startup.team)
            if (!m.invited) m,
        ],
      ),
    );
  }

  /// Opens a closed startup again (its owner only). It comes back Private.
  Future<Startup> reopen(Startup startup) async {
    if (startup.founderId != _founderId || !startup.isClosed) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    return update(startup.copyWith(isClosed: false, isPublic: false));
  }

  /// The startups where I'm shown as "Founder (former)" (public ones: a
  /// private startup can't be read by someone who left it).
  Future<List<Startup>> fetchFormerStartups() async {
    final uid = _founderId;
    final docs = await _firestore.queryWhereAll(_collection, {
      StartupFields.formerFounderId: uid,
      StartupFields.isPublic: true,
    });
    return [for (final doc in docs) ?Startup.fromMap(doc.id, doc.data)];
  }

  /// "Remove my name": I'm no longer shown as Founder (former) on [startupId].
  Future<void> removeMyFormerName(String startupId) async {
    if (_auth.currentAccount == null) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    await _firestore.updateDocument(_collection, startupId, {
      StartupFields.formerFounderId: _firestore.deleteField(),
    });
    changes.value++;
    _refreshMyProfile();
  }

  /// The signed-in founder still belongs to a startup (owned, joined or
  /// closed). Every founder account must.
  Future<bool> hasAnyStartup() async =>
      (await fetchMyStartups()).isNotEmpty ||
      (await fetchMemberStartups()).isNotEmpty;

  /// "My name carries over": after [uid] changed their name on Edit profile,
  /// every team card of theirs in the startups they founded shows the new
  /// one. A member is theirs when it is linked to [uid], or (not linked yet)
  /// when it carried their old name; it is linked from then on.
  Future<void> syncMemberName({
    required String uid,
    required String oldName,
    required String newName,
  }) async {
    PublicProfileRepository.forgetNames();
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
    // The logo is a small compressed picture saved inside the startup
    // (no Firebase Storage). Done first: if it fails, nothing is written.
    final logoData = logo == null ? null : await ImageFit.base64Of(logo);
    final toSave = startup.copyWith(
      id: id,
      founderId: founderId,
      logoData: logoData,
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
      rethrow;
    }
    changes.value++;
    _refreshMyProfile();
    return toSave;
  }

  /// Saves changes to an existing startup.
  ///
  /// Pass [newLogo] to replace the logo, or [removeLogo] to clear it (the field
  /// is deleted). The logo is saved inside the startup as base64 text.
  ///
  /// The funding rounds follow the Funding answers in the same write: Funding
  /// ticked opens a round (or updates the open one), unticked closes it.
  Future<Startup> update(
    Startup startup, {
    File? newLogo,
    bool removeLogo = false,
  }) async {
    var updated = startup;
    if (newLogo != null) {
      updated = startup.copyWith(logoData: await ImageFit.base64Of(newLogo));
    } else if (removeLogo) {
      updated = startup.copyWith(clearLogo: true);
    }

    // The open round follows the Funding answers (opened, updated or
    // closed), in the same write as the startup.
    final roundWrites = await _rounds.writesFor(startup.id, updated);
    final startupData = {
      ...updated.toMap(),
      // "Remove logo" deletes the field.
      if (updated.logoData == null)
        StartupFields.logoData: _firestore.deleteField(),
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

    changes.value++;
    _refreshMyProfile();
    return updated;
  }

  /// Before the account is deleted: each startup I own is deleted (nobody
  /// else on it), handed to its first co-founder in the team list, or closed
  /// for its team (the delete confirmation listed which), then I leave the
  /// teams I'm on and my "Founder (former)" names go. Stops at the first
  /// failure, so the account is never deleted with a startup left behind.
  Future<void> handOverAllMine() async {
    for (final s in await fetchMyStartups()) {
      if (s.isClosed) {
        if (s.memberRoles.isEmpty) {
          await delete(s);
        } else {
          await leave(s);
        }
        continue;
      }
      switch (s.ownerOption) {
        case OwnerOption.delete:
          await delete(s);
        case OwnerOption.transfer:
          await leave(
            await transferOwnership(s, s.coFoundersInTeamOrder.first),
          );
        case OwnerOption.close:
          await leave(await close(s));
      }
    }
    await leaveAll();
    try {
      for (final s in await fetchFormerStartups()) {
        await removeMyFormerName(s.id);
      }
    } catch (e) {
      // The name goes with the public profile anyway.
      debugPrint('Could not remove a former founder name: $e');
    }
  }

  /// Deletes the startup and its funding rounds (the logo is inside the
  /// startup) when nobody else is on it. Its pending invitations are
  /// cancelled first, so nobody is asked to join a startup that no longer
  /// exists. Every membership goes with it (the members are stored inside the
  /// startup document). Other people's bookmarks of it are dropped the next
  /// time they open Bookmarks (the bookmark repository removes a bookmark
  /// whose startup no longer exists).
  Future<void> delete(Startup startup) async {
    if (startup.memberRoles.isNotEmpty) {
      // Somebody else is on it: hand it over or close it instead.
      throw const AuthException(AuthFailure.permissionDenied);
    }
    // Before the startup goes: the rules read it to allow cancelling.
    await InvitationRepository.instance.cancelAllFor(startup);
    // The requests investors sent to it go too (before the startup: the
    // rules read it to allow this).
    try {
      await TicketRepository.instance.removeRequestsForStartup(startup.id);
    } catch (e) {
      debugPrint('Could not remove the requests of a startup: $e');
    }
    await _deleteDocumentAndRounds(startup);
    changes.value++;
    _refreshMyProfile();
  }

  Future<void> _deleteDocumentAndRounds(Startup startup) async {
    // Its funding rounds first: Firestore doesn't delete a subcollection
    // with its document, and the rules read the startup to allow it.
    final roundDeletes = await _rounds.deletesFor(startup.id);
    if (roundDeletes.isNotEmpty) await _firestore.commit(roundDeletes);
    await _firestore.deleteDocument(_collection, startup.id);
  }

  /// A just-saved document may have no server timestamp yet; treat it as new.
  DateTime _editedAt(Startup s) => s.updatedAt ?? s.createdAt ?? DateTime.now();
}
