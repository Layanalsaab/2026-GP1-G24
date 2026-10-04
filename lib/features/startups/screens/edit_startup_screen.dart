import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/common_widgets/confirm_dialog.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/startup_form_view_model.dart';
import '../widgets/startup_form_page.dart';
import 'startup_profile_screen.dart';

/// Edit an existing startup: the Add form pre-filled, plus "Preview as
/// public" and Delete. Closes with a [StartupFormResult] after a save or
/// delete.
class EditStartupScreen extends StatelessWidget {
  const EditStartupScreen({super.key, required this.startup});

  final Startup startup;

  static Future<StartupFormResult?> open(
    BuildContext context,
    Startup startup,
  ) => Navigator.of(context).push<StartupFormResult>(
    MaterialPageRoute(builder: (_) => EditStartupScreen(startup: startup)),
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StartupFormViewModel(initial: startup),
      child: Builder(
        builder: (context) => StartupFormPage(
          title: StartupStrings.editTitle,
          saveLabel: StartupStrings.saveChanges,
          actions: [
            TopBarIconButton(
              icon: Icons.visibility_outlined,
              tooltip: StartupStrings.previewAsPublic,
              onPressed: () => _preview(context),
            ),
          ],
          footer: const _DeleteSection(),
        ),
      ),
    );
  }

  void _preview(BuildContext context) {
    final vm = context.read<StartupFormViewModel>();
    StartupProfileScreen.openPreview(
      context,
      vm.initial!,
      hasUnsavedChanges: vm.isDirty,
    );
  }
}

class _DeleteSection extends StatelessWidget {
  const _DeleteSection();

  Future<void> _delete(BuildContext context, {bool confirmed = false}) async {
    if (!context.mounted) return;
    final vm = context.read<StartupFormViewModel>();
    final startup = vm.initial!;
    if (!confirmed) {
      final ok = await showConfirmDialog(
        context,
        title: StartupStrings.deleteTitle(startup.name),
        message: StartupStrings.deleteBody(startup.name),
        confirmLabel: StartupStrings.deleteConfirm,
        cancelLabel: StartupStrings.cancel,
        icon: Icons.delete_outline_rounded,
        destructive: true,
      );
      if (!ok || !context.mounted) return;
    }
    final deleted = await vm.delete();
    if (!context.mounted) return;
    if (deleted) {
      Navigator.of(context).pop<StartupFormResult>((
        outcome: StartupFormOutcome.deleted,
        startup: startup,
      ));
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(vm.actionError ?? StartupStrings.deleteFailed),
          action: SnackBarAction(
            label: StartupStrings.retry,
            // Already confirmed once; don't ask again on retry.
            onPressed: () => _delete(context, confirmed: true),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StartupFormViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          StartupStrings.dangerZone,
          style: AppText.groupLabel.copyWith(color: AppColors.error),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(StartupStrings.deleteHint, style: AppText.caption),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: StartupStrings.deleteButton,
          icon: Icons.delete_outline_rounded,
          color: AppColors.error,
          isLoading: vm.isDeleting,
          onPressed: vm.isBusy ? null : () => _delete(context),
        ),
      ],
    );
  }
}
