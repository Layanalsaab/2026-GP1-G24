import 'package:flutter/foundation.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/mock_data/prototype_seed.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../data_access/repositories/invitation_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/auth_failure.dart';
import '../../../models/invitation.dart';
import '../../../models/startup.dart';

class ManageStartupViewModel extends ChangeNotifier with SafeNotifier {
  ManageStartupViewModel({required this.startup, StartupRepository? repository})
    : _repository = repository ?? StartupRepository.instance;

  final StartupRepository _repository;

  /// The startup as last saved.
  Startup startup;

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

  /// Flips Public / Private and saves it.
  Future<bool?> setPublic(bool value) async {
    if (isSavingVisibility || value == startup.isPublic) return null;
    final before = startup;
    startup = startup.copyWith(isPublic: value);
    isSavingVisibility = true;
    error = null;
    notifyListeners();
    try {
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

  Invitation? pendingOwnerInvite;

  /// Reads pendingOwnerInvite (the owner, on an active startup).
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

  Future<bool> transferTo(String uid, {String? stay}) => _run(
    FounderToolsStrings.handoverFailed,
    () async {
      startup = await _repository.transferOwnership(startup, uid, stay: stay);
      if (stay == null) {
        _forget(startup.id);
      } else {
        // Still on the team: no longer one of mine, one I joined.
        final session = AppSession.instance;
        session.setOwnStartupIds([
          for (final own in session.ownStartupIds)
            if (own != startup.id) own,
        ]);
        session.setMemberStartupIds({...session.memberStartupIds, startup.id});
      }
    },
  );

  Future<bool> inviteOwner(
    String email, {
    required bool newUser,
    String? stay,
  }) => _run(FounderToolsStrings.ownerInviteFailed, () async {
    final repo = InvitationRepository.instance;
    final invitation = await repo.inviteOwner(
      startup: startup,
      email: email,
      invitedByName: AppSession.instance.user?.fullName ?? '',
      newUser: newUser,
      stay: stay,
    );
    pendingOwnerInvite = invitation;
    expiredOwnerEmail = null;
    ownerEmailResult = await repo.sendEmail(invitation);
  });

  /// What happened to the e-mail of the last owner invitation or resend.
  InviteSendResult? ownerEmailResult;

  Future<InviteSendResult> resendOwnerInvite() async {
    final invite = pendingOwnerInvite;
    if (invite == null) return InviteSendResult.failed;
    final result = await InvitationRepository.instance.sendEmail(invite);
    ownerEmailResult = result;
    notifyListeners();
    return result;
  }

  /// Cancels pendingOwnerInvite.
  Future<bool> cancelOwnerInvite() =>
      _run(FounderToolsStrings.ownerInviteCancelFailed, () async {
        await InvitationRepository.instance.cancelOwnerInvite(startup);
        pendingOwnerInvite = null;
      });

  /// Closes the startup (its owner): permanent, kept for everyone.
  Future<bool> close() => _run(FounderToolsStrings.closeFailed, () async {
    startup = await _repository.close(startup);
    pendingOwnerInvite = null;
  });

  Future<String?> deleteStartup(String password) async {
    if (isBusy) return AppStrings.genericError;
    isBusy = true;
    error = null;
    notifyListeners();
    try {
      try {
        await AuthRepository.instance.verifyPassword(password);
      } on AuthException catch (e) {
        return switch (e.failure) {
          AuthFailure.invalidCredentials => AccountStrings.passwordIncorrect,
          AuthFailure.network => AppStrings.networkError,
          AuthFailure.tooManyRequests => AppStrings.tooManyRequests,
          _ => AppStrings.genericError,
        };
      }
      try {
        await _repository.delete(startup);
      } catch (e) {
        debugPrint('${FounderToolsStrings.deleteFailed} ($e)');
        return FounderToolsStrings.deleteFailed;
      }
      _forget(startup.id);
      return null;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// Leaves the startup (a co-founder or team member of an active one).
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
      debugPrint('$failed ($e)');
      error = failed;
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  /// The session stops listing id as one of my startups.
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
