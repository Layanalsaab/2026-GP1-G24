import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/theme/app_theme.dart';

/// Label shown above every field: name, plus a gold * when required or an
/// "Optional" tag otherwise.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, required this.isRequired});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              text: text,
              children: [
                if (isRequired)
                  TextSpan(
                    text: StartupStrings.requiredMark,
                    style: AppText.label.copyWith(color: AppColors.gold700),
                  ),
              ],
            ),
            style: AppText.label,
          ),
        ),
        if (!isRequired) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(StartupStrings.optional, style: AppText.caption),
        ],
      ],
    );
  }
}

/// Label above, input, then (below) either the inline error or helper text,
/// and an optional live character counter.
class StartupTextField extends StatelessWidget {
  const StartupTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.isRequired,
    this.errorText,
    this.helperText,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.prefixText,
    this.enabled = true,
    this.showCounter = false,
    this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isRequired;
  final String? errorText;
  final String? helperText;

  /// Hard limit on input length. Also the counter's maximum.
  final int? maxLength;
  final int maxLines;
  final int? minLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final String? prefixText;
  final bool enabled;
  final bool showCounter;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: color, width: width),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, isRequired: isRequired),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          inputFormatters: [
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
            ...?inputFormatters,
          ],
          cursorColor: AppColors.moss600,
          style: AppText.input,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: enabled ? AppColors.surface : AppColors.mutedFill,
            hintText: hint,
            hintStyle: AppText.input.copyWith(color: AppColors.grey),
            prefixText: prefixText,
            prefixStyle: AppText.input.copyWith(color: AppColors.grey),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2,
              vertical: AppSpacing.md - 1,
            ),
            enabledBorder: border(
              hasError ? AppColors.error : AppColors.borderStrong,
              hasError ? 1.5 : 1,
            ),
            disabledBorder: border(AppColors.border, 1),
            focusedBorder: border(
              hasError ? AppColors.error : AppColors.moss600,
              1.5,
            ),
          ),
        ),
        if (hasError || helperText != null || showCounter) ...[
          const SizedBox(height: AppSpacing.xs + 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: hasError
                    ? FormMessage.error(errorText!)
                    : Text(helperText ?? '', style: AppText.caption),
              ),
              if (showCounter && maxLength != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _Counter(controller: controller, max: maxLength!),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Live "n / max" counter. Listens to the controller directly so only this
/// text rebuilds on each keystroke.
class _Counter extends StatelessWidget {
  const _Counter({required this.controller, required this.max});

  final TextEditingController controller;
  final int max;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final count = value.text.trim().length;
        return Text(
          StartupStrings.charCount(count, max),
          style: AppText.caption.copyWith(
            color: count >= max ? AppColors.gold700 : AppColors.grey,
          ),
        );
      },
    );
  }
}

/// Small grey heading between groups of fields (BASICS, DETAILS, ...).
class FieldGroupHeading extends StatelessWidget {
  const FieldGroupHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.sm),
    child: Text(text, style: AppText.groupLabel),
  );
}
