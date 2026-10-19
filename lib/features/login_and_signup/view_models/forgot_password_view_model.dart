import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/validators.dart';
import '../../../models/auth_failure.dart';

/// Forgot password (docs/05 A13, docs/06 section 6).
class ForgotPasswordViewModel extends ChangeNotifier with SafeNotifier {
  ForgotPasswordViewModel({String email = '', AuthRepository? authRepository})
    : _auth = authRepository ?? AuthRepository.instance,
      email = TextEditingController(text: email) {
    this.email.addListener(notifyListeners);
  }

  final AuthRepository _auth;
  final TextEditingController email;

  bool attempted = false;
  bool isLoading = false;

  /// A network / rate-limit problem to show as a toast.
  String? formError;

  /// "Enter a valid email address" for an empty or malformed email.
  String? get emailError =>
      (attempted || email.text.trim().isNotEmpty) &&
          !Validators.isEmail(email.text)
      ? ValidationStrings.emailInvalid
      : null;

  bool get emailValid => Validators.isEmail(email.text);

  /// Sends the reset link. Returns the email it was sent to, or null when
  /// the email is invalid or sending failed ([formError]).
  Future<String?> submit() async {
    if (isLoading) return null;
    attempted = true;
    formError = null;
    if (!Validators.isEmail(email.text)) {
      notifyListeners();
      return null;
    }
    final address = email.text.trim();
    isLoading = true;
    notifyListeners();
    try {
      await _auth.sendPasswordReset(address);
      return address;
    } on AuthException catch (e) {
      formError = switch (e.failure) {
        AuthFailure.network => AppStrings.networkError,
        AuthFailure.tooManyRequests => AppStrings.tooManyRequests,
        _ => AppStrings.genericError,
      };
    } catch (_) {
      formError = AppStrings.genericError;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }

  @override
  void dispose() {
    email.removeListener(notifyListeners);
    email.dispose();
    super.dispose();
  }
}
