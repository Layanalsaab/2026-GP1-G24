import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/app_text_field.dart';
import '../../../shared_ui/common_widgets/form_message.dart';
import '../../../shared_ui/common_widgets/primary_button.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/delete_account_view_model.dart';

/// "Log out of Start.sa?" (PBI 8). Returns true when the user confirms.
Future<bool?> showLogOutDialog(BuildContext context) => showDialog<bool>(
      context: context,
      builder: (dialogContext) => _AccountDialog(
        icon: Icons.logout,
        destructive: false,
        title: AccountStrings.logOutTitle,
        children: [
          PrimaryButton(
            label: AppStrings.logOut,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: AccountStrings.cancel,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
        ],
      ),
    );

/// "Delete your account?" (PBI 13). Returns true once the account has been
/// deleted; the caller then opens the Start screen.
Future<bool?> showDeleteAccountDialog(
  BuildContext context, {
  required AccountRole role,
}) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteAccountDialog(role: role),
    );

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
        return PopScope(
          // Don't let Back close the dialog half-way through deleting.
          canPop: !loading,
          child: _AccountDialog(
            icon: Icons.delete_outline,
            destructive: true,
            title: AccountStrings.deleteTitle,
            children: [
              Text(
                widget.role == AccountRole.founder
                    ? AccountStrings.deleteWarningFounder
                    : AccountStrings.deleteWarningInvestor,
                style: AppText.sans(size: 14, color: AppColors.grey, height: 21),
              ),
              const SizedBox(height: 10),
              Text(
                AccountStrings.cannotBeUndone,
                style: AppText.sans(
                  size: 14,
                  color: AppColors.error,
                  weight: FontWeight.w600,
                  height: 20,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: AccountStrings.deletePasswordLabel,
                hint: AccountStrings.deletePasswordHint,
                controller: _password,
                errorText: _viewModel.passwordError,
                enabled: !loading,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _delete(),
              ),
              if (_viewModel.formError != null) ...[
                const SizedBox(height: 12),
                FormMessage.error(_viewModel.formError!),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: AccountStrings.deleteAccount,
                color: AppColors.error,
                isLoading: loading,
                onPressed: _delete,
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: AccountStrings.cancel,
                onPressed: loading ? null : () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// White rounded dialog: round icon, serif title, then [children].
class _AccountDialog extends StatelessWidget {
  const _AccountDialog({
    required this.icon,
    required this.destructive,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final bool destructive;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: destructive
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.moss100,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: destructive ? AppColors.error : AppColors.green,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AppText.serif(size: 22, color: AppColors.ink, height: 28),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}
