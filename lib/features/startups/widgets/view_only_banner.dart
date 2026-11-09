import 'package:flutter/material.dart';

import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';

/// The notices of the founder tools ("Closed", "You no longer have a
/// startup"): a soft gold box ([AppColors.noticeFill], 1 px
/// [AppColors.noticeBorder], radius 16, padding 12 / 14), a white 36 px tile
/// with a gold icon, a title (15.5 bold) and the reason. Every notice uses
/// this one widget, so they all look the same. (Team members no longer get a "View only" notice: the
/// tabs simply have no editing for them.)
class ViewOnlyBanner extends StatelessWidget {
  /// A notice with its own words (and icon).
  const ViewOnlyBanner.notice({
    super.key,
    required this.title,
    required this.message,
    this.icon = AppIcons.info,
  });

  final String title;
  final String message;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $message',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.noticeFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.noticeBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: AppIcon.filled(
                  icon,
                  size: 18,
                  color: AppColors.noticeIcon,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.sans(
                      size: 15.5,
                      weight: FontWeight.w700,
                      color: AppColors.noticeTitle,
                    ),
                  ),
                  Text(
                    message,
                    style: AppText.sans(
                      size: 13.5,
                      height: 19,
                      color: AppColors.noticeText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
