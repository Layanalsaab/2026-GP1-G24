import 'package:flutter/material.dart';

import '../../motion/motion.dart';

/// How the panel of an [AppOverlayRoute] enters.
enum AppOverlayEntry { slideUp, slideLeft, fadeScale }

/// A modal route with the prototype's two-layer overlay animation: a dim layer
/// that fades ([dimDuration]) and a panel that slides up / in from the left /
/// fades and scales ([duration], [curve]). Tapping outside the panel or the
/// system back gesture pops it. Under reduced motion both layers use a 200 ms
/// fade. Use [showAppOverlay] rather than building it directly.
class AppOverlayRoute<T> extends PopupRoute<T> {
  AppOverlayRoute({
    required this.builder,
    required this.dim,
    required this.dimDuration,
    required this.duration,
    required this.entry,
    required this.curve,
    required this.reduced,
    this.label = 'Close',
    this.dismissible = true,
  });

  final WidgetBuilder builder;
  final Color dim;
  final Duration dimDuration;
  final Duration duration;
  final AppOverlayEntry entry;
  final Curve curve;
  final bool reduced;
  final String label;
  final bool dismissible;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => label;

  @override
  Duration get transitionDuration => reduced ? Motion.reducedFade : duration;

  @override
  Duration get reverseTransitionDuration =>
      reduced ? Motion.reducedFade : duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      // Text fields, ink and list tiles inside a sheet need a Material
      // ancestor, and an overlay route has none of its own.
      child: Material(type: MaterialType.transparency, child: builder(context)),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final total = duration.inMilliseconds;
    final dimEnd = (dimDuration.inMilliseconds / total).clamp(0.0, 1.0);
    final dimA = reduced
        ? animation
        : animation.drive(
            CurveTween(curve: Interval(0, dimEnd, curve: Motion.easeOut)),
          );
    Widget panel;
    if (reduced) {
      panel = FadeTransition(opacity: animation, child: child);
    } else {
      final eased = animation.drive(CurveTween(curve: curve));
      switch (entry) {
        case AppOverlayEntry.slideUp:
          panel = SlideTransition(
            position: eased.drive(
              Tween(begin: const Offset(0, 1), end: Offset.zero),
            ),
            child: child,
          );
        case AppOverlayEntry.slideLeft:
          panel = SlideTransition(
            position: eased.drive(
              Tween(begin: const Offset(-1, 0), end: Offset.zero),
            ),
            child: child,
          );
        case AppOverlayEntry.fadeScale:
          final fade = animation.drive(CurveTween(curve: curve));
          panel = FadeTransition(
            opacity: fade,
            child: ScaleTransition(
              scale: fade.drive(Tween(begin: 0.96, end: 1.0)),
              child: child,
            ),
          );
      }
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: FadeTransition(
            opacity: dimA,
            child: ColoredBox(color: dim),
          ),
        ),
        panel,
      ],
    );
  }
}

/// Pushes an [AppOverlayRoute] on the root navigator.
Future<T?> showAppOverlay<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required Color dim,
  required Duration dimDuration,
  required Duration duration,
  required AppOverlayEntry entry,
  Curve curve = Motion.drawer,
  String label = 'Close',
  bool dismissible = true,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    AppOverlayRoute<T>(
      builder: builder,
      dim: dim,
      dimDuration: dimDuration,
      duration: duration,
      entry: entry,
      curve: curve,
      reduced: Motion.reduced(context),
      label: label,
      dismissible: dismissible,
    ),
  );
}
