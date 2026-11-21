import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/auth_failure.dart';
import '../../models/home_item.dart';
import '../../models/startup.dart';
import '../../models/startup_enums.dart';
import '../../models/startup_notice.dart';
import '../../models/team_member.dart';
import '../firebase_services/auth_service.dart';
import '../firebase_services/firestore_service.dart';
import '../device_services/image_fit.dart';
import '../remote/for_you_api.dart';
import 'discovery_repository.dart';
import 'funding_round_repository.dart';
import 'invitation_repository.dart';
import 'notice_repository.dart';
import 'public_profile_repository.dart';
import 'ticket_repository.dart';

/// Reads and writes the startups collection and the startups' logos in Storage.
class StartupRepository {
  StartupRepository({
    AuthService? auth,
    FirestoreService? firestore,
    FundingRoundRepository? rounds,
    ForYouSource? forYou,
  }) : _auth = auth ?? AuthService(),
       _firestore = firestore ?? FirestoreService(),
       _roundsOverride = rounds,
       _forYou = forYou ?? ForYouApi.instance;

  /// The app-wide instance.
  static StartupRepository instance = StartupRepository();

  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  final AuthService _auth;
  final FirestoreService _firestore;
  final FundingRoundRepository? _roundsOverride;
  final ForYouSource _forYou;

  /// Asks the server to re-encode this startup's text. Fire and forget: a
  /// failure is logged and never reaches the save.
  void _refreshText(String id) {
    if (!_forYou.enabled) return;
    unawaited(() async {
      try {
        await _forYou.profileText(HomeItemKind.startup, id);
      } catch (e) {
        debugPrint('profile-text refresh failed: $e');
      }
    }());
  }

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

  Future<Startup> _withLiveNames(Startup s) async {
    try {
      if (s.founderId == Startup.datasetFounderId) return s;
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
    startups.sort((a, b) => _editedAt(b).compareTo(_editedAt(a)));
    return startups;
  }

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

  void _refreshMyProfile() {
    try {
      unawaited(PublicProfileRepository.instance.refreshMyStartups(_founderId));
    } catch (_) {}
  }

  Future<void> leave(Startup startup) async {
    if (startup.isClosed || startup.founderId == _founderId) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    await _removeMe(startup);
    changes.value++;
    _refreshMyProfile();
  }

  /// Drops my membership of startup (active or closed): my uid and my card.
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

  Future<void> leaveAll() async {
    for (final s in await fetchMemberStartups()) {
      await _removeMe(s);
    }
    changes.value++;
  }

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
      memberRoles: roles,
      team: team,
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
    final data = moved.toMap();
    await _firestore.updateDocument(_collection, startup.id, {
      for (final key in const [
        StartupFields.founderId,
        StartupFields.memberIds,
        StartupFields.memberRoles,
        StartupFields.coFounderIds,
        StartupFields.team,
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

  void _showInDirectory(Startup startup) {
    try {
      DiscoveryRepository.instance.apply(startup);
    } catch (e) {
      debugPrint('Could not update the loaded lists: $e');
    }
  }

  Future<bool> hasAnyStartup() async =>
      (await fetchMyStartups()).isNotEmpty ||
      (await fetchMemberStartups()).isNotEmpty;

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

  /// Saves a new startup and returns it as stored.
  Future<Startup> create(Startup startup, {File? logo}) async {
    final founderId = _founderId;
    final id = _firestore.newDocumentId(_collection);
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
    _refreshText(id);
    changes.value++;
    _refreshMyProfile();
    return toSave;
  }

  /// Saves changes to an existing startup.
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
    await _tellRemoved(updated);

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

    _refreshText(startup.id);
    changes.value++;
    _refreshMyProfile();
    _showInDirectory(updated);
    return updated;
  }

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

  Future<void> settleMineBeforeDeletion(Map<String, StartupFate> fates) async {
    for (final s in await fetchMyStartups()) {
      final fate = fates[s.id];
      if (fate == null) {
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
    await InvitationRepository.instance.cancelAllFor(startup);
    try {
      await InvitationRepository.instance.cancelOwnerInvite(startup);
    } catch (e) {
      debugPrint('Could not cancel the founder invitation: $e');
    }
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
    final roundDeletes = await _rounds.deletesFor(startup.id);
    if (roundDeletes.isNotEmpty) await _firestore.commit(roundDeletes);
    await _firestore.deleteDocument(_collection, startup.id);
  }

  DateTime _editedAt(Startup s) => s.updatedAt ?? s.createdAt ?? DateTime.now();
}

class StartupFate {
  const StartupFate.close({this.nextFounder}) : delete = false;
  const StartupFate.delete() : delete = true, nextFounder = null;

  final bool delete;
  final String? nextFounder;
}
