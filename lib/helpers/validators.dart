import '../app_constants/app_strings.dart';

/// One line of a live checklist shown under a field ("At least 8 characters").
/// [met] flips from false (red) to true (green) as the user types.
class FieldRule {
  const FieldRule(this.label, this.met);

  final String label;
  final bool met;
}

/// Pure form validators. Each returns an error message, or null when valid.
/// The `*Rules` methods return the same checks as a checklist, for live
/// feedback while typing. No Flutter or Firebase imports, so they are trivial
/// to unit test and can be reused later (reset password, change password).
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  /// Letters in any language, plus spaces, apostrophes, dots and hyphens.
  static final _namePattern = RegExp(r"^[\p{L}\p{M}\s'’.\-]+$", unicode: true);

  /// Saudi mobile numbers: 9 digits, starting with 5 (without the +966).
  static final _phonePattern = RegExp(r'^5\d{8}$');

  static final _uppercase = RegExp(r'[A-Z]');
  static final _lowercase = RegExp(r'[a-z]');
  static final _digit = RegExp(r'[0-9]');
  static final _special = RegExp(r'[^A-Za-z0-9\s]');

  /// Minimum length for passwords. Firebase only enforces 6, so we enforce more.
  static const minPasswordLength = 8;

  static const maxFullNameLength = 50;
  static const maxEmailLength = 100;
  static const maxPasswordLength = 32;
  static const phoneLength = 9;
  static const maxBioLength = 160;

  // ------------------------------------------------------------ full name

  static List<FieldRule> fullNameRules(String? value) {
    final name = (value ?? '').trim();
    return [
      FieldRule(AppStrings.ruleNameLength, name.length >= 2),
      FieldRule(
        AppStrings.ruleNameLetters,
        name.isNotEmpty && _namePattern.hasMatch(name),
      ),
    ];
  }

  static String? fullName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return AppStrings.fullNameRequired;
    if (name.length < 2) return AppStrings.fullNameTooShort;
    if (!_namePattern.hasMatch(name)) return AppStrings.fullNameLettersOnly;
    return null;
  }

  // ---------------------------------------------------------------- email

  static List<FieldRule> emailRules(String? value) {
    final email = (value ?? '').trim();
    return [
      FieldRule(
        AppStrings.ruleEmailAt,
        RegExp(r'^[^\s@]+@[^@]*$').hasMatch(email),
      ),
      FieldRule(
        AppStrings.ruleEmailDomain,
        RegExp(r'@[^\s@]+\.[^\s@]{2,}$').hasMatch(email),
      ),
    ];
  }

  static String? email(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return AppStrings.emailRequired;
    if (!_emailPattern.hasMatch(email)) return AppStrings.emailInvalid;
    return null;
  }

  // ---------------------------------------------------------------- phone

  static List<FieldRule> phoneRules(String? value) {
    final phone = value ?? '';
    return [
      FieldRule(
        AppStrings.rulePhoneDigits,
        phone.length == phoneLength && RegExp(r'^\d+$').hasMatch(phone),
      ),
      FieldRule(AppStrings.rulePhoneStart, phone.startsWith('5')),
    ];
  }

  /// [value] is the number without the +966 country code.
  static String? phone(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return AppStrings.phoneRequired;
    if (!_phonePattern.hasMatch(phone)) return AppStrings.phoneInvalid;
    return null;
  }

  // ------------------------------------------------------------- password

  static List<FieldRule> passwordRules(String? value) {
    final password = value ?? '';
    return [
      FieldRule(
        AppStrings.rulePasswordLength,
        password.length >= minPasswordLength,
      ),
      FieldRule(AppStrings.rulePasswordUpper, password.contains(_uppercase)),
      FieldRule(AppStrings.rulePasswordLower, password.contains(_lowercase)),
      FieldRule(AppStrings.rulePasswordNumber, password.contains(_digit)),
      FieldRule(AppStrings.rulePasswordSpecial, password.contains(_special)),
    ];
  }

  /// Password rules: 8+ characters, one uppercase, one lowercase, one number,
  /// one special character. Returns the first rule that fails.
  static String? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return AppStrings.passwordRequired;
    if (password.length < minPasswordLength) return AppStrings.passwordTooShort;
    if (!password.contains(_uppercase)) {
      return AppStrings.passwordNeedsUppercase;
    }
    if (!password.contains(_lowercase)) {
      return AppStrings.passwordNeedsLowercase;
    }
    if (!password.contains(_digit)) return AppStrings.passwordNeedsNumber;
    if (!password.contains(_special)) return AppStrings.passwordNeedsSpecial;
    return null;
  }

  static List<FieldRule> confirmPasswordRules(
    String? password,
    String? confirmation,
  ) =>
      [
        FieldRule(
          AppStrings.ruleConfirmMatches,
          (confirmation ?? '').isNotEmpty && password == confirmation,
        ),
      ];

  static String? confirmPassword(String? password, String? confirmation) {
    if ((confirmation ?? '').isEmpty) return AppStrings.confirmPasswordRequired;
    if (password != confirmation) return AppStrings.passwordsDontMatch;
    return null;
  }

  // ----------------------------------------------------- other form fields

  static String? city(String? value) =>
      (value ?? '').isEmpty ? AppStrings.cityRequired : null;

  static String? sectors(List<String> value) =>
      value.isEmpty ? AppStrings.sectorsRequired : null;
}
