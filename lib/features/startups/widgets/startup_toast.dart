import 'package:flutter/material.dart';

import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';

/// The dark green confirmation toast with a gold check (Figma "V2 · 44b",
/// "Rafeeq Health was added"). Shown as a floating snackbar.
void showStartupToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.green,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        content: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: Center(child: svgIcon('st_check.svg', size: 14)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(
                  size: 14,
                  color: AppColors.onDark,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
