import 'package:flutter/material.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import 'form_fields.dart';

/// A field that looks like a text input (Figma "V2 · 25 · Create Startup")
/// but opens a list to choose from. Use [SelectField.single] or
/// [SelectField.multi].
class SelectField<T> extends StatelessWidget {
  /// Choose exactly one option.
  SelectField.single({
    super.key,
    required this.label,
    required this.options,
    required this.labelOf,
    required T? value,
    required ValueChanged<T> onChanged,
    this.isRequired = true,
    this.errorText,
    this.enabled = true,
  }) : selected = {?value},
       multi = false,
       _onPicked = ((picked) => onChanged(picked.first));

  /// Choose any number of options.
  const SelectField.multi({
    super.key,
    required this.label,
    required this.options,
    required this.labelOf,
    required Set<T> values,
    required ValueChanged<Set<T>> onChanged,
    this.isRequired = true,
    this.errorText,
    this.enabled = true,
  }) : selected = values,
       multi = true,
       _onPicked = onChanged;

  final String label;
  final List<T> options;
  final String Function(T) labelOf;
  final Set<T> selected;
  final bool multi;
  final bool isRequired;
  final String? errorText;
  final bool enabled;
  final ValueChanged<Set<T>> _onPicked;

  Future<void> _open(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<Set<T>>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _OptionsSheet<T>(
        title: label,
        options: options,
        labelOf: labelOf,
        initial: selected,
        multi: multi,
      ),
    );
    // Null means the sheet was dismissed without choosing.
    if (picked == null) return;
    if (!multi && picked.isEmpty) return;
    _onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    // Listed in option order, so the text doesn't depend on tap order.
    final text = [
      for (final option in options)
        if (selected.contains(option)) labelOf(option),
    ].join(', ');
    final shape = BorderRadius.circular(AppRadius.sm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, isRequired: isRequired),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          label: label,
          value: text,
          child: Material(
            color: enabled ? AppColors.surface : AppColors.mutedFill,
            borderRadius: shape,
            child: InkWell(
              borderRadius: shape,
              onTap: enabled ? () => _open(context) : null,
              child: Ink(
                height: AppSizes.fieldHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md + 2,
                ),
                decoration: BoxDecoration(
                  borderRadius: shape,
                  border: Border.all(
                    color: hasError ? AppColors.error : AppColors.borderStrong,
                    width: hasError ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        text.isEmpty ? StartupStrings.choose(label) : text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.input.copyWith(
                          color: text.isEmpty ? AppColors.grey : AppColors.ink,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.grey,
                      size: AppSizes.icon,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          FormMessage.error(errorText!),
        ],
      ],
    );
  }
}

/// Bottom sheet listing the options. Single choice closes on tap; multiple
/// choice has a Done button.
class _OptionsSheet<T> extends StatefulWidget {
  const _OptionsSheet({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.initial,
    required this.multi,
  });

  final String title;
  final List<T> options;
  final String Function(T) labelOf;
  final Set<T> initial;
  final bool multi;

  @override
  State<_OptionsSheet<T>> createState() => _OptionsSheetState<T>();
}

class _OptionsSheetState<T> extends State<_OptionsSheet<T>> {
  late final Set<T> _picked = {...widget.initial};

  void _tap(T option) {
    if (!widget.multi) {
      Navigator.of(context).pop(<T>{option});
      return;
    }
    setState(() {
      if (!_picked.remove(option)) _picked.add(option);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.xl,
          AppSpacing.page,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, style: AppText.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final option in widget.options)
                    _OptionRow(
                      label: widget.labelOf(option),
                      selected: _picked.contains(option),
                      multi: widget.multi,
                      onTap: () => _tap(option),
                    ),
                ],
              ),
            ),
            if (widget.multi) ...[
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: StartupStrings.done,
                onPressed: () => Navigator.of(context).pop(_picked),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.multi,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch ((multi, selected)) {
      (true, true) => Icons.check_box_rounded,
      (true, false) => Icons.check_box_outline_blank_rounded,
      (false, true) => Icons.radio_button_checked_rounded,
      (false, false) => Icons.radio_button_unchecked_rounded,
    };
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppSizes.icon,
              color: selected ? AppColors.moss600 : AppColors.grey,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppText.body.copyWith(
                  color: selected ? AppColors.green : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
