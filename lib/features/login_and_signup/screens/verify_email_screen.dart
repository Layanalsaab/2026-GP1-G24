import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/repositories/team_lookup.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/invitation_claimer.dart';
import '../../../helpers/app_session.dart';
import '../../../models/app_user.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/app_text_field.dart';
import '../../../shared_ui/widgets/forms/form_page.dart';
import '../../../shared_ui/widgets/headers/auth_headers.dart';
import '../../../shared_ui/widgets/headers/overlap_layout.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../../startups/screens/startup_steps_screen.dart';
import '../view_models/signup_flow.dart';
import '../view_models/verify_email_view_model.dart';
import '../widgets/resend_row.dart';
import 'forgot_password_screen.dart';
import 'investor_investments_screen.dart';
import 'signup_screen.dart';

/// Sign-up step 2, "Verify your email" (docs/05 A8). Arrives with the verify
/// dialog open; the user opens the emailed link, comes back, enters email and
/// password and taps Continue, which signs in and checks the email is verified.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.flow,
    this.showDialogOnOpen = true,
  });

  final SignupFlow flow;

  /// Show the "Verify your email" dialog as soon as the screen appears.
  final bool showDialogOnOpen;

  /// Pushes step 2 after step 1 created the account (dialog shown).
  static void open(BuildContext context, SignupFlow flow) =>
      AppNav.push(context, VerifyEmailScreen(flow: flow), greenHeader: true);

  /// Returns to step 2 from the first onboarding step after it (the Back arrow
  /// of founder step 3 and of investor step 3): replaces the stack, back
  /// transition, no dialog.
  static void openFromOnboarding(BuildContext context) {
    final flow = SignupFlow.current;
    if (flow == null) {
      // They logged in (no sign-up in progress), so there is no Verify step to
      // go back to: leaving the form logs them out and returns to Welcome.
      AppRouter.logOut(context);
      return;
    }
    AppNav.reset(
      context,
      VerifyEmailScreen(flow: flow, showDialogOnOpen: false),
      kind: RouteKind.back,
      greenHeader: true,
    );
  }

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  late final VerifyEmailViewModel _vm = VerifyEmailViewModel(flow: widget.flow);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.showDialogOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showDialog();
        if (!widget.flow.emailSent) {
          AppToast.error(context, _sendFailed);
        }
      });
    }
  }

  static const _sendFailed =
      'We couldn’t send the verification email. Tap “Resend email” to try again.';

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The countdown is derived from an end time, so just re-sync it.
    if (state == AppLifecycleState.resumed) _vm.refreshCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vm.dispose();
    super.dispose();
  }

  void _back() {
    if (Navigator.of(context).canPop()) {
      AppNav.back(context);
    } else {
      // Arrived by reset from step 3: step 1 is not on the stack any more.
      AppNav.reset(
        context,
        SignupScreen(role: widget.flow.role, flow: widget.flow),
        kind: RouteKind.back,
        greenHeader: true,
      );
    }
  }

  void _showDialog({bool notVerified = false}) {
    showAppDialog<void>(
      context,
      builder: (ctx) => VerifyEmailDialog(
        email: widget.flow.email,
        inSignup: true,
        notVerifiedYet: notVerified,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  /// Sends the email again. No toast when it works: the countdown restarting
  /// is the feedback. "Too many attempts" shows under the resend row.
  Future<void> _resend() async {
    final outcome = await _vm.resend();
    if (!mounted) return;
    switch (outcome) {
      case ResendOutcome.sent:
        break;
      case ResendOutcome.alreadyVerified:
        AppToast.show(context, AuthStrings.alreadyVerified);
      case ResendOutcome.failed:
        final error = _vm.formError;
        if (error != null) AppToast.error(context, error);
    }
  }

  Future<void> _continue() async {
    final result = await _vm.submit();
    if (!mounted) return;
    switch (result) {
      case VerifyResult.invalid:
      case VerifyResult.wrongPassword:
        // The errors are under the fields; the pop-up says to fix them.
        AppToast.error(context, ValidationStrings.fixFields);
      case VerifyResult.notVerified:
        _showDialog(notVerified: true);
      case VerifyResult.failed:
        AppToast.error(context, _vm.formError ?? '');
      case VerifyResult.verified:
        _onVerified(_vm.user!);
    }
  }

  Future<void> _onVerified(AppUser user) async {
    AppSession.instance.signIn(user);
    // Teams can find this account by e-mail from now on.
    unawaited(TeamLookup.instance.publish(user, emailVerified: true));
    if (user.role == AccountRole.founder) {
      // A new account joins every team that invited its e-mail, and then has
      // no need to create a startup first.
      final joined = await InvitationClaimer.acceptAll(user);
      if (!mounted) return;
      if (joined.isNotEmpty) {
        SignupFlow.current = null;
        try {
          await UserRepository.instance.completeOnboarding(user.uid);
        } catch (_) {}
        if (!mounted) return;
        AppRouter.openHome(context);
        AppToast.showGlobal(InvitationClaimer.addedMessage(joined));
        return;
      }
      StartupStepsScreen.openOnboarding(context);
    } else {
      // An investor can't join a team: whatever invited this e-mail is
      // marked declined.
      await InvitationClaimer.declineAll();
      if (!mounted) return;
      InvestorInvestmentsScreen.open(context, user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          final vm = _vm;
          return FormPageScaffold(
            header: StepHeader(
              step: 2,
              total: widget.flow.totalSteps,
              title: AuthStrings.verifyTitle,
              onBack: _back,
            ),
            footer: FormFooter(
              primary: AppButton(
                label: AuthStrings.continueLabel,
                onPressed: _continue,
                loading: vm.isLoading,
              ),
            ),
            children: [
              AuthCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormFieldColumn(
                      children: [
                        LabeledTextField(
                          label: AuthStrings.email,
                          required: true,
                          controller: vm.email,
                          placeholder: AuthStrings.emailPlaceholder,
                          keyboardType: TextInputType.emailAddress,
                          valid: vm.emailValid,
                          error: vm.emailError,
                          autofillHints: const [AutofillHints.email],
                        ),
                        LabeledTextField(
                          label: AuthStrings.password,
                          required: true,
                          controller: vm.password,
                          placeholder: AuthStrings.passwordPlaceholderLogin,
                          password: true,
                          error: vm.passwordError,
                          linkLabel: AuthStrings.forgotLink,
                          onLink: () => ForgotPasswordScreen.open(
                            context,
                            email: vm.email.text.trim(),
                          ),
                          autofillHints: const [AutofillHints.password],
                        ),
                      ],
                    ),
                    ResendRow(
                      seconds: vm.resendSeconds,
                      error: vm.resendError,
                      busy: vm.isResending,
                      onResend: _resend,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
