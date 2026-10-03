import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
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
      listenable: _viewModel,
      builder: (context, _) {
        return FormPageScaffold(
          child: Column(
            children: [
              svgIcon('lock.svg', size: 40),
              const SizedBox(height: 20),
              Text(
                AppStrings.forgotTitle,
                textAlign: TextAlign.center,
                style: AppText.serif(size: 22, color: AppColors.ink, height: 28),
              ),
              const SizedBox(height: 20),
              Text(
                AppStrings.forgotSubtitle,
                textAlign: TextAlign.center,
                style: AppText.sans(size: 16, color: AppColors.grey, height: 24),
              ),
              const SizedBox(height: 20),
              AppTextField(
                label: AppStrings.emailLabel,
                hint: AppStrings.emailHint,
                controller: _email,
                errorText: _viewModel.emailError,
                enabled: !_viewModel.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              if (_viewModel.formError != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FormMessage.error(_viewModel.formError!),
                ),
              ],
              if (_viewModel.successMessage != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FormMessage.success(_viewModel.successMessage!),
                ),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: AppStrings.forgotButton,
                isLoading: _viewModel.isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        );
      },
    );
  }
}
