import 'package:flutter/foundation.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/validators.dart';
import '../../../models/auth_failure.dart';

/// Logic for the Change Password screen (PBI 7). Uses the same password rules
/// as sign up ([Validators.password]).
class ChangePasswordViewModel extends ChangeNotifier with SafeNotifier {
  ChangePasswordViewModel({AuthRepository? authRepository})
      : _auth = authRepository ?? AuthRepository.instance;

  final AuthRepository _auth;

  bool isLoading = false;
  String? currentPasswordError;
  String? newPasswordError;
  String? confirmPasswordError;

  /// Shown above the button for problems that aren't about one field.
  String? formError;

  /// Returns true when the password was changed. Otherwise the error fields
  /// say why, and the password is unchanged.
  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (isLoading) return false;

    currentPasswordError =
        currentPassword.isEmpty ? AccountStrings.currentPasswordRequired : null;
    newPasswordError = Validators.password(newPassword);
    if (newPasswordError == null &&
        currentPassword.isNotEmpty &&
        newPassword == currentPassword) {
      newPasswordError = AccountStrings.samePassword;
    }
    confirmPasswordError =
        Validators.confirmPassword(newPassword, confirmPassword);
    formError = null;

    if (currentPasswordError != null ||
        newPasswordError != null ||
        confirmPasswordError != null) {
      notifyListeners();
      return false;
    }

    isLoading = true;
    notifyListeners();
    try {
      await _auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } on AuthException catch (e) {
      switch (e.failure) {
        case AuthFailure.invalidCredentials:
          currentPasswordError = AccountStrings.currentPasswordIncorrect;
        case AuthFailure.weakPassword:
          newPasswordError = AppStrings.weakPassword;
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
    return false;
  }
}
