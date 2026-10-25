import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/list_entries.dart';
import 'founder_ui.dart';
import 'manage_card.dart';

/// Manage startup -> Settings: one white card per row, each a full-width
/// button with a 40 px icon tile, a title with sub-text and, where needed, a
/// control on the right.
///
/// * **Public profile** (founder and co-founder): globe, a switch.
/// * **Delete startup** (founder only): red trash, red title.
/// * **Leave startup** (co-founder and team member): red leave icon, red
///   title; the founder has no Leave (transferring ownership is later).
///
/// What a role cannot do is not shown at all.
class ManageSettingsTab extends StatelessWidget {
  const ManageSettingsTab({
    super.key,
    required this.role,
    required this.isPublic,
    required this.onVisibilityChanged,
    required this.onDelete,
    required this.onLeave,
  });

  final StartupRole role;
  final bool isPublic;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onDelete;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    // Only the founder can delete the startup.
    final canDelete = role == StartupRole.founder;
    final cards = <Widget>[
      if (role.canManage)
        _SettingCard(
          icon: AppIcons.globe,
          fill: AppColors.moss50,
          color: AppColors.moss600,
          title: FounderToolsStrings.publicProfile,
          text: isPublic
              ? FounderToolsStrings.publicProfileOn
              : FounderToolsStrings.publicProfileOff,
          onTap: () => onVisibilityChanged(!isPublic),
          trailing: AppSwitch(
            value: isPublic,
            onChanged: onVisibilityChanged,
            semanticLabel: FounderToolsStrings.publicProfile,
          ),
        ),
      if (canDelete)
        _SettingCard(
          icon: AppIcons.trash,
          fill: AppColors.errorFill,
          color: AppColors.error,
          title: FounderToolsStrings.deleteStartup,
          text: FounderToolsStrings.deleteStartupText,
          danger: true,
          onTap: onDelete,
        ),
      if (role != StartupRole.founder)
        _SettingCard(
          icon: AppIcons.logout,
          fill: AppColors.errorFill,
          color: AppColors.error,
          title: FounderToolsStrings.leaveStartup,
          text: role == StartupRole.coFounder
              ? FounderToolsStrings.leaveCoFounderText
              : FounderToolsStrings.leaveMemberText,
          danger: true,
          onTap: onLeave,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          cards[i],
        ],
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  const _SettingCard({
    required this.icon,
    required this.fill,
    required this.color,
    required this.title,
    required this.text,
    required this.onTap,
    this.trailing,
    this.danger = false,
  });

  final String icon;
  final Color fill;
  final Color color;
  final String title;
  final String text;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title, $text',
      excludeSemantics: trailing == null,
      child: ManageCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AppIcon.filled(icon, size: 20, color: color),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.sans(
                      size: 16.5,
                      weight: FontWeight.w600,
                      color: danger ? AppColors.error : AppColors.ink,
                    ),
                  ),
                  Text(
                    text,
                    style: AppText.sans(
                      size: 14,
                      height: 20,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
  }
}
