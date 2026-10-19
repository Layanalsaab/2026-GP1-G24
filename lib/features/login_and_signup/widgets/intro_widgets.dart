import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import 'auth_decor.dart';

/// The three page dots of the intro: 8 x 8 grey, the current one widens to 24
/// and turns gold (green on the last page, [dark]); 260 ms easeOut.
class IntroDots extends StatelessWidget {
  const IntroDots({
    super.key,
    required this.index,
    this.count = 3,
    this.dark = false,
  });

  final int index;
  final int count;

  /// Green current dot (cream pages) instead of gold.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final d = Motion.dur(context, const Duration(milliseconds: 260));
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              AnimatedContainer(
                duration: d,
                curve: Motion.easeOut,
                width: i == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == index
                      ? (dark ? AppColors.green : AppColors.gold)
                      : AppColors.switchOff,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The round 56 x 56 "next" arrow button of intro pages 1 and 2.
class IntroNextButton extends StatelessWidget {
  const IntroNextButton({
    super.key,
    required this.onTap,
    required this.background,
    required this.foreground,
    required this.shadowColor,
  });

  final VoidCallback onTap;
  final Color background;
  final Color foreground;

  /// Shadow tint: `#00000066` on green, `#1F3F2799` on cream.
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Next',
      excludeSemantics: true,
      child: Pressable(
        scale: 0.92,
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: const Offset(0, 8),
                blurRadius: 20,
                spreadRadius: -6,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AppIcon.filled(AppIcons.arrow, size: 24, color: foreground),
        ),
      ),
    );
  }
}

/// Gold house outlines along the bottom of intro page 1 (18 % opacity).
class IntroHouses extends StatelessWidget {
  const IntroHouses({super.key});

