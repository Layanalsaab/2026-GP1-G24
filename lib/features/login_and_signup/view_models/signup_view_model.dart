import 'package:flutter/foundation.dart';

import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';

class SignupViewModel extends ChangeNotifier {
  SignupViewModel({AuthRepository? authRepository})
      : _auth = authRepository ?? AuthRepository.instance;

  final AuthRepository _auth;

  bool isLoading = false;
  String? fullNameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;

  /// An error that doesn't belong to one field (network, unknown, ...).
  String? formError;

  /// Validates every field, then creates the account. Returns the result on
  /// success, or null when validation failed, a request is already running,
  /// or the sign-up failed (the errors above explain why).
  Future<SignupResult?> submit({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
    required AccountRole role,
  }) async {
    if (isLoading) return null;

    fullNameError = Validators.fullName(fullName);
    emailError = Validators.email(email);
    passwordError = Validators.password(password);
    confirmPasswordError = Validators.confirmPassword(password, confirmPassword);
    formError = null;

    final hasErrors = fullNameError != null ||
        emailError != null ||
        passwordError != null ||
        confirmPasswordError != null;
    if (hasErrors) {
      notifyListeners();
      return null;
    }

    isLoading = true;
    notifyListeners();
    try {
      return await _auth.signUp(
        fullName: fullName.trim(),
        email: email.trim(),
        password: password,
        role: role,
      );
    } on AuthException catch (e) {
      _showFailure(e.failure);
    } catch (_) {
      formError = AppStrings.genericError;
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }

  void _showFailure(AuthFailure failure) {
    switch (failure) {
      case AuthFailure.emailInUse:
        emailError = AppStrings.emailInUse;
      case AuthFailure.invalidEmail:
        emailError = AppStrings.emailInvalid;
      case AuthFailure.weakPassword:
        passwordError = AppStrings.weakPassword;
      case AuthFailure.profileSaveFailed:
        formError = AppStrings.profileSaveFailed;
      case AuthFailure.network:
        formError = AppStrings.networkError;
      case AuthFailure.tooManyRequests:
        formError = AppStrings.tooManyRequests;
      default:
        formError = AppStrings.genericError;
    }
  }
}
