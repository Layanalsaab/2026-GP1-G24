import 'package:flutter/foundation.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/auth_failure.dart';

class DeleteAccountViewModel extends ChangeNotifier with SafeNotifier {
  DeleteAccountViewModel({
    AuthRepository? authRepository,
    this.fates = const {},
  }) : _auth = authRepository ?? AuthRepository.instance;

  final AuthRepository _auth;

  /// What the founder chose for each startup he holds (by startup id).
  final Map<String, StartupFate> fates;

  bool isLoading = false;
  String? passwordError;
  String? formError;

  /// The message to show for the last attempt (null when there is none).
  String? get error => passwordError ?? formError;

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
      await _auth.deleteAccount(password: password, fates: fates);
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
