import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// The Private / Public pill at the right end of the Email and Phone label
/// rows. One tap switches directly between the two (no sheet, menu or toast).
///
/// Height 26, radius 999, 12 px semibold, 14 px icon + text, no chevron.
/// Private (default): lock, white fill, `#E4E1DA` border, `#5B625D` text.
/// Public: globe, `#EEF4EF` fill, `#CFE0D3` border, `#2F5D3A` text. Colors
/// animate over 160 ms; press scale 0.96.
///
/// The pill is 26 px high; pass it as `AppField.labelTrailing`, which lets it
/// hang over the 20 px label line so the label row never gets taller.
class VisibilityPill extends StatelessWidget {
  const VisibilityPill({
    super.key,
    required this.isPublic,
    required this.onChanged,
    required this.fieldName,
  });

  final bool isPublic;
  final ValueChanged<bool> onChanged;

  /// "email" or "phone", for the screen-reader label.
  final String fieldName;

  @override
  Widget build(BuildContext context) {
    final fill = isPublic ? const Color(0xFFEEF4EF) : AppColors.surface;
    final border = isPublic ? const Color(0xFFCFE0D3) : const Color(0xFFE4E1DA);
    final color = isPublic ? AppColors.moss600 : AppColors.grey;
    return Semantics(
      button: true,
      label: isPublic
          ? 'Your $fieldName is public. Tap to make it private.'
          : 'Your $fieldName is private. Tap to make it public.',
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.chip,
        borderRadius: BorderRadius.circular(999),
        onTap: () => onChanged(!isPublic),
        child: AnimatedContainer(
          duration: Motion.dur(context, const Duration(milliseconds: 160)),
          curve: Curves.ease,
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.filled(
                isPublic ? AppIcons.globe : AppIcons.lock,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: Motion.dur(
                  context,
                  const Duration(milliseconds: 160),
                ),
                style: AppText.sans(
                  size: 12,
                  weight: FontWeight.w600,
                  color: color,
                ),
                child: Text(isPublic ? 'Public' : 'Private'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
