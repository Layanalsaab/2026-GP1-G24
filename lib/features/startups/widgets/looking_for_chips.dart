import 'package:flutter/material.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../models/startup_enums.dart';
import '../../../models/startup.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/profile_form_fields.dart'
    show OtherChip;
import '../../../shared_ui/theme/app_theme.dart';
import 'form_fields.dart';
import 'select_field.dart' show otherTextFormatters;

/// "What are you looking for?": every option as a tappable chip, any number
/// can be selected (Figma "Add Startup"). Choosing "Other" turns that chip into
/// "Other: [text box]", the same as on the Create Account sectors.
class LookingForChips extends StatelessWidget {
  const LookingForChips({
    super.key,
    required this.values,
    required this.onChanged,
    this.enabled = true,
    this.errorText,
    this.otherController,
    this.otherErrorText,
    this.onOtherChanged,
  });

  /// Holds the text typed into the "Other:" chip.
  final TextEditingController? otherController;
  final String? otherErrorText;
  final VoidCallback? onOtherChanged;

  final Set<LookingFor> values;
  final ValueChanged<Set<LookingFor>> onChanged;
  final bool enabled;
  final String? errorText;

  void _toggle(LookingFor item) {
    final next = {...values};
    if (!next.remove(item)) next.add(item);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel(StartupStrings.lookingForLabel),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final item in LookingFor.values)
              if (item == LookingFor.other &&
                  otherController != null &&
                  values.contains(item))
                OtherChip(
                  controller: otherController!,
                  hint: StartupStrings.lookingForOtherHint,
                  maxLength: Startup.otherMaxLength,
                  inputFormatters: otherTextFormatters,
                  onChanged: (_) => onOtherChanged?.call(),
                  onClear: enabled
                      ? () {
                          otherController!.clear();
                          _toggle(item);
                        }
                      : null,
                )
              else
                _Chip(
                  label: item.label,
                  selected: values.contains(item),
                  onTap: enabled ? () => _toggle(item) : null,
                ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          FormMessage.error(errorText!),
        ],
        if (otherErrorText != null) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          FormMessage.error(otherErrorText!),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.moss100 : AppColors.surface,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.moss600 : AppColors.borderStrong,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.sm + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.check,
                    size: AppSizes.iconSm,
                    color: AppColors.moss600,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: AppText.label.copyWith(
                    color: selected ? AppColors.green : AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
