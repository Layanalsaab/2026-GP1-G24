import 'package:flutter/material.dart';

import '../../../models/invitation.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';

/// "{Startup} invited you as a Co-founder": Accept or Decline.
Future<bool?> showInvitationDecision(
  BuildContext context,
  Invitation invitation,
) {
  final who = invitation.invitedByName.trim().isEmpty
      ? 'A founder'
      : invitation.invitedByName.trim();
  final role = invitation.isCoFounder ? 'a co-founder' : 'a team member';
  // Invited to take the startup over as its owner.
  final owner = invitation.isOwner;
  return showAppDialog<bool>(
    context,
    builder: (ctx) => AppDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DialogIcon(),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              owner
                  ? 'Become the founder of ${invitation.startupName}?'
                  : 'Join ${invitation.startupName}?',
              textAlign: TextAlign.center,
              style: AppText.sans(size: 21, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            owner
                ? '$who invited you to take over ${invitation.startupName} as its founder. You would have full control of it, including its team, its visibility and its settings.'
                : '$who invited you to join ${invitation.startupName} as $role.',
            textAlign: TextAlign.center,
            style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
          ),
          const SizedBox(height: 22),
          AppButton(
            label: 'Accept',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: 4),
          AppButton(
            label: 'Decline',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    ),
  );
}

Future<bool?> showInvitedInvestorDialog(
  BuildContext context,
  List<String> startupNames,
) {
  final one = startupNames.length == 1;
  final names = one ? startupNames.first : '${startupNames.length} startups';
  return showAppDialog<bool>(
    context,
    builder: (ctx) => AppDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DialogIcon(),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              'You’ve been invited',
              textAlign: TextAlign.center,
              style: AppText.sans(size: 21, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$names ${one ? 'has' : 'have'} invited this email to join '
            '${one ? 'its' : 'their'} team. If you continue as an investor, '
            'you can’t join ${one ? 'the team' : 'the teams'} later. '
            'Do you want to continue as an investor?',
            textAlign: TextAlign.center,
            style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
          ),
          const SizedBox(height: 22),
          AppButton(
            label: 'Join the team',
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
          const SizedBox(height: 4),
          AppButton(
            label: 'Continue as investor',
            variant: AppButtonVariant.ghost,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
        ],
      ),
    ),
  );
}

class DialogIcon extends StatelessWidget {
  const DialogIcon({super.key, this.icon = AppIcons.people});

  final String icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Pop(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.moss100,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: AppIcon.filled(icon, size: 28, color: AppColors.mossText),
        ),
      ),
    );
  }
}
