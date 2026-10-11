import 'package:flutter/material.dart';

import '../../app_constants/navigation_strings.dart';
import '../theme/app_theme.dart';

/// The three main areas of the app, in the order shown on the bottom bar.
enum AppTab { supportSystems, hub, explore }

/// The bottom navigation bar (Figma "Nav · 3 tabs"): Support Systems, Hub and
/// Explore. The selected tab's icon and label turn green.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  static const _items = [
    (
      tab: AppTab.supportSystems,
      icon: Icons.work_outline_rounded,
      selectedIcon: Icons.work_rounded,
      label: NavigationStrings.supportSystems,
    ),
    (
      tab: AppTab.hub,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: NavigationStrings.hub,
    ),
    (
      tab: AppTab.explore,
      icon: Icons.search_rounded,
      selectedIcon: Icons.search_rounded,
      label: NavigationStrings.explore,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final item in _items)
                Expanded(
                  child: _BarItem(
                    icon: item.tab == current ? item.selectedIcon : item.icon,
                    label: item.label,
                    selected: item.tab == current,
                    onTap: () => onSelect(item.tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.moss600 : AppColors.grey;
    return Semantics(
      container: true,
      button: true,
      enabled: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(
                size: 11,
                color: color,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
                height: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
