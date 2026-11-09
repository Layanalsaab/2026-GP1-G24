import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/list_entries.dart';
import 'founder_ui.dart';
import 'manage_card.dart';

/// Manage startup -> Settings: one white card per row, each a full-width
/// button with a 40 px icon tile, a title with sub-text and, where needed, a
/// control on the right (docs: Closing a Startup, Leaving and Deleting an
/// Account).
///
/// * **Public startup / Private startup** (globe, a switch): the owner and
///   co-founders of an active startup; on a closed startup only its owner
///   (it is the one thing left to change).
/// * The owner of an active startup: **Close startup** (permanent, kept for
///   everyone) and **Leave startup** (she names the next owner first). While
///   a person she invited to take over hasn't answered, a "Waiting for…" card
///   with **Cancel invitation** replaces Leave.
/// * Co-founders and team members of an active startup: **Leave startup**.
/// * Nobody leaves a closed startup.
///
/// What a role cannot do is not shown at all.
class ManageSettingsTab extends StatelessWidget {
  const ManageSettingsTab({
    super.key,
    required this.role,
    required this.startupName,
    required this.isPublic,
    required this.onVisibilityChanged,
    required this.onLeave,
    this.isClosed = false,
    this.onClose,
    this.pendingOwnerEmail,
    this.onCancelOwnerInvite,
  });

  /// What the user may do here ([StartupRole.founder] is the owner).
  final StartupRole role;
  final String startupName;
  final bool isPublic;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onLeave;
  final bool isClosed;
  final VoidCallback? onClose;

  /// The e-mail of the person invited to take over, still waiting.
  final String? pendingOwnerEmail;
  final VoidCallback? onCancelOwnerInvite;

  @override
  Widget build(BuildContext context) {
    final owner = role == StartupRole.founder;
    final cards = <Widget>[
      if ((role.canManage && !isClosed) || (owner && isClosed))
        _SettingCard(
          icon: AppIcons.globe,
          fill: AppColors.moss50,
          color: AppColors.moss600,
          // The title follows the switch: "Public startup" / "Private
          // startup".
          title: isPublic
              ? FounderToolsStrings.visibilityPublicTitle
              : FounderToolsStrings.visibilityPrivateTitle,
          text: isClosed
              ? (isPublic
                    ? FounderToolsStrings.closedPublicText
                    : FounderToolsStrings.closedPrivateText)
              : (isPublic
                    ? FounderToolsStrings.publicProfileOn
                    : FounderToolsStrings.publicProfileOff),
          onTap: () => onVisibilityChanged(!isPublic),
          trailing: AppSwitch(
            value: isPublic,
            onChanged: onVisibilityChanged,
            semanticLabel: isPublic
                ? FounderToolsStrings.visibilityPublicTitle
                : FounderToolsStrings.visibilityPrivateTitle,
          ),
        ),
      if (owner && !isClosed)
        _SettingCard(
          icon: AppIcons.lock,
          fill: AppColors.errorFill,
          color: AppColors.error,
          title: FounderToolsStrings.closeStartup,
          text: FounderToolsStrings.closeStartupText,
          danger: true,
          onTap: onClose ?? () {},
        ),
      if (owner && !isClosed && pendingOwnerEmail != null)
        _SettingCard(
          icon: AppIcons.people,
          fill: AppColors.moss50,
          color: AppColors.moss600,
          title: FounderToolsStrings.cancelInvitation,
          text: FounderToolsStrings.ownerWaiting(
            pendingOwnerEmail!,
            startupName,
          ),
          onTap: onCancelOwnerInvite ?? () {},
        )
      else if (!isClosed)
        _SettingCard(
          icon: AppIcons.logout,
          fill: AppColors.errorFill,
          color: AppColors.error,
          title: FounderToolsStrings.leaveStartup,
          text: owner
              ? FounderToolsStrings.leaveOwnerText
              : role == StartupRole.coFounder
              ? FounderToolsStrings.leaveCoFounderText
              : FounderToolsStrings.leaveMemberText,
          danger: true,
          onTap: onLeave,
        ),
    ];
    if (cards.isEmpty) {
      // A team member of a closed startup: nothing to change.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          FounderToolsStrings.closedNoSettings,
          style: AppText.sans(size: 14, height: 20, color: AppColors.grey),
        ),
      );
    }
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
