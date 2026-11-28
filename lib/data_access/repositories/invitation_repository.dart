import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/auth_failure.dart';
import '../../models/invitation.dart';
import '../../models/startup.dart';
import '../../models/startup_notice.dart';
import '../../models/team_member.dart';
import '../firebase_services/auth_service.dart';
import '../firebase_services/firestore_service.dart';
import '../firebase_services/invite_relay_service.dart';
import 'notice_repository.dart';
import 'public_profile_repository.dart';

/// The result of sending one invitation e-mail.
enum InviteSendResult {
  /// The e-mail left (and the invitation says so).
  sent,

  /// The relay refused or failed; the invitation stays "not sent".
  failed,

  /// The relay address isn't configured yet (a deployment step).
  notConfigured,

  /// No connection.
  offline,

  /// Gmail's daily limit for invitation e-mails was reached.
  dailyLimit,

  /// This invitation was e-mailed less than an hour ago (nothing to do).
  tooSoon,
}

class InvitationRepository {
  InvitationRepository({
    AuthService? auth,
    FirestoreService? firestore,
    InviteRelayService? relay,
  }) : _auth = auth ?? AuthService(),
       _firestore = firestore ?? FirestoreService(),
       _relay = relay ?? const InviteRelayService();

  /// The app-wide instance.
  static InvitationRepository instance = InvitationRepository();

  final AuthService _auth;
  final FirestoreService _firestore;
  final InviteRelayService _relay;

  static const _col = FirestoreCollections.invitations;

  String get _uid {
    final uid = _auth.currentAccount?.uid;
    if (uid == null) throw const AuthException(AuthFailure.permissionDenied);
    return uid;
  }

  Future<Invitation> ensure({
    required Startup startup,
    required TeamMember member,
    required String invitedByName,
    bool newUser = false,
  }) async {
    final email = member.email.trim().toLowerCase();
    final id = Invitation.idOf(startup.id, email);
    final role = member.coFounder
        ? Invitation.roleCoFounder
        : Invitation.roleMember;
    final existing = Invitation.fromMap(await _firestore.getDocument(_col, id));
    if (existing == null) {
      final invitation = Invitation(
        startupId: startup.id,
        startupName: startup.name,
        emailLower: email,
        role: role,
        roleText: member.role,
        contribution: member.contribution,
        invitedBy: _uid,
        invitedByName: invitedByName,
        newUser: newUser,
      );
      await _firestore.setDocument(_col, id, {
        ...invitation.toCreateMap(),
        'createdAt': _firestore.serverTimestamp(),
      });
      await _addToInviteIndex(email, startup.name);
      return invitation;
    }
    if (existing.status == InvitationStatus.declined ||
        (existing.status == InvitationStatus.accepted &&
            await _stillOnTeam(existing, startup))) {
      return existing;
    }
    await _firestore.updateDocument(_col, id, {
      'status': InvitationStatus.pending.value,
      'role': role,
      'roleText': member.role,
      'contribution': member.contribution,
      'newUser': newUser,
      if (existing.status != InvitationStatus.pending) 'emailSent': false,
    });
    await _addToInviteIndex(email, startup.name);
    return Invitation(
      startupId: existing.startupId,
      startupName: existing.startupName,
      emailLower: existing.emailLower,
      role: role,
      roleText: member.role,
      contribution: member.contribution,
      invitedBy: existing.invitedBy,
      invitedByName: existing.invitedByName,
      newUser: newUser,
      emailSent: existing.status == InvitationStatus.pending
          ? existing.emailSent
          : false,
    );
  }

  /// The person who accepted invitation is still on the startup's team.
  Future<bool> _stillOnTeam(Invitation invitation, Startup startup) async {
    Startup current;
    try {
      current =
          Startup.fromMap(
            startup.id,
            await _firestore.getDocument(
              FirestoreCollections.startups,
              startup.id,
            ),
          ) ??
          startup;
    } catch (_) {
      return true;
    }
    final uid = invitation.acceptedBy;
    if (uid != null && uid.isNotEmpty) {
      return uid == current.founderId || current.memberRoles.containsKey(uid);
    }
    return current.team.any(
      (m) => !m.invited && m.email == invitation.emailLower,
    );
  }

