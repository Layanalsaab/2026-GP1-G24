import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../shared_ui/common_widgets/confirm_dialog.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/startup_form_view_model.dart';

/// "Make this startup public" switch with helper text that follows its
/// state. On Edit, turning a public startup private asks for confirmation.
class VisibilityCard extends StatelessWidget {
  const VisibilityCard({super.key});

  Future<void> _onChanged(
    BuildContext context,
    StartupFormViewModel vm,
    bool value,
  ) async {
    if (vm.needsPrivateConfirmation(value)) {
      final confirmed = await showConfirmDialog(
        context,
        title: StartupStrings.makePrivateTitle,
        message: StartupStrings.makePrivateBody,
        confirmLabel: StartupStrings.makePrivateConfirm,
        cancelLabel: StartupStrings.cancel,
        icon: Icons.visibility_off_outlined,
      );
      if (!confirmed) return;
    }
    vm.setPublic(value);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StartupFormViewModel>();
    final isPublic = vm.isPublic;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isPublic ? AppColors.moss50 : AppColors.mutedFill,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isPublic ? AppColors.moss400 : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
            color: isPublic ? AppColors.moss600 : AppColors.grey,
            size: AppSizes.icon,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(StartupStrings.visibilitySwitch, style: AppText.label),
                const SizedBox(height: AppSpacing.xs),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    isPublic
                        ? StartupStrings.visibilityOn
                        : StartupStrings.visibilityOff,
                    key: ValueKey(isPublic),
                    style: AppText.bodyMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            label: StartupStrings.visibilitySwitch,
            child: Switch(
              value: isPublic,
              onChanged: vm.isBusy
                  ? null
                  : (value) => _onChanged(context, vm, value),
              activeThumbColor: AppColors.onDark,
              activeTrackColor: AppColors.moss600,
              inactiveThumbColor: AppColors.surface,
              inactiveTrackColor: AppColors.borderStrong,
              trackOutlineColor: const WidgetStatePropertyAll(
                Colors.transparent,
              ),
              thumbIcon: WidgetStateProperty.resolveWith(
                (states) => Icon(
                  states.contains(WidgetState.selected)
                      ? Icons.check_rounded
                      : Icons.close_rounded,
                  size: AppSizes.iconSm,
                  color: states.contains(WidgetState.selected)
                      ? AppColors.moss600
                      : AppColors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
