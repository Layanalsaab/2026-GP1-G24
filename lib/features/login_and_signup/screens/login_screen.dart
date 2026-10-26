import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/app_text_field.dart';
import '../../../shared_ui/widgets/headers/auth_headers.dart';
import '../../../shared_ui/widgets/headers/overlap_layout.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../view_models/login_view_model.dart';
import '../view_models/verify_email_view_model.dart';
import '../widgets/auth_navigation.dart';
import '../widgets/resend_row.dart';
import 'forgot_password_screen.dart';

/// Log in (docs/05 A12): email and password; an unverified account gets the
/// "Verify your email" dialog ending "...then log in."
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.email});

  /// An e-mail to start with (the one an invitation was sent to).
  final String? email;

  /// Pushes Log in (Welcome, Choose role and the sign-up footers).
  static void open(BuildContext context, {String? email}) =>
      AppNav.push(context, LoginScreen(email: email), greenHeader: true);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginViewModel _vm = LoginViewModel();

  @override
  void initState() {
    super.initState();
    final start = widget.email;
    if (start != null && _vm.email.text.isEmpty) _vm.email.text = start;
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = await _vm.submit();
    if (!mounted) return;
    if (user != null) {
      AppRouter.openAfterLogin(context, user, welcomeBack: true);
    } else if (_vm.needsVerification) {
      _showVerifyDialog();
    } else {
      AppToast.error(context, _vm.formError ?? ValidationStrings.fixFields);
    }
  }

  void _showVerifyDialog() {
    showAppDialog<void>(
      context,
      builder: (ctx) => VerifyEmailDialog(
        email: _vm.verificationEmail,
        needLogin: true,
        notVerifiedYet: true,
        onClose: () => Navigator.of(ctx).pop(),
        below: _LoginResend(vm: _vm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final vm = _vm;
        return Scaffold(
          backgroundColor: AppColors.cream,
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  title: AuthStrings.loginTitle,
                  onBack: () => authBack(context),
                ),
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: AppButton(
                          label: AuthStrings.logIn,
                          onPressed: _submit,
                          loading: vm.isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The resend row of the "Email not verified yet" pop-up: the same row and
/// 60 s countdown as the Verify step.
class _LoginResend extends StatelessWidget {
  const _LoginResend({required this.vm});

  final LoginViewModel vm;

  Future<void> _resend(BuildContext context) async {
    final outcome = await vm.resend();
    if (!context.mounted) return;
    switch (outcome) {
      case ResendOutcome.sent:
        break; // the countdown starting is the feedback
      case ResendOutcome.alreadyVerified:
        AppToast.show(context, AuthStrings.alreadyVerifiedLogin);
      case ResendOutcome.failed:
        final error = vm.formError;
        if (error != null) AppToast.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => ResendRow(
        seconds: vm.resendSeconds,
        error: vm.resendError,
        busy: vm.isResending,
        onResend: () => _resend(context),
        divider: false,
      ),
    );
  }
}
