import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/auth_failure.dart';
import '../../models/startup.dart';
import '../../models/startup_enums.dart';
import '../../models/startup_notice.dart';
import '../../models/team_member.dart';
import '../firebase_services/auth_service.dart';
import '../firebase_services/firestore_service.dart';
import '../device_services/image_fit.dart';
import 'discovery_repository.dart';
import 'funding_round_repository.dart';
import 'invitation_repository.dart';
import 'notice_repository.dart';
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

  /// "Leave startup" (a co-founder or team member of an ACTIVE startup):
  /// removes ONLY the signed-in user's own membership: their uid from
  /// `memberIds`, `memberRoles` and `coFounderIds`, and their card from the
  /// team list, so they are not shown on the Team tab any more. The security
  /// rules allow a member to change nothing else.
  ///
  /// Nobody leaves a closed startup (it stays in their account), and the
  /// owner leaves only by naming the next owner ([transferOwnership], or an
  /// owner invitation that is accepted).
  Future<void> leave(Startup startup) async {
    if (startup.isClosed || startup.founderId == _founderId) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    await _removeMe(startup);
    changes.value++;
    _refreshMyProfile();
  }

  /// Drops my membership of [startup] (active or closed): my uid and my card.
  /// Its founder gets a notice first ("… left …"), while I'm still on it.
  Future<void> _removeMe(Startup startup) async {
    final uid = _founderId;
    final stored = await _stored(startup);
    final team = stored.team;
    var myName = '';
    for (final m in team) {
      if (m.uid == uid) myName = m.name;
    }
    await NoticeRepository.instance.send(
      [stored.founderId],
      StartupNotice(
        type: StartupNotice.left,
        startupId: stored.id,
        startupName: stored.name,
        person: myName,
      ),
    );
    final rest = [
      for (final m in team)
        if (m.uid != uid) m.toMap(),
    ];
    await _firestore.updateDocument(_collection, startup.id, {
      StartupFields.memberIds: _firestore.arrayRemove([uid]),
      '${StartupFields.memberRoles}.$uid': _firestore.deleteField(),
      StartupFields.coFounderIds: _firestore.arrayRemove([uid]),
      if (rest.length != team.length) StartupFields.team: rest,
    });
  }

  /// [startup] as stored: the rules compare the team list with the stored
  /// one, and a loaded copy shows people's current names instead.
  Future<Startup> _stored(Startup startup) async {
    try {
      return Startup.fromMap(
            startup.id,
            await _firestore.getDocument(_collection, startup.id),
          ) ??
          startup;
    } catch (_) {
      return startup;
    }
  }

  /// Account deletion: my membership goes from every team I'm on, closed
  /// startups included (my information leaves with my account). Stops at the
  /// first failure, so the account is never deleted while still on a team.
  Future<void> leaveAll() async {
    for (final s in await fetchMemberStartups()) {
      await _removeMe(s);
    }
    changes.value++;
  }

  /// The founder hands [startup] to [newOwnerId], someone who joined its
  /// team (a co-founder or a member): they become its founder (their card
  /// takes the Founder title), and the current founder becomes [stay]
  /// (`coFounder` or `member`, his card following) or leaves the team, card
  /// included (null). A closed startup can be handed over too (its founder
  /// deleting his account): it stays closed. The new founder and the rest
  /// of the team get a notice. The requests investors sent move to the new
  /// founder. Returns the startup as stored.
  Future<Startup> transferOwnership(
    Startup startup,
    String newOwnerId, {
    String? stay,
  }) async {
    final me = _founderId;
    if (startup.founderId != me ||
        !startup.memberRoles.containsKey(newOwnerId)) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    final stored = await _stored(startup);
    final roles = {...stored.memberRoles}..remove(newOwnerId);
    if (stay != null) roles[me] = stay;
    // The new founder's card takes the Founder title; mine follows my
    // choice, or goes.
    final team = <TeamMember>[];
    for (final m in stored.team) {
      if (m.uid == newOwnerId) {
        team.add(m.copyWith(isFounder: true, coFounder: false));
      } else if (m.uid == me) {
        if (stay != null) {
          team.add(
            m.copyWith(isFounder: false, coFounder: stay == 'coFounder'),
          );
        }
      } else {
        team.add(m);
      }
    }
    final moved = stored.copyWith(
      founderId: newOwnerId,
      foundedBy: stored.originalFounderId,
      memberRoles: roles,
      team: team,
      ownerChangedAt: DateTime.now(),
    );
    final newName = stored.nameOf(newOwnerId);
    final notices = NoticeRepository.instance;
    await notices.send(
      [newOwnerId],
      StartupNotice(
        type: StartupNotice.newFounder,
        startupId: stored.id,
        startupName: stored.name,
      ),
    );
    await notices.send(
      [
        for (final uid in stored.memberRoles.keys)
          if (uid != newOwnerId) uid,
      ],
      StartupNotice(
        type: StartupNotice.founderChanged,
        startupId: stored.id,
        startupName: stored.name,
        person: newName,
      ),
    );
    // Only the team fields change (the rules allow nothing else here).
    final data = moved.toMap();
    await _firestore.updateDocument(_collection, startup.id, {
      for (final key in const [
        StartupFields.founderId,
        StartupFields.foundedBy,
        StartupFields.memberIds,
        StartupFields.memberRoles,
        StartupFields.coFounderIds,
        StartupFields.team,
        StartupFields.ownerChangedAt,
      ])
        key: data[key],
      StartupFields.updatedAt: _firestore.serverTimestamp(),
    });
    if (!stored.isClosed) {
      try {
        await TicketRepository.instance.moveRequests(
          startup.id,
          from: me,
          to: newOwnerId,
        );
      } catch (e) {
        debugPrint('Could not move the requests to the new founder: $e');
      }
    }
    try {
      // Somebody invited to take over is no longer needed.
      await InvitationRepository.instance.cancelOwnerInvite(startup);
    } catch (e) {
      debugPrint('Could not cancel the owner invitation: $e');
    }
    changes.value++;
    _refreshMyProfile();
    return moved;
  }

  /// Closes [startup] (its owner): permanent and read only, it stays in
  /// everyone's account with its current visibility. Pending invitations are
  /// cancelled, waiting investment requests are declined, and the open round
  /// ends (Funding is unticked in the same write). Returns the startup as
  /// stored.
  Future<Startup> close(Startup startup) async {
    if (startup.founderId != _founderId || startup.isClosed) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    await InvitationRepository.instance.cancelAllFor(startup);
    try {
      await InvitationRepository.instance.cancelOwnerInvite(startup);
    } catch (e) {
      debugPrint('Could not cancel the owner invitation: $e');
    }
    try {
      await TicketRepository.instance.declinePendingFor(
        startup.id,
        founderId: startup.founderId,
      );
    } catch (e) {
      debugPrint('Could not decline the requests of a closed startup: $e');
    }
    final closed = await update(
      startup.copyWith(
        isClosed: true,
        closedAt: DateTime.now(),
        lookingFor: {...startup.lookingFor}..remove(LookingFor.funding),
        clearFunding: true,
        // Nobody can join a closed startup.
        team: [
          for (final m in startup.team)
            if (!m.invited) m,
        ],
      ),
    );
    await NoticeRepository.instance.send(
      startup.memberRoles.keys,
      StartupNotice(
        type: StartupNotice.closed,
        startupId: startup.id,
        startupName: startup.name,
      ),
    );
    return closed;
  }

  /// The owner's one control on a closed startup: whether it shows in the
  /// Hub. Only `isPublic` changes.
  Future<Startup> setClosedVisibility(Startup startup, bool isPublic) async {
    if (startup.founderId != _founderId || !startup.isClosed) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    await _firestore.updateDocument(_collection, startup.id, {
      StartupFields.isPublic: isPublic,
      StartupFields.updatedAt: _firestore.serverTimestamp(),
    });
    final saved = startup.copyWith(isPublic: isPublic);
    changes.value++;
    _refreshMyProfile();
    _showInDirectory(saved);
    return saved;
  }

  /// The Hub and Explore lists follow my own change at once (see
  /// [DiscoveryRepository.apply]).
  void _showInDirectory(Startup startup) {
    try {
      DiscoveryRepository.instance.apply(startup);
    } catch (e) {
      debugPrint('Could not update the loaded lists: $e');
    }
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
    // People the founder took off the team are told, while still on it.
    await _tellRemoved(updated);

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
    _showInDirectory(updated);
    return updated;
  }

  /// The joined people [updated] no longer has (the founder took them off
  /// the team) get a notice, before the save takes them off.
  Future<void> _tellRemoved(Startup updated) async {
    try {
      final before = await _stored(updated);
      final gone = [
        for (final uid in before.memberRoles.keys)
          if (!updated.memberRoles.containsKey(uid) && uid != updated.founderId)
            uid,
      ];
      if (gone.isEmpty) return;
      await NoticeRepository.instance.send(
        gone,
        StartupNotice(
          type: StartupNotice.removed,
          startupId: updated.id,
          startupName: before.name,
        ),
      );
    } catch (e) {
      debugPrint('Could not tell the removed members: $e');
    }
  }

  /// Before the founder's account is deleted: what he chose for each startup
  /// he holds ([fates], by startup id). Delete removes it for everyone; Close
  /// closes it (if it isn't already) and, when [StartupFate.nextFounder] is
  /// set, hands it to that person, who then controls whether it shows in the
  /// Hub. A closed startup nobody else is on stays as it is, with my name, as
  /// history. Then I leave every team I joined. Stops at the first failure,
  /// so the account is never deleted with a startup left half done.
  Future<void> settleMineBeforeDeletion(Map<String, StartupFate> fates) async {
    for (final s in await fetchMyStartups()) {
      final fate = fates[s.id];
      if (fate == null) {
        // Every startup must have a choice (the app asks for all of them).
        throw const AuthException(AuthFailure.permissionDenied);
      }
      if (fate.delete) {
        await delete(s);
        continue;
      }
      final closed = s.isClosed ? s : await close(s);
      final next = fate.nextFounder;
      if (next != null && closed.memberRoles.containsKey(next)) {
        await transferOwnership(closed, next);
      }
    }
    await leaveAll();
  }

  /// Deletes the startup, its funding rounds (the logo is inside the
  /// startup) and the requests investors sent it: its founder only (Delete
  /// startup, or deleting his account), with or without a team. Its team
  /// gets a notice first (while the rules can still see they are on it),
  /// and its pending invitations are cancelled, so nobody is asked to join a
  /// startup that no longer exists. Every membership goes with it (the
  /// members are stored inside the startup document). Other people's
  /// bookmarks of it are dropped the next time they open Bookmarks (the
  /// bookmark repository removes a bookmark whose startup no longer exists).
  Future<void> delete(Startup startup) async {
    if (startup.founderId != _founderId) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    await NoticeRepository.instance.send(
      startup.memberRoles.keys,
      StartupNotice(
        type: StartupNotice.deleted,
        startupId: startup.id,
        startupName: startup.name,
      ),
    );
    // Before the startup goes: the rules read it to allow cancelling (a
    // closed startup's were cancelled when it closed).
    await InvitationRepository.instance.cancelAllFor(startup);
    try {
      await InvitationRepository.instance.cancelOwnerInvite(startup);
    } catch (e) {
      debugPrint('Could not cancel the founder invitation: $e');
    }
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
    try {
      DiscoveryRepository.instance.forget(startup.id);
    } catch (_) {}
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

/// What the founder chose for one of his startups before deleting his
/// account: [delete] it, or close it ([delete] false) and, when it has a
/// team, hand it to [nextFounder].
class StartupFate {
  const StartupFate.close({this.nextFounder}) : delete = false;
  const StartupFate.delete() : delete = true, nextFounder = null;

  final bool delete;
  final String? nextFounder;
}
