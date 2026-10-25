import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/list_entries.dart';
import '../../../shared_ui/theme/app_text.dart';

/// The role tag next to a startup name: height 20, radius 999, 11 px
/// semibold, padding 0 8. Founder = gold, Co-founder = blue, Team member =
/// green. (Invited = transparent with a dashed grey border: [RoleTag.invited].)
class RoleTag extends StatelessWidget {
  const RoleTag(this.role, {super.key}) : invited = false;

  /// "Invited": transparent, 1 px dashed `#B9BDB8` border, grey text.
  const RoleTag.invited({super.key}) : role = null, invited = true;

  final StartupRole? role;
  final bool invited;

  static String labelOf(StartupRole role) => switch (role) {
    StartupRole.founder => FounderToolsStrings.roleFounder,
    StartupRole.coFounder => FounderToolsStrings.roleCoFounder,
    StartupRole.member => FounderToolsStrings.roleMember,
  };

  @override
  Widget build(BuildContext context) {
    if (invited) {
      return Semantics(
        label: 'Invited',
        excludeSemantics: true,
        child: CustomPaint(
          painter: _DashedPillPainter(),
          child: Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            child: Text(
              'Invited',
              style: AppText.sans(
                size: 11,
                weight: FontWeight.w600,
                color: const Color(0xFF6B726C),
              ),
            ),
          ),
        ),
      );
    }
    final (fill, color) = switch (role!) {
      StartupRole.founder => (const Color(0xFFF6EEDB), const Color(0xFF7A5A12)),
      StartupRole.coFounder => (
        const Color(0xFFE7EEF8),
        const Color(0xFF2B4F80),
      ),
      StartupRole.member => (const Color(0xFFE6EFE7), const Color(0xFF2F5D3A)),
    };
    return Semantics(
      label: labelOf(role!),
      excludeSemantics: true,
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          labelOf(role!),
          style: AppText.sans(size: 11, weight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}

class _DashedPillPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height / 2),
    );
    final path = Path()..addRRect(rrect.deflate(0.5));
    final paint = Paint()
      ..color = const Color(0xFFB9BDB8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 3), paint);
        d += 5;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPillPainter old) => false;
}
