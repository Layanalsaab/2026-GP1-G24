import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';

/// Tracks whether a mouse/trackpad pointer is over [builder]'s widget (never
/// true for touch) and hands that to [builder].
class _HoverBuilder extends StatefulWidget {
  const _HoverBuilder({required this.builder});

  final Widget Function(BuildContext context, bool hovering) builder;

  @override
  State<_HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<_HoverBuilder> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hover = true),
    onExit: (_) => setState(() => _hover = false),
    child: widget.builder(context, _hover),
  );
}

/// Form selection chip (docs/02 §8.6): 34 high, padding 0 16, radius 999,
/// 13/500, soft (moss50 fill, moss600 text) or [selected] (moss600 fill, white
/// text, a 16 px check that pops in, left padding 12, gap 6). Colors animate
/// 180 ms; press scale 0.96.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onDark : AppColors.moss600;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: _HoverBuilder(
        builder: (context, hovering) => Pressable(
          scale: PressScale.chip,
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.dur(context, Motion.color),
            curve: Curves.ease,
            height: 34,
            padding: EdgeInsets.only(left: selected ? 12 : 16, right: 16),
            decoration: BoxDecoration(
              color: selected ? AppColors.moss600 : AppColors.moss50,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected
                    ? AppColors.moss600
                    : (hovering && onTap != null
                          ? AppColors.borderStrong
                          : const Color(0x008C918D)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Pop(
                    key: const ValueKey('chip-check'),
                    child: AppIcon.filled(AppIcons.check, size: 16, color: fg),
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: Motion.dur(context, Motion.color),
                    style: AppText.chip.copyWith(color: fg),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Request / interest filter chip (`.fchip`): 34 high, padding 0 14, white
/// with a 1 px `#E4E1DA` border and 13/600 grey text; selected = green fill,
/// green border, white text. Named `AppFilterChip` to avoid Material's
/// `FilterChip`.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// e.g. "Pending · 1".
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: _HoverBuilder(
        builder: (context, hovering) => Pressable(
          scale: PressScale.chip,
          onTap: onTap,
          child: AnimatedContainer(
            duration: Motion.dur(context, Motion.color),
            curve: Curves.ease,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.green : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected
                    ? AppColors.green
                    : (hovering && onTap != null
                          ? AppColors.borderStrong
                          : AppColors.border),
              ),
            ),
            child: Center(
              widthFactor: 1,
              child: AnimatedDefaultTextStyle(
                duration: Motion.dur(context, Motion.color),
                style: AppText.sans(
                  size: 13,
                  weight: FontWeight.w600,
                  color: selected ? AppColors.onDark : AppColors.grey,
                ),
                child: Text(label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Removable result chip of the home results row (`.xchip`): 30 high, white,
/// 1 px `#CFD6D0` border, 12.5/600 green label and a 14 px x; enters with
/// `chipIn` (opacity + scale .94 -> 1, 220 ms).
class RemovableChip extends StatelessWidget {
  const RemovableChip({super.key, required this.label, required this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduced
          ? Motion.reducedFade
          : const Duration(milliseconds: 220),
      curve: Motion.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: reduced
            ? child
            : Transform.scale(scale: 0.94 + 0.06 * t, child: child),
      ),
      child: Semantics(
        button: true,
        label: 'Remove $label',
        excludeSemantics: true,
        child: Pressable(
          scale: 0.96,
          onTap: onRemove,
          child: Container(
            height: 30,
            padding: const EdgeInsets.only(left: 12, right: 7),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.chipBorderSoft),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppText.sans(
                    size: 12.5,
                    weight: FontWeight.w600,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 4),
                AppIcon.outline(
                  AppIcons.closeStroke,
                  size: 14,
                  stroke: 2.4,
                  color: AppColors.green,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Segmented control of N equal buttons (`.rng4`, activity range Today / 7D /
/// 30D / 12M): mutedFill track radius 12 padding 3; buttons 34 high radius 9
/// 13/600 grey; the selected one is white with green text and a soft shadow
/// (180 ms).
class RangeControl extends StatelessWidget {
  const RangeControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.mutedFill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selectedIndex,
                label: labels[i],
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: Motion.dur(context, Motion.color),
                    curve: Curves.ease,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selectedIndex
                          ? AppColors.surface
                          : const Color(0x00FFFFFF),
                      borderRadius: BorderRadius.circular(9),
                      boxShadow: i == selectedIndex
                          ? AppShadow.rangeThumb
                          : const [],
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: Motion.dur(context, Motion.color),
                      style: AppText.sans(
                        size: 13,
                        weight: FontWeight.w600,
                        color: i == selectedIndex
                            ? AppColors.green
                            : AppColors.grey,
                      ),
                      child: Text(labels[i]),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
