import '../app_constants/validation_strings.dart';

/// One line of the live password checklist.
class FieldRule {
  const FieldRule(this.label, this.met);

  final String label;
  final bool met;
}

/// Pure account-form validators, following docs/06 exactly. Each returns the
/// error message, or null when the value is valid. No Flutter or Firebase
/// imports, so they are trivial to unit test.
class Validators {
  Validators._();

  static const maxFullName = 50;
  static const maxEmail = 100;
  static const maxPassword = 32;
  static const maxLinkedin = 120;
  static const maxBio = 1000;
  static const maxValueText = 1000;
  static const maxOther = 40;
  static const phoneLength = 9;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _linkedinPattern = RegExp(
    r'^(https?://)?([a-z]{2,3}\.)?linkedin\.com/(in|company)/[A-Za-z0-9\-_%.]+/?$',
    caseSensitive: false,
  );

  /// A word of a name: letters in any language, with an apostrophe, dot or
  /// hyphen allowed inside, at least 2 characters (the original app rule for
  /// which characters a name may hold).
  static final _nameWord = RegExp(
    r"^[\p{L}\p{M}][\p{L}\p{M}'’.\-]+$",
    unicode: true,
  );

  // ------------------------------------------------------------ full name

  /// At least two words, each at least two letters.
  static bool isFullName(String? value) {
    final words = (value ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return words.length >= 2 && words.every(_nameWord.hasMatch);
  }

  static String? fullName(String? value) =>
      isFullName(value) ? null : ValidationStrings.fullName;

  // ---------------------------------------------------------------- email

  static bool isEmail(String? value) =>
      _emailPattern.hasMatch((value ?? '').trim());

  /// Log in, verify and forgot-password: "Please enter your email address."
  /// when empty, "Enter a valid email address" when malformed.
  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationStrings.emailRequired;
    if (!_emailPattern.hasMatch(v)) return ValidationStrings.emailInvalid;
    return null;
  }

  /// Live (while typing) full-name message: shown as soon as something is
  /// typed and it is not yet a first and last name.
  static String? fullNameLive(String? value) =>
      (value ?? '').trim().isEmpty || isFullName(value)
      ? null
      : ValidationStrings.fullName;

  /// Live phone message: once something is typed and it is not yet valid.
  static String? phoneLive(String? value) =>
      phoneDigits(value).isEmpty || isPhone(value)
      ? null
      : ValidationStrings.phoneInvalid;

  /// Live LinkedIn message: once something is typed and it is not a link.
  static String? linkedinLive(String? value) =>
      isLinkedin(value) ? null : ValidationStrings.linkedin;

  /// Sign-up: shown live once something is typed.
  static String? emailLive(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty || _emailPattern.hasMatch(v)) return null;
    return ValidationStrings.emailLive;
  }

  // ---------------------------------------------------------------- phone

  /// The digits of [value] (spaces and symbols removed), at most 9.
  static String phoneDigits(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length > phoneLength
        ? digits.substring(0, phoneLength)
        : digits;
  }

  /// Exactly 9 digits (spaces are not counted) and starting with 5.
  static bool isPhone(String? value) {
    final d = phoneDigits(value);
    return d.length == phoneLength && d.startsWith('5');
  }

  /// Sign-up: empty -> "Please enter your phone number.", wrong -> the
  /// 9-digit message.
  static String? phone(String? value) {
    if (phoneDigits(value).isEmpty) return ValidationStrings.phoneRequired;
    return isPhone(value) ? null : ValidationStrings.phoneInvalid;
  }

  /// Edit profile.
  static String? phoneEdit(String? value) =>
      isPhone(value) ? null : ValidationStrings.phoneEdit;

  // ------------------------------------------------------------- linkedin

  /// Optional: empty is fine.
  static bool isLinkedin(String? value) {
    final v = (value ?? '').trim();
    return v.isEmpty || _linkedinPattern.hasMatch(v);
  }

  static String? linkedin(String? value) =>
      isLinkedin(value) ? null : ValidationStrings.linkedin;

  // ------------------------------------------------------------- password

  /// The five live rules under the sign-up password field (8+ characters, one
  /// uppercase, one lowercase, one number, one special character).
  static List<FieldRule> passwordRules(String? value) {
    final p = value ?? '';
    return [
      FieldRule(ValidationStrings.ruleLength, p.length >= 8),
      FieldRule(ValidationStrings.ruleUpper, RegExp(r'[A-Z]').hasMatch(p)),
      FieldRule(ValidationStrings.ruleLower, RegExp(r'[a-z]').hasMatch(p)),
      FieldRule(ValidationStrings.ruleNumber, RegExp(r'[0-9]').hasMatch(p)),
      FieldRule(
        ValidationStrings.ruleSpecial,
        RegExp(r'[^A-Za-z0-9]').hasMatch(p),
      ),
    ];
  }

  static bool isPassword(String? value) =>
      passwordRules(value).every((r) => r.met);

  /// "Passwords don’t match" once something is typed in the confirm field.
  static String? confirmPassword(String? password, String? confirmation) {
    final c = confirmation ?? '';
    if (c.isEmpty || c == password) return null;
    return ValidationStrings.confirmMismatch;
  }

  static bool confirmMatches(String? password, String? confirmation) =>
      (confirmation ?? '').isNotEmpty && confirmation == password;

  // ----------------------------------------------------- selections / text

  static String? city(String? value) =>
      (value ?? '').trim().isEmpty ? ValidationStrings.city : null;

  static String? sectors(Iterable<String> selected) =>
      selected.isEmpty ? ValidationStrings.sectors : null;

  /// Required free text: [message] when blank.
  static String? requiredText(String? value, String message) =>
      (value ?? '').trim().isEmpty ? message : null;

  /// The text typed after choosing "Other": required, at most [maxOther].
  static bool isOtherText(String? value) {
    final v = (value ?? '').trim();
    return v.isNotEmpty && v.length <= maxOther;
  }
}
