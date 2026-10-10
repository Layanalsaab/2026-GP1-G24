import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../helpers/validators.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/forgot_password_view_model.dart';

/// Figma: "V2 · 34 · Forgot Password"
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _viewModel = ForgotPasswordViewModel();
  final _email = TextEditingController();

  @override
  void dispose() {
    _viewModel.dispose();
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    _viewModel.submit(_email.text);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_viewModel, _email]),
      builder: (context, _) {
        return FormPageScaffold(
          contentTopPadding: 24,
          bottomTopPadding: 16,
          bottom: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PrimaryButton(
                label: AppStrings.forgotButton,
                isLoading: _viewModel.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.moss100,
                  shape: BoxShape.circle,
                ),
                child: Center(child: svgIcon('lock.svg', size: 28)),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.forgotTitle,
                style: AppText.sans(
                  size: 22,
                  color: AppColors.ink,
                  weight: FontWeight.w600,
                  height: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.forgotSubtitle,
                style: AppText.sans(size: 14, color: AppColors.grey, height: 21),
              ),
              const SizedBox(height: 28),
              AppTextField(
                label: AppStrings.emailLabel,
                hint: AppStrings.forgotEmailHint,
                controller: _email,
                rules: Validators.emailRules(_email.text),
                // The checklist already explains an invalid email.
                showRules: _viewModel.emailError != null,
                enabled: !_viewModel.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              if (_viewModel.formError != null) ...[
                const SizedBox(height: 12),
                FormMessage.error(_viewModel.formError!),
              ],
              if (_viewModel.successMessage != null) ...[
                const SizedBox(height: 12),
                FormMessage.success(_viewModel.successMessage!),
              ],
            ],
          ),
        );
      },
    );
  }
}
