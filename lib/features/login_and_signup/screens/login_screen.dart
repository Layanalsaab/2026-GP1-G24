import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/login_view_model.dart';
import 'choose_role_screen.dart';
import 'forgot_password_screen.dart';

/// Figma: "V2 · 05 · Log In"
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _viewModel = LoginViewModel();
  final _email = TextEditingController();
  final _password = TextEditingController();

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
    if (user == null || !mounted) return;
    AppRouter.openHome(context, user);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final loading = _viewModel.isLoading;
        final resendMessage = _viewModel.resendMessage;
        return FormPageScaffold(
          contentTopPadding: 4,
          bottomTopPadding: 8,
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PrimaryButton(
                label: AppStrings.loginButton,
                isLoading: loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: loading
                    ? null
                    : () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const ChooseRoleScreen(),
                          ),
                        ),
                child: Text(
                  AppStrings.loginNoAccount,
                  style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
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
                style: AppText.serif(size: 22, color: AppColors.ink, height: 28),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.loginSubtitle,
                style: AppText.sans(size: 14, color: AppColors.grey, height: 20),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.emailLabel,
                hint: AppStrings.emailHint,
                controller: _email,
                enabled: !loading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.passwordLabel,
                hint: AppStrings.passwordHint,
                controller: _password,
                enabled: !loading,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              if (_viewModel.formError != null) ...[
                const SizedBox(height: 12),
                FormMessage.error(_viewModel.formError!),
              ],
              if (_viewModel.needsVerification) ...[
                const SizedBox(height: 4),
                _viewModel.isResending
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.moss600,
                          ),
                        ),
                      )
                    : TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 44),
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: _viewModel.resendVerification,
                        child: Text(
                          AppStrings.resendVerification,
                          style: AppText.sans(
                            size: 14,
                            color: AppColors.moss600,
                            weight: FontWeight.w600,
                            height: 20,
                          ),
                        ),
                      ),
              ],
              if (resendMessage != null) ...[
                const SizedBox(height: 4),
                _viewModel.resendFailed
                    ? FormMessage.error(resendMessage)
                    : FormMessage.success(resendMessage),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: loading
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
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
            ],
          ),
        );
      },
    );
  }
}
