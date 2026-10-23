import 'package:flutter/material.dart';

import '../../../app_constants/profile_strings.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/app_text_field.dart';
import '../../../shared_ui/widgets/forms/form_page.dart';
import '../../../shared_ui/widgets/forms/password_rules.dart';
import '../../../shared_ui/widgets/headers/auth_headers.dart';
import '../../../shared_ui/widgets/headers/overlap_layout.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../view_models/change_password_view_model.dart';

/// Change password (not designed in the prototype: the existing flow in the
/// design system): green header, a card with the current password, the new
/// password with its live rules and the confirmation, and a pinned button.
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
  void dispose() {
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
    if (!mounted) return;
    if (changed) {
      AppToast.show(context, ProfileStrings.passwordUpdated);
      AppNav.back(context);
    } else {
      AppToast.error(context, _viewModel.formError ?? ProfileStrings.fixFields);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final loading = _viewModel.isLoading;
        return PopScope(
          // While saving, Back is blocked so the result is not lost.
          canPop: !loading,
          child: FormPageScaffold(
            header: AuthHeader(
              title: ProfileStrings.changePasswordTitle,
              onBack: loading ? null : () => AppNav.back(context),
            ),
            footer: FormFooter(
              primary: AppButton(
                label: ProfileStrings.updatePassword,
                loading: loading,
                onPressed: _submit,
              ),
            ),
            children: [
              AuthCard(
                child: FormFieldColumn(
                  children: [
                    LabeledTextField(
                      label: ProfileStrings.currentPassword,
                      required: true,
                      controller: _current,
                      placeholder: ProfileStrings.currentPasswordHint,
                      password: true,
                      enabled: !loading,
                      maxLength: 32,
                      showCounter: false,
                      error: _viewModel.currentPasswordError,
                    ),
                    LabeledTextField(
                      label: ProfileStrings.newPassword,
                      required: true,
                      controller: _new,
                      placeholder: ProfileStrings.newPasswordHint,
                      password: true,
                      enabled: !loading,
                      maxLength: 32,
                      showCounter: false,
                      error: _viewModel.newPasswordError,
                      below: ListenableBuilder(
                        listenable: _new,
                        builder: (context, _) =>
                            PasswordRules(password: _new.text),
                      ),
                    ),
                    LabeledTextField(
                      label: ProfileStrings.confirmPassword,
                      required: true,
                      controller: _confirm,
                      placeholder: ProfileStrings.confirmPasswordHint,
                      password: true,
                      enabled: !loading,
                      maxLength: 32,
                      showCounter: false,
                      error: _viewModel.confirmPasswordError,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
