import 'package:flutter/foundation.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/mock_data/prototype_seed.dart';
import '../../../data_access/repositories/invitation_repository.dart';
import '../../../data_access/repositories/request_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/connection_request.dart';
import '../../../models/invitation.dart';
import '../../../models/startup.dart';

/// State of Manage startup (docs/05 D3): the startup as last saved, the
/// current tab, the visibility switch, closing, and leaving (the owner names
/// the next owner first).
class ManageStartupViewModel extends ChangeNotifier with SafeNotifier {
  ManageStartupViewModel({required this.startup, StartupRepository? repository})
    : _repository = repository ?? StartupRepository.instance;

  final StartupRepository _repository;

  /// The startup as last saved.
  Startup startup;

  /// 0 Dashboard, 1 Interest (EOI), 2-7 the six steps of the add-startup form
  /// (Startup Overview ... Startup Ask, the same tabs as the startup page), 8
  /// Settings. (The requests of a round live inside the round.)
  int tab = 0;

  bool isSavingVisibility = false;
  String? error;

  void selectTab(int index) {
    if (index == tab) return;
    tab = index;
    notifyListeners();
  }

  /// The startup was edited elsewhere.
  void replace(Startup updated) {
    startup = updated;
    notifyListeners();
  }

  /// Flips Public / Private and saves it. Returns the new value, or null
  /// when saving failed (the switch goes back).
  Future<bool?> setPublic(bool value) async {
    if (isSavingVisibility || value == startup.isPublic) return null;
    final before = startup;
    startup = startup.copyWith(isPublic: value);
    isSavingVisibility = true;
    error = null;
    notifyListeners();
    try {
      // A closed startup: only its visibility changes (its owner only).
      startup = before.isClosed
          ? await _repository.setClosedVisibility(before, value)
          : await _repository.update(startup);
      return value;
    } catch (_) {
      startup = before;
      error = FounderToolsStrings.saveFailed;
      return null;
    } finally {
      isSavingVisibility = false;
      notifyListeners();
    }
  }

  /// A change (close, hand over, leave, invite) is being saved.
  bool isBusy = false;

  /// The people who joined the team (co-founders and members), who can
  /// become the next owner: (uid, name, role), in the order of the team list.
  List<(String, String, String)> get nextOwnerChoices {
    final ids = startup.memberIds.toSet();
    final ordered = <String>[
      for (final m in startup.team)
        if (m.uid != null && ids.contains(m.uid)) m.uid!,
    ];
    return [
      for (final uid in {...ordered, ...ids})
        (uid, startup.nameOf(uid, fallback: _roleLabel(uid)), _roleLabel(uid)),
    ];
  }

  String _roleLabel(String uid) => startup.memberRoles[uid] == 'coFounder'
      ? FounderToolsStrings.roleCoFounder
      : FounderToolsStrings.roleMember;

  /// The owner invitation still waiting for an answer (the "Waiting for…"
  /// card in Settings), or null.
  Invitation? pendingOwnerInvite;

  /// Reads [pendingOwnerInvite] (the owner, on an active startup).
  /// The e-mail of an owner invitation that was not answered in 30 days (it
  /// is cancelled when Settings opens). The tab says so once.
  String? expiredOwnerEmail;

  Future<void> loadOwnerInvite() async {
    if (startup.isClosed ||
        startup.founderId != AppSession.instance.user?.uid ||
        PrototypeSeed.isSampleStartup(startup.id)) {
      return;
    }
    try {
      final found = await InvitationRepository.instance.pendingOwnerInvite(
        startup.id,
      );
      if (found != null && found.isExpired(DateTime.now())) {
        // Nobody answered in 30 days: it ends, and she may invite again.
        await InvitationRepository.instance.cancelOwnerInvite(startup);
        expiredOwnerEmail = found.emailLower;
        pendingOwnerInvite = null;
      } else {
        pendingOwnerInvite = found;
      }
      notifyListeners();
    } catch (_) {
      // The card shows the next time.
    }
  }

  /// The owner leaves: the joined person [uid] becomes the owner. True on
  /// success.
  Future<bool> transferTo(String uid) =>
      _run(FounderToolsStrings.handoverFailed, () async {
        startup = await _repository.transferOwnership(startup, uid);
        _forget(startup.id);
      });

  /// The owner invites [email] to take over (she stays in control until it is
  /// accepted); the invitation e-mail is sent too. True on success.
  Future<bool> inviteOwner(String email, {required bool newUser}) =>
      _run(FounderToolsStrings.ownerInviteFailed, () async {
        final repo = InvitationRepository.instance;
        final invitation = await repo.inviteOwner(
          startup: startup,
          email: email,
          invitedByName: AppSession.instance.user?.fullName ?? '',
          newUser: newUser,
        );
        pendingOwnerInvite = invitation;
        expiredOwnerEmail = null;
        // The e-mail is best effort: the invitation also waits in the app.
        ownerEmailResult = await repo.sendEmail(invitation);
      });

  /// What happened to the e-mail of the last owner invitation or resend.
  InviteSendResult? ownerEmailResult;

  /// "Resend email": sends the waiting owner invitation again (the relay
  /// allows one e-mail per invitation per hour). Returns what happened.
  Future<InviteSendResult> resendOwnerInvite() async {
    final invite = pendingOwnerInvite;
    if (invite == null) return InviteSendResult.failed;
    final result = await InvitationRepository.instance.sendEmail(invite);
    ownerEmailResult = result;
    notifyListeners();
    return result;
  }

  /// Cancels [pendingOwnerInvite]. True on success.
  Future<bool> cancelOwnerInvite() =>
      _run(FounderToolsStrings.ownerInviteCancelFailed, () async {
        await InvitationRepository.instance.cancelOwnerInvite(startup);
        pendingOwnerInvite = null;
      });

  /// Closes the startup (its owner): permanent, kept for everyone. Waiting
  /// requests are declined too. True on success.
  Future<bool> close() => _run(FounderToolsStrings.closeFailed, () async {
    startup = await _repository.close(startup);
    pendingOwnerInvite = null;
    final requests = RequestRepository.instance;
    for (final r in requests.inboxFor(startup.id)) {
      if (r.status == RequestStatus.pending) {
        requests.setStatus(r.id, RequestStatus.declined);
      }
    }
  });

  /// Leaves the startup (a co-founder or team member of an active one).
  /// Sample startups (interface only) are left by the screen that listed
  /// them. True on success.
  Future<bool> leave() => _run(FounderToolsStrings.leaveFailed, () async {
    if (!PrototypeSeed.isSampleStartup(startup.id)) {
      await _repository.leave(startup);
    }
    _forget(startup.id);
  });

  Future<bool> _run(String failed, Future<void> Function() action) async {
    if (isBusy) return false;
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      // The real cause (e.g. PERMISSION_DENIED) for the debug console.
      debugPrint('$failed ($e)');
      error = failed;
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// The session stops listing [id] as one of my startups.
  void _forget(String id) {
    final session = AppSession.instance;
    session.setOwnStartupIds([
      for (final own in session.ownStartupIds)
        if (own != id) own,
    ]);
    session.setMemberStartupIds({
      for (final m in session.memberStartupIds)
        if (m != id) m,
    });
  }
}
