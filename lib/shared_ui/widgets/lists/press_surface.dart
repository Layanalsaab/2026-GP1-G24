import 'package:flutter/material.dart';

import '../../motion/motion.dart';

/// A tappable region that tints its background while pressed (the prototype's
/// `.tr:active`, `.di:active` and `.srow` rows). No ripple. Under reduced
/// motion the tint still shows but does not animate.
class PressSurface extends StatefulWidget {
  const PressSurface({
    super.key,
    required this.child,
    this.onTap,
    this.pressedColor = const Color(0xFFF6F4EF),
    this.borderRadius,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Background while pressed.
  final Color pressedColor;
  final BorderRadius? borderRadius;

  /// Optional explicit accessibility label (otherwise the child's text is
  /// merged).
  final String? semanticLabel;
  final bool? selected;

  @override
  State<PressSurface> createState() => _PressSurfaceState();
}

class _PressSurfaceState extends State<PressSurface> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      container: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Motion.dur(context, const Duration(milliseconds: 150)),
          decoration: BoxDecoration(
            color: _down ? widget.pressedColor : Colors.transparent,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
