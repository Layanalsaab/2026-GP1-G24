import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/common_widgets/confirm_dialog.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/plain_top_bar.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/startup_form_view_model.dart';
import 'startup_form.dart';

/// What happened on the Add/Edit page, returned to My Startups when it closes.
enum StartupFormOutcome { created, saved, deleted }

typedef StartupFormResult = ({StartupFormOutcome outcome, Startup startup});

/// Page frame shared by Add and Edit (Figma "V2 · 44a" / "V2 · 44d"): a cream
/// top bar with the centred title, then the scrolling form.
///
/// * Add: a close (X) button, and a pinned "Create startup" button below.
/// * Edit: a back arrow and a green "Save" button in the top bar.
///
/// Leaving with unsaved changes (back arrow or system back) asks
/// "Discard changes?". While saving, leaving is blocked.
class StartupFormPage extends StatelessWidget {
  const StartupFormPage({
    super.key,
    required this.title,
    required this.saveLabel,
  });

  final String title;
  final String saveLabel;

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
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              PlainTopBar(
                title: title,
                showDivider: true,
                leading: vm.isEditing
                    ? PlainTopBarIcon.back(context)
                    : PlainTopBarIcon(
                        asset: 'st_close.svg',
                        tooltip: StartupStrings.close,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                trailing: [
                  if (vm.isEditing)
                    _SavePill(label: saveLabel, onSave: () => _save(context)),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.lg,
                    AppSpacing.page,
                    AppSpacing.xxl,
                  ),
                  child: Column(
                    children: [
                      // Edit has no bottom bar, so a failed save says why here.
                      if (vm.isEditing &&
                          vm.actionError != null &&
                          !vm.isBusy) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FormMessage.error(vm.actionError!),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      const StartupForm(),
                    ],
                  ),
                ),
              ),
              if (!vm.isEditing)
                _SaveBar(label: saveLabel, onSave: () => _save(context)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Figma "Save" button of the Edit top bar: a small green pill.
class _SavePill extends StatelessWidget {
  const _SavePill({required this.label, required this.onSave});

  final String label;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StartupFormViewModel>();
    final enabled = vm.canSave && !vm.isBusy;
    return Padding(
      // The top bar already pads 8; Figma keeps 16 from the screen edge.
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: enabled ? AppColors.moss600 : AppColors.mutedFill,
          borderRadius: BorderRadius.circular(16.5),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.5),
            onTap: enabled ? onSave : null,
            child: SizedBox(
              height: 33,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Center(
                  child: vm.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          label,
                          style: AppText.sans(
                            size: 14,
                            color: enabled ? Colors.white : AppColors.grey,
                            weight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
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
    return Container(
      // Figma: the button sits on the page background, with a hairline above.
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.border)),
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
            isLoading: vm.isSaving,
            onPressed: vm.canSave && !vm.isBusy ? onSave : null,
          ),
        ],
      ),
    );
  }
}
