import 'package:flutter/material.dart';

import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

/// "Expected revenue" bars (prototype `.prev`): three columns (gap 12, height
/// 150, padding 6 4 0). Bar heights are relative to the largest value (min 6 %
/// of the 144 px column, capped so the labels fit); the last bar is the gold
/// gradient, the others moss -> green. Bars Grow in (520 ms). Under each bar:
/// a 12 grey label ("Year 1") and the 14/700 value ("1.2M").
class RevenueBars extends StatelessWidget {
  const RevenueBars({
    super.key,
    required this.values,
    required this.labels,
    required this.valueLabels,
  });

  /// Raw numbers used for the relative heights.
  final List<double> values;

  /// e.g. "Year 1".
  final List<String> labels;

  /// e.g. "1.2M" (or "—").
  final List<String> valueLabels;

  @override
  Widget build(BuildContext context) {
    final mx = values.fold<double>(0, (a, b) => b > a ? b : a);
    const inner = 144.0;
    const labelsHeight = 46.0;
    final n = values.length;
    // The two label lines grow with the system font size, so the chart grows
    // with them (a fixed height overflowed by a few pixels at large text).
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final extra = scale > 1
        ? (labelsHeight * (scale - 1)).ceilToDouble() + 2
        : 0.0;
    return SizedBox(
      height: 150 + extra,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FractionallySizedBox(
                      widthFactor: 0.6,
                      child: Grow(
                        child: Container(
                          height: _barHeight(
                            values[i],
                            mx,
                            inner,
                            labelsHeight,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              topRight: Radius.circular(8),
                              bottomLeft: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: i == n - 1
                                  ? const [Color(0xFFD8B864), AppColors.gold]
                                  : [
                                      AppColors.moss600,
                                      AppColors.isDark
                                          ? AppColors.moss400
                                          : AppColors.green,
                                    ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        labels[i],
                        style: AppText.sans(size: 12, color: AppColors.grey),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valueLabels[i],
                      style: AppText.sans(
                        size: 14,
                        weight: FontWeight.w700,
                        tabular: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static double _barHeight(double v, double mx, double inner, double labels) {
    final pct = mx <= 0
        ? 6.0
        : (v / mx * 100).roundToDouble().clamp(6.0, 100.0);
    final h = pct / 100 * inner;
    final cap = inner - labels;
    return h > cap ? cap : h;
  }
}

/// Smooth area chart (prototype Manage > Activity `.area`): a Catmull-Rom line
/// through [values] (moss 2.4), a gradient fill (moss 22 % -> 0) and a gold end
/// dot with a white ring. Heights are relative to the maximum. When [values]
/// changes the line morphs over 400 ms (easeOut) by interpolating the points.
/// [axisLabels] (11 grey, space-between) are drawn under the chart.
class AreaChart extends StatefulWidget {
  const AreaChart({
    super.key,
    required this.values,
    this.axisLabels = const [],
    this.height = 80,
  });

  final List<double> values;
  final List<String> axisLabels;
  final double height;

  @override
  State<AreaChart> createState() => _AreaChartState();
}

class _AreaChartState extends State<AreaChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: 1,
  );
  late List<double> _from = _norm(widget.values);
  late List<double> _to = _from;

  static List<double> _norm(List<double> v) {
    if (v.isEmpty) return const [0, 0];
    final mx = v.fold<double>(0, (a, b) => b > a ? b : a);
    final r = [for (final x in v) mx <= 0 ? 0.0 : x / mx];
    return r.length == 1 ? [r[0], r[0]] : r;
  }

  static List<double> _resample(List<double> v, int n) {
    if (v.length == n) return v;
    return [
      for (var i = 0; i < n; i++)
        () {
          final pos = i * (v.length - 1) / (n - 1);
          final lo = pos.floor();
          final hi = (lo + 1).clamp(0, v.length - 1);
          return v[lo] + (v[hi] - v[lo]) * (pos - lo);
        }(),
    ];
  }

  List<double> _current() {
    final t = Motion.easeOut.transform(_c.value);
    if (t >= 1) return _to;
    final n = _from.length > _to.length ? _from.length : _to.length;
    final a = _resample(_from, n);
    final b = _resample(_to, n);
    return [for (var i = 0; i < n; i++) a[i] + (b[i] - a[i]) * t];
  }

  @override
  void didUpdateWidget(AreaChart old) {
    super.didUpdateWidget(old);
    final next = _norm(widget.values);
    if (_same(next, _to)) return;
    _from = _current();
    _to = next;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  static bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => SizedBox(
              height: widget.height,
              width: double.infinity,
              child: CustomPaint(painter: _AreaPainter(_current())),
            ),
          ),
        ),
        if (widget.axisLabels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final l in widget.axisLabels)
                  Text(l, style: AppText.sans(size: 11, color: AppColors.grey)),
              ],
            ),
          ),
      ],
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter(this.f);

  final List<double> f;

  @override
  void paint(Canvas canvas, Size size) {
    final n = f.length;
    final pts = <Offset>[
      for (var i = 0; i < n; i++)
        Offset(i * size.width / (n - 1), (84 - f[i] * 72) * size.height / 90),
    ];
    final line = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < n - 1; i++) {
      final p0 = i > 0 ? pts[i - 1] : pts[i];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < n ? pts[i + 2] : p2;
      line.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final b = fill.getBounds();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.moss600.withValues(alpha: 0.22),
            AppColors.moss600.withValues(alpha: 0),
          ],
        ).createShader(b),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.moss600
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(pts.last, 5, Paint()..color = AppColors.white);
    canvas.drawCircle(pts.last, 4, Paint()..color = AppColors.gold);
  }

  @override
  bool shouldRepaint(_AreaPainter old) => old.f != f;
}

