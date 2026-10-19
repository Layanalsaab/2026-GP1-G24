import 'package:flutter/material.dart';

import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_metrics.dart';

/// Hover shadow of a base card: 0 2 4 #1F3F2712, 0 12 28 -6 #1F3F2729
/// (spec section 3.2 / 10).
const List<BoxShadow> kCardHoverShadow = [
  BoxShadow(color: Color(0x121F3F27), offset: Offset(0, 2), blurRadius: 4),
  BoxShadow(
    color: Color(0x291F3F27),
    offset: Offset(0, 12),
    blurRadius: 28,
    spreadRadius: -6,
  ),
];

/// A white tappable card that lifts 2 px, swaps to the hover shadow and shows
/// a `#D9D4C9` border while a mouse pointer is over it (220 ms easeOut), and
/// scales to .97 while pressed. Touch never hovers; reduced motion turns the
/// lift, the scale and the animation off.
class HoverLiftCard extends StatefulWidget {
  const HoverLiftCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppRadius.homeCard,
    this.baseShadow = AppShadow.listCard,
    this.border,
    this.hoverBorder = const Color(0xFFD9D4C9),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final List<BoxShadow> baseShadow;

  /// A permanent border (drawn in the layout, e.g. the draft card's gold).
  final Border? border;

  /// Colour of the hover border (null: none).
  final Color? hoverBorder;

  @override
  State<HoverLiftCard> createState() => _HoverLiftCardState();
}

class _HoverLiftCardState extends State<HoverLiftCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    final hovering = _hover && widget.onTap != null;
    final radius = BorderRadius.circular(widget.radius);
    return Pressable(
      onTap: widget.onTap,
      scale: PressScale.button,
      borderRadius: radius,
      child: MouseRegion(
        onEnter: (_) {
          if (!_hover && mounted) setState(() => _hover = true);
        },
        onExit: (_) {
          if (_hover && mounted) setState(() => _hover = false);
        },
        child: AnimatedContainer(
          duration: reduced ? Duration.zero : AppDur.card,
          curve: AppCurves.easeOut,
          transformAlignment: Alignment.center,
          transform: Matrix4.translationValues(
            0,
            hovering && !reduced ? -2 : 0,
            0,
          ),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
            border: widget.border,
            boxShadow: hovering ? kCardHoverShadow : widget.baseShadow,
          ),
          foregroundDecoration: widget.hoverBorder == null
              ? null
              : BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: hovering
                        ? widget.hoverBorder!
                        : const Color(0x00D9D4C9),
                  ),
                ),
          child: widget.child,
        ),
      ),
    );
  }
}
