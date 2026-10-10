import 'package:flutter/foundation.dart';

import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({AuthRepository? authRepository})
      : _auth = authRepository ?? AuthRepository.instance;

  final AuthRepository _auth;

  bool isLoading = false;
  bool isResending = false;

  /// Shown under the form after a failed log in.
  String? formError;

  /// Field-level errors from the last submit ("Enter your password").
  String? emailError;
  String? passwordError;

  /// True after the first submit attempt, so empty fields show their
  /// checklist instead of staying silent.
  bool attempted = false;

  /// True when the credentials were right but the email isn't verified yet.
  bool needsVerification = false;

  /// True when the pop-up is a reminder: the user tried to log in without
  /// verifying. False for the first pop-up, right after sign up.
  bool verificationReminder = false;

  /// Result of the last "Resend verification email" tap.
  String? resendMessage;
  bool resendFailed = false;

  // Kept in memory only, so we can resend the verification email later.
  String _email = '';
  String _password = '';

  /// The email the verification link was (or will be) sent to.
  String get verificationEmail => _email;

  /// Opens the "Verify your email" pop-up right after sign up: the account
  /// exists but its email isn't verified yet. [emailSent] is false when the
  /// first email could not be sent, so the pop-up says so.
  void promptVerification({
    required String email,
    required String password,
    required bool emailSent,
  }) {
    _email = email.trim();
    _password = password;
    needsVerification = true;
    verificationReminder = false;
    resendFailed = !emailSent;
    resendMessage = emailSent ? null : AppStrings.checkEmailSendFailed;
    notifyListeners();
  }

  /// Called when the pop-up is closed.
  void dismissVerification() {
    // No notification: the pop-up is already animating out and must not
    // change its text while it does.
    needsVerification = false;
    resendMessage = null;
    resendFailed = false;
  }

  /// Returns the signed-in user's profile, or null when log in failed (see
  /// [formError] / [needsVerification]). When the email isn't verified yet,
  /// [needsVerification] is true and the screen shows the pop-up.
  Future<AppUser?> submit({
    required String email,
    required String password,
  }) async {
    if (isLoading) return null;

    attempted = true;
    formError = null;
    needsVerification = false;
    resendMessage = null;
    resendFailed = false;

    _email = email.trim();
    _password = password;

    // A missing or malformed value is reported under its own field. Wrong
    // credentials still get one generic message (see below).
    emailError =
        Validators.email(_email) == null ? null : AppStrings.loginEmailInvalid;
    passwordError =
        password.isEmpty ? AppStrings.loginPasswordRequired : null;
    if (emailError != null || passwordError != null) {
      notifyListeners();
      return null;
    }

    isLoading = true;
    notifyListeners();
    try {
      return await _auth.logIn(_email, password);
    } on AuthException catch (e) {
      switch (e.failure) {
        case AuthFailure.emailNotVerified:
          needsVerification = true;
          verificationReminder = true;
        case AuthFailure.profileMissing:
          formError = AppStrings.profileMissing;
        case AuthFailure.network:
          formError = AppStrings.networkError;
        case AuthFailure.tooManyRequests:
          formError = AppStrings.tooManyRequests;
        case AuthFailure.invalidCredentials:
        case AuthFailure.invalidEmail:
          formError = AppStrings.incorrectCredentials;
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

  /// Clears the field errors as soon as the user edits a field.
  void fieldEdited() {
    if (emailError == null && passwordError == null && formError == null) return;
    emailError = null;
    passwordError = null;
    formError = null;
    notifyListeners();
  }

  Future<void> resendVerification() async {
    if (isResending || !needsVerification) return;

    isResending = true;
    resendMessage = null;
    notifyListeners();
    try {
      final result = await _auth.resendVerification(_email, _password);
      resendFailed = false;
      resendMessage = result == ResendResult.sent
          ? AppStrings.verificationSent
          : AppStrings.alreadyVerified;
    } on AuthException catch (e) {
      resendFailed = true;
      resendMessage = switch (e.failure) {
        AuthFailure.network => AppStrings.networkError,
        AuthFailure.tooManyRequests => AppStrings.tooManyRequests,
        _ => AppStrings.genericError,
      };
    } catch (_) {
      resendFailed = true;
      resendMessage = AppStrings.genericError;
    } finally {
      isResending = false;
      notifyListeners();
    }
  }
}
