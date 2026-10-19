import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../icons/app_icons.dart';
import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';
import '../../theme/app_text.dart';
import '../lists/press_surface.dart';
import '../overlays/app_overlay_route.dart';

/// One row of the side drawer: a stroke [icon] path (e.g.
/// [AppIcons.menuRocket]), a [label] and an optional gold count [badge]
/// (hidden when null or 0).
class AppDrawerItem {
  const AppDrawerItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String icon;
  final int? badge;

  /// Runs after the drawer has been closed.
  final VoidCallback onTap;
}

/// Opens the side drawer over the current screen (dim fades 300 ms, panel
/// slides in from the left 340 ms with [Motion.drawer]). It is a route, so
/// Android back and a tap on the dim close it. Item taps, "View profile" and
/// "Log out" close the drawer first and then call their callback.
Future<void> openAppDrawer(
  BuildContext context, {
  required String name,
  required String initials,
  required String roleLine,
  required List<AppDrawerItem> items,
  required VoidCallback onViewProfile,
  required VoidCallback onLogOut,
  String logOutLabel = 'Log out',
}) {
  return showAppOverlay<void>(
    context,
    builder: (_) => Align(
      alignment: Alignment.centerLeft,
      child: AppSideDrawer(
        name: name,
        initials: initials,
        roleLine: roleLine,
        items: items,
        onViewProfile: onViewProfile,
        onLogOut: onLogOut,
        logOutLabel: logOutLabel,
      ),
    ),
    dim: const Color(0x800C160F),
    dimDuration: const Duration(milliseconds: 300),
    duration: Motion.slow,
    entry: AppOverlayEntry.slideLeft,
    label: 'Close menu',
  );
}

/// The drawer panel (prototype `.dpanel`): 84 % wide (max 330), `#F6F4EF`,
/// right corners 22, green header (padding 48 20 18, faint gold ring top-right,
/// avatar 56 with gold border, name 18/700, [roleLine] such as
/// "Founder · Riyadh", "View profile" outline pill), rows (min 48, 15.5/500,
/// 22 px stroke icon) that slide in with a 90 ms + 30 ms x index stagger,
/// and a divider + red Log out at the bottom. Use [openAppDrawer].
class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({
    super.key,
    required this.name,
    required this.initials,
    required this.roleLine,
    required this.items,
    required this.onViewProfile,
    required this.onLogOut,
    this.logOutLabel = 'Log out',
  });

  final String name;
  final String initials;
  final String roleLine;
  final List<AppDrawerItem> items;
  final VoidCallback onViewProfile;
  final VoidCallback onLogOut;
  final String logOutLabel;

  void _then(BuildContext context, VoidCallback cb) {
    Navigator.of(context).pop();
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final w = math.min(330.0, MediaQuery.sizeOf(context).width * 0.84);
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    return Semantics(
      label: 'Menu',
      scopesRoute: true,
      explicitChildNodes: true,
      child: Container(
        width: w,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.profileBg,
          borderRadius: BorderRadius.horizontal(right: Radius.circular(22)),
          boxShadow: AppShadow.drawer,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              name: name,
              initials: initials,
              roleLine: roleLine,
              onViewProfile: () => _then(context, onViewProfile),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                children: [
                  for (var i = 0; i < items.length; i++)
                    _EntranceX(
                      index: i,
                      child: _DrawerRow(
                        item: items[i],
                        onTap: () => _then(context, items[i].onTap),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(10, 0, 10, 14 + bottom),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: PressSurface(
                onTap: () => _then(context, onLogOut),
                pressedColor: AppColors.rangeFill,
                semanticLabel: logOutLabel,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 50),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const AppIcon.outline(
                          AppIcons.menuLogout,
                          size: 22,
                          color: AppColors.logOut,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          logOutLabel,
                          style: AppText.sans(
                            size: 15.5,
                            color: AppColors.logOut,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ],
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

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.initials,
    required this.roleLine,
    required this.onViewProfile,
  });

  final String name;
  final String initials;
  final String roleLine;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.green,
      child: Stack(
        children: [
          const Positioned(
            right: -40,
            top: -30,
            width: 170,
            height: 170,
            child: ExcludeSemantics(
              child: CustomPaint(painter: _RingPainter()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(bottom: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0x1FFFFFFF),
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: Text(
                    initials,
                    style: AppText.sans(
                      size: 19,
                      color: AppColors.white,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    size: 18,
                    color: AppColors.white,
                    weight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleLine,
                  style: AppText.sans(size: 13, color: AppColors.onGreenMuted),
                ),
                const SizedBox(height: 12),
                Pressable(
                  onTap: onViewProfile,
                  scale: 0.96,
                  child: Semantics(
                    button: true,
                    label: 'View profile',
                    excludeSemantics: true,
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x59FFFFFF)),
                      ),
                      child: Text(
                        'View profile',
                        style: AppText.sans(
                          size: 13,
                          color: AppColors.white,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Faint gold ring: 1.2 px border at 35 % plus a 22 px 6 % halo.
class _RingPainter extends CustomPainter {
  const _RingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final halo = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: c, radius: r + 22)),
      Path()..addOval(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawPath(halo, Paint()..color = const Color(0x0FC9A24A));
    canvas.drawCircle(
      c,
      r - 0.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x59C9A24A),
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => false;
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({required this.item, required this.onTap});

  final AppDrawerItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final badge = item.badge ?? 0;
    return PressSurface(
      onTap: onTap,
      pressedColor: AppColors.rangeFill,
      borderRadius: BorderRadius.circular(12),
      semanticLabel: badge > 0 ? '${item.label}, $badge' : item.label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              AppIcon.outline(item.icon, size: 22, color: AppColors.moss600),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(size: 15.5, weight: FontWeight.w500),
                ),
              ),
              if (badge > 0)
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '$badge',
                    style: AppText.sans(
                      size: 12,
                      color: AppColors.green,
                      weight: FontWeight.w700,
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

/// Row entrance (`diIn`): fade + slide from x -10, 320 ms easeOut, delayed by
/// 90 ms + 30 ms x [index]. Off under reduced motion.
class _EntranceX extends StatefulWidget {
  const _EntranceX({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_EntranceX> createState() => _EntranceXState();
}

class _EntranceXState extends State<_EntranceX>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
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
      return;
    }
    _t = Timer(
      Motion.stagger(context, widget.index, stepMs: 30, leadMs: 90),
      () {
        if (mounted) _c.forward();
      },
    );
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
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: a.value,
        child: Transform.translate(
          offset: Offset(-10 * (1 - a.value), 0),
          child: child,
        ),
      ),
    );
  }
}
