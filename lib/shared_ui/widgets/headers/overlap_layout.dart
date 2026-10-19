import 'package:flutter/material.dart';

import '../../motion/motion.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_metrics.dart';

/// White card that sits on the green [AuthHeader] / [StepHeader] (log in,
/// forgot password, every sign-up and add-startup step): radius 22,
/// `authCard` shadow, side margin 16, rise animation (460 ms, 60 ms delay).
///
/// The header is what overlaps (it reports a height 44 px smaller, see
/// [overlap]); place this card directly after it in a column.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child, this.animate = true});

  /// How far the card climbs into the header (the header's default overlap).
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

/// The list variant of [AuthCard] (choose role, My Startups, calculator): a
/// column of separate cards with a [gap] (12, role 14) and side margin 16,
/// bottom padding 20, rising together (460 ms, 60 ms delay). Its header
/// overlap is [overlap] = 48 (`AuthHeader(overlap: OverlapList.overlap)`;
/// [RoleHeader] already defaults to it).
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
