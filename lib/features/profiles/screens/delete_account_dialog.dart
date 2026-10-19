import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/profile_strings.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/app_text_field.dart';
import '../../../shared_ui/widgets/overlays/app_dialog.dart';
import '../view_models/delete_account_view_model.dart';

/// "Delete your account?": asks for the password, then deletes the account
/// and profile. Completes with true once the account is deleted.
Future<bool?> showDeleteAccountDialog(
  BuildContext context, {
  required AccountRole role,
}) => showAppDialog<bool>(
  context,
  dismissible: false,
  builder: (_) => DeleteAccountDialog(role: role),
);

/// The dialog card: red trash circle, title, the warning for the [role],
/// "This can't be undone.", the password field and the danger / cancel
/// buttons.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key, required this.role});

  final AccountRole role;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _viewModel = DeleteAccountViewModel();
  final _password = TextEditingController();

  @override
  void dispose() {
    _viewModel.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    FocusScope.of(context).unfocus();
    final deleted = await _viewModel.submit(_password.text);
    if (!deleted || !mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final loading = _viewModel.isLoading;
        final error = _viewModel.passwordError ?? _viewModel.formError;
        return PopScope(
          canPop: !loading,
          child: AppDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Pop(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: AppColors.errorFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: AppIcon.filled(
                          AppIcons.trash,
                          size: 28,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  ProfileStrings.deleteTitle,
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 21, weight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.role == AccountRole.founder
                      ? AccountStrings.deleteWarningFounder
                      : AccountStrings.deleteWarningInvestor,
                  style: AppText.sans(
                    size: 14,
                    height: 21,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AccountStrings.cannotBeUndone,
                  style: AppText.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 16),
                LabeledTextField(
                  label: ProfileStrings.deletePasswordLabel,
                  controller: _password,
                  placeholder: ProfileStrings.deletePasswordHint,
                  password: true,
                  enabled: !loading,
                  maxLength: 32,
                  showCounter: false,
                  error: error,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _delete(),
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: ProfileStrings.deleteAccount,
                  variant: AppButtonVariant.danger,
                  loading: loading,
                  onPressed: _delete,
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: ProfileStrings.cancel,
                  variant: AppButtonVariant.outline,
                  onPressed: loading
                      ? null
                      : () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
