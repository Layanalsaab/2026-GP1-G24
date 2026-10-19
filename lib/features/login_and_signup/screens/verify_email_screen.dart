import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../models/app_user.dart';
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
import 'forgot_password_screen.dart';
import 'investor_investments_screen.dart';
import 'signup_screen.dart';
import 'welcome_screen.dart';

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
      WelcomeScreen.open(context);
      return;
    }
    AppNav.reset(
      context,
      VerifyEmailScreen(flow: flow, showDialogOnOpen: false),
      kind: RouteKind.back,
      greenHeader: true,
    );
  }

  /// A founder logged in but never created a startup: the account is not
  /// complete, so they authenticate again on this step (the Firebase session
  /// is closed first) before they can continue to "Add your startup".
  static Future<void> openForIncompleteFounder(
    BuildContext context,
    AppUser user,
  ) async {
    try {
      await AuthRepository.instance.signOut();
    } catch (_) {}
    AppSession.instance.signOut();
    final flow = SignupFlow(role: AccountRole.founder)
      ..email = user.email
      ..createdRole = AccountRole.founder
      ..accountCreated = true
      ..fromLogin = true;
    SignupFlow.current = flow;
    if (!context.mounted) return;
    AppNav.reset(
      context,
      VerifyEmailScreen(flow: flow, showDialogOnOpen: false),
      kind: RouteKind.fade,
      greenHeader: true,
    );
  }

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final VerifyEmailViewModel _vm = VerifyEmailViewModel(flow: widget.flow);

  @override
  void initState() {
    super.initState();
    if (widget.showDialogOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showDialog();
        if (!widget.flow.emailSent) {
          AppToast.show(context, _sendFailed);
        }
      });
    }
  }

  static const _sendFailed =
      'We couldn’t send the verification email. Tap “Resend verification email” to try again.';

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _back() {
    if (widget.flow.fromLogin) {
      WelcomeScreen.open(context);
    } else if (Navigator.of(context).canPop()) {
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

  void _showDialog() {
    showAppDialog<void>(
      context,
      builder: (ctx) => VerifyEmailDialog(
        email: widget.flow.email,
        inSignup: true,
        onResend: () {
          Navigator.of(ctx).pop();
          _resend(AuthStrings.verifyEmailSent);
        },
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _resend(String sentMessage) async {
    final outcome = await _vm.resend();
    if (!mounted) return;
    switch (outcome) {
      case ResendOutcome.sent:
        AppToast.show(context, sentMessage);
      case ResendOutcome.alreadyVerified:
        AppToast.show(context, AuthStrings.alreadyVerified);
      case ResendOutcome.failed:
        AppToast.show(context, _vm.formError ?? '');
    }
  }

  Future<void> _continue() async {
    final result = await _vm.submit();
    if (!mounted) return;
    switch (result) {
      case VerifyResult.invalid:
      case VerifyResult.wrongPassword:
        break; // The errors are already under the fields.
      case VerifyResult.notVerified:
        _showDialog();
      case VerifyResult.failed:
        AppToast.show(context, _vm.formError ?? '');
      case VerifyResult.verified:
        _onVerified(_vm.user!);
    }
  }

  void _onVerified(AppUser user) {
    AppSession.instance.signIn(user);
    AppToast.show(context, AuthStrings.emailVerified);
    if (user.role == AccountRole.founder) {
      StartupStepsScreen.openOnboarding(context);
    } else {
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
              link: FooterLink(
                prefix: AuthStrings.verifyDidntGet,
                linkLabel: AuthStrings.resendEmail,
                onTap: () =>
                    _resend(AuthStrings.verifyEmailSentTo(widget.flow.email)),
              ),
            ),
            children: [
              AuthCard(
                child: FormFieldColumn(
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
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
