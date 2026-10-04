import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../helpers/validators.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/change_password_view_model.dart';

/// Change Password (PBI 7): current password, new password with a live rules
/// checklist, and confirmation. On success it closes and shows a message.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _viewModel = ChangePasswordViewModel();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Re-draw the rules checklist as the new password is typed.
    _new.addListener(_onNewPasswordChanged);
  }

  void _onNewPasswordChanged() => setState(() {});

  @override
  void dispose() {
    _new.removeListener(_onNewPasswordChanged);
    _viewModel.dispose();
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final changed = await _viewModel.submit(
      currentPassword: _current.text,
      newPassword: _new.text,
      confirmPassword: _confirm.text,
    );
    if (!changed || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text(AccountStrings.passwordUpdated)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final loading = _viewModel.isLoading;
        // While saving, Back is blocked so the result is not lost.
        return PopScope(
          canPop: !loading,
          child: FormPageScaffold(
            title: AccountStrings.changePasswordTitle,
            bottom: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_viewModel.formError != null) ...[
                  FormMessage.error(_viewModel.formError!),
                  const SizedBox(height: 12),
                ],
                PrimaryButton(
                  label: AccountStrings.updatePassword,
                  isLoading: loading,
                  onPressed: _submit,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: AccountStrings.currentPasswordLabel,
                  hint: AccountStrings.currentPasswordHint,
                  controller: _current,
                  errorText: _viewModel.currentPasswordError,
                  enabled: !loading,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: AccountStrings.newPasswordLabel,
                  hint: AccountStrings.newPasswordHint,
                  controller: _new,
                  errorText: _viewModel.newPasswordError,
                  enabled: !loading,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                _PasswordRules(password: _new.text),
                const SizedBox(height: 20),
                AppTextField(
                  label: AccountStrings.confirmNewPasswordLabel,
                  hint: AccountStrings.confirmNewPasswordHint,
                  controller: _confirm,
                  errorText: _viewModel.confirmPasswordError,
                  enabled: !loading,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Checklist of Person 1's password rules ([Validators.password]); each line
/// turns green with a check mark once the typed password meets it.
class _PasswordRules extends StatelessWidget {
  const _PasswordRules({required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final hasLength = password.length >= Validators.minPasswordLength;
    final hasUpperAndLower = password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AccountStrings.passwordRulesTitle,
            style: AppText.sans(
              size: 13,
              color: AppColors.ink,
              weight: FontWeight.w600,
              height: 18,
            ),
          ),
          const SizedBox(height: 8),
          _RuleLine(text: AccountStrings.ruleLength, met: hasLength),
          const SizedBox(height: 6),
          _RuleLine(text: AccountStrings.ruleUpperLower, met: hasUpperAndLower),
          const SizedBox(height: 6),
          _RuleLine(text: AccountStrings.ruleNumber, met: hasNumber),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text, required this.met});

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.moss600 : AppColors.grey;
    return Row(
      children: [
        // An icon as well as a color, so the state isn't shown by color alone.
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: color,
          semanticLabel: met ? 'Met' : 'Not met yet',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppText.sans(size: 13, color: color, height: 18),
          ),
        ),
      ],
    );
  }
}
