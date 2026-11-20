import 'dart:async';

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import 'arch_background.dart';
import 'header_buttons.dart';

class ExploreTab {
  const ExploreTab(this.label, this.icon);

  final String label;

  /// Outline icon path from AppIcons (tabLatest, tabTrending, tabForYou).
  final String icon;

  static const latest = ExploreTab('Latest', AppIcons.tabLatest);
  static const trending = ExploreTab('Trending', AppIcons.tabTrending);
  static const forYou = ExploreTab('For You', AppIcons.tabForYou);

  /// Latest · Trending · For You, for investors and founders alike.
  static const defaults = [latest, trending, forYou];

  /// The tabs of a founder or an investor (the same).
  static List<ExploreTab> forRole({required bool founder}) => defaults;
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.title,
    this.initials = '',
    this.guest = false,
    this.hasNotification = false,
    this.menuLabel,
    this.onAvatarTap,
    this.onSignUp,
    this.tabs,
    this.selectedTab = 0,
    this.onTabChanged,
  });

  /// How far the search bar overlaps the header (.below3 margin-top -24).
  static const double searchOverlap = 24;

  final String title;

  /// Initials in the avatar (founder / investor).
  final String initials;

  /// Shows the "Sign up" gold pill instead of the avatar.
  final bool guest;

  /// Red dot on the avatar (pops in after 250 ms).
  final bool hasNotification;

  /// Semantic label of the avatar, e.g.
  final String? menuLabel;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onSignUp;

  /// Explore sub-tabs (null = no tab row).
  final List<ExploreTab>? tabs;
  final int selectedTab;
  final ValueChanged<int>? onTabChanged;

  @override
  Widget build(BuildContext context) {
    final hasTabs = tabs != null && tabs!.isNotEmpty;
    return ArchHeaderShell(
      overlap: searchOverlap,
      bottomRadius: AppRadius.headerHome,
      arches: const ArchBackground.home(),
      padding: EdgeInsets.fromLTRB(16, 14, 16, hasTabs ? 50 : 60),
      child: Column(
        children: [
          SizedBox(
            height: 54,
            child: LayoutBuilder(
              builder: (context, box) {
                final side = guest ? 100.0 : 52.0;
                final titleMax = (box.maxWidth - 2 * side).clamp(80.0, 240.0);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: guest
                          ? GoldPillButton.signUp(onTap: onSignUp)
                          : _HomeAvatar(
                              initials: initials,
                              showDot: hasNotification,
                              label: menuLabel ?? 'Open menu',
                              onTap: onAvatarTap,
                            ),
                    ),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: HeaderLogo(
                        size: AppSize.headerLogoHome,
                        rightMargin: 0,
                        animate: false,
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: titleMax),
                      child: Semantics(
                        header: true,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            title,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: AppText.homeTitle,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (hasTabs)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: LayoutBuilder(
                builder: (context, c) => SizedBox(
                  height: 40,
                  child: OverflowBox(
                    minWidth: c.maxWidth + 8,
                    maxWidth: c.maxWidth + 8,
                    child: ExploreTabs(
                      tabs: tabs!,
                      selectedIndex: selectedTab,
                      onChanged: onTabChanged ?? (_) {},
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

class _HomeAvatar extends StatelessWidget {
  const _HomeAvatar({
    required this.initials,
    required this.showDot,
    required this.label,
    required this.onTap,
  });

  final String initials;
  final bool showDot;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        scale: 0.94,
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.moss600,
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: Text(
                  initials,
                  style: AppText.sans(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppColors.onDark,
                  ),
                ),
              ),
              if (showDot)
                const Positioned(top: 0, right: 0, child: _NotificationDot()),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDot extends StatefulWidget {
  const _NotificationDot();

  @override
  State<_NotificationDot> createState() => _NotificationDotState();
}

class _NotificationDotState extends State<_NotificationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  Timer? _t;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
      _t = Timer(const Duration(milliseconds: 250), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Motion.easeOut);
    return AnimatedBuilder(
      animation: a,
      builder: (context, child) => Opacity(
        opacity: a.value,
        child: Transform.scale(scale: 0.4 + 0.6 * a.value, child: child),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.notifDot,
          boxShadow: [BoxShadow(color: AppColors.green, spreadRadius: 1.5)],
        ),
      ),
    );
  }
}

class ExploreTabs extends StatelessWidget {
  const ExploreTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<ExploreTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final n = tabs.length;
    final x = n <= 1 ? 0.0 : -1 + 2 * selectedIndex / (n - 1);
    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 2,
            height: 3,
            child: IgnorePointer(
              child: AnimatedAlign(
                alignment: Alignment(x, 0),
                duration: Motion.dur(
                  context,
                  Motion.medium + const Duration(milliseconds: 40),
                ),
                curve: Motion.easeOut,
                child: FractionallySizedBox(
                  widthFactor: 1 / (n == 0 ? 1 : n),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: _ExploreTabItem(
                    tab: tabs[i],
                    selected: i == selectedIndex,
                    onTap: () => onChanged(i),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreTabItem extends StatelessWidget {
  const _ExploreTabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final ExploreTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slow = Motion.dur(context, const Duration(milliseconds: 300));
    final quick = Motion.dur(context, const Duration(milliseconds: 200));
    return Semantics(
      button: true,
      selected: selected,
      label: tab.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: slow,
                curve: Motion.easeOut,
                width: selected ? 26 : 0,
                height: 18,
                clipBehavior: Clip.hardEdge,
                decoration: const BoxDecoration(),
                alignment: Alignment.centerLeft,
                child: OverflowBox(
                  alignment: Alignment.centerLeft,
                  minWidth: 0,
                  maxWidth: 26,
                  child: AnimatedOpacity(
                    duration: quick,
                    opacity: selected ? 1 : 0,
                    child: AnimatedScale(
                      duration: slow,
                      curve: Motion.easeOut,
                      scale: selected ? 1 : 0.6,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AppIcon.outline(
                          tab.icon,
                          size: 18,
                          stroke: 2,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: quick,
                  style: AppText.sans(
                    size: 15.5,
                    weight: FontWeight.w600,
                    color: selected
                        ? AppColors.onDark
                        : const Color(0x9EFFFFFF),
                  ),
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
