import 'package:flutter/material.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../shared_ui/theme/app_theme.dart';

/// Pill reading "Public" or "Private", with an icon so the state is never
/// shown by colour alone.
class VisibilityBadge extends StatelessWidget {
  const VisibilityBadge({super.key, required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final color = isPublic ? AppColors.moss600 : AppColors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: isPublic ? AppColors.moss100 : AppColors.mutedFill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
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
