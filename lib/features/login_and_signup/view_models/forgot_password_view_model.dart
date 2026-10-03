import 'package:flutter/foundation.dart';

import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/validators.dart';
import '../../../models/auth_failure.dart';

class ForgotPasswordViewModel extends ChangeNotifier {
  ForgotPasswordViewModel({AuthRepository? authRepository})
      : _auth = authRepository ?? AuthRepository.instance;

  final AuthRepository _auth;

  bool isLoading = false;
  String? emailError;
  String? formError;

  /// The confirmation shown after sending. It is identical whether or not the
  /// email is registered, so the app never reveals which emails have accounts.
  String? successMessage;

  Future<void> submit(String email) async {
    if (isLoading) return;

    emailError = Validators.email(email);
    formError = null;
    successMessage = null;
    if (emailError != null) {
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    try {
      await _auth.sendPasswordReset(email.trim());
      successMessage = AppStrings.resetLinkMessage;
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
  }
}
