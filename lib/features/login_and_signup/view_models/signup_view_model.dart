import 'package:flutter/foundation.dart';

import '../../../app_constants/app_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';

/// The fields of the Create Account form that can show an error.
enum SignupField {
  fullName,
  email,
  phone,
  password,
  confirmPassword,
  city,
  sectors,
}

class SignupViewModel extends ChangeNotifier {
  SignupViewModel({AuthRepository? authRepository})
      : _auth = authRepository ?? AuthRepository.instance;

  final AuthRepository _auth;

  bool isLoading = false;
  String? fullNameError;
  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  String? phoneError;
  String? cityError;
  String? sectorsError;

  /// True after the first submit attempt, so untouched fields also show their
  /// checklists instead of staying silent.
  bool attempted = false;

  /// An error that doesn't belong to one field (network, unknown, ...).
  String? formError;

  /// Clears one field's error as soon as the user edits that field.
  void clearError(SignupField field) {
    final had = switch (field) {
      SignupField.fullName => fullNameError != null,
      SignupField.email => emailError != null,
      SignupField.phone => phoneError != null,
      SignupField.password => passwordError != null,
      SignupField.confirmPassword => confirmPasswordError != null,
      SignupField.city => cityError != null,
      SignupField.sectors => sectorsError != null,
    };
    if (!had) return;
    switch (field) {
      case SignupField.fullName:
        fullNameError = null;
      case SignupField.email:
        emailError = null;
      case SignupField.phone:
        phoneError = null;
      case SignupField.password:
        passwordError = null;
      case SignupField.confirmPassword:
        confirmPasswordError = null;
      case SignupField.city:
        cityError = null;
      case SignupField.sectors:
        sectorsError = null;
    }
    notifyListeners();
  }

  /// Validates every field, then creates the account. Returns the result on
  /// success, or null when validation failed, a request is already running,
  /// or the sign-up failed (the errors above explain why).
  ///
  /// [phone] is the 9 digits without +966. [phone], [city] and [sectors] are
  /// validated here but not saved yet: the `users` create rule only accepts
  /// role, fullName and email.
  Future<SignupResult?> submit({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    required String? city,
    required List<String> sectors,
    required AccountRole role,
  }) async {
    if (isLoading) return null;

    attempted = true;
    fullNameError = Validators.fullName(fullName);
    emailError = Validators.email(email);
    phoneError = Validators.phone(phone);
    passwordError = Validators.password(password);
    confirmPasswordError = Validators.confirmPassword(password, confirmPassword);
    cityError = Validators.city(city);
    sectorsError = Validators.sectors(sectors);
    formError = null;

    final hasErrors = fullNameError != null ||
        emailError != null ||
        phoneError != null ||
        passwordError != null ||
        confirmPasswordError != null ||
        cityError != null ||
        sectorsError != null;
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
