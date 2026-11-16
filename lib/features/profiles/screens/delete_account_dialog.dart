import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/app_text_field.dart';
import '../../../shared_ui/widgets/overlays/app_bottom_sheet.dart';
import '../view_models/delete_account_view_model.dart';

/// The password step of Delete Account: only "Enter your password to delete
/// your account" (the warning came before), on the same bottom sheet as the
/// warning. The founder's startups follow [fates]. Completes with true once
/// the account is deleted.
Future<bool> showDeleteAccountPassword(
  BuildContext context, {
  Map<String, StartupFate> fates = const {},
}) {
  final viewModel = DeleteAccountViewModel(fates: fates);
  return showPasswordSheet(
    context,
    title: ProfileStrings.deleteTitle,
    message: AccountStrings.deletePasswordText,
    confirmLabel: ProfileStrings.deleteAccount,
    submit: (password) async {
      final deleted = await viewModel.submit(password);
      return deleted ? null : viewModel.error;
    },
  ).whenComplete(viewModel.dispose);
}

/// The password step of a deletion (an account, or a startup), laid out like
/// [ConfirmSheet]: the red trash circle, [title], one line ([message]), the
/// password field, the red [confirmLabel] button and a white Cancel. [submit]
/// runs with the password and returns what to show under the field (null when
/// it worked: the sheet closes). Completes with true when it worked.
Future<bool> showPasswordSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required Future<String?> Function(String password) submit,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  final done = await showAppBottomSheet<bool>(
    context,
    dismissible: false,
    builder: (_) => PasswordSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      submit: submit,
    ),
  );
  return done == true;
}

class PasswordSheet extends StatefulWidget {
  const PasswordSheet({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.submit,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final Future<String?> Function(String password) submit;

  @override
  State<PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<PasswordSheet> {
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    final password = _password.text;
    if (password.isEmpty) {
      setState(() => _error = AccountStrings.passwordRequired);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final problem = await widget.submit(password);
    if (!mounted) return;
    if (problem == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _loading = false;
      _error = problem;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_loading,
      child: AppSheetScaffold(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
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
                    alignment: Alignment.center,
                    child: const AppIcon.filled(
                      AppIcons.trash,
                      size: 28,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                header: true,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: AppText.sans(size: 21, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: AppText.sans(
                  size: 15,
                  color: AppColors.grey,
                  height: 22,
                ),
              ),
              const SizedBox(height: 18),
              LabeledTextField(
                label: AccountStrings.deletePasswordLabel,
                controller: _password,
                placeholder: AccountStrings.deletePasswordHint,
                password: true,
                enabled: !_loading,
                maxLength: 32,
                showCounter: false,
                error: _error,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _go(),
              ),
              const SizedBox(height: 22),
              AppButton(
                label: widget.confirmLabel,
                variant: AppButtonVariant.danger,
                loading: _loading,
                onPressed: _go,
              ),
              const SizedBox(height: 10),
              SheetCancelButton(
                label: ProfileStrings.cancel,
                onTap: _loading ? null : () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
