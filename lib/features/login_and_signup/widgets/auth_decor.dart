import 'package:flutter/material.dart';

import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';

/// The full Start.sa logo on a cream page (splash 150 x 143, welcome 120 x 114).
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (AppColors.isDark) {
      return Image.asset(
        'assets/images/logo_small.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        semanticLabel: 'Start.sa logo',
      );
    }
    return Image.asset(
      'assets/images/logo_full.png',
      width: width,
      height: height,
      fit: BoxFit.contain,
      color: AppColors.cream,
      colorBlendMode: BlendMode.multiply,
      semanticLabel: 'Start.sa logo',
    );
  }
}

class FlexPage extends StatelessWidget {
  const FlexPage({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// A 4-point gold sparkle (the prototype's twinkle star) of size px.
class Sparkle extends StatelessWidget {
  const Sparkle({super.key, required this.size, this.color = AppColors.gold});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _SparklePainter(color),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 20;
    final p = Path()
      ..moveTo(10 * s, 0)
      ..relativeLineTo(3 * s, 7 * s)
      ..relativeLineTo(7 * s, 3 * s)
      ..relativeLineTo(-7 * s, 3 * s)
      ..relativeLineTo(-3 * s, 7 * s)
      ..relativeLineTo(-3 * s, -7 * s)
      ..relativeLineTo(-7 * s, -3 * s)
      ..relativeLineTo(7 * s, -3 * s)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

/// The gold divider (line, rotated diamond, line) under the splash and welcome taglines.
class GoldDivider extends StatelessWidget {
  const GoldDivider({super.key, this.lineWidth = 44, this.diamond = 8});

  final double lineWidth;
  final double diamond;

  @override
  Widget build(BuildContext context) {
    Widget line() =>
        Container(width: lineWidth, height: 1.5, color: AppColors.gold);
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          line(),
          const SizedBox(width: 10),
          Transform.rotate(
            angle: 0.7853981633974483,
            child: Container(
              width: diamond,
              height: diamond,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 10),
          line(),
        ],
      ),
    );
  }
}

class SplashBackdrop extends StatelessWidget {
  const SplashBackdrop({super.key});

  static const _box = Size(390, 844);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final s = c.maxWidth / _box.width;
        final size = Size(c.maxWidth, _box.height * s);
        Widget arch(String d, double opacity, int delay) => DrawPath(
          pathData: d,
          color: AppColors.moss600.withValues(alpha: opacity),
          size: size,
          viewBox: _box,
          delay: Duration(milliseconds: delay),
        );
        Widget star(double x, double y, double r, int delay) => Positioned(
          left: x * s,
          top: y * s,
          child: Twinkle(
            delay: Duration(milliseconds: delay),
            child: Sparkle(size: r * 2 * s),
          ),
        );
        return Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                arch('M20 844V250L195 110l175 140v594', .10, 0),
                arch('M60 844V275L195 168l135 107v569', .13, 120),
                arch('M100 844V300L195 226l95 74v544', .16, 240),
                star(70, 200, 10, 0),
                star(311, 300, 7, 800),
                star(293, 620, 7, 1400),
              ],
            ),
          ),
        );
      },
    );
  }
}

class WelcomeBackdrop extends StatelessWidget {
  const WelcomeBackdrop({super.key});

  static const _box = Size(390, 560);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final s = c.maxWidth / _box.width;
        final size = Size(c.maxWidth, _box.height * s);
        Widget star(double x, double y, int delay) => Positioned(
          left: x * s,
          top: y * s,
          child: Twinkle(
            delay: Duration(milliseconds: delay),
            child: Sparkle(size: 14 * s),
          ),
        );
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: PathsPainter(
                        viewBox: _box,
                        strokes: [
                          (
                            'M20 560V170L195 40l175 130v390',
                            AppColors.moss600.withValues(alpha: .09),
                          ),
                          (
                            'M60 560V200L195 100l135 100v360',
                            AppColors.moss600.withValues(alpha: .12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                star(43, 110, 0),
                star(333, 140, 900),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Paints static stroked SVG paths authored in viewBox, scaled to fit.
class PathsPainter extends CustomPainter {
  PathsPainter({
    required this.viewBox,
    required this.strokes,
    this.strokeWidth = 1.5,
  });

  final Size viewBox;

  /// (svg path data, color) pairs.
  final List<(String, Color)> strokes;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / viewBox.width, size.height / viewBox.height);
    for (final (d, color) in strokes) {
      canvas.drawPath(
        svgPath(d),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.miter,
      );
    }
  }

  @override
  bool shouldRepaint(PathsPainter old) =>
      old.strokes != strokes || old.viewBox != viewBox;
}
