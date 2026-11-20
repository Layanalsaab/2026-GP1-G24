import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../icons/app_icons.dart';
import '../../theme/app_colors.dart';

/// The gold Saudi-doorway arches drawn at the bottom of every green header (docs/02 §4).
class ArchBackground extends StatelessWidget {
  const ArchBackground({
    super.key,
    this.height = 130,
    this.opacity = 0.22,
    this.inner = true,
  });

  /// Outer path only, opacity .13, fills the whole height of the stack.
  const ArchBackground.home({super.key})
    : height = null,
      opacity = 0.13,
      inner = false;

  /// Profile banner: outer path only, opacity .15, height 96.
  const ArchBackground.banner({super.key})
    : height = 96,
      opacity = 0.15,
      inner = false;

  /// Painted height anchored at the bottom; null fills the parent stack.
  final double? height;

  /// 0..1 opacity of the gold lines.
  final double opacity;

  /// Also draw the inner (thinner) path.
  final bool inner;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      top: height == null ? 0 : null,
      height: height,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: CustomPaint(
            painter: _ArchPainter(opacity: opacity, inner: inner),
          ),
        ),
      ),
    );
  }
}

class _ArchPainter extends CustomPainter {
  _ArchPainter({required this.opacity, required this.inner});

  final double opacity;
  final bool inner;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.clipRect(Offset.zero & size);
    canvas.scale(
      size.width / ArchPaths.viewBox.width,
      size.height / ArchPaths.viewBox.height,
    );
    final color = AppColors.gold.withValues(alpha: opacity);
    canvas.drawPath(
      svgPath(ArchPaths.outer),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    if (inner) {
      canvas.drawPath(
        svgPath(ArchPaths.inner),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_ArchPainter old) =>
      old.opacity != opacity || old.inner != inner;
}

/// Reports a height overlap pixels smaller than its child while still painting the whole child.
class HeaderOverlap extends SingleChildRenderObjectWidget {
  const HeaderOverlap({super.key, required this.overlap, required Widget child})
    : super(child: child);

  final double overlap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeaderOverlap(overlap);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderHeaderOverlap).overlap = overlap;
  }
}

class _RenderHeaderOverlap extends RenderProxyBox {
  _RenderHeaderOverlap(this._overlap);

  double _overlap;
  set overlap(double v) {
    if (v == _overlap) return;
    _overlap = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(
      constraints.copyWith(minHeight: 0, maxHeight: double.infinity),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(c.size.width, math.max(0, c.size.height - _overlap)),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child;
    if (c == null) return constraints.smallest;
    final s = c.getDryLayout(
      constraints.copyWith(minHeight: 0, maxHeight: double.infinity),
    );
    return constraints.constrain(
      Size(s.width, math.max(0, s.height - _overlap)),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(0, (child?.getMinIntrinsicHeight(width) ?? 0) - _overlap);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(0, (child?.getMaxIntrinsicHeight(width) ?? 0) - _overlap);
}

class ArchHeaderShell extends StatelessWidget {
  const ArchHeaderShell({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.bottomRadius = 28,
    this.overlap = 0,
    this.arches = const ArchBackground(),
    this.safeTop = true,
  });

  final Widget child;

  /// Inner padding (before the status-bar inset is added to the top).
  final EdgeInsets padding;

  /// Bottom corner radius: 28 auth / steps / role, 30 home, 0 tabbed.
  final double bottomRadius;

  final double overlap;
  final ArchBackground arches;

  /// Adds the system status-bar height to the top padding.
  final bool safeTop;

  @override
  Widget build(BuildContext context) {
    final inset = safeTop ? MediaQuery.paddingOf(context).top : 0.0;
    Widget block = ClipRRect(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(bottomRadius),
      ),
      child: ColoredBox(
        color: AppColors.green,
        child: Stack(
          children: [
            arches,
            Padding(
              padding: padding.copyWith(top: padding.top + inset),
              child: SizedBox(width: double.infinity, child: child),
            ),
          ],
        ),
      ),
    );
    if (overlap > 0) block = HeaderOverlap(overlap: overlap, child: block);
    return block;
  }
}