  Future<void> cancelAllFor(Startup startup) async {
    for (final m in startup.team) {
      if (!m.invited || m.email.trim().isEmpty) continue;
      try {
        await cancel(startup.id, m.email);
      } catch (e) {
        debugPrint('Could not cancel the invitation of ${m.email}: $e');
      }
    }
  }

  /// The startup is deleted: every invitation it sent goes too (any status).
  Future<void> deleteAllFor(Startup startup) async {
    final ids = <String>{
      for (final m in startup.team)
        if (m.email.trim().isNotEmpty) Invitation.idOf(startup.id, m.email),
    };
    try {
      ids.addAll([for (final i in await sentFor(startup.id)) i.id]);
    } catch (e) {
      debugPrint('Could not list the startup invitations: $e');
    }
    for (final id in ids) {
      try {
        final existing = Invitation.fromMap(
          await _firestore.getDocument(_col, id),
        );
        if (existing == null) continue;
        await _firestore.deleteDocument(_col, id);
        await _removeFromInviteIndex(existing.emailLower, existing.startupName);
      } catch (e) {
        debugPrint('Could not delete the invitation $id: $e');
      }
    }
  }

  /// The account is deleted: every invitation to its e-mail (any status) and
  /// its invite index entry go too.
  Future<void> deleteAllForMe() async {
    try {
      final account = _auth.currentAccount;
      if (account == null) return;
      final email = account.email.trim().toLowerCase();
      if (account.emailVerified) {
        try {
          for (final d in await _firestore.queryWhereEqual(
            _col,
            'emailLower',
            email,
          )) {
            await _firestore.deleteDocument(_col, d.id);
          }
        } catch (e) {
          debugPrint('Could not delete my invitations: $e');
        }
      }
      await _firestore.deleteDocument(FirestoreCollections.inviteEmails, email);
    } catch (e) {
      debugPrint('Could not delete my invite index entry: $e');
    }
  }

  /// The team removed the person before they joined.
  Future<void> cancel(String startupId, String email) async {
    final id = Invitation.idOf(startupId, email);
    final existing = Invitation.fromMap(await _firestore.getDocument(_col, id));
    if (existing == null || existing.status == InvitationStatus.accepted) {
      return;
    }
    if (existing.status == InvitationStatus.declined) {
      await _firestore.deleteDocument(_col, id);
      return;
    }
    await _firestore.updateDocument(_col, id, {
      'status': InvitationStatus.cancelled.value,
    });
    await _removeFromInviteIndex(existing.emailLower, existing.startupName);
  }

  /// The founder invites email to take startup over when he leaves.
  Future<Invitation> inviteOwner({
    required Startup startup,
    required String email,
    required String invitedByName,
    bool newUser = false,
    String? stay,
  }) async {
    final lower = email.trim().toLowerCase();
    final id = Invitation.idOf(startup.id, lower);
    final existing = Invitation.fromMap(await _firestore.getDocument(_col, id));
    final invitation = Invitation(
      startupId: startup.id,
      startupName: startup.name,
      emailLower: lower,
      role: Invitation.roleOwner,
      invitedBy: _uid,
      invitedByName: invitedByName,
      newUser: newUser,
      previousFounderRole: stay,
    );
    if (existing != null) await _firestore.deleteDocument(_col, id);
    await _firestore.setDocument(_col, id, {
      ...invitation.toCreateMap(),
      'createdAt': _firestore.serverTimestamp(),
    });
    await _addToInviteIndex(lower, startup.name);
    return Invitation(
      startupId: invitation.startupId,
      startupName: invitation.startupName,
      emailLower: invitation.emailLower,
      role: invitation.role,
      invitedBy: invitation.invitedBy,
      invitedByName: invitation.invitedByName,
      newUser: invitation.newUser,
      createdAt: DateTime.now(),
      previousFounderRole: stay,
    );
  }

  Future<Invitation?> pendingOwnerInvite(String startupId) async {
    for (final i in await sentFor(startupId)) {
      if (i.isOwner && i.isPending) return i;
    }
    return null;
  }

  Future<void> cancelOwnerInvite(Startup startup) async {
    final pending = await pendingOwnerInvite(startup.id);
    if (pending != null) await cancel(startup.id, pending.emailLower);
  }