  static const _box = Size(390, 260);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = _box.height * c.maxWidth / _box.width;
        return ExcludeSemantics(
          child: CustomPaint(
            size: Size(c.maxWidth, h),
            painter: PathsPainter(
              viewBox: _box,
              strokes: [
                (
                  'M-10 260V120L60 60l70 60v140M120 260V120l70-60 70 60v140M250 260V120l70-60 70 60v140',
                  AppColors.gold.withValues(alpha: .18),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Intro page 1 graphic: a floating 240 x 240 network (a gold circle on top
/// joined to two moss-outlined circles, the gold triangle drawing itself).
class IntroNetwork extends StatelessWidget {
  const IntroNetwork({super.key});

  @override
  Widget build(BuildContext context) {
    const size = Size(240, 240);
    return ExcludeSemantics(
      child: Float(
        child: SizedBox(
          width: 240,
          height: 240,
          child: Stack(
            children: [
              CustomPaint(size: size, painter: _NetworkBelow()),
              DrawPath(
                pathData: 'M120 128L44 186L200 178Z',
                color: AppColors.gold,
                strokeWidth: 2,
                size: size,
                viewBox: size,
              ),
              CustomPaint(size: size, painter: _NetworkAbove()),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkBelow extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      const Offset(120, 80),
      const Offset(120, 128),
      Paint()
        ..color = AppColors.gold
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _NetworkAbove extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.gold
      ..strokeWidth = 2.5;
    canvas.drawCircle(const Offset(120, 54), 28, ring);
    for (final c in const [Offset(44, 186), Offset(200, 178)]) {
      canvas.drawCircle(c, 22, Paint()..color = AppColors.green);
      canvas.drawCircle(
        c,
        22,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xFFE6EFE7).withValues(alpha: .7)
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(
      const Offset(120, 128),
      7,
      Paint()..color = AppColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Intro page 2 graphic: four growing bars and a gold dashed trend line that
/// draws itself (300 x 300).
class IntroBars extends StatelessWidget {
  const IntroBars({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double x, double y, double h, Color color, int delay) =>
        Positioned(
          left: x,
          top: y,
          child: Grow(
            delay: Duration(milliseconds: delay),
            child: Container(
              width: 44,
              height: h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
    return ExcludeSemantics(
      child: SizedBox(
        width: 300,
        height: 300,
        child: Stack(
          children: [
            const Positioned.fill(child: _DashedTrend()),
            bar(50, 190, 80, AppColors.introGrey, 80),
            bar(110, 150, 120, AppColors.introSageBar, 160),
            bar(170, 100, 170, AppColors.green, 240),
            bar(230, 50, 220, AppColors.gold, 320),
          ],
        ),
      ),
    );
  }
}

/// The dashed gold line that draws itself (1400 ms easeInOut).
class _DashedTrend extends StatefulWidget {
  const _DashedTrend();

  @override
  State<_DashedTrend> createState() => _DashedTrendState();
}

class _DashedTrendState extends State<_DashedTrend>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Motion.easeInOut);
    return AnimatedBuilder(
      animation: a,
      builder: (context, _) =>
          CustomPaint(painter: _DashedPainter(progress: a.value)),
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(40, 170)
      ..lineTo(250, 20);
    final paint = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final PathMetric m in path.computeMetrics()) {
      final end = m.length * progress;
      var d = 0.0;
      while (d < end) {
        canvas.drawPath(m.extractPath(d, math.min(d + 3, end)), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) => old.progress != progress;
}

/// Intro page 3 graphic: three floating cards (programs, growing bars, AI
/// bubble) and two sparkles (330 high, centered on a 412 px frame).
class IntroCards extends StatelessWidget {
  const IntroCards({super.key});

  static const _shadowCard = [
    BoxShadow(
      color: Color(0x401F3F27),
      offset: Offset(0, 16),
      blurRadius: 32,
      spreadRadius: -12,
    ),
  ];
  static const _shadowDark = [
    BoxShadow(
      color: Color(0x991F3F27),
      offset: Offset(0, 18),
      blurRadius: 36,
      spreadRadius: -12,
    ),
  ];

  static const _sparkle =
      'M12 2l2.4 7.6L22 12l-7.6 2.4L12 22l-2.4-7.6L2 12l7.6-2.4z';
  static const _flag = 'M14.4 6L14 4H5v17h2v-7h5.6l.4 2h7V6z';

  Widget _line(double w, Color color, {double h = 6, double? r}) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(r ?? h / 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final programs = Container(
      width: 140,
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.tagGoldFill,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const AppIcon.filled(
              _flag,
              size: 18,
              color: AppColors.tagGoldText,
            ),
          ),
          const SizedBox(height: 16),
          _line(90, AppColors.introGrey),
          const SizedBox(height: 8),
          _line(60, AppColors.introGrey),
          const SizedBox(height: 12),
          _line(70, AppColors.moss100, h: 14, r: 7),
        ],
      ),
    );

    Widget growBar(double h, Color color, int delay) => Grow(
      delay: Duration(milliseconds: delay),
      child: Container(
        width: 14,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
    final insights = Container(
      width: 150,
      height: 130,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: _shadowCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(70, AppColors.introGrey),
          const SizedBox(height: 18),
          SizedBox(
            height: 70,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                growBar(20, AppColors.moss100, 0),
                const SizedBox(width: 8),
                growBar(38, AppColors.moss400, 100),
                const SizedBox(width: 8),
                growBar(52, AppColors.green, 200),
                const SizedBox(width: 8),
                growBar(66, AppColors.gold, 300),
              ],
            ),
          ),
        ],
      ),
    );

    Widget dot(Color color, int delay) => Twinkle(
      delay: Duration(milliseconds: delay),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
    final ai = Container(
      width: 210,
      height: 96,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _shadowDark,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const AppIcon.filled(
              _sparkle,
              size: 20,
              color: AppColors.green,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: .7,
                  child: Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.introSage,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    dot(AppColors.gold, 0),
                    const SizedBox(width: 5),
                    dot(AppColors.gold, 300),
                    const SizedBox(width: 5),
                    dot(AppColors.introSage, 600),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // The artwork was drawn on a 412 px frame: keep it centered, and let it
    // shrink to the screen width on narrower phones.
    return ExcludeSemantics(
      child: Center(
        child: SizedBox(
          width: 412,
          height: 330,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                left: 44,
                top: 30,
                child: Twinkle(
                  child: AppIcon.outline(
                    _sparkle,
                    size: 22,
                    color: AppColors.green,
                    stroke: 1.5,
                  ),
                ),
              ),
              const Positioned(
                right: 50,
                top: 16,
                child: Twinkle(
                  delay: Duration(milliseconds: 700),
                  child: AppIcon.filled(
                    _sparkle,
                    size: 18,
                    color: AppColors.green,
                  ),
                ),
              ),
              Positioned(left: 32, top: 60, child: Float(child: programs)),
              Positioned(
                right: 30,
                top: 50,
                child: Float(
                  delay: const Duration(milliseconds: 600),
                  child: insights,
                ),
              ),
              Positioned(
                left: 82,
                top: 200,
                child: Float(
                  delay: const Duration(milliseconds: 300),
                  child: ai,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
