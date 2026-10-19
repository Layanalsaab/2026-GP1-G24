import 'package:flutter/material.dart';

import '../motion/motion.dart';
import '../theme/app_colors.dart';

/// The prototype's screen transitions (docs/03_motion.md §Screen transitions).
enum RouteKind {
  /// Opening a screen from a list or button: fade in, slide from x +28.
  forward,

  /// Back button / closing a preview: fade in, slide from x -28.
  back,

  /// Entering Home (after log in, finishing sign-up, guest entry): fade in,
  /// slide from y +24.
  up,

  /// Splash -> Intro: opacity only.
  fade,
}

/// A page route with the Start.sa transitions.
///
/// The previous screen is replaced instantly (a cream backdrop covers it
/// from the first frame), so there is no exit animation. Popping is also
/// instant: the revealed screen plays the "back" entrance itself, which is
/// how the prototype's Back works.
///
/// Screens whose top is a green arch header pass [greenHeader]: they never
/// fade (fading from 0 would flash the cream background behind the green
/// bar) and slide only 12 px.
class AppRoute<T> extends PageRouteBuilder<T> {
  AppRoute({
    required WidgetBuilder builder,
    this.kind = RouteKind.forward,
    this.greenHeader = false,
    bool instant = false,
    super.settings,
  }) : super(
         opaque: true,
         transitionDuration: instant
             ? Duration.zero
             : const Duration(milliseconds: 260),
         reverseTransitionDuration: Duration.zero,
         pageBuilder: (context, animation, secondary) => builder(context),
       );

  final RouteKind kind;
  final bool greenHeader;

  final ValueNotifier<int> _backTick = ValueNotifier<int>(0);

  @override
  void didPopNext(Route<dynamic> nextRoute) {
    super.didPopNext(nextRoute);
    // Only our own screens trigger the back entrance; closing a sheet or a
    // dialog must not re-animate the screen underneath.
    if (nextRoute is AppRoute) _backTick.value++;
  }

  @override
  void dispose() {
    _backTick.dispose();
    super.dispose();
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.cream),
        _BackEnter(
          tick: _backTick,
          greenHeader: greenHeader,
          child: _Enter(
            animation: animation,
            kind: kind,
            greenHeader: greenHeader,
            child: child,
          ),
        ),
      ],
    );
  }
}

double _distance(bool greenHeader) => greenHeader ? 12 : 28;

class _Enter extends StatelessWidget {
  const _Enter({
    required this.animation,
    required this.kind,
    required this.greenHeader,
    required this.child,
  });

  final Animation<double> animation;
  final RouteKind kind;
  final bool greenHeader;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final curved = CurvedAnimation(
      parent: animation,
      curve: reduced ? Curves.linear : Motion.easeOut,
    );
    final fades = reduced || (!greenHeader);
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) {
        final v = curved.value;
        var dx = 0.0;
        var dy = 0.0;
        if (!reduced) {
          switch (kind) {
            case RouteKind.forward:
              dx = _distance(greenHeader) * (1 - v);
            case RouteKind.back:
              dx = -_distance(greenHeader) * (1 - v);
            case RouteKind.up:
              dy = (greenHeader ? 12 : 24) * (1 - v);
            case RouteKind.fade:
              break;
          }
        }
        final moved = (dx == 0 && dy == 0)
            ? child!
            : Transform.translate(offset: Offset(dx, dy), child: child);
        // Green-header screens keep full opacity, except under reduced
        // motion (which is a plain fade) or the explicit fade kind.
        final shouldFade = fades || kind == RouteKind.fade;
        return shouldFade ? Opacity(opacity: v, child: moved) : moved;
      },
    );
  }
}

/// Plays the "back" entrance on this screen when the screen above it pops:
/// fade in and slide from x -28 (12 and no fade for green-header screens).
class _BackEnter extends StatefulWidget {
  const _BackEnter({
    required this.tick,
    required this.greenHeader,
    required this.child,
  });

  final ValueNotifier<int> tick;
  final bool greenHeader;
  final Widget child;

  @override
  State<_BackEnter> createState() => _BackEnterState();
}

class _BackEnterState extends State<_BackEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  @override
  void initState() {
    super.initState();
    widget.tick.addListener(_play);
  }

  void _play() {
    if (mounted) _c.forward(from: 0);
  }

  @override
  void dispose() {
    widget.tick.removeListener(_play);
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
      builder: (context, child) {
        final v = curved.value;
        if (v >= 1) return child!;
        final dx = reduced ? 0.0 : -_distance(widget.greenHeader) * (1 - v);
        final moved = dx == 0
            ? child!
            : Transform.translate(offset: Offset(dx, 0), child: child);
        return (reduced || !widget.greenHeader)
            ? Opacity(opacity: v, child: moved)
            : moved;
      },
    );
  }
}

/// Navigation helpers matching the prototype's stack model
/// (docs/04_navigation_and_flows.md §Stack model).
class AppNav {
  AppNav._();

  /// `go`: pushes [screen] with the forward transition.
  static Future<T?> push<T>(
    BuildContext context,
    Widget screen, {
    bool greenHeader = false,
    RouteSettings? settings,
  }) => Navigator.of(context).push<T>(
    AppRoute<T>(
      builder: (_) => screen,
      greenHeader: greenHeader,
      settings: settings,
    ),
  );

  /// `back`: pops the current screen. The revealed screen plays the back
  /// entrance. Does nothing when there is nothing to pop.
  static void back<T extends Object?>(BuildContext context, [T? result]) =>
      Navigator.of(context).maybePop<T>(result);

  /// `reset`: replaces the whole stack with [screen]. [kind] picks the
  /// entrance (`up` for Home, `back` for log out, `forward` for onboarding
  /// steps, `fade` for splash -> intro).
  static Future<T?> reset<T>(
    BuildContext context,
    Widget screen, {
    RouteKind kind = RouteKind.up,
    bool greenHeader = false,
  }) => Navigator.of(context).pushAndRemoveUntil<T>(
    AppRoute<T>(builder: (_) => screen, kind: kind, greenHeader: greenHeader),
    (route) => false,
  );

  /// `reset` to a stack of several screens (e.g. `[Home, MyStartups]`). Only
  /// the last one animates, with [kind]; the ones beneath appear instantly.
  static Future<T?> resetStack<T>(
    BuildContext context,
    List<Widget> screens, {
    RouteKind kind = RouteKind.back,
    bool greenHeader = false,
  }) {
    assert(screens.isNotEmpty);
    final navigator = Navigator.of(context);
    final routes = <Route<dynamic>>[
      for (var i = 0; i < screens.length - 1; i++)
        AppRoute<dynamic>(builder: (_) => screens[i], instant: true),
    ];
    final last = AppRoute<T>(
      builder: (_) => screens.last,
      kind: kind,
      greenHeader: greenHeader,
    );
    if (routes.isEmpty) {
      return navigator.pushAndRemoveUntil<T>(last, (route) => false);
    }
    // Clear everything, seat the base screens, then animate the top one in.
    navigator.pushAndRemoveUntil<dynamic>(routes.first, (route) => false);
    for (final r in routes.skip(1)) {
      navigator.push<dynamic>(r);
    }
    return navigator.push<T>(last);
  }
}
