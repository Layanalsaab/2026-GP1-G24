import 'package:flutter/material.dart';

import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import '../lists/press_surface.dart';
import 'avatars.dart';

/// The Trending list container (prototype `.tbox`): one white box, radius 20,
/// home-card shadow, rows separated by `#F0EDE6`. Enters with cardIn (300 ms).
/// Put [TrendingRow]s in [children].
class TrendingBox extends StatelessWidget {
  const TrendingBox({super.key, required this.children, this.animate = true});

  final List<Widget> children;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        boxShadow: AppShadow.homeCard,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const ColoredBox(
                color: AppColors.rowSeparator,
                child: SizedBox(height: 1),
              ),
            children[i],
          ],
        ],
      ),
    );
    if (!animate) return box;
    return Rise(
      duration: const Duration(milliseconds: 300),
      offset: 8,
      child: box,
    );
  }
}

/// One Trending row (prototype `.tr`): padding 18, gap 14. Kicker
/// "N · Trending in X" (13.5 grey; rank 1 is gold 600), name 18/700, and a
/// [HueAvatar] 50 on the right. Press tints the row `#F6F4EF`.
class TrendingRow extends StatelessWidget {
  const TrendingRow({
    super.key,
    required this.rank,
    required this.category,
    required this.name,
    this.kind = HueAvatarKind.startup,
    this.onTap,
  });

  /// 1-based rank; 1 gets the gold kicker.
  final int rank;

  /// Sector shown after "Trending in".
  final String category;
  final String name;
  final HueAvatarKind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final top = rank == 1;
    return PressSurface(
      onTap: onTap,
      semanticLabel: '$rank, trending in $category, $name',
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$rank · Trending in $category',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.sans(
                      size: 13.5,
                      color: top ? AppColors.gold700 : AppColors.metaText,
                      weight: top ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.trendingName,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            HueAvatar(name: name, kind: kind, size: 50),
          ],
        ),
      ),
    );
  }
}

/// The caption under the Trending box (prototype `.tnote`): 12 `#8C918D`,
/// centered, e.g. "Ranked by profile views in the last 7 days".
class TrendingNote extends StatelessWidget {
  const TrendingNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.sans(size: 12, color: AppColors.hint),
      ),
    );
  }
}
