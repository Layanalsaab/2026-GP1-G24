import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import 'motion_tokens.dart';

export 'motion_tokens.dart';

/// Motion tokens and reusable effects (docs/03_motion.md).
///
/// Every effect here honours reduced motion: with
/// `MediaQuery.disableAnimations` on, movement becomes a 200 ms fade (or
/// nothing at all for press/hover).
class Motion {
  Motion._();

  /// Default curve for almost everything.
  static const easeOut = AppCurves.easeOut;

  /// SVG line drawing, legacy tab bar.
  static const easeInOut = AppCurves.easeInOut;

  /// Sheets and the side drawer.
  static const drawer = AppCurves.drawer;

  static const press = AppDur.press;
  static const fast = AppDur.fast;
  static const color = AppDur.chip;
  static const medium = AppDur.screen;
  static const slow = AppDur.sheet;

  /// Reduced-motion fade used in place of every movement.
  static const reducedFade = AppDur.reducedFade;

  /// True when the user (or platform) asked for less motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// A duration that collapses to zero under reduced motion.
  static Duration dur(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;

  /// Stagger delay for list items: 40 ms x index (cards), 50 ms (My Startups),
  /// 30 ms (drawer rows after a 90 ms lead). Off under reduced motion.
  static Duration stagger(
    BuildContext context,
    int index, {
    int stepMs = 40,
    int leadMs = 0,
    int maxIndex = 12,
  }) {
    if (reduced(context)) return Duration.zero;
    final i = index > maxIndex ? maxIndex : index;
    return Duration(milliseconds: leadMs + stepMs * i);
  }
}

/// Plays [builder] once after [delay], driving a 0..1 animation. Shared by
/// the one-shot effects below.
abstract class _OneShotState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  Timer? _timer;

  Duration get delay;
  Duration get duration;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: duration);
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      controller.duration = Motion.reducedFade;
    }
    final wait = Motion.reduced(context) ? Duration.zero : delay;
    if (wait == Duration.zero) {
      controller.forward();
    } else {
      _timer = Timer(wait, () {
        if (mounted) controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    controller.dispose();
    super.dispose();
  }
}

/// opacity 0 -> 1 and translateY [offset] -> 0 (the prototype's `rise`).
class Rise extends StatefulWidget {
  const Rise({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 360),
    this.offset = 10,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  /// `cardIn`: 320 ms, 8 px. Used for list cards with a stagger.
  const Rise.card({super.key, required this.child, this.delay = Duration.zero})
    : duration = const Duration(milliseconds: 320),
      offset = 8;

  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends _OneShotState<Rise> {
  @override
  Duration get delay => widget.delay;
  @override
  Duration get duration => widget.duration;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final curved = CurvedAnimation(
      parent: controller,
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
                offset: Offset(0, widget.offset * (1 - curved.value)),
                child: child,
              ),
      ),
    );
  }
}

/// opacity 0 -> 1 (the prototype's `fade-in`, 500 ms).
class FadeInOnce extends StatefulWidget {
  const FadeInOnce({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  State<FadeInOnce> createState() => _FadeInOnceState();
}

class _FadeInOnceState extends _OneShotState<FadeInOnce> {
  @override
  Duration get delay => widget.delay;
  @override
  Duration get duration => widget.duration;

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: CurvedAnimation(parent: controller, curve: Motion.easeOut),
    child: widget.child,
  );
}

/// opacity 0 -> 1, scale .92 -> 1, translateY 8 -> 0 (`logo-in`, 700 ms).
class LogoIn extends StatefulWidget {
  const LogoIn({super.key, required this.child});

  final Widget child;

  @override
  State<LogoIn> createState() => _LogoInState();
}

class _LogoInState extends _OneShotState<LogoIn> {
  @override
  Duration get delay => Duration.zero;
  @override
  Duration get duration => const Duration(milliseconds: 700);

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final a = CurvedAnimation(
      parent: controller,
      curve: reduced ? Curves.linear : Motion.easeOut,
    );
    return AnimatedBuilder(
      animation: a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: a.value,
        child: reduced
            ? child
            : Transform.translate(
                offset: Offset(0, 8 * (1 - a.value)),
                child: Transform.scale(
                  scale: 0.92 + 0.08 * a.value,
                  child: child,
                ),
              ),
      ),
    );
  }
}

/// scale .7 -> 1.15 (at 60 %) -> 1 over 320 ms (`pop`). Plays when mounted,
/// so wrap the thing that appears (a check icon, a filled bookmark).
class Pop extends StatefulWidget {
  const Pop({super.key, required this.child});

  final Widget child;

  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends _OneShotState<Pop> {
  @override
  Duration get delay => Duration.zero;
  @override
  Duration get duration => const Duration(milliseconds: 320);

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.15), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 40),
  ]);

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) {
      return FadeTransition(opacity: controller, child: widget.child);
    }
    return ScaleTransition(
      scale: _scale.animate(
        CurvedAnimation(parent: controller, curve: Motion.easeOut),
      ),
      child: widget.child,
    );
  }
}

