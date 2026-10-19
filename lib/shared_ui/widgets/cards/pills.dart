import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// Colour family of an [AppPill].
enum AppPillTone { moss, gold, grey }

/// The prototype's `.pill`: height 28, padding 0 12, radius 999, 13/500.
/// Moss (moss100 / green), gold (tagGoldFill / tagGoldText) or grey
/// (mutedFill / grey). [icon] is an optional filled [AppIcons] path shown
/// before the label (gap 6). [height] 26 with [fontSize] 12 gives the My
/// Startups card chips.
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.tone = AppPillTone.moss,
    this.icon,
    this.height = 28,
    this.fontSize = 13,
    this.weight = FontWeight.w500,
  });

  final String label;
  final AppPillTone tone;
  final String? icon;
  final double height;
  final double fontSize;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final (fill, color) = switch (tone) {
      AppPillTone.moss => (AppColors.moss100, AppColors.green),
      AppPillTone.gold => (AppColors.tagGoldFill, AppColors.tagGoldText),
      AppPillTone.grey => (AppColors.mutedFill, AppColors.grey),
    };
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon.filled(icon!, size: 14, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            maxLines: 1,
            style: AppText.sans(size: fontSize, color: color, weight: weight),
          ),
        ],
      ),
    );
  }
}

/// The card tag chip (`.c2tag`): 12/600 moss600 on `#EEF4EF`, padding 4 9.
/// Shows a startup's sector, an investor's first sector or a program's type.
class TagChip extends StatelessWidget {
  const TagChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mossChip,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, maxLines: 1, style: AppText.tag),
    );
  }
}

/// The "live" status dot (`.live`): 7 px green dot with a soft 3 px ring when
/// [on] (public startup), grey when off (private).
class LiveDot extends StatelessWidget {
  const LiveDot({super.key, this.on = true});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: on ? AppColors.liveDot : AppColors.liveOff,
        boxShadow: [
          BoxShadow(
            color: on ? AppColors.liveRing : AppColors.liveOffRing,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}
