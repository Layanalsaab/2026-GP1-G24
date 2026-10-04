import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/startup_form_view_model.dart';
import 'form_fields.dart';
import 'startup_logo.dart';

/// Logo preview with Upload / Change / Remove. The placeholder letter follows
/// the name as it is typed.
class LogoField extends StatelessWidget {
  const LogoField({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StartupFormViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(StartupStrings.logoLabel, isRequired: false),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _Preview(vm: vm),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: vm.isBusy ? null : vm.pickLogo,
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      size: AppSizes.iconSm + 2,
                    ),
                    label: Text(
                      vm.hasLogo
                          ? StartupStrings.logoChange
                          : StartupStrings.logoUpload,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.moss600,
                      textStyle: AppText.link,
                      side: const BorderSide(color: AppColors.moss600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  if (vm.hasLogo)
                    TextButton.icon(
                      onPressed: vm.isBusy ? null : vm.clearLogo,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: AppSizes.iconSm + 2,
                      ),
                      label: const Text(StartupStrings.logoRemove),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.grey,
                        textStyle: AppText.link,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(StartupStrings.logoHint, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
        if (vm.logoError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          FormMessage.error(vm.logoError!),
        ],
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.vm});

  final StartupFormViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: vm.name,
          builder: (context, value, _) {
            final name = value.text.trim();
            return StartupLogo(
              initial: name.isEmpty
                  ? '?'
                  : String.fromCharCode(name.runes.first).toUpperCase(),
              size: AppSizes.formLogo,
              file: vm.newLogo,
              url: vm.existingLogoUrl,
            );
          },
        ),
        if (vm.isPickingLogo)
          Container(
            width: AppSizes.formLogo,
            height: AppSizes.formLogo,
            decoration: const BoxDecoration(
              color: AppColors.scrim,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.onDark),
            ),
          ),
      ],
    );
  }
}
