import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../models/app_user.dart';
import '../../../models/startup.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/widgets/overlays/app_bottom_sheet.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../widgets/startup_fates_sheet.dart';
import 'delete_account_dialog.dart';

Future<void> startAccountDeletion(BuildContext context) async {
  final role = AppSession.instance.user?.role ?? AccountRole.founder;
  var fates = const <String, StartupFate>{};
  if (role == AccountRole.founder) {
    final List<Startup> owned;
    var joined = const <Startup>[];
    try {
      final repo = StartupRepository.instance;
      owned = await repo.fetchMyStartups();
      try {
        joined = await repo.fetchMemberStartups();
      } catch (_) {}
    } catch (_) {
      // Without the startups the choices can't be asked.
      if (context.mounted) AppToast.error(context, AppStrings.genericError);
      return;
    }
    if (!context.mounted) return;
    if (owned.isNotEmpty) {
      final chosen = await showStartupFatesSheet(
        context,
        owned: owned,
        joinedCount: joined.length,
      );
      if (chosen == null) return;
      fates = chosen;
    } else {
      final sure = await showConfirmSheet(
        context,
        title: ProfileStrings.deleteTitle,
        message:
            '${joined.isEmpty ? AccountStrings.deleteWarningNoStartup : AccountStrings.deleteWarningMember} ${AccountStrings.cannotBeUndone}',
        confirmLabel: ProfileStrings.deleteConfirm,
        cancelLabel: ProfileStrings.cancel,
      );
      if (!sure) return;
    }
  } else {
    final sure = await showConfirmSheet(
      context,
      title: ProfileStrings.deleteTitle,
      message:
          '${AccountStrings.deleteWarningInvestor} ${AccountStrings.cannotBeUndone}',
      confirmLabel: ProfileStrings.deleteConfirm,
      cancelLabel: ProfileStrings.cancel,
    );
    if (!sure) return;
  }
  if (!context.mounted) return;
  final deleted = await showDeleteAccountPassword(context, fates: fates);
  if (!deleted || !context.mounted) return;
  AppSession.instance.signOut();
  AppRouter.openStart(context);
}
