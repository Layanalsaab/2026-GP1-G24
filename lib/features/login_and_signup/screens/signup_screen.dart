import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/signup_view_model.dart';
import 'check_email_screen.dart';
import 'login_screen.dart';

/// Figma: "V2 · 04 · Create Account"
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.role});

  final AccountRole role;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _viewModel = SignupViewModel();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _viewModel.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final result = await _viewModel.submit(
      fullName: _name.text,
      email: _email.text,
      password: _password.text,
      confirmPassword: _confirm.text,
      role: widget.role,
    );
    if (result == null || !mounted) return;

    // Clear the history down to the Start screen so Back can't return to the form.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => CheckEmailScreen(
          email: _email.text.trim(),
          password: _password.text,
          verificationEmailSent: result.verificationEmailSent,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final loading = _viewModel.isLoading;
        return FormPageScaffold(
          progressSteps: 2,
          contentTopPadding: 4,
          bottomTopPadding: 8,
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_viewModel.formError != null) ...[
                FormMessage.error(_viewModel.formError!),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                label: AppStrings.signupButton,
                isLoading: loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: loading
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
                child: Text(
                  AppStrings.signupHaveAccount,
                  style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
                ),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.signupTitle,
                style: AppText.serif(size: 22, color: AppColors.ink, height: 28),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.signupSubtitle(AppStrings.roleName(widget.role)),
                style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.fullNameLabel,
                hint: AppStrings.fullNameHint,
                controller: _name,
                errorText: _viewModel.fullNameError,
                enabled: !loading,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.emailLabel,
                hint: AppStrings.emailHint,
                controller: _email,
                errorText: _viewModel.emailError,
                enabled: !loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.passwordLabel,
                hint: AppStrings.passwordHint,
                controller: _password,
                errorText: _viewModel.passwordError,
                enabled: !loading,
                obscureText: true,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.confirmPasswordLabel,
                hint: AppStrings.passwordHint,
                controller: _confirm,
                errorText: _viewModel.confirmPasswordError,
                enabled: !loading,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        );
      },
    );
  }
}
