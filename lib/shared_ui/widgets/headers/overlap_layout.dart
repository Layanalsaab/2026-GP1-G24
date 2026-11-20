import 'package:flutter/material.dart';

import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child, this.animate = true});

  static const double overlap = 44;

  final Widget child;

  /// Play the rise on mount (turn off for cards that are re-created often).
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final card = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.authCard),
          boxShadow: AppShadow.authCard,
        ),
        child: child,
      ),
    );
    if (!animate) return card;
    return Rise(
      delay: const Duration(milliseconds: 60),
      duration: const Duration(milliseconds: 460),
      child: card,
    );
  }
}

class OverlapList extends StatelessWidget {
  const OverlapList({
    super.key,
    required this.children,
    this.gap = 12,
    this.animate = true,
  });

  static const double overlap = 48;

  final List<Widget> children;
  final double gap;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final list = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            children[i],
          ],
        ],
      ),
    );
    if (!animate) return list;
    return Rise(
      delay: const Duration(milliseconds: 60),
      duration: const Duration(milliseconds: 460),
      child: list,
    );
  }
}
