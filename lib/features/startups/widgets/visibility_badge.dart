import 'package:flutter/material.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../shared_ui/theme/app_theme.dart';

/// Pill reading "Public" (gold outline, globe) or "Private" (grey, lock), as
/// in Figma "V2 · 24". The icon means the state is never shown by colour alone.
class VisibilityBadge extends StatelessWidget {
  const VisibilityBadge({super.key, required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final color = isPublic ? AppColors.gold700 : AppColors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isPublic ? AppColors.gold100 : AppColors.mutedFill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: isPublic ? AppColors.gold : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
            size: AppSizes.iconSm - 2,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            isPublic ? StartupStrings.publicBadge : StartupStrings.privateBadge,
            style: AppText.badge.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
