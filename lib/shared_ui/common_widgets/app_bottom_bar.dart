import 'package:flutter/material.dart';

import '../../app_constants/navigation_strings.dart';
import '../theme/app_theme.dart';

/// The five main areas of the app, in the order shown on the bottom bar.
enum AppTab { hub, programs, explore, services, account }

/// The bottom navigation bar (Figma "Nav · Founder" / "Nav · Investor").
///
/// Every tab looks the same whether it works yet or not; only the tabs in
/// [enabledTabs] respond to taps. Screen readers still announce the others as
/// unavailable, so nobody is left tapping a tab that does nothing.
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.current,
    required this.enabledTabs,
    required this.onSelect,
    this.tabs,
  });

  /// Which tabs to show, in order. Defaults to all five; the seeker's bar
  /// (Figma "Nav · Seeker") shows only Hub, Explore and Programs.
  final List<AppTab>? tabs;

  /// The tab whose screen is showing (green pill behind its icon).
  final AppTab current;

  /// The tabs that have been built and can be opened.
  final Set<AppTab> enabledTabs;

  final ValueChanged<AppTab> onSelect;

  static const _items = [
    (tab: AppTab.hub, icon: Icons.search, label: NavigationStrings.hub),
    (
      tab: AppTab.programs,
      icon: Icons.work_outline,
      label: NavigationStrings.programs,
    ),
    (
      tab: AppTab.explore,
      icon: Icons.grid_view_outlined,
      label: NavigationStrings.explore,
    ),
    (
      tab: AppTab.services,
      icon: Icons.category_outlined,
      label: NavigationStrings.services,
    ),
    (
      tab: AppTab.account,
      icon: Icons.person_outline,
      label: NavigationStrings.account,
    ),
  ];

  List<({AppTab tab, IconData icon, String label})> get _visibleItems {
    final wanted = tabs;
    if (wanted == null) return _items;
    return [
      for (final tab in wanted) _items.firstWhere((item) => item.tab == tab),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 9, 4, 12),
          child: Row(
            children: [
              for (final item in _visibleItems)
                Expanded(
                  child: _BarItem(
                    icon: item.icon,
                    label: item.label,
                    selected: item.tab == current,
                    onTap: enabledTabs.contains(item.tab)
                        ? () => onSelect(item.tab)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tab: a 56 × 32 pill around the icon (filled when selected) and the
/// label underneath. [onTap] is null for tabs that aren't built yet.
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
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.grey;
    final content = SizedBox(
      height: 50,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.moss100 : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(
              size: 12,
              height: 16,
              color: color,
              weight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      container: true,
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: label,
      // Screen readers activate the tab through this, since the label and
      // gesture underneath are hidden from them.
      onTap: onTap,
      excludeSemantics: true,
      child: onTap == null
          ? content
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: content,
            ),
    );
  }
}
