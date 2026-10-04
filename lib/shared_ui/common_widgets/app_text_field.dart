import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'form_message.dart';

/// Figma "Text field": label above, 48px field with a strong border.
/// When [errorText] is set the border turns red and an icon + message appear.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
  });

  final String label;
  final String hint;
  final TextEditingController? controller;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  /// Shows a value that can't be edited (e.g. the login email) in a grey,
  /// muted field. Different from [enabled]: false, which is used while loading.
  final bool readOnly;

  /// More than 1 makes a multi-line field (e.g. a bio).
  final int maxLines;

  /// When set, limits the length and shows a "0/150" counter under the field.
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.sans(
            size: 14,
            color: AppColors.ink,
            weight: FontWeight.w500,
            height: 20,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          cursorColor: AppColors.moss600,
          autocorrect: false,
          enableSuggestions: !obscureText,
          style: AppText.sans(
            size: 16,
            color: readOnly ? AppColors.grey : AppColors.ink,
            height: 24,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: readOnly ? AppColors.mutedFill : AppColors.surface,
            hintText: hint,
            hintStyle: AppText.sans(size: 16, color: AppColors.grey, height: 24),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            enabledBorder: border(
              hasError
                  ? AppColors.error
                  : readOnly
                      ? AppColors.border
                      : AppColors.borderStrong,
              hasError ? 1.5 : 1,
            ),
            disabledBorder: border(AppColors.border, 1),
            focusedBorder: readOnly
                ? border(AppColors.border, 1)
                : border(hasError ? AppColors.error : AppColors.moss600, 1.5),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          FormMessage.error(errorText!),
        ],
      ],
    );
  }
}
