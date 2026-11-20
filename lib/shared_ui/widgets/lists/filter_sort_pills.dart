import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

class FilterSortPills extends StatelessWidget {
  const FilterSortPills({
    super.key,
    required this.filterLabel,
    required this.sortLabel,
    required this.onFilter,
    required this.onSort,
    this.filterActive = false,
  });

  final String filterLabel;
  final String sortLabel;
  final VoidCallback onFilter;
  final VoidCallback onSort;

  /// Anything other than the default filter: the pill turns light gold.
  final bool filterActive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HeaderPill(
          icon: AppIcons.tune,
          label: filterLabel,
          active: filterActive,
          onTap: onFilter,
        ),
        const SizedBox(width: 8),
        HeaderPill(icon: AppIcons.sort, label: sortLabel, onTap: onSort),
      ],
    );
  }
}

/// One header pill: height 28, radius 999, white, no border, soft shadow, 12/600 text and 13 px icons.
class HeaderPill extends StatelessWidget {
  const HeaderPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fill = active ? AppColors.goldFillSoft : AppColors.surface;
    final text = active ? AppColors.greenText : AppColors.ink;
    final iconColor = active ? AppColors.greenText : AppColors.grey;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        scale: PressScale.chip,
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.dur(context, const Duration(milliseconds: 160)),
          curve: Curves.ease,
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x8C0F2314),
                offset: Offset(0, 8),
                blurRadius: 18,
                spreadRadius: -12,
              ),
              BoxShadow(
                color: Color(0x140F2314),
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.filled(icon, size: 13, color: iconColor),
              const SizedBox(width: 4),
              AnimatedDefaultTextStyle(
                duration: Motion.dur(
                  context,
                  const Duration(milliseconds: 160),
                ),
                style: AppText.sans(
                  size: 12,
                  weight: FontWeight.w600,
                  color: text,
                ),
                child: Text(label),
              ),
              const SizedBox(width: 3),
              AppIcon.filled(AppIcons.chevDown, size: 13, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}