/// One part of an [OwnershipBar].
class OwnershipSegment {
  const OwnershipSegment(this.percent, this.color);

  final double percent;
  final Color color;
}

/// Stacked ownership bar (prototype `.obar`): 12 high, radius 6, 2 px gaps,
/// `#F1EFEA` track. Segment widths animate over 400 ms (easeOut) when
/// [segments] change. Keep the same number of segments between rebuilds (use a
/// 0 percent segment for a hidden part).
class OwnershipBar extends StatefulWidget {
  const OwnershipBar({super.key, required this.segments});

  final List<OwnershipSegment> segments;

  @override
  State<OwnershipBar> createState() => _OwnershipBarState();
}

class _OwnershipBarState extends State<OwnershipBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
    value: 1,
  );
  late List<double> _from = [for (final s in widget.segments) s.percent];
  late List<double> _to = _from;

  List<double> _current() {
    final t = Motion.easeOut.transform(_c.value);
    return [
      for (var i = 0; i < _to.length; i++)
        (i < _from.length ? _from[i] : 0) +
            (_to[i] - (i < _from.length ? _from[i] : 0)) * t,
    ];
  }

  @override
  void didUpdateWidget(OwnershipBar old) {
    super.didUpdateWidget(old);
    final next = [for (final s in widget.segments) s.percent];
    if (next.length == _to.length) {
      var same = true;
      for (var i = 0; i < next.length; i++) {
        if (next[i] != _to[i]) same = false;
      }
      if (same) return;
    }
    _from = _current();
    _to = next;
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else {
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
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => SizedBox(
          height: 12,
          width: double.infinity,
          child: CustomPaint(
            painter: _BarPainter(_current(), [
              for (final s in widget.segments) s.color,
            ]),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.widths, this.colors);

  final List<double> widths;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final clip = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    canvas.clipRRect(clip);
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.mutedFill);
    final visible = [
      for (var i = 0; i < widths.length; i++)
        if (widths[i] > 0.01) i,
    ];
    final gaps = visible.isEmpty ? 0 : (visible.length - 1) * 2.0;
    final usable = size.width - gaps;
    var x = 0.0;
    for (final i in visible) {
      final w = usable * widths[i] / 100;
      canvas.drawRect(
        Rect.fromLTWH(x, 0, w, size.height),
        Paint()..color = colors[i],
      );
      x += w + 2;
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => true;
}
