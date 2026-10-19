import 'package:flutter/material.dart';

import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_metrics.dart';
import '../../../shared_ui/theme/app_text.dart';

/// One role card of Choose role (docs/05 A6): a 48 px icon box, title,
/// description and a radio. Selected = 2 px moss border + moss50 fill, the
/// icon box turns moss with a white icon and the radio dot pops.
class RoleCard extends StatefulWidget {
  const RoleCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  /// A filled [AppIcons] path (sprout, trend).
  final String icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<RoleCard> {
  bool _hover = false;

  /// Hover shadow: 0 2 4 #1F3F2712, 0 12 28 -6 #1F3F2729 (spec 3.2).
  static const _hoverShadow = <BoxShadow>[
    BoxShadow(color: Color(0x121F3F27), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(
      color: Color(0x291F3F27),
      offset: Offset(0, 12),
      blurRadius: 28,
      spreadRadius: -6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final icon = widget.icon;
    final title = widget.title;
    final description = widget.description;
    final selected = widget.selected;
    final reduced = Motion.reduced(context);
    final d = Motion.dur(context, const Duration(milliseconds: 220));
    final hovering = _hover && !reduced;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '$title. $description',
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Pressable(
          scale: PressScale.button,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: d,
            curve: Motion.easeOut,
            transform: Matrix4.translationValues(0, hovering ? -2 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.moss600
                    : (_hover
                          ? const Color(0xFFD9D4C9)
                          : const Color(0x00D9D4C9)),
                width: selected ? 2 : 1.5,
              ),
              boxShadow: hovering ? _hoverShadow : AppShadow.listCard,
            ),
            child: Container(
              // The fill switches instantly; only border/shadow animate.
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
              decoration: BoxDecoration(
                color: selected ? AppColors.moss50 : AppColors.surface,
                borderRadius: BorderRadius.circular(selected ? 18 : 18.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.moss600 : AppColors.mutedFill,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: AppIcon.filled(
                      icon,
                      size: 24,
                      color: selected ? AppColors.onDark : AppColors.grey,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppText.sans(
                            size: 17,
                            weight: FontWeight.w600,
                            height: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppText.sans(
                            size: 13,
                            color: AppColors.grey,
                            height: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  _Radio(selected: selected, duration: d),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.duration});

  final bool selected;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: duration,
            curve: Motion.easeOut,
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.moss600 : AppColors.borderStrong,
                width: 1.5,
              ),
            ),
          ),
          if (selected)
            Pop(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.moss600,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