  /// Sends the e-mail of invitation through the relay and records it.
  Future<InviteSendResult> sendEmail(Invitation invitation) async {
    try {
      final token = await _auth.idToken();
      if (token == null) return InviteSendResult.failed;
      final ok = await _relay.send(idToken: token, invitationId: invitation.id);
      if (!ok) {
        final why = InviteRelayService.lastError ?? '';
        if (why.contains('daily limit')) return InviteSendResult.dailyLimit;
        if (why.contains('sent recently')) return InviteSendResult.tooSoon;
        return InviteSendResult.failed;
      }
      await _firestore.updateDocument(_col, invitation.id, {'emailSent': true});
      return InviteSendResult.sent;
    } on StateError {
      return InviteSendResult.notConfigured;
    } on AuthException catch (e) {
      debugPrint('Sending the invitation failed: $e');
      return e.failure == AuthFailure.network
          ? InviteSendResult.offline
          : InviteSendResult.failed;
    } catch (e) {
      debugPrint('Sending the invitation failed: $e');
      return InviteSendResult.failed;
    }
  }

  /// The invitations I sent for startupId (statuses: Invited / Declined).
  Future<List<Invitation>> sentFor(String startupId) async {
    final docs = await _firestore.queryWhereEqual(_col, 'invitedBy', _uid);
    return [
      for (final d in docs)
        if (d.data['startupId'] == startupId) ?Invitation.fromMap(d.data),
    ];
  }

  /// One invitation by its id (readable before the person has an account).
  Future<Invitation?> byId(String id) async =>
      Invitation.fromMap(await _firestore.getDocument(_col, id));

  Future<List<String>> invitedBy(String email) async {
    final data = await _firestore.getDocument(
      FirestoreCollections.inviteEmails,
      email.trim().toLowerCase(),
    );
    final names = data?['names'];
    return [
      if (names is List)
        for (final n in names)
          if (n is String && n.trim().isNotEmpty) n,
    ];
  }

  /// My pending invitations (my account must have a VERIFIED e-mail).
  Future<List<Invitation>> pendingForMe() async {
    final account = _auth.currentAccount;
    if (account == null || !account.emailVerified) return const [];
    final docs = await _firestore.queryWhereAll(_col, {
      'emailLower': account.email.trim().toLowerCase(),
      'status': InvitationStatus.pending.value,
    });
    final now = DateTime.now();
    return [
      for (final d in docs)
        if (Invitation.fromMap(d.data) case final i?)
          if (!i.isExpired(now)) i,
    ];
  }

  Future<void> accept(Invitation invitation, {required String fullName}) async {
    if (invitation.isOwner) {
      return _acceptOwnership(invitation, fullName: fullName);
    }
    final uid = _uid;
    List<Map<String, Object?>>? team;
    try {
      final data = await _firestore.getDocument(
        FirestoreCollections.startups,
        invitation.startupId,
      );
      final startup = Startup.fromMap(invitation.startupId, data);
      if (startup != null) {
        team = [
          for (final m in startup.team)
            if (m.email == invitation.emailLower)
              m.copyWith(invited: false, uid: uid, name: fullName).toMap()
            else
              m.toMap(),
        ];
      }
    } catch (_) {}
    await _firestore.commit([
      FirestoreWrite.update(
        FirestoreCollections.startups,
        invitation.startupId,
        {
          'memberIds': _firestore.arrayUnion([uid]),
          'memberRoles.$uid': invitation.role,
          // The rules protect the joined co-founders through this list.
          if (invitation.isCoFounder)
            'coFounderIds': _firestore.arrayUnion([uid]),
          'teamMembers': ?team,
          'updatedAt': _firestore.serverTimestamp(),
        },
      ),
      FirestoreWrite.update(_col, invitation.id, {
        'status': InvitationStatus.accepted.value,
        'acceptedBy': uid,
        'acceptedByName': fullName,
      }),
    ]);
    await _removeFromInviteIndex(invitation.emailLower, invitation.startupName);
    // My profile now lists this startup.
    unawaited(PublicProfileRepository.instance.refreshMyStartups(uid));
  }

