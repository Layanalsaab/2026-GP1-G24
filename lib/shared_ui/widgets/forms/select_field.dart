import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

class SelectField extends StatelessWidget {
  const SelectField({
    super.key,
    required this.placeholder,
    required this.onTap,
    this.value,
    this.hasError = false,
    this.semanticLabel,
  });

  final String placeholder;
  final String? value;
  final VoidCallback? onTap;
  final bool hasError;
  final String? semanticLabel;

  /// "Other: text", or "Other — describe it" when the write-in is blank.
  static String otherText(String other) =>
      other.trim().isEmpty ? 'Other — describe it' : 'Other: ${other.trim()}';

  @override
  Widget build(BuildContext context) {
    final has = value != null && value!.isNotEmpty;
    return Semantics(
      button: true,
      label: semanticLabel,
      value: has ? value : placeholder,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.dur(context, const Duration(milliseconds: 160)),
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? AppColors.error : AppColors.borderStrong,
            ),
            boxShadow: [
              BoxShadow(
                color: hasError ? AppColors.errorRing : const Color(0x00000000),
                spreadRadius: 3,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  has ? value! : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 16,
                    height: 24,
                    color: has ? AppColors.ink : AppColors.grey,
                  ),
                ),
              ),
              AppIcon.filled(AppIcons.chevDown, size: 22, color: AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
