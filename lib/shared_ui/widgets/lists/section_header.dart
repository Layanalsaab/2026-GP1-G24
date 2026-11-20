import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
    this.seeAllLabel = 'See all',
    this.trailing,
  });

  final String title;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;

  /// Replaces the "See all" link when given.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final right =
        trailing ??
        (onSeeAll == null
            ? null
            : Semantics(
                button: true,
                label: '$seeAllLabel, $title',
                excludeSemantics: true,
                onTap: onSeeAll,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSeeAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      seeAllLabel,
                      style: AppText.sans(
                        size: 13,
                        color: AppColors.mossText,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppText.sectionTitle),
            ),
          ),
          ?right,
        ],
      ),
    );
  }
}
