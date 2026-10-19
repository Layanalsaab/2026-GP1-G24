import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';
import 'signup_flow.dart';

/// What happened when the user tapped Continue on the Verify step.
enum VerifyResult {
  /// A field is empty or malformed, or the email is not the sign-up email.
  invalid,

  /// Signed in, but the email link has not been opened yet.
  notVerified,

  /// The password is wrong (the error shows under the field).
  wrongPassword,

  /// Network or unknown problem ([VerifyEmailViewModel.formError]).
  failed,

  /// Verified: [VerifyEmailViewModel.user] is the signed-in profile.
  verified,
}

/// What happened when the user asked for a new verification email.
enum ResendOutcome { sent, alreadyVerified, failed }

/// Sign-up step 2, "Verify your email" (docs/05 A8, docs/08 section 1).
/// There is no code to type: the user opens the emailed link, comes back and
/// signs in with the email and password; we then check `emailVerified`.
class VerifyEmailViewModel extends ChangeNotifier with SafeNotifier {
  VerifyEmailViewModel({required this.flow, AuthRepository? authRepository})
    : _auth = authRepository ?? AuthRepository.instance,
      email = TextEditingController(text: flow.email) {
    email.addListener(_edited);
    password.addListener(_edited);
  }

  final SignupFlow flow;
  final AuthRepository _auth;

  final TextEditingController email;
  final password = TextEditingController();

  bool tried = false;
  bool isLoading = false;
  bool isResending = false;

  /// A problem that is not about one field (network, unknown).
  String? formError;

  AppUser? user;

  bool _wrongEmail = false;
  bool _wrongPassword = false;

  void _edited() {
    if (_wrongEmail || _wrongPassword) {
      _wrongEmail = false;
      _wrongPassword = false;
    }
    notifyListeners();
  }

  String? get emailError {
    if (_wrongEmail) return ValidationStrings.verifyWrongEmail;
    return tried ? Validators.email(email.text) : null;
  }

  String? get passwordError {
    if (_wrongPassword) return ValidationStrings.passwordIncorrect;
    if (tried && password.text.isEmpty) {
      return ValidationStrings.passwordRequired;
    }
    return null;
  }

  bool get emailValid => Validators.isEmail(email.text) && !_wrongEmail;

  /// Signs in and checks the account is verified (docs/08).
  Future<VerifyResult> submit() async {
    if (isLoading) return VerifyResult.failed;
    tried = true;
    formError = null;
    _wrongEmail = false;
    _wrongPassword = false;
    if (Validators.email(email.text) != null || password.text.isEmpty) {
      notifyListeners();
      return VerifyResult.invalid;
    }
    if (email.text.trim().toLowerCase() != flow.email.trim().toLowerCase()) {
      _wrongEmail = true;
      notifyListeners();
      return VerifyResult.invalid;
    }

    isLoading = true;
    notifyListeners();
    try {
      user = await _auth.logIn(email.text.trim(), password.text);
      return VerifyResult.verified;
    } on AuthException catch (e) {
      switch (e.failure) {
        case AuthFailure.emailNotVerified:
          return VerifyResult.notVerified;
        case AuthFailure.invalidCredentials:
        case AuthFailure.invalidEmail:
          _wrongPassword = true;
          return VerifyResult.wrongPassword;
        case AuthFailure.network:
          formError = AppStrings.networkError;
        case AuthFailure.tooManyRequests:
          formError = AppStrings.tooManyRequests;
        case AuthFailure.profileMissing:
          formError = AppStrings.profileMissing;
        default:
          formError = AppStrings.genericError;
      }
      return VerifyResult.failed;
    } catch (_) {
      formError = AppStrings.genericError;
      return VerifyResult.failed;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Sends a new link with the credentials kept in memory from step 1.
  Future<ResendOutcome> resend() async {
    if (isResending) return ResendOutcome.failed;
    isResending = true;
    formError = null;
    notifyListeners();
    try {
      final result = await _auth.resendVerification(flow.email, flow.password);
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
