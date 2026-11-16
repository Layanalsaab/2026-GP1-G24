import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../models/list_entries.dart';
import 'founder_ui.dart';
import 'view_only_banner.dart';
import 'manage_card.dart';

/// Manage startup -> Settings: one white card per row, each a full-width
/// button with a 40 px icon tile, a title with sub-text and, where needed, a
/// control on the right (docs: Closing a Startup, Leaving and Deleting an
/// Account).
///
/// Everything here is the founder's (co-founders and team members only see
/// that there is nothing to change):
///
/// * **Public startup / Private startup** (globe, a switch), also on a
///   closed startup (the one thing left to change there).
/// * **Close startup** (an active startup; permanent, kept for everyone).
/// * **Delete startup** (permanent, for everyone; asks for his password).
/// * **Leave startup** is not here: it sits at the bottom of the Startup
///   Team tab ([ManageLeaveSection]).
///
/// What a role cannot do is not shown at all.
class ManageSettingsTab extends StatelessWidget {
  const ManageSettingsTab({
    super.key,
    required this.role,
    required this.startupName,
    required this.isPublic,
    required this.onVisibilityChanged,
    this.isClosed = false,
    this.onClose,
    this.onDelete,
  });

  /// What the user may do here ([StartupRole.founder]: everything).
  final StartupRole role;
  final String startupName;
  final bool isPublic;
  final ValueChanged<bool> onVisibilityChanged;
  final bool isClosed;
  final VoidCallback? onClose;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final owner = role == StartupRole.founder;
    final cards = <Widget>[
      if (owner)
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
      if (owner)
        _SettingCard(
          icon: AppIcons.trash,
          fill: AppColors.errorFill,
          color: AppColors.error,
          title: FounderToolsStrings.deleteStartup,
          text: FounderToolsStrings.deleteStartupText,
          danger: true,
          onTap: onDelete ?? () {},
        ),
    ];
    if (cards.isEmpty) {
      // A team member of a closed startup: nothing to change.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          isClosed
              ? FounderToolsStrings.closedNoSettings
              : FounderToolsStrings.noSettings,
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

/// Manage startup -> Startup Team, below the team: **Leave startup** (the
/// founder names the next founder, then whether he stays on the team). While
/// a person he invited to take over hasn't answered, a "Waiting for…" card
/// with **Resend email** and **Cancel invitation** replaces Leave.
/// Co-founders and team members of an active startup just see Leave startup.
/// Nobody leaves a closed startup, so it shows nothing then.
class ManageLeaveSection extends StatelessWidget {
  const ManageLeaveSection({
    super.key,
    required this.role,
    required this.startupName,
    required this.onLeave,
    this.isClosed = false,
    this.pendingOwnerEmail,
    this.onCancelOwnerInvite,
    this.ownerInviteDaysLeft,
    this.onResendOwnerInvite,
    this.expiredOwnerEmail,
  });

  final StartupRole role;
  final String startupName;
  final VoidCallback onLeave;
  final bool isClosed;

  /// The e-mail of the person invited to take over, still waiting.
  final String? pendingOwnerEmail;
  final VoidCallback? onCancelOwnerInvite;

  /// Days left of the waiting invitation (null: unknown), and "Resend email".
  final int? ownerInviteDaysLeft;
  final VoidCallback? onResendOwnerInvite;

  /// An invitation that ended after 30 days without an answer.
  final String? expiredOwnerEmail;

  @override
  Widget build(BuildContext context) {
    if (isClosed) return const SizedBox.shrink();
    final owner = role == StartupRole.founder;
    final cards = <Widget>[
      if (owner && !isClosed && pendingOwnerEmail != null) ...[
        _SettingCard(
          icon: AppIcons.mail,
          fill: AppColors.moss50,
          color: AppColors.moss600,
          title: FounderToolsStrings.resendEmail,
          text: FounderToolsStrings.ownerResendText(ownerInviteDaysLeft),
          onTap: onResendOwnerInvite ?? () {},
        ),
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
        ),
      ] else if (!isClosed) ...[
        if (owner && expiredOwnerEmail != null)
          ViewOnlyBanner.notice(
            title: FounderToolsStrings.ownerInviteExpiredTitle,
            message: FounderToolsStrings.ownerInviteExpiredText(
              expiredOwnerEmail!,
            ),
          ),
        _SettingCard(
          icon: AppIcons.logout,
          fill: AppColors.errorFill,
          color: AppColors.error,
          title: FounderToolsStrings.leaveStartup,
          text: owner
              ? FounderToolsStrings.leaveFounderText
              : role == StartupRole.coFounder
              ? FounderToolsStrings.leaveCoFounderText
              : FounderToolsStrings.leaveMemberText,
          danger: true,
          onTap: onLeave,
        ),
      ],
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
