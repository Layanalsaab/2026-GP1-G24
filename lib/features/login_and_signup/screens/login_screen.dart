import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../helpers/validators.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/login_view_model.dart';
import 'choose_role_screen.dart';
import 'forgot_password_screen.dart';

/// Figma: "V2 · 05 · Log In" and "V2 · 05c · Log In · Email not verified".
///
/// After sign up this screen opens with the new account filled in and the
/// "Verify your email" pop-up on top ([verifyEmail]). The same pop-up appears
/// when someone logs in with an email that isn't verified yet.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.initialEmail,
    this.initialPassword,
    this.verifyEmail = false,
    this.verificationEmailSent = true,
  });

  final String? initialEmail;

  /// Kept in memory only, so the verification email can be resent.
  final String? initialPassword;

  /// Open the "Verify your email" pop-up as soon as the screen shows.
  final bool verifyEmail;

  /// False when the verification email could not be sent after sign up.
  final bool verificationEmailSent;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _viewModel = LoginViewModel();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail ?? '';
    _password.text = widget.initialPassword ?? '';
    if (widget.verifyEmail) {
      _viewModel.promptVerification(
        email: _email.text,
        password: _password.text,
        emailSent: widget.verificationEmailSent,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showVerifyDialog();
      });
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final user = await _viewModel.submit(
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    if (user == null) {
      if (_viewModel.needsVerification) _showVerifyDialog();
      return;
    }
    AppRouter.openHome(context, user);
  }

  Future<void> _showVerifyDialog() async {
    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x800F1A12),
      builder: (_) => _VerifyEmailDialog(viewModel: _viewModel),
    );
    _viewModel.dismissVerification();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _email]),
      builder: (context, _) {
        final loading = _viewModel.isLoading;
        return FormPageScaffold(
          contentTopPadding: 4,
          bottomTopPadding: 8,
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                label: AppStrings.loginButton,
                isLoading: loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: loading
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChooseRoleScreen(),
                          ),
                        ),
                child: SizedBox(
                  height: 44,
                  child: Center(
                    child: Text.rich(
                      TextSpan(
                        text: '${AppStrings.loginNoAccount} ',
                        style: AppText.sans(
                          size: 14,
                          color: AppColors.grey,
                          height: 20,
                        ),
                        children: [
                          TextSpan(
                            text: AppStrings.signupLink,
                            style: AppText.sans(
                              size: 14,
                              color: AppColors.moss600,
                              weight: FontWeight.w600,
                              height: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                height: 58,
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.loginTitle,
                style: AppText.sans(
                  size: 22,
                  color: AppColors.ink,
                  weight: FontWeight.w600,
                  height: 28,
                ),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.emailLabel,
                hint: AppStrings.emailHint,
                controller: _email,
                rules: Validators.emailRules(_email.text),
                showRules: _viewModel.attempted,
                enabled: !loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _viewModel.fieldEdited(),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.passwordLabel,
                hint: AppStrings.loginPasswordHint,
                controller: _password,
                errorText: _viewModel.passwordError,
                enabled: !loading,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                onChanged: (_) => _viewModel.fieldEdited(),
              ),
              if (_viewModel.formError != null) ...[
                const SizedBox(height: 12),
                FormMessage.error(_viewModel.formError!),
              ],
              const SizedBox(height: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: loading
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                child: SizedBox(
                  height: 44,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppStrings.forgotPasswordLink,
                      style: AppText.sans(
                        size: 14,
                        color: AppColors.moss600,
                        weight: FontWeight.w500,
                        height: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Figma "Verify your email" dialog: envelope, the address, a spam hint, then
/// "Resend verification email" and "OK". Resending reports its result inside
/// the dialog.
class _VerifyEmailDialog extends StatelessWidget {
  const _VerifyEmailDialog({required this.viewModel});

  final LoginViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      elevation: 16,
      shadowColor: Colors.black,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final message = viewModel.resendMessage;
          final reminder = viewModel.verificationReminder;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.gold100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mail_outline_rounded,
                    size: 30,
                    color: AppColors.gold700,
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    reminder
                        ? AppStrings.verifyEmailReminderTitle
                        : AppStrings.verifyEmailTitle,
                    textAlign: TextAlign.center,
                    style: AppText.sans(
                      size: 20,
                      color: AppColors.ink,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    text: reminder
                        ? AppStrings.verifyEmailReminderBodyBefore
                        : AppStrings.verifyEmailBodyBefore,
                    style: AppText.sans(
                      size: 14,
                      color: AppColors.grey,
                      height: 21,
                    ),
                    children: [
                      TextSpan(
                        text: viewModel.verificationEmail,
                        style: AppText.sans(
                          size: 14,
                          color: AppColors.ink,
                          weight: FontWeight.w600,
                          height: 21,
                        ),
                      ),
                      TextSpan(
                        text: reminder
                            ? AppStrings.verifyEmailReminderBodyAfter
                            : AppStrings.verifyEmailBodyAfter,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.verifyEmailSpamHint,
                  textAlign: TextAlign.center,
                  style: AppText.sans(
                    size: 12,
                    color: AppColors.borderStrong,
                    height: 16,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 12),
                  viewModel.resendFailed
                      ? FormMessage.error(message)
                      : FormMessage.success(message),
                ],
                const SizedBox(height: 16),
                PrimaryButton(
                  label: AppStrings.resendVerification,
                  isLoading: viewModel.isResending,
                  onPressed: viewModel.resendVerification,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      AppStrings.verifyEmailOk,
                      style: AppText.sans(
                        size: 16,
                        color: AppColors.moss600,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
