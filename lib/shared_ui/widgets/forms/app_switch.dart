import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';

/// The 50 x 30 switch: track `#D6D3CC` (on: moss600, 200 ms), 24 px white knob
/// that slides 20 px (220 ms easeOut).
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: AnimatedContainer(
          duration: Motion.dur(context, const Duration(milliseconds: 200)),
          curve: Curves.ease,
          width: 50,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? AppColors.moss600 : AppColors.switchOff,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: AnimatedAlign(
            duration: Motion.dur(context, const Duration(milliseconds: 220)),
            curve: Motion.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x4D000000),
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Card with a 36 px icon box, title (15/600), description (13/18 grey) and an
/// [AppSwitch]: the Visibility card of Add startup step 4 and the Settings
/// switch rows. [icon] is a filled path from [AppIcons] (globe when public,
/// lock when private). Toggles never get a `*`.
class ToggleCard extends StatelessWidget {
  const ToggleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadow.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.moss100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: AppIcon.filled(icon, size: 20, color: AppColors.moss600),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.sans(size: 15, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppText.sans(
                    size: 13,
                    color: AppColors.grey,
                    height: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppSwitch(value: value, onChanged: onChanged, semanticLabel: title),
        ],
      ),
    );
  }
}
