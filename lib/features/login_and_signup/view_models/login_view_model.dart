import 'package:flutter/foundation.dart';

import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
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

  /// True when the credentials were right but the email isn't verified yet.
  bool needsVerification = false;

  /// Result of the last "Resend verification email" tap.
  String? resendMessage;
  bool resendFailed = false;

  // Kept in memory only, so we can resend the verification email later.
  String _email = '';
  String _password = '';

  /// Returns the signed-in user's profile, or null when log in failed (see
  /// [formError] / [needsVerification]).
  Future<AppUser?> submit({
    required String email,
    required String password,
  }) async {
    if (isLoading) return null;

    formError = null;
    needsVerification = false;
    resendMessage = null;
    resendFailed = false;

    _email = email.trim();
    _password = password;

    // Missing email or password gets the same message as a wrong one.
    if (_email.isEmpty || password.isEmpty) {
      formError = AppStrings.incorrectCredentials;
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
          formError = AppStrings.verifyEmailFirst;
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
