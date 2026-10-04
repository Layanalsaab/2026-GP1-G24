import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/common_widgets/confirm_dialog.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/startup_form_view_model.dart';
import 'startup_form.dart';

/// What happened on the Add/Edit page, returned to My Startups when it closes.
enum StartupFormOutcome { created, saved, deleted }

typedef StartupFormResult = ({StartupFormOutcome outcome, Startup startup});

/// Page frame shared by Add and Edit: green top bar, the scrolling form, an
/// optional [footer] below it, and a pinned Save button.
///
/// Leaving with unsaved changes (back arrow or system back) asks
/// "Discard changes?". While saving or deleting, leaving is blocked.
class StartupFormPage extends StatelessWidget {
  const StartupFormPage({
    super.key,
    required this.title,
    required this.saveLabel,
    this.actions = const [],
    this.footer,
  });

  final String title;
  final String saveLabel;
  final List<Widget> actions;
  final Widget? footer;

  Future<void> _save(BuildContext context) async {
    // Retry can be tapped on a snackbar after this page has closed.
    if (!context.mounted) return;
    FocusScope.of(context).unfocus();
    final vm = context.read<StartupFormViewModel>();
    final saved = await vm.save();
    if (!context.mounted) return;
    if (saved != null) {
      final outcome = vm.isEditing
          ? StartupFormOutcome.saved
          : StartupFormOutcome.created;
      Navigator.of(context)
          .pop<StartupFormResult>((outcome: outcome, startup: saved));
      return;
    }
    // A network/permission failure (not a validation one): offer Retry.
    if (vm.errors.isEmpty && vm.actionError != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(vm.actionError!),
            action: SnackBarAction(
              label: StartupStrings.retry,
              onPressed: () => _save(context),
            ),
          ),
        );
    }
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final vm = context.read<StartupFormViewModel>();
    if (vm.isBusy) return;
    final discard = await showConfirmDialog(
      context,
      title: StartupStrings.discardTitle,
      message: StartupStrings.discardBody,
      confirmLabel: StartupStrings.discard,
      cancelLabel: StartupStrings.keepEditing,
      icon: Icons.edit_off_outlined,
      destructive: true,
    );
    if (discard && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StartupFormViewModel>();
    return PopScope(
      canPop: !vm.isDirty && !vm.isBusy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave(context);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              GreenTopBar(
                title: title,
                leading: TopBarBackButton(onPressed: vm.isBusy ? () {} : null),
                actions: actions,
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    children: [
                      const StartupForm(),
                      if (footer != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        footer!,
                      ],
                    ],
                  ),
                ),
              ),
              _SaveBar(label: saveLabel, onSave: () => _save(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.label, required this.onSave});

  final String label;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StartupFormViewModel>();
    final hint = !vm.requiredFilled
        ? StartupStrings.saveDisabledHint
        : (vm.isEditing && !vm.isDirty ? StartupStrings.noChangesHint : null);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: AppShadows.raised,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.lg,
        AppSpacing.page,
        AppSpacing.lg + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vm.actionError != null && !vm.isBusy) ...[
            FormMessage.error(vm.actionError!),
            const SizedBox(height: AppSpacing.md),
          ],
          PrimaryButton(
            label: label,
            icon: Icons.check_rounded,
            isLoading: vm.isSaving,
            onPressed: vm.canSave && !vm.isBusy ? onSave : null,
          ),
          if (hint != null && !vm.isSaving) ...[
            const SizedBox(height: AppSpacing.sm),
            Center(child: Text(hint, style: AppText.caption)),
          ],
        ],
      ),
    );
  }
}
