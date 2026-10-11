import 'package:flutter/material.dart';

import '../../../app_constants/startup_strings.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';

/// Pill reading "Public" (moss, globe) or "Private" (grey, lock), as in
/// Figma "V2 · 44b / 44c". The icon means the state is never shown by colour
/// alone.
class VisibilityBadge extends StatelessWidget {
  const VisibilityBadge({super.key, required this.isPublic});

  final bool isPublic;

  @override
  Widget build(BuildContext context) {
    final color = isPublic ? AppColors.moss600 : AppColors.grey;
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 10, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: isPublic ? AppColors.moss100 : AppColors.neutralPillFill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          svgIcon(isPublic ? 'st_globe.svg' : 'st_lock.svg', size: 13),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              isPublic
                  ? StartupStrings.publicBadge
                  : StartupStrings.privateBadge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(
                size: 12,
                color: color,
                weight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
