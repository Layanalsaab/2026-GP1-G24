import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/auth_failure.dart';
import '../../models/invitation.dart';
import '../../models/startup.dart';
import '../../models/team_member.dart';
import '../firebase_services/auth_service.dart';
import '../firebase_services/firestore_service.dart';
import '../firebase_services/invite_relay_service.dart';
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

/// Team invitations: creating them, sending the e-mail, and the invited
/// person's side (finding, accepting, declining).
///
/// Everything about who may do what is in `firestore.rules`; this class only
/// reads and writes the `invitations` collection (and `inviteEmails`, the
/// little index that lets sign-up warn an invited person).
class InvitationRepository {
  InvitationRepository({
    AuthService? auth,
    FirestoreService? firestore,
    InviteRelayService? relay,
  }) : _auth = auth ?? AuthService(),
       _firestore = firestore ?? FirestoreService(),
       _relay = relay ?? const InviteRelayService();

  /// The app-wide instance. Tests replace it with a fake.
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

  // ------------------------------------------------------------ the team

  /// Makes sure an invitation exists and is pending for [member] of
  /// [startup] (a new one, or a cancelled / declined one invited again), and
  /// keeps its role text and contribution up to date. Returns it.
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
    // A joined person stays; a declined one is not invited again behind the
    // founder's back (removing the card and adding it again does that).
    if (existing.status == InvitationStatus.accepted ||
        existing.status == InvitationStatus.declined) {
      return existing;
    }
    // Pending, cancelled or declined: pending again with the current words.
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
      lastSentAt: existing.lastSentAt,
    );
  }

  /// The team removed the person before they joined.
  Future<void> cancel(String startupId, String email) async {
    final id = Invitation.idOf(startupId, email);
    final existing = Invitation.fromMap(await _firestore.getDocument(_col, id));
    if (existing == null || existing.status == InvitationStatus.accepted) {
      return;
    }
    if (existing.status == InvitationStatus.declined) {
      // The founder removed a declined card: forget it, so inviting the same
      // e-mail again starts fresh.
      await _firestore.deleteDocument(_col, id);
      return;
    }
    await _firestore.updateDocument(_col, id, {
      'status': InvitationStatus.cancelled.value,
    });
    await _removeFromInviteIndex(existing.emailLower, existing.startupName);
  }

  /// Sends the e-mail of [invitation] through the relay and records it.
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
      await _firestore.updateDocument(_col, invitation.id, {
        'emailSent': true,
        'lastSentAt': _firestore.serverTimestamp(),
      });
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

  /// The invitations I sent for [startupId] (statuses: Invited / Declined).
  Future<List<Invitation>> sentFor(String startupId) async {
    final docs = await _firestore.queryWhereEqual(_col, 'invitedBy', _uid);
    return [
      for (final d in docs)
        if (d.data['startupId'] == startupId) ?Invitation.fromMap(d.data),
    ];
  }

  // ------------------------------------------------------ the invited side

  /// One invitation by its id (readable before the person has an account).
  Future<Invitation?> byId(String id) async =>
      Invitation.fromMap(await _firestore.getDocument(_col, id));

  /// The startup names that invited [email] (no account needed), for the
  /// sign-up warning.
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
    return [for (final d in docs) ?Invitation.fromMap(d.data)];
  }

  /// Joins the team: I am added to the startup (with the invitation's role)
  /// and the invitation turns "accepted", together. When the startup is
  /// readable (a public one) my card in the team list is updated too.
  Future<void> accept(Invitation invitation, {required String fullName}) async {
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
    } catch (_) {
      // A private startup can't be read yet: the team updates the card later.
    }
    await _firestore.commit([
      FirestoreWrite.update(
        FirestoreCollections.startups,
        invitation.startupId,
        {
          'memberIds': _firestore.arrayUnion([uid]),
          'memberRoles.$uid': invitation.role,
          'teamMembers': ?team,
          'updatedAt': _firestore.serverTimestamp(),
        },
      ),
      FirestoreWrite.update(_col, invitation.id, {
        'status': InvitationStatus.accepted.value,
        'acceptedBy': uid,
        'acceptedByName': fullName,
        'respondedAt': _firestore.serverTimestamp(),
      }),
    ]);
    await _removeFromInviteIndex(invitation.emailLower, invitation.startupName);
    // My profile now lists this startup.
    unawaited(PublicProfileRepository.instance.refreshMyStartups(uid));
  }

  /// "No thanks."
  Future<void> decline(Invitation invitation) async {
    await _firestore.updateDocument(_col, invitation.id, {
      'status': InvitationStatus.declined.value,
      'respondedAt': _firestore.serverTimestamp(),
    });
    await _removeFromInviteIndex(invitation.emailLower, invitation.startupName);
  }

  // ------------------------------------------------- the team, afterwards

  /// A person accepted while the startup was private (so only they could not
  /// update the team list): the team fixes the card now. Returns the new list
  /// (or null when nothing changed).
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

  // ------------------------------------------------------------- the index

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
