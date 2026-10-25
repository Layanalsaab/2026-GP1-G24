import 'package:flutter/material.dart';

import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'arch_background.dart';
import 'auth_headers.dart';

/// One tab of a [HeaderTabBar]: [label] and an optional count [badge]
/// (Requests "1", Interest "2"; hidden when null or 0).
class HeaderTab {
  const HeaderTab(this.label, {this.badge});

  final String label;
  final int? badge;
}

/// Gold gradient tile avatar of the startup headers (`avatar-tile t-gold`):
/// 60 px, radius 17, initials 20/700 `#7A5A12`.
class HeaderAvatarTile extends StatelessWidget {
  const HeaderAvatarTile({
    super.key,
    required this.initials,
    this.size = 60,
    this.radius = 17,
    this.fontSize = 20,
  });

  final String initials;
  final double size;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment(-0.57, -0.82), // 145 degrees
          end: Alignment(0.57, 0.82),
          colors: [Color(0xFFFAF3E3), Color(0xFFF2E6C9)],
        ),
      ),
      child: Text(
        initials,
        style: AppText.sans(
          size: fontSize,
          weight: FontWeight.w700,
          color: AppColors.tagGoldText,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Tab bar at the bottom of a green header (docs/02 §8.14): equal tabs, top
/// hairline white 12 %, 14/600 text (`#A9C0AE`, selected white; 250 ms), count
/// badges, and a gold 2.5 px indicator that slides under the selected tab
/// (380 ms easeOut).
class HeaderTabBar extends StatelessWidget {
  const HeaderTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<HeaderTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final n = tabs.length;
    final x = n <= 1 ? 0.0 : -1 + 2 * selectedIndex / (n - 1);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.glassFill)),
      ),
      child: SizedBox(
        height: 41,
        child: Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: _HeaderTabItem(
                      tab: tabs[i],
                      selected: i == selectedIndex,
                      position: i + 1,
                      count: n,
                      onTap: () => onChanged(i),
                    ),
                  ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 2.5,
              child: AnimatedAlign(
                alignment: Alignment(x, 0),
                duration: Motion.dur(
                  context,
                  const Duration(milliseconds: 380),
                ),
                curve: Motion.easeOut,
                child: FractionallySizedBox(
                  widthFactor: 1 / (n == 0 ? 1 : n),
                  // An explicit height: a childless DecoratedBox under loose
                  // constraints collapses to 0 and the line disappears.
                  child: SizedBox(
                    height: 2.5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderTabItem extends StatelessWidget {
  const _HeaderTabItem({
    required this.tab,
    required this.selected,
    required this.position,
    required this.count,
    required this.onTap,
  });

  final HeaderTab tab;
  final bool selected;
  final int position;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = tab.badge;
    return Semantics(
      button: true,
      selected: selected,
      label: badge != null && badge > 0
          ? '${tab.label}, $badge, tab $position of $count'
          : '${tab.label}, tab $position of $count',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: AnimatedDefaultTextStyle(
                  duration: Motion.dur(
                    context,
                    const Duration(milliseconds: 250),
                  ),
                  style: AppText.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: selected ? AppColors.onDark : AppColors.onGreenTab,
                  ),
                  child: Text(
                    tab.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (badge != null && badge > 0) ...[
                const SizedBox(width: 5),
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: AppText.sans(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.green,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab bar that scrolls sideways (Manage startup: six tabs). Tabs keep their
/// natural width (padding 15 / 14 / 13), 15 px semibold, `#A9C0AE` and white
/// when selected, with a 3 px gold underline inset 12 px on each side. The
/// right edge fades out (from 82 %) to show there is more. Choosing a tab
/// scrolls it into view, centered.
class ScrollableHeaderTabBar extends StatefulWidget {
  const ScrollableHeaderTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.equalWidth = false,
  });

  final List<HeaderTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  /// Equal-width tabs that fill the bar: no scrolling and no fade (the startup
  /// page's four tabs). The look is the same as the scrolling bar.
  final bool equalWidth;

  @override
  State<ScrollableHeaderTabBar> createState() => _ScrollableHeaderTabBarState();
}

class _ScrollableHeaderTabBarState extends State<ScrollableHeaderTabBar> {
  late final List<GlobalKey> _keys = [for (final _ in widget.tabs) GlobalKey()];

  @override
  void didUpdateWidget(ScrollableHeaderTabBar old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex) _reveal();
  }

  /// Scrolls the selected tab to the middle of the bar.
  void _reveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[widget.selectedIndex].currentContext;
      if (ctx == null || !mounted) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: Motion.dur(context, const Duration(milliseconds: 300)),
        curve: Motion.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.equalWidth) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.glassFill)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < widget.tabs.length; i++)
              Expanded(
                child: _ScrollTab(
                  key: _keys[i],
                  tab: widget.tabs[i],
                  selected: i == widget.selectedIndex,
                  position: i + 1,
                  count: widget.tabs.length,
                  center: true,
                  onTap: () => widget.onChanged(i),
                ),
              ),
          ],
        ),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.glassFill)),
      ),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.82, 1],
        ).createShader(rect),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var i = 0; i < widget.tabs.length; i++)
                _ScrollTab(
                  key: _keys[i],
                  tab: widget.tabs[i],
                  selected: i == widget.selectedIndex,
                  position: i + 1,
                  count: widget.tabs.length,
                  onTap: () => widget.onChanged(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScrollTab extends StatelessWidget {
  const _ScrollTab({
    super.key,
    required this.tab,
    required this.selected,
    required this.position,
    required this.count,
    required this.onTap,
    this.center = false,
  });

  final HeaderTab tab;
  final bool selected;
  final int position;
  final int count;
  final VoidCallback onTap;

  /// Centre the label in its cell (equal-width tabs).
  final bool center;

  @override
  Widget build(BuildContext context) {
    final badge = tab.badge;
    final dur = Motion.dur(context, const Duration(milliseconds: 250));
    return Semantics(
      button: true,
      selected: selected,
      label: badge != null && badge > 0
          ? '${tab.label}, $badge, tab $position of $count'
          : '${tab.label}, tab $position of $count',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          alignment: center ? Alignment.center : AlignmentDirectional.topStart,
          children: [
            Padding(
              // Equal-width cells are narrower, so the label may shrink a bit.
              padding: EdgeInsets.fromLTRB(
                center ? 4 : 14,
                15,
                center ? 4 : 14,
                13,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (center)
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AnimatedDefaultTextStyle(
                          duration: dur,
                          style: AppText.sans(
                            size: 15,
                            weight: FontWeight.w600,
                            color: selected
                                ? AppColors.onDark
                                : AppColors.onGreenTab,
                          ),
                          child: Text(tab.label, maxLines: 1),
                        ),
                      ),
                    )
                  else
                    AnimatedDefaultTextStyle(
                      duration: dur,
                      style: AppText.sans(
                        size: 15,
                        weight: FontWeight.w600,
                        color: selected
                            ? AppColors.onDark
                            : AppColors.onGreenTab,
                      ),
                      child: Text(tab.label, maxLines: 1),
                    ),
                  if (badge != null && badge > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      constraints: const BoxConstraints(minWidth: 18),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$badge',
                        style: AppText.sans(
                          size: 11,
                          weight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 0,
              height: 3,
              child: AnimatedOpacity(
                duration: dur,
                opacity: selected ? 1 : 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tabbed header (Manage startup, Startup profile): green block with no
/// bottom radius and padding-bottom 0, arches (two paths, 22 %), top row
/// (back + [actions] or the logo), then an [avatar] + title block, optional
/// [infoLine] / [metaLeft] + [metaRight], and the [HeaderTabBar].
///
/// Startup profile: `actions: [HeaderBookmarkButton, GlassIconButton.share]`,
/// `pitch`, `infoLine: "HealthTech · Pre-seed · Riyadh"`, `metaLeft` (link
/// icon + website), `metaRight` ("Raising" + value in light gold).
/// Manage: `subline` (live dot + "Public · HealthTech · Pre-seed"), no meta.
class TabbedHeader extends StatelessWidget {
  const TabbedHeader({
    super.key,
    required this.title,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.onBack,
    this.actions,
    this.avatar,
    this.pitch,
    this.subline,
    this.infoLine,
    this.metaLeft,
    this.metaRight,
    this.closeIcon = false,
    this.scrollableTabs = false,
    this.equalTabs = false,
    this.eyebrow,
  });

  /// Four equal-width tabs with the Manage underline (the startup page).
  final bool equalTabs;

  /// Tabs keep their natural width and scroll sideways (Manage startup).
  final bool scrollableTabs;

  /// Small label above the title (Manage: "FOUNDER" in gold).
  final String? eyebrow;

  final String title;
  final List<HeaderTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback? onBack;

  /// Right side of the top row (glass buttons); null = the logo. Spaced 6 px.
  final List<Widget>? actions;

  /// Leading tile, normally a [HeaderAvatarTile].
  final Widget? avatar;

  /// One-liner under the title (14/20 `#E4EEE6`, profile).
  final String? pitch;

  /// Widget under the title (Manage: live dot + sub-line).
  final Widget? subline;

  /// Sub-line below the block (13 `#CFE0D3`, margin 12 16 0).
  final String? infoLine;
  final Widget? metaLeft;
  final Widget? metaRight;

  /// Show a close icon instead of the back chevron (startup preview).
  final bool closeIcon;

  @override
  Widget build(BuildContext context) {
    Widget? trailing;
    if (actions != null) {
      trailing = Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < actions!.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              actions![i],
            ],
          ],
        ),
      );
    }
    final metaStyle = AppText.onGreenMeta;
    return ArchHeaderShell(
      bottomRadius: 0,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderTopRow(onBack: onBack, trailing: trailing, close: closeIcon),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              crossAxisAlignment: pitch != null
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                if (avatar != null) ...[avatar!, const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null) ...[
                        Text(
                          eyebrow!.toUpperCase(),
                          style: AppText.sans(
                            size: 11.5,
                            weight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: const Color(0xFFC9A24A),
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      HeaderTitle(title, style: AppText.profileHeaderName),
                      SizedBox(height: pitch != null ? 4 : 6),
                      if (pitch != null)
                        Text(pitch!, style: AppText.headerPitch),
                      ?subline,
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (infoLine != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(infoLine!, style: metaStyle),
            ),
          if (metaLeft != null || metaRight != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: DefaultTextStyle.merge(
                style: metaStyle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: metaLeft ?? const SizedBox.shrink()),
                    const SizedBox(width: 8),
                    ?metaRight,
                  ],
                ),
              ),
            ),
          const SizedBox(height: 18),
          if (scrollableTabs || equalTabs)
            ScrollableHeaderTabBar(
              tabs: tabs,
              selectedIndex: selectedIndex,
              onChanged: onTabChanged,
              equalWidth: equalTabs,
            )
          else
            HeaderTabBar(
              tabs: tabs,
              selectedIndex: selectedIndex,
              onChanged: onTabChanged,
            ),
        ],
      ),
    );
  }
}

/// Wraps the content of a tabbed screen: when [index] changes the child slides
/// in 24 px from the side you moved toward (right when the new tab is to the
/// right) and fades in, 340 ms easeOut. Reduced motion: 200 ms fade.
class TabPaneSlide extends StatefulWidget {
  const TabPaneSlide({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<TabPaneSlide> createState() => _TabPaneSlideState();
}

class _TabPaneSlideState extends State<TabPaneSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 1,
  );
  double _dir = 0;

  @override
  void didUpdateWidget(TabPaneSlide old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _dir = widget.index > old.index ? 1 : -1;
      _c.duration = Motion.reduced(context)
          ? Motion.reducedFade
          : const Duration(milliseconds: 340);
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final curved = CurvedAnimation(
      parent: _c,
      curve: reduced ? Curves.linear : Motion.easeOut,
    );
    return AnimatedBuilder(
      animation: curved,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: reduced
            ? child
            : Transform.translate(
                offset: Offset(24 * _dir * (1 - curved.value), 0),
                child: child,
              ),
      ),
    );
  }
}
