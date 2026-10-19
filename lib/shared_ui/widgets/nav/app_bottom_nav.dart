import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';

/// The home bottom navigation (prototype `.gnav`, docs/05 §B10): a green bar
/// (padding 4 0 14, shadow) with three icon-only items in a 270 px wide
/// centered grid: 0 Support Channels (briefcase), 1 Hub (house), 2 Explore
/// (compass).
///
/// Selected item: icon lifts 3 px (350 ms), cross-fades outline -> filled
/// (filled: opacity 250 ms + scale 0.6 -> 1 over 350 ms; outline: opacity
/// 200 ms), colour white 62 % -> `#E3CF9B` (250 ms). A 5 px gold dot slides
/// under the selected item (420 ms easeOut). Bottom safe-area is added.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const _labels = ['Support Channels', 'Hub', 'Explore'];
  static const _icons = [
    AppIcons.navSupport,
    AppIcons.navHub,
    AppIcons.navExplore,
  ];

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.viewPaddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(0, 4, 0, 14 + safe),
      decoration: const BoxDecoration(
        color: AppColors.green,
        boxShadow: AppShadow.bottomNav,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 270),
          child: SizedBox(
            height: 46,
            child: LayoutBuilder(
              builder: (context, c) {
                final col = c.maxWidth / 3;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: Motion.dur(
                        context,
                        const Duration(milliseconds: 420),
                      ),
                      curve: Motion.easeOut,
                      left: currentIndex * col,
                      bottom: 2,
                      width: col,
                      height: 5,
                      child: const IgnorePointer(
                        child: Center(
                          child: SizedBox(
                            width: 5,
                            height: 5,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          Expanded(
                            child: _NavItem(
                              label: _labels[i],
                              outline: _icons[i].outline,
                              filled: _icons[i].filled,
                              selected: i == currentIndex,
                              onTap: () {
                                if (i != currentIndex) onSelect(i);
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.outline,
    required this.filled,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String outline;
  final String filled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lift = Motion.dur(context, const Duration(milliseconds: 350));
    final color = selected ? AppColors.goldLight : const Color(0x9EFFFFFF);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 10),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: color),
            duration: Motion.dur(context, const Duration(milliseconds: 250)),
            builder: (context, c, _) => AnimatedSlide(
              offset: Offset(0, selected ? -3 / 24 : 0),
              duration: lift,
              curve: Motion.easeOut,
              child: Center(
                heightFactor: 1,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    children: [
                      AnimatedOpacity(
                        opacity: selected ? 0 : 1,
                        duration: Motion.dur(
                          context,
                          const Duration(milliseconds: 200),
                        ),
                        child: AppIcon.outline(outline, size: 24, color: c),
                      ),
                      AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: Motion.dur(
                          context,
                          const Duration(milliseconds: 250),
                        ),
                        child: AnimatedScale(
                          scale: selected ? 1 : 0.6,
                          duration: lift,
                          curve: Motion.easeOut,
                          child: AppIcon.filled(filled, size: 24, color: c),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
