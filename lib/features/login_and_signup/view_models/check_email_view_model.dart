import 'package:flutter/foundation.dart';

import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../models/auth_failure.dart';

/// Backs the "Check your email" screen. The sign-up credentials are held in
/// memory only so the verification email can be resent.
class CheckEmailViewModel extends ChangeNotifier {
  CheckEmailViewModel({
    required this.email,
    required this.password,
    required bool verificationEmailSent,
    AuthRepository? authRepository,
  })  : _auth = authRepository ?? AuthRepository.instance,
        message = verificationEmailSent ? null : AppStrings.checkEmailSendFailed,
        messageIsError = !verificationEmailSent;

  final String email;
  final String password;
  final AuthRepository _auth;

  bool isResending = false;
  String? message;
  bool messageIsError;

  Future<void> resend() async {
    if (isResending) return;

    isResending = true;
    message = null;
    notifyListeners();
    try {
      final result = await _auth.resendVerification(email, password);
      messageIsError = false;
      message = result == ResendResult.sent
          ? AppStrings.verificationSent
          : AppStrings.alreadyVerified;
    } on AuthException catch (e) {
      messageIsError = true;
      message = switch (e.failure) {
        AuthFailure.network => AppStrings.networkError,
        AuthFailure.tooManyRequests => AppStrings.tooManyRequests,
        _ => AppStrings.genericError,
      };
    } catch (_) {
      messageIsError = true;
      message = AppStrings.genericError;
    } finally {
      isResending = false;
      notifyListeners();
    }
  }
}
