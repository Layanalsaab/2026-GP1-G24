import '../app_constants/app_strings.dart';

/// Pure form validators. Each returns an error message, or null when valid.
/// No Flutter or Firebase imports, so they are trivial to unit test and can be
/// reused later (reset password, change password).
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// Minimum length for passwords. Firebase only enforces 6, so we enforce more.
  static const minPasswordLength = 8;

  static String? fullName(String? value) {
    if ((value ?? '').trim().isEmpty) return AppStrings.fullNameRequired;
    return null;
  }

  static String? email(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return AppStrings.emailRequired;
    if (!_emailPattern.hasMatch(email)) return AppStrings.emailInvalid;
    return null;
  }

  /// Password rules: 8+ characters, one uppercase, one lowercase, one number.
  /// Returns the first rule that fails.
  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return AppStrings.passwordRequired;
    if (password.length < minPasswordLength) return AppStrings.passwordTooShort;
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return AppStrings.passwordNeedsUppercase;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return AppStrings.passwordNeedsLowercase;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return AppStrings.passwordNeedsNumber;
    }
    return null;
  }

  static String? confirmPassword(String? password, String? confirmation) {
    if ((confirmation ?? '').isEmpty) return AppStrings.confirmPasswordRequired;
    if (password != confirmation) return AppStrings.passwordsDontMatch;
    return null;
  }
}
