import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
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
    required this.hint,
    this.isRequired = true,
    this.errorText,
    this.enabled = true,
    this.other,
    this.customPicker,
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
    required this.hint,
    this.isRequired = true,
    this.errorText,
    this.enabled = true,
  }) : selected = values,
       multi = true,
       other = null,
       customPicker = null,
       _onPicked = onChanged;

  final String label;

  /// Shown while nothing is chosen, e.g. "Select a sector".
  final String hint;
  final List<T> options;
  final String Function(T) labelOf;
  final Set<T> selected;
  final bool multi;
  final bool isRequired;
  final String? errorText;
  final bool enabled;

  /// Optional "Other" choice (single choice only). Picking it shows a text
  /// box in the list, bound to [OtherChoice.controller], and Done closes it.
  final OtherChoice<T>? other;

  /// Opens a different chooser (e.g. the searchable city list) instead of the
  /// plain options sheet. Returns the chosen option, or null when dismissed.
  final Future<T?> Function(BuildContext context)? customPicker;
  final ValueChanged<Set<T>> _onPicked;

  Future<void> _open(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final custom = customPicker;
    if (custom != null) {
      final choice = await custom(context);
      if (choice != null) _onPicked({choice});
      return;
    }
    final picked = await showModalBottomSheet<Set<T>>(
      context: context,
      backgroundColor: AppColors.cream,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (_) => _OptionsSheet<T>(
        title: label,
        options: options,
        labelOf: labelOf,
        initial: selected,
        multi: multi,
        other: other,
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
        FieldLabel(label, optional: !isRequired),
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
                        text.isEmpty ? hint : text,
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

/// Describes an "Other" option that reveals a text box (Figma "Select
/// commerce model": the choice "Other", then a text input and Done).
class OtherChoice<T> {
  const OtherChoice({
    required this.option,
    required this.controller,
    required this.label,
    required this.hint,
    this.maxLength = 40,
    this.onChanged,
  });

  /// The option that means "Other".
  final T option;

  /// Holds the typed text (owned by the caller).
  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLength;
  final VoidCallback? onChanged;
}

/// Bottom sheet listing the options (Figma "Select ..." sheet). Single choice
/// closes on tap, except for an "Other" option, which shows a text box and a
/// Done button; multiple choice always has a Done button.
class _OptionsSheet<T> extends StatefulWidget {
  const _OptionsSheet({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.initial,
    required this.multi,
    this.other,
  });

  final String title;
  final List<T> options;
  final String Function(T) labelOf;
  final Set<T> initial;
  final bool multi;
  final OtherChoice<T>? other;

  @override
  State<_OptionsSheet<T>> createState() => _OptionsSheetState<T>();
}

class _OptionsSheetState<T> extends State<_OptionsSheet<T>> {
  late final Set<T> _picked = {...widget.initial};
  String? _otherError;

  bool get _otherChosen =>
      widget.other != null && _picked.contains(widget.other!.option);

  void _tap(T option) {
    final other = widget.other;
    if (!widget.multi) {
      if (other != null && option == other.option) {
        // Keep the list open: the text box appears under it.
        setState(() {
          _picked
            ..clear()
            ..add(option);
        });
        return;
      }
      Navigator.of(context).pop(<T>{option});
      return;
    }
    setState(() {
      if (!_picked.remove(option)) _picked.add(option);
    });
  }

  void _done() {
    final other = widget.other;
    if (other != null && _otherChosen && other.controller.text.trim().isEmpty) {
      setState(() => _otherError = StartupStrings.otherRequiredShort);
      return;
    }
    Navigator.of(context).pop(_picked);
  }

  @override
  Widget build(BuildContext context) {
    final other = widget.other;
    final showDone = widget.multi || _otherChosen;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: AppText.sectionTitle),
                ),
                IconButton(
                  tooltip: StartupStrings.close,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: AppSizes.icon,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
            if (other != null && _otherChosen) ...[
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                label: other.label,
                hint: other.hint,
                controller: other.controller,
                maxLength: other.maxLength,
                inputFormatters: otherTextFormatters,
                textInputAction: TextInputAction.done,
                errorText: _otherError,
                onChanged: (_) {
                  if (_otherError != null) setState(() => _otherError = null);
                  other.onChanged?.call();
                },
                onSubmitted: (_) => _done(),
              ),
            ],
            if (showDone) ...[
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(label: StartupStrings.done, onPressed: _done),
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
    final shape = BorderRadius.circular(AppRadius.md);
    if (!multi) {
      // Figma: plain text rows; the chosen one is moss-tinted with a check.
      return Padding(
        padding: EdgeInsets.zero,
        child: Material(
          color: selected ? AppColors.moss100 : Colors.transparent,
          borderRadius: shape,
          child: InkWell(
            borderRadius: shape,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppText.body.copyWith(
                        color: selected ? AppColors.moss600 : AppColors.ink,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_rounded,
                      size: AppSizes.icon,
                      color: AppColors.moss600,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final icon = selected
        ? Icons.check_box_rounded
        : Icons.check_box_outline_blank_rounded;
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
                  color: selected ? AppColors.moss600 : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lets only letters (any language), numbers and spaces be typed in an
/// "Other" box, so symbols such as "--" or an apostrophe can't be added.
final List<TextInputFormatter> otherTextFormatters = [
  FilteringTextInputFormatter.allow(
    RegExp(r'[\p{L}\p{M}\p{N} ]', unicode: true),
  ),
];
