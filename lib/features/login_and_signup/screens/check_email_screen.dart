import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/check_email_view_model.dart';
import 'login_screen.dart';

/// "Check your email" — shown after sign up. There is no Figma frame for this
/// screen yet, so it reuses the existing form components.
class CheckEmailScreen extends StatefulWidget {
  const CheckEmailScreen({
    super.key,
    required this.email,
    required this.password,
    required this.verificationEmailSent,
  });

  final String email;

  /// Kept in memory only, to be able to resend the verification email.
  final String password;
  final bool verificationEmailSent;

  @override
  State<CheckEmailScreen> createState() => _CheckEmailScreenState();
}

class _CheckEmailScreenState extends State<CheckEmailScreen> {
  late final CheckEmailViewModel _viewModel = CheckEmailViewModel(
    email: widget.email,
    password: widget.password,
    verificationEmailSent: widget.verificationEmailSent,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _backToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final message = _viewModel.message;
        return FormPageScaffold(
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: AppStrings.backToLogin,
                onPressed: _backToLogin,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.moss100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 34,
                  color: AppColors.moss600,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.checkEmailTitle,
                textAlign: TextAlign.center,
                style: AppText.serif(size: 22, color: AppColors.ink, height: 28),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.checkEmailBody(widget.email),
                textAlign: TextAlign.center,
                style: AppText.sans(size: 16, color: AppColors.grey, height: 24),
              ),
              const SizedBox(height: 24),
              if (message != null) ...[
                _viewModel.messageIsError
                    ? FormMessage.error(message)
                    : FormMessage.success(message),
                const SizedBox(height: 16),
              ],
              _viewModel.isResending
                  ? const SizedBox(
                      height: 48,
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.moss600,
                          ),
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: _viewModel.resend,
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
          ),
        );
      },
    );
  }
}
