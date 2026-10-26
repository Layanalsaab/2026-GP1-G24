import 'package:flutter/material.dart';

import '../../../models/invitation.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';

/// "{Startup} invited you as a Co-founder": Accept or Decline. Completes with
/// true (accept), false (decline), or null when it is dismissed (decide
/// later: the invitation stays pending).
Future<bool?> showInvitationDecision(
  BuildContext context,
  Invitation invitation,
) {
  final who = invitation.invitedByName.trim().isEmpty
      ? 'A founder'
      : invitation.invitedByName.trim();
  final role = invitation.isCoFounder ? 'a co-founder' : 'a team member';
  return showAppDialog<bool>(
    context,
    builder: (ctx) => AppDialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _DialogIcon(),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              'Join ${invitation.startupName}?',
              textAlign: TextAlign.center,
              style: AppText.sans(size: 21, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$who invited you to join ${invitation.startupName} as $role.',
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

/// Sign-up as an investor with an e-mail that was invited to a team:
/// "Join the team" (true) or "Continue as investor" (false). Dismissing it
/// completes with null and stays on the form.
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
          const _DialogIcon(),
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

class _DialogIcon extends StatelessWidget {
  const _DialogIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Pop(
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.moss100,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const AppIcon.filled(
            AppIcons.people,
            size: 28,
            color: AppColors.moss600,
          ),
        ),
      ),
    );
  }
}
