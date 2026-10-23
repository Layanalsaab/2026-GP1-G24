import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/app_text_field.dart';
import '../../../shared_ui/widgets/headers/auth_headers.dart';
import '../../../shared_ui/widgets/headers/overlap_layout.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../view_models/forgot_password_view_model.dart';
import '../widgets/auth_navigation.dart';

/// Forgot password (docs/05 A13): enter the email, "Send reset link" goes
/// back with the toast `Reset link sent to <email>`.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.email = ''});

  /// Pre-filled email (from Log in or the Verify step).
  final String email;

  /// Pushes Forgot password with [email] pre-filled.
  static void open(BuildContext context, {String email = ''}) => AppNav.push(
    context,
    ForgotPasswordScreen(email: email),
    greenHeader: true,
  );

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final ForgotPasswordViewModel _vm = ForgotPasswordViewModel(
    email: widget.email,
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final sentTo = await _vm.submit();
    if (!mounted) return;
    if (sentTo != null) {
      // The toast lives in the root overlay, so it survives the pop.
      AppToast.show(context, AuthStrings.resetLinkSent(sentTo));
      authBack(context);
    } else {
      // A mistake in the field: say so (it also shows under the field).
      AppToast.error(context, _vm.formError ?? ValidationStrings.fixFields);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final vm = _vm;
        return Scaffold(
          backgroundColor: AppColors.cream,
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  title: AuthStrings.forgotTitle,
                  onBack: () => authBack(context),
                ),
                AuthCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Text(
                          AuthStrings.forgotIntro,
                          style: AppText.sans(
                            size: 14,
                            color: AppColors.grey,
                            height: 21,
                          ),
                        ),
                      ),
                      FormFieldColumn(
                        children: [
                          LabeledTextField(
                            label: AuthStrings.email,
                            required: true,
                            controller: vm.email,
                            placeholder: AuthStrings.forgotPlaceholder,
                            keyboardType: TextInputType.emailAddress,
                            valid: vm.emailValid,
                            error: vm.emailError,
                            autofillHints: const [AutofillHints.email],
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: AppButton(
                          label: AuthStrings.sendResetLink,
                          onPressed: _send,
                          loading: vm.isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        );
      },
    );
  }
}
