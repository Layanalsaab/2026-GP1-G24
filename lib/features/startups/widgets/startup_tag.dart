import 'package:flutter/material.dart';

import '../../../shared_ui/theme/app_theme.dart';

/// A small label (Figma "Tag"): moss for sector and stage, gold for what the
/// startup is looking for. [pill] is the larger, fully rounded form used on
/// the profile page.
class StartupTag extends StatelessWidget {
  const StartupTag(
    this.label, {
    super.key,
    this.gold = false,
    this.pill = false,
  });

  final String label;
  final bool gold;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: pill
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 5)
          : const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: gold ? AppColors.tagGoldFill : AppColors.moss100,
        borderRadius: BorderRadius.circular(pill ? AppRadius.pill : 6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.sans(
          size: pill ? 13 : 12,
          color: gold ? AppColors.tagGoldText : AppColors.moss600,
          weight: FontWeight.w500,
        ),
      ),
    );
  }
}
