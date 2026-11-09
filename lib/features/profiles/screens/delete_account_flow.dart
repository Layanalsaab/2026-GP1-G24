import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';
import '../../../models/startup.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/widgets/overlays/app_bottom_sheet.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import 'delete_account_dialog.dart';

/// Delete account (Settings, or the forced "Add your startup" of a founder
/// with no startup): the confirmation, which for a founder lists what happens
/// to each of their startups, then the deletion (asking for the password
/// when Firebase wants a fresh sign-in), then Welcome.
Future<void> startAccountDeletion(BuildContext context) async {
  final role = AppSession.instance.user?.role ?? AccountRole.founder;
  final message = role == AccountRole.founder
      ? await founderDeletionMessage()
      : AccountStrings.deleteWarningInvestor;
  if (!context.mounted) return;
  final sure = await showConfirmSheet(
    context,
    title: ProfileStrings.deleteTitle,
    message: '$message\n\n${AccountStrings.cannotBeUndone}',
    confirmLabel: ProfileStrings.deleteConfirm,
    cancelLabel: ProfileStrings.cancel,
  );
  if (!sure || !context.mounted) return;

  var deleted = false;
  try {
    await AuthRepository.instance.deleteAccount();
    deleted = true;
  } on AuthException catch (e) {
    if (!context.mounted) return;
    if (e.failure == AuthFailure.requiresRecentLogin) {
      // Firebase wants a fresh sign-in: ask for the password this once.
      deleted = await showDeleteAccountDialog(context, role: role) == true;
    } else {
      AppToast.error(
        context,
        e.failure == AuthFailure.network
            ? AppStrings.networkError
            : AppStrings.genericError,
      );
      return;
    }
  } catch (_) {
    if (context.mounted) AppToast.error(context, AppStrings.genericError);
    return;
  }
  if (!deleted || !context.mounted) return;
  // The account is gone and signed out: back to Welcome with no way back.
  AppSession.instance.signOut();
  AppRouter.openStart(context);
}

/// The founder's warning: one line per startup saying what will happen to it
/// (the same rules as [StartupRepository.closeAllMine]). Just the general
/// warning when the startups can't be read.
Future<String> founderDeletionMessage() async {
  final lines = <String>[AccountStrings.deleteWarningFounderBase];
  try {
    final repo = StartupRepository.instance;
    for (final s in await repo.fetchMyStartups()) {
      lines.add(_lineFor(s));
    }
    for (final s in await repo.fetchMemberStartups()) {
      lines.add(AccountStrings.deleteLeaves(s.name));
    }
  } catch (_) {
    return AccountStrings.deleteWarningFounder;
  }
  return lines.join('\n');
}

String _lineFor(Startup s) {
  if (s.memberRoles.isEmpty) return AccountStrings.deleteDeletes(s.name);
  return s.isClosed
      ? AccountStrings.deleteStaysClosed(s.name)
      : AccountStrings.deleteCloses(s.name);
}
