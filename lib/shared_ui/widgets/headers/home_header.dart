import 'dart:async';

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import 'arch_background.dart';
import 'header_buttons.dart';

/// An Explore sub-tab: [label] plus the outline icon (stroke 2) that shows
/// only while the tab is selected.
class ExploreTab {
  const ExploreTab(this.label, this.icon);

  final String label;

  /// Outline icon path from [AppIcons] (`tabForYou`, `tabTrending`,
  /// `tabMatches`).
  final String icon;

  static const forYou = ExploreTab('For You', AppIcons.tabForYou);
  static const trending = ExploreTab('Trending', AppIcons.tabTrending);
  static const matches = ExploreTab('Matches', AppIcons.tabMatches);

  /// For You · Trending · Matches.
  static const defaults = [forYou, trending, matches];
}

/// Home header (Hub / Explore / Support Channels): green, bottom radius 30,
/// padding 14 16 60 (50 with Explore tabs), arches at 13 % filling the header.
///
/// Row (height 54): left = avatar with notification dot (or the guest
/// "Sign up" pill when [guest]), center = [title] (21/700), right = 36 px logo.
/// Pass [tabs] for the Explore sub-tab row (height 40, sliding gold 28 x 3
/// indicator, icon only on the selected tab).
///
/// OVERLAP: the header reports a height [searchOverlap] (24) shorter than it
/// paints, so the search bar placed right below it in a column already
/// overlaps it by 24 with no negative margin. The search bar is 46 high
/// ([searchBarHeight]); the list below starts 18 px under it.
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

  /// How far the search bar overlaps the header (`.below3` margin-top -24).
  static const double searchOverlap = 24;

  /// Height of the search bar that sits on the overlap.
  static const double searchBarHeight = 46;

  final String title;

  /// Initials in the avatar (founder / investor).
  final String initials;

  /// Shows the "Sign up" gold pill instead of the avatar.
  final bool guest;

  /// Red dot on the avatar (pops in after 250 ms).
  final bool hasNotification;

  /// Semantic label of the avatar, e.g. "Open menu, 4 new notifications".
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
            child: Row(
              children: [
                Expanded(
                  child: Align(
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
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppText.homeTitle,
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: HeaderLogo(
                      size: AppSize.headerLogoHome,
                      rightMargin: 0,
                      animate: false,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (hasTabs)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: LayoutBuilder(
                // The prototype row is 4 px wider than the content on each side.
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

/// 8 px red dot with a 1.5 px green ring; scale .4 -> 1 and fade in over
/// 400 ms easeOut after a 250 ms delay.
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

/// The Explore sub-tab row (For You · Trending · Matches): height 40, equal
/// tabs, 15.5/600 (white 62 % / white, 200 ms). Only the selected tab shows
/// its 18 px light-gold icon (width 0 -> 20 + 6 margin, opacity 200 ms, scale
/// .6 -> 1 300 ms). A gold 28 x 3 indicator slides under the selected tab
/// (300 ms easeOut). Normally used through [HomeHeader.tabs].
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
                  child: Center(
                    child: Container(
                      width: 28,
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
