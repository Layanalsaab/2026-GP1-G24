import 'package:flutter/material.dart';

import '../../../app_constants/app_config.dart';
import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/repositories/invitation_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../models/app_user.dart';
import '../../../models/invitation.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../../login_and_signup/screens/login_screen.dart';
import '../../login_and_signup/screens/signup_screen.dart';

/// Where the "Open Start.sa" button of the invitation e-mail lands when the
/// app is installed: who invited you, to which startup and as what, with the
/// e-mail to use. A person with no account creates one; somebody who is
/// already signed in with that e-mail accepts or declines.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key, required this.invitationId});

  final String invitationId;

  static void open(BuildContext context, String invitationId) => AppNav.push(
    context,
    InviteScreen(invitationId: invitationId),
    greenHeader: true,
  );

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  Invitation? _invitation;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    Invitation? found;
    try {
      found = await InvitationRepository.instance.byId(widget.invitationId);
    } catch (_) {
      found = null;
    }
    if (!mounted) return;
    // Nobody is signed in: go straight to the screen that fits, with the
    // invited e-mail filled in. No account yet -> "Create your account";
    // an account already -> "Log in".
    if (found != null && found.isPending && AppSession.instance.user == null) {
      if (found.newUser) {
        SignupScreen.openReplacing(
          context,
          AccountRole.founder,
          email: found.emailLower,
        );
      } else {
        Navigator.of(context).pushReplacement(
          AppRoute<void>(
            builder: (_) => LoginScreen(email: found!.emailLower),
            greenHeader: true,
          ),
        );
      }
      return;
    }
    setState(() {
      _invitation = found;
      _loading = false;
    });
  }

  AppUser? get _me => AppSession.instance.user;

  bool get _signedInAsInvited =>
      _me != null &&
      _me!.isFounder &&
      _me!.email.trim().toLowerCase() == _invitation?.emailLower;

  /// Signed in with an investor account that has the invited email: it can't
  /// join a team, and logging out would not help.
  bool get _investorWithThatEmail =>
      _me != null &&
      !_me!.isFounder &&
      _me!.email.trim().toLowerCase() == _invitation?.emailLower;

  /// Signs out and opens Log in (or Create your account for somebody who
  /// has none) with the invited email already filled in.
  Future<void> _logOutAndContinue(Invitation inv) => AppRouter.logOut(
    context,
    toLogin: true,
    email: inv.emailLower,
    signup: inv.newUser,
  );

  Future<void> _answer(bool accept) async {
    final invitation = _invitation;
    final me = _me;
    if (invitation == null || me == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (accept) {
        await InvitationRepository.instance.accept(
          invitation,
          fullName: me.fullName,
        );
      } else {
        await InvitationRepository.instance.decline(invitation);
      }
      if (!mounted) return;
      if (accept) {
        AppToast.showGlobal(
          invitation.isOwner
              ? FounderToolsStrings.noticeNewOwnerTitle(invitation.startupName)
              : 'You’ve been added to ${invitation.startupName}',
        );
      }
      AppRouter.openHome(context);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        AppToast.error(context, FounderToolsStrings.inviteJoinFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = _invitation;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : (inv != null && inv.isExpired(DateTime.now()))
                  ? _unavailable(FounderToolsStrings.inviteExpired)
                  : (inv == null || !inv.isPending)
                  ? _unavailable()
                  : _details(inv),
            ),
          ),
        ),
      ),
    );
  }

  Widget _unavailable([
    String message = 'This invitation is no longer active.',
  ]) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        message,
        textAlign: TextAlign.center,
        style: AppText.sans(size: 20, weight: FontWeight.w700),
      ),
      const SizedBox(height: 18),
      AppButton(
        label: 'Continue',
        onPressed: () => AppRouter.openHome(context),
      ),
    ],
  );

  Widget _details(Invitation inv) {
    final who = inv.invitedByName.trim().isEmpty
        ? 'A founder'
        : inv.invitedByName.trim();
    final role = inv.isCoFounder ? 'a co-founder' : 'a team member';
    // Invited to take the startup over as its owner.
    final owner = inv.isOwner;
    final me = _me;
    final other = me != null && !_signedInAsInvited;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: TileAvatar(
            initials: appInitials(inv.startupName),
            tone: TileTone.gold,
            size: 64,
            radius: 18,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          owner
              ? 'You’re invited to take over ${inv.startupName}'
              : 'You’re invited to join ${inv.startupName}',
          textAlign: TextAlign.center,
          style: AppText.sans(size: 21, weight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          owner
              ? '$who invited you to become the owner of ${inv.startupName}. You would have full control of it, including its team, its visibility and its settings.'
              : '$who invited you as $role${inv.roleText.trim().isEmpty ? '' : ' (${inv.roleText.trim()})'}.',
          textAlign: TextAlign.center,
          style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            style: AppText.sans(size: 14, color: AppColors.grey, height: 21),
            children: [
              const TextSpan(text: 'Use this email: '),
              TextSpan(
                text: inv.emailLower,
                style: AppText.sans(
                  size: 14,
                  weight: FontWeight.w700,
                  height: 21,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 22),
        if (_signedInAsInvited) ...[
          AppButton(
            label: owner
                ? 'Become the owner'
                : AppConfig.autoJoinExistingAccounts
                ? 'Join the team'
                : 'Accept',
            loading: _busy,
            onPressed: () => _answer(true),
          ),
          // Taking a startup over can always be declined; joining a team
          // can when it isn't automatic.
          if (owner || !AppConfig.autoJoinExistingAccounts) ...[
            const SizedBox(height: 4),
            AppButton(
              label: 'Decline',
              variant: AppButtonVariant.ghost,
              onPressed: _busy ? null : () => _answer(false),
            ),
          ],
        ] else if (_investorWithThatEmail) ...[
          // Logging out would not help: an investor account can't join.
          Text(
            FounderToolsStrings.inviteInvestorAccount,
            textAlign: TextAlign.center,
            style: AppText.sans(size: 14, color: AppColors.grey, height: 21),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Continue',
            onPressed: () => AppRouter.openHome(context),
          ),
        ] else if (other) ...[
          // Somebody else is signed in on this phone: one tap signs them out
          // and opens Log in (or Create account) with the invited email.
          Text(
            FounderToolsStrings.inviteSignedInAs(me.email, inv.emailLower),
            textAlign: TextAlign.center,
            style: AppText.sans(size: 14, color: AppColors.grey, height: 21),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: FounderToolsStrings.inviteLogOutContinue,
            onPressed: () => _logOutAndContinue(inv),
          ),
          const SizedBox(height: 4),
          AppButton(
            label: FounderToolsStrings.inviteStayHere,
            variant: AppButtonVariant.ghost,
            onPressed: () => AppRouter.openHome(context),
          ),
        ] else ...[
          AppButton(
            label: 'Create account',
            onPressed: () => SignupScreen.open(
              context,
              AccountRole.founder,
              email: inv.emailLower,
            ),
          ),
          const SizedBox(height: 4),
          AppButton(
            label: 'Log in',
            variant: AppButtonVariant.ghost,
            onPressed: () => LoginScreen.open(context, email: inv.emailLower),
          ),
        ],
      ],
    );
  }
}