  Future<void> _acceptOwnership(
    Invitation invitation, {
    required String fullName,
  }) async {
    final uid = _uid;
    final startup = Startup.fromMap(
      invitation.startupId,
      await _firestore.getDocument(
        FirestoreCollections.startups,
        invitation.startupId,
      ),
    );
    if (startup == null || startup.isClosed) {
      throw const AuthException(AuthFailure.permissionDenied);
    }
    final previous = startup.founderId;
    final stay = invitation.previousFounderRole;
    final team = <Map<String, Object?>>[
      TeamMember(
        name: fullName,
        email: invitation.emailLower,
        role: '',
        contribution: '',
        isFounder: true,
        uid: uid,
      ).toMap(),
    ];
    for (final m in startup.team) {
      if (m.email == invitation.emailLower) continue;
      if (previous.isNotEmpty && m.uid == previous) {
        if (stay != null) {
          team.add(
            m
                .copyWith(isFounder: false, coFounder: stay == 'coFounder')
                .toMap(),
          );
        }
        continue;
      }
      team.add(m.toMap());
    }
    final notices = NoticeRepository.instance;
    await notices.send(
      [previous],
      StartupNotice(
        type: StartupNotice.handedOver,
        startupId: startup.id,
        startupName: startup.name,
        person: fullName,
        stay: stay,
      ),
    );
    await notices.send(
      startup.memberRoles.keys,
      StartupNotice(
        type: StartupNotice.founderChanged,
        startupId: startup.id,
        startupName: startup.name,
        person: fullName,
      ),
    );
    await _firestore.commit([
      FirestoreWrite.update(
        FirestoreCollections.startups,
        invitation.startupId,
        {
          StartupFields.founderId: uid,
          StartupFields.team: team,
          // The previous founder stays on the team, if he chose to.
          if (stay != null) ...{
            StartupFields.memberIds: _firestore.arrayUnion([previous]),
            '${StartupFields.memberRoles}.$previous': stay,
            if (stay == 'coFounder')
              StartupFields.coFounderIds: _firestore.arrayUnion([previous]),
          },
          StartupFields.updatedAt: _firestore.serverTimestamp(),
        },
      ),
      FirestoreWrite.update(_col, invitation.id, {
        'status': InvitationStatus.accepted.value,
        'acceptedBy': uid,
        'acceptedByName': fullName,
      }),
    ]);
    await _removeFromInviteIndex(invitation.emailLower, invitation.startupName);
    unawaited(PublicProfileRepository.instance.refreshMyStartups(uid));
  }

  Future<void> decline(Invitation invitation) async {
    if (invitation.isOwner && invitation.isPending) {
      await NoticeRepository.instance.send(
        [invitation.invitedBy],
        StartupNotice(
          type: StartupNotice.declined,
          startupId: invitation.startupId,
          startupName: invitation.startupName,
          person: invitation.emailLower,
        ),
      );
    }
    await _firestore.updateDocument(_col, invitation.id, {
      'status': InvitationStatus.declined.value,
    });
    await _removeFromInviteIndex(invitation.emailLower, invitation.startupName);
  }

  Future<List<TeamMember>?> reconcileTeam(Startup startup) async {
    if (!startup.team.any((m) => m.invited && m.email.isNotEmpty)) return null;
    final sent = await sentFor(startup.id);
    final accepted = {
      for (final i in sent)
        if (i.status == InvitationStatus.accepted && i.acceptedBy != null)
          i.emailLower: i,
    };
    if (accepted.isEmpty) return null;
    var changed = false;
    final team = [
      for (final m in startup.team)
        if (m.invited && accepted.containsKey(m.email))
          () {
            changed = true;
            final who = accepted[m.email]!;
            // Their own account name replaces the one the founder typed.
            return m.copyWith(
              invited: false,
              uid: who.acceptedBy,
              name: who.acceptedByName.trim().isEmpty
                  ? null
                  : who.acceptedByName.trim(),
            );
          }()
        else
          m,
    ];
    return changed ? team : null;
  }

  Future<void> _addToInviteIndex(String email, String startupName) async {
    try {
      await _firestore.setDocument(FirestoreCollections.inviteEmails, email, {
        'names': _firestore.arrayUnion([startupName]),
        'updatedAt': _firestore.serverTimestamp(),
      }, merge: true);
    } catch (e) {
      debugPrint('Could not update the invite index: $e');
    }
  }

  Future<void> _removeFromInviteIndex(String email, String startupName) async {
    try {
      await _firestore.updateDocument(
        FirestoreCollections.inviteEmails,
        email,
        {
          'names': _firestore.arrayRemove([startupName]),
          'updatedAt': _firestore.serverTimestamp(),
        },
      );
    } catch (e) {
      debugPrint('Could not update the invite index: $e');
    }
  }
}