/// scaleY .08 -> 1 anchored at the bottom (`grow`, 520 ms). Bars and charts.
class Grow extends StatefulWidget {
  const Grow({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<Grow> createState() => _GrowState();
}

class _GrowState extends _OneShotState<Grow> {
  @override
  Duration get delay => widget.delay;
  @override
  Duration get duration => const Duration(milliseconds: 520);

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) {
      return FadeTransition(opacity: controller, child: widget.child);
    }
    final a = Tween<double>(
      begin: 0.08,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Motion.easeOut));
    return AnimatedBuilder(
      animation: a,
      child: widget.child,
      builder: (context, child) => Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.diagonal3Values(1, a.value, 1),
        child: child,
      ),
    );
  }
}

/// Looping effects: [Float] (translateY 0 -> -6 -> 0, 4 s) and [Twinkle]
/// (opacity .35 <-> 1, scale .85 <-> 1, 2.4 s). Static under reduced motion.
class Float extends StatefulWidget {
  const Float({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<Float> createState() => _FloatState();
}

class _FloatState extends State<Float> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );
  Timer? _t;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || Motion.reduced(context)) return;
    _started = true;
    _t = Timer(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // 0 -> -6 -> 0, eased like a sine.
        final dy = -6 * (0.5 - 0.5 * _cosTurns(_c.value));
        return Transform.translate(offset: Offset(0, dy), child: child);
      },
    );
  }
}

class Twinkle extends StatefulWidget {
  const Twinkle({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<Twinkle> createState() => _TwinkleState();
}

class _TwinkleState extends State<Twinkle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  Timer? _t;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || Motion.reduced(context)) return;
    _started = true;
    _t = Timer(widget.delay, () {
      if (mounted) _c.repeat();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // .35 -> 1 -> .35 (and scale .85 -> 1 -> .85).
        final p = 0.5 - 0.5 * _cosTurns(_c.value);
        return Opacity(
          opacity: 0.35 + 0.65 * p,
          child: Transform.scale(scale: 0.85 + 0.15 * p, child: child),
        );
      },
    );
  }
}

double _cosTurns(double t) => math.cos(2 * math.pi * t);

