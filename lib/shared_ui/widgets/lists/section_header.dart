import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// A home section header (prototype `.shd2`): title 16/700 (ls -0.1) on the
/// left and, on the right, either a "See all" link (13/600 moss600, via
/// [onSeeAll]) or any [trailing] widget (e.g. the Trending range dropdown).
/// Has a 2 px side inset like the prototype.
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
                        color: AppColors.moss600,
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
