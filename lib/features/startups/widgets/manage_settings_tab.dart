import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/list_entries.dart';
import '../../../models/startup.dart';
import 'founder_ui.dart';
import 'manage_card.dart';

/// Manage startup -> Settings: one white card per row, each a full-width
/// button with a 40 px icon tile, a title with sub-text and, where needed, a
/// control on the right.
///
/// * **Public startup / Private startup** (owner and co-founder, not on a closed startup):
///   globe, a switch.
/// * The owner gets ONE way to end the startup ([ownerOption]):
///   **Delete startup** (nobody else on it), **Transfer ownership** (a
///   co-founder joined) or **Close startup** (only members).
/// * A closed startup: the owner gets **Reopen startup** and **Leave
///   startup** (nobody owns it afterwards).
/// * **Leave startup** (co-founder and team member): red leave icon, red
///   title.
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
    this.ownerOption = OwnerOption.delete,
    this.isClosed = false,
    this.onTransfer,
    this.onClose,
    this.onReopen,
    this.isFounder = false,
  });

  /// What the user may do here ([StartupRole.founder] is the owner).
  final StartupRole role;
  final bool isPublic;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onDelete;
  final VoidCallback onLeave;
  final OwnerOption ownerOption;
  final bool isClosed;
  final VoidCallback? onTransfer;
  final VoidCallback? onClose;
  final VoidCallback? onReopen;

  /// The user created this startup (the Founder title), whether or not they
  /// still own it.
  final bool isFounder;

  @override
  Widget build(BuildContext context) {
    final owner = role == StartupRole.founder;
    final cards = <Widget>[
      if (role.canManage && !isClosed)
        _SettingCard(
          icon: AppIcons.globe,
          fill: AppColors.moss50,
          color: AppColors.moss600,
          // The title follows the switch: "Public startup" / "Private
          // startup".
          title: isPublic
              ? FounderToolsStrings.visibilityPublicTitle
              : FounderToolsStrings.visibilityPrivateTitle,
          text: isPublic
              ? FounderToolsStrings.publicProfileOn
              : FounderToolsStrings.publicProfileOff,
          onTap: () => onVisibilityChanged(!isPublic),
          trailing: AppSwitch(
            value: isPublic,
            onChanged: onVisibilityChanged,
            semanticLabel: isPublic
                ? FounderToolsStrings.visibilityPublicTitle
                : FounderToolsStrings.visibilityPrivateTitle,
          ),
        ),
      if (owner && isClosed)
        _SettingCard(
          icon: AppIcons.rocket,
          fill: AppColors.moss50,
          color: AppColors.moss600,
          title: FounderToolsStrings.reopenStartup,
          text: FounderToolsStrings.reopenStartupText,
          onTap: onReopen ?? () {},
        ),
      // Nobody else on it (also once closed): it can be deleted.
      if (owner && ownerOption == OwnerOption.delete)
        _SettingCard(
          icon: AppIcons.trash,
          fill: AppColors.errorFill,
          color: AppColors.error,
          title: FounderToolsStrings.deleteStartup,
          text: FounderToolsStrings.deleteStartupText,
          danger: true,
          onTap: onDelete,
        ),
      if (owner && !isClosed && ownerOption == OwnerOption.transfer)
        _SettingCard(
          icon: AppIcons.people,
          fill: AppColors.moss50,
          color: AppColors.moss600,
          title: FounderToolsStrings.transferOwnership,
          text: FounderToolsStrings.transferOwnershipText,
          onTap: onTransfer ?? () {},
        ),
      if (owner && !isClosed && ownerOption == OwnerOption.close)
        _SettingCard(
          icon: AppIcons.lock,
          fill: AppColors.errorFill,
          color: AppColors.error,
          title: FounderToolsStrings.closeStartup,
          text: FounderToolsStrings.closeStartupText,
          danger: true,
          onTap: onClose ?? () {},
        ),
      // The owner leaves only a closed startup that has a team (an active
      // one is handed over or deleted, and an empty one deleted, never left
      // behind).
      if (!owner || (isClosed && ownerOption != OwnerOption.delete))
        _SettingCard(
          icon: AppIcons.logout,
          fill: AppColors.errorFill,
          color: AppColors.error,
          title: FounderToolsStrings.leaveStartup,
          text: owner
              ? FounderToolsStrings.leaveClosedOwnerText
              : isFounder
              ? FounderToolsStrings.leaveFounderText
              : role == StartupRole.coFounder
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
