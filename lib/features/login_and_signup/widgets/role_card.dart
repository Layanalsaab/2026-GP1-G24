import 'package:flutter/material.dart';

import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_metrics.dart';
import '../../../shared_ui/theme/app_text.dart';

/// One role card of Choose role (docs/05 A6): a 48 px icon box, title,
/// description and a radio. Selected = 2 px moss border + moss50 fill, the
/// icon box turns moss with a white icon and the radio dot pops.
class RoleCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final d = Motion.dur(context, const Duration(milliseconds: 220));
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '$title. $description',
      excludeSemantics: true,
      child: Pressable(
        scale: 0.97,
        onTap: onTap,
        child: AnimatedContainer(
          duration: d,
          curve: Motion.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          decoration: BoxDecoration(
            color: selected ? AppColors.moss50 : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.moss600 : const Color(0x00000000),
              width: selected ? 2 : 1.5,
            ),
            boxShadow: AppShadow.listCard,
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
