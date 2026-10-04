import 'package:flutter/foundation.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/auth_failure.dart';

/// Logic for the Delete Account dialog (PBI 13): the user re-enters their
/// password, then the account and profile are deleted.
class DeleteAccountViewModel extends ChangeNotifier with SafeNotifier {
  DeleteAccountViewModel({AuthRepository? authRepository})
      : _auth = authRepository ?? AuthRepository.instance;

  final AuthRepository _auth;

  bool isLoading = false;
  String? passwordError;
  String? formError;

  /// Returns true when the account was deleted (the user is then signed out).
  Future<bool> submit(String password) async {
    if (isLoading) return false;

    formError = null;
    if (password.isEmpty) {
      passwordError = AccountStrings.passwordRequired;
      notifyListeners();
      return false;
    }

    passwordError = null;
    isLoading = true;
    notifyListeners();
    try {
      await _auth.deleteAccount(password);
      return true;
    } on AuthException catch (e) {
      switch (e.failure) {
        case AuthFailure.invalidCredentials:
          passwordError = AccountStrings.passwordIncorrect;
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
