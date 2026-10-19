import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/auth_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';
import 'verify_email_view_model.dart' show ResendOutcome;

/// Log in (docs/05 A12, docs/06 section 5).
class LoginViewModel extends ChangeNotifier with SafeNotifier {
  LoginViewModel({AuthRepository? authRepository})
    : _auth = authRepository ?? AuthRepository.instance {
    email.addListener(_edited);
    password.addListener(_edited);
  }

  final AuthRepository _auth;

  final email = TextEditingController();
  final password = TextEditingController();

  bool attempted = false;
  bool isLoading = false;
  bool isResending = false;

  /// A problem that is not about one field (network, unknown).
  String? formError;

  /// True when the credentials were right but the email is not verified yet.
  bool needsVerification = false;

  String? _credentialsError;

  // Kept in memory only, so the verify pop-up can resend the link.
  String _sentEmail = '';
  String _sentPassword = '';

  String get verificationEmail => _sentEmail;

  void _edited() {
    _credentialsError = null;
    notifyListeners();
  }

  String? get emailError => attempted || email.text.trim().isNotEmpty
      ? Validators.email(email.text)
      : null;

  String? get passwordError {
    if (_credentialsError != null) return _credentialsError;
    if (attempted && password.text.isEmpty) {
      return ValidationStrings.passwordRequired;
    }
    return null;
  }

  bool get emailValid => Validators.isEmail(email.text);

  /// Returns the signed-in profile, or null (see [emailError], [passwordError],
  /// [formError], [needsVerification]).
  Future<AppUser?> submit() async {
    if (isLoading) return null;
    attempted = true;
    formError = null;
    needsVerification = false;
    _credentialsError = null;
    if (Validators.email(email.text) != null || password.text.isEmpty) {
      notifyListeners();
      return null;
    }

    _sentEmail = email.text.trim();
    _sentPassword = password.text;
    isLoading = true;
    notifyListeners();
    try {
      return await _auth.logIn(_sentEmail, _sentPassword);
    } on AuthException catch (e) {
      switch (e.failure) {
        case AuthFailure.emailNotVerified:
          needsVerification = true;
        case AuthFailure.invalidCredentials:
        case AuthFailure.invalidEmail:
          _credentialsError = AuthStrings.incorrectCredentials;
        case AuthFailure.profileMissing:
          formError = AppStrings.profileMissing;
        case AuthFailure.network:
          formError = AppStrings.networkError;
        case AuthFailure.tooManyRequests:
          formError = AppStrings.tooManyRequests;
        default:
          formError = AppStrings.genericError;
      }
    } catch (_) {
      formError = AppStrings.genericError;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }

  /// "Resend verification email" in the verify pop-up.
  Future<ResendOutcome> resend() async {
    if (isResending) return ResendOutcome.failed;
    isResending = true;
    formError = null;
    notifyListeners();
    try {
      final result = await _auth.resendVerification(_sentEmail, _sentPassword);
      return result == ResendResult.sent
          ? ResendOutcome.sent
          : ResendOutcome.alreadyVerified;
    } on AuthException catch (e) {
      formError = switch (e.failure) {
        AuthFailure.network => AppStrings.networkError,
        AuthFailure.tooManyRequests => AppStrings.tooManyRequests,
        _ => AppStrings.genericError,
      };
      return ResendOutcome.failed;
    } catch (_) {
      formError = AppStrings.genericError;
      return ResendOutcome.failed;
    } finally {
      isResending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    email.removeListener(_edited);
    password.removeListener(_edited);
    email.dispose();
    password.dispose();
    super.dispose();
  }
}
