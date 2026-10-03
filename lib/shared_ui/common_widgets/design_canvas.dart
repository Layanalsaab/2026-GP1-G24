import 'package:flutter/material.dart';

/// Lays children out using the Figma frame coordinates (360 x 800) and scales
/// the whole frame to fit the device, so every screen matches the design.
/// The [background] fills the full screen, including any letterbox area.
class DesignCanvas extends StatelessWidget {
  const DesignCanvas({
    super.key,
    required this.background,
    required this.children,
  });

  static const double designWidth = 360;
  static const double designHeight = 800;

  final Color background;

  /// Usually [Positioned] widgets, in Figma frame coordinates.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: designWidth,
            height: designHeight,
            child: Stack(clipBehavior: Clip.none, children: children),
          ),
        ),
      ),
    );
  }
}