/// One wrapper for everything tappable (§0.4): scales to [scale] while
/// pressed (140 ms, easeOut), optionally reacts to a mouse pointer
/// ([hoverOffset] lift, [hoverColor] / [hoverDecoration] background), shows a
/// 2 px moss600 focus outline (2 px offset) for keyboard users only, and does
/// nothing when it has no action (disabled). No ripple, ever.
///
/// Use the [PressScale] constants for [scale]. Under reduced motion the press
/// scale and hover lift are off (hover colors change instantly).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = PressScale.button,
    this.behavior = HitTestBehavior.opaque,
    this.hoverOffset,
    this.hoverColor,
    this.hoverDecoration,
    this.hoverDuration = AppDur.base,
    this.borderRadius,
    this.focusRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final HitTestBehavior behavior;

  /// Translation while the pointer hovers (cards lift `Offset(0, -2)`).
  final Offset? hoverOffset;

  /// Background painted behind the child while hovered (needs
  /// [borderRadius] to match the child's shape).
  final Color? hoverColor;

  /// Decoration applied while hovered (a shadow, a border, a ring), animated
  /// over [hoverDuration].
  final BoxDecoration? hoverDecoration;
  final Duration hoverDuration;

  /// Corner radius of the child's shape (for [hoverColor]).
  final BorderRadius? borderRadius;

  /// Corner radius of the keyboard focus outline; defaults to [borderRadius]
  /// or 12.
  final BorderRadius? focusRadius;

  bool get _hasHover =>
      hoverOffset != null || hoverColor != null || hoverDecoration != null;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  bool _hover = false;
  bool _focus = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final reduced = Motion.reduced(context);
    final animate = enabled && !reduced;
    final hovering = enabled && _hover;

    Widget content = widget.child;
    if (widget._hasHover) {
      final shape = widget.borderRadius;
      content = AnimatedContainer(
        duration: reduced ? Duration.zero : widget.hoverDuration,
        curve: AppCurves.easeOut,
        transformAlignment: Alignment.center,
        transform: hovering && !reduced && widget.hoverOffset != null
            ? Matrix4.translationValues(
                widget.hoverOffset!.dx,
                widget.hoverOffset!.dy,
                0,
              )
            : Matrix4.identity(),
        decoration: hovering
            ? (widget.hoverDecoration ??
                  BoxDecoration(color: widget.hoverColor, borderRadius: shape))
            : BoxDecoration(borderRadius: shape),
        foregroundDecoration: null,
        child: content,
      );
      if (widget.hoverDecoration != null && widget.hoverColor != null) {
        // Both given: the color sits under the decoration's own fill.
        content = ColoredBox(
          color: hovering ? widget.hoverColor! : const Color(0x00000000),
          child: content,
        );
      }
    }

    final radius =
        widget.focusRadius ??
        widget.borderRadius ??
        const BorderRadius.all(Radius.circular(12));

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      // A real pointer only: touch never hovers.
      onEnter: (_) {
        if (!_hover && mounted) setState(() => _hover = true);
      },
      onExit: (_) {
        if (_hover && mounted) setState(() => _hover = false);
      },
      child: FocusableActionDetector(
        enabled: enabled,
        // Only true while the keyboard drives focus (never after a tap).
        onShowFocusHighlight: (v) {
          if (_focus != v && mounted) setState(() => _focus = v);
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: widget.behavior,
          onTapDown: enabled ? (_) => _set(true) : null,
          onTapUp: enabled ? (_) => _set(false) : null,
          onTapCancel: enabled ? () => _set(false) : null,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: AnimatedScale(
            scale: animate && _down ? widget.scale : 1,
            duration: AppDur.press,
            curve: AppCurves.easeOut,
            child: Stack(
              // Passthrough keeps the parent's constraints exactly as before.
              fit: StackFit.passthrough,
              clipBehavior: Clip.none,
              children: [
                content,
                if (_focus)
                  Positioned(
                    left: -3,
                    top: -3,
                    right: -3,
                    bottom: -3,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: radius.topLeft + const Radius.circular(3),
                            topRight:
                                radius.topRight + const Radius.circular(3),
                            bottomLeft:
                                radius.bottomLeft + const Radius.circular(3),
                            bottomRight:
                                radius.bottomRight + const Radius.circular(3),
                          ),
                          border: Border.all(
                            color: const Color(0xFF2F5D3A),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Draws an SVG [d] path progressively (`draw`, 1400 ms, easeInOut) by
/// extracting a growing prefix of each path metric. Used for the splash
/// arches, intro graphics and program-details circles.
class DrawPath extends StatefulWidget {
  const DrawPath({
    super.key,
    required this.pathData,
    required this.color,
    this.strokeWidth = 1.5,
    this.size,
    this.viewBox,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 1400),
    this.fillOpacity = 0,
  });

  /// SVG path `d` string in [viewBox] coordinates.
  final String pathData;
  final Color color;
  final double strokeWidth;

  /// Size of the painted area. Null expands to the parent.
  final Size? size;

  /// The SVG viewBox the path was authored in (scaled to [size]).
  final Size? viewBox;
  final Duration delay;
  final Duration duration;
  final double fillOpacity;

  @override
  State<DrawPath> createState() => _DrawPathState();
}

class _DrawPathState extends _OneShotState<DrawPath> {
  @override
  Duration get delay => widget.delay;
  @override
  Duration get duration => widget.duration;

  late final Path _path = parseSvgPathData(widget.pathData);

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final a = CurvedAnimation(parent: controller, curve: Motion.easeInOut);
    return AnimatedBuilder(
      animation: a,
      builder: (context, _) => CustomPaint(
        size: widget.size ?? Size.zero,
        painter: _DrawPainter(
          path: _path,
          progress: reduced ? 1 : a.value,
          color: widget.color,
          strokeWidth: widget.strokeWidth,
          viewBox: widget.viewBox,
        ),
      ),
    );
  }
}

class _DrawPainter extends CustomPainter {
  _DrawPainter({
    required this.path,
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.viewBox,
  });

  final Path path;
  final double progress;
  final Color color;
  final double strokeWidth;
  final Size? viewBox;

  @override
  void paint(Canvas canvas, Size size) {
    final box = viewBox;
    if (box != null) {
      canvas.scale(size.width / box.width, size.height / box.height);
    }
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(_DrawPainter old) =>
      old.progress != progress || old.color != color || old.path != path;
}

/// `cardIn`: a list card appears with opacity 0 -> 1 and translateY 8 -> 0
/// over 320 ms, delayed 40 ms x [index] (§0.3). Off (instant) under reduced
/// motion. The start state is shown during the delay.
class CardIn extends StatelessWidget {
  const CardIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Rise.card(delay: Motion.stagger(context, index), child: child);
}

/// `chipIn`: opacity 0 -> 1 and scale .94 -> 1 over 220 ms (§0.3), for a
/// filter chip that has just appeared.
class ChipIn extends StatefulWidget {
  const ChipIn({super.key, required this.child});

  final Widget child;

  @override
  State<ChipIn> createState() => _ChipInState();
}

class _ChipInState extends _OneShotState<ChipIn> {
  @override
  Duration get delay => Duration.zero;
  @override
  Duration get duration => AppDur.card;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final a = CurvedAnimation(
      parent: controller,
      curve: reduced ? Curves.linear : AppCurves.easeOut,
    );
    return AnimatedBuilder(
      animation: a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: a.value,
        child: reduced
            ? child
            : Transform.scale(scale: 0.94 + 0.06 * a.value, child: child),
      ),
    );
  }
}

/// `fade-in`: opacity 0 -> 1 over 500 ms after an optional delay (§0.3).
typedef FadeIn = FadeInOnce;
