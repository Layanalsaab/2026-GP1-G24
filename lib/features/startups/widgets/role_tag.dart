import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/list_entries.dart';
import '../../../models/team_member.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';

/// The role tag next to a startup name: height 20, radius 999, 11 px
/// semibold, padding 0 8. Founder = gold, Co-founder = blue, Team member =
/// green. (Invited = transparent with a dashed grey border: [RoleTag.invited].)
class RoleTag extends StatelessWidget {
  const RoleTag(this.role, {super.key, this.label})
    : invited = false,
      warn = false;

  /// "Invited": transparent, 1 px dashed `#B9BDB8` border, grey text.
  const RoleTag.invited({super.key, this.label, this.warn = false})
    : role = null,
      invited = true;

  final StartupRole? role;
  final bool invited;

  /// Text shown instead of the role's own name ("You · Founder").
  final String? label;

  /// The dashed tag in red ("Declined").
  final bool warn;

  static String labelOf(StartupRole role) => switch (role) {
    StartupRole.founder => FounderToolsStrings.roleFounder,
    StartupRole.coFounder => FounderToolsStrings.roleCoFounder,
    StartupRole.member => FounderToolsStrings.roleMember,
  };

  @override
  Widget build(BuildContext context) {
    if (invited) {
      return Semantics(
        label: label ?? 'Invited',
        excludeSemantics: true,
        child: CustomPaint(
          painter: _DashedPillPainter(),
          // No `alignment` on the Container: that would stretch it to the
          // full width. The Center only centres the text vertically.
          child: Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              widthFactor: 1,
              child: Text(
                label ?? 'Invited',
                style: AppText.sans(
                  size: 11,
                  height: 18,
                  weight: FontWeight.w600,
                  color: warn ? AppColors.error : const Color(0xFF5B625D),
                ),
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
      label: label ?? labelOf(role!),
      excludeSemantics: true,
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label ?? labelOf(role!),
            style: AppText.sans(
              size: 11,
              height: 20,
              weight: FontWeight.w600,
              color: color,
            ),
          ),
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

/// The tag capsules of one team member, the same everywhere a team is shown
/// (Startup Team step, Manage -> Details, startup page Team tab): the role
/// tag (Founder / Co-founder / Member, prefixed "You · " on my own card), and
/// for an invited person a dashed "Invited" tag next to it (never on the
/// founder).
List<Widget> teamTagsOf(
  TeamMember member, {
  required bool isYou,
  bool declined = false,
}) {
  final you = isYou ? 'You · ' : '';
  final tag = member.isFounder
      ? RoleTag(StartupRole.founder, label: '${you}Founder')
      : member.coFounder
      ? RoleTag(StartupRole.coFounder, label: '${you}Co-founder')
      : RoleTag(StartupRole.member, label: '${you}Member');
  return [
    tag,
    if (member.invited && !member.isFounder)
      declined
          ? const RoleTag.invited(label: 'Declined', warn: true)
          : const RoleTag.invited(),
  ];
}
