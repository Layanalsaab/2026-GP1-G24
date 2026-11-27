import '../app_constants/validation_strings.dart';

/// One line of the live password checklist.
class FieldRule {
  const FieldRule(this.label, this.met);

  final String label;
  final bool met;
}

/// Pure account-form validators, following docs/06 exactly.
class Validators {
  Validators._();

  static const maxFullName = 50;
  static const maxEmail = 100;
  static const maxPassword = 32;

  /// Founder sign-up bio (required).
  static const maxFounderBio = 2000;
  static const maxValueText = 1000;
  static const maxOther = 40;
  static const phoneLength = 9;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static final _linkedinHost = RegExp(
    r'^([a-z0-9\-]+\.)*linkedin\.com$',
    caseSensitive: false,
  );

  static final _nameWord = RegExp(
    r"^[\p{L}\p{M}][\p{L}\p{M}'’.\-]+$",
    unicode: true,
  );

  /// At least two words, each at least two letters.
  static bool isFullName(String? value) {
    final words = (value ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    return words.length >= 2 && words.every(_nameWord.hasMatch);
  }

  static String? fullName(String? value) => hasDigit(value)
      ? ValidationStrings.nameNoNumbers
      : (isFullName(value) ? null : ValidationStrings.fullName);

  /// True when value has a digit (names can't contain numbers).
  static bool hasDigit(String? value) => RegExp(r'\d').hasMatch(value ?? '');

  static bool _wellFormed(String v) {
    if (!_emailPattern.hasMatch(v)) return false;
    final labels = v.substring(v.lastIndexOf('@') + 1).toLowerCase().split('.');
    final n = labels.length;
    return n < 2 || labels[n - 1] != labels[n - 2];
  }

  static String? email(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return ValidationStrings.emailRequired;
    if (!isEmail(v)) return ValidationStrings.emailInvalid;
    return null;
  }

  /// The email domains accepted everywhere: the common providers.
  static const _allowedDomains = {
    'gmail.com',
    'hotmail.com',
    'outlook.com',
    'live.com',
    'yahoo.com',
    'icloud.com',
    'msn.com',
    'me.com',
    'aol.com',
    'proton.me',
    'protonmail.com',
  };

  static final _universityDomain = RegExp(
    r'^([a-z0-9\-]+\.)+(edu|edu\.[a-z]{2}|ac\.[a-z]{2})$',
  );

  static bool _isUniversityDomain(String domain) =>
      _universityDomain.hasMatch(domain);

  /// A well-formed email at a common provider or a university.
  static bool isEmail(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    if (!_wellFormed(v)) return false;
    final domain = v.substring(v.lastIndexOf('@') + 1);
    return _allowedDomains.contains(domain) || _isUniversityDomain(domain);
  }

  static String? fullNameLive(String? value) => hasDigit(value)
      ? ValidationStrings.nameNoNumbers
      : ((value ?? '').trim().isEmpty || isFullName(value)
            ? null
            : ValidationStrings.fullName);

  /// Live phone message: once something is typed and it is not yet valid.
  static String? phoneLive(String? value) =>
      phoneDigits(value).isEmpty || isPhone(value)
      ? null
      : ValidationStrings.phoneInvalid;

  /// Live LinkedIn message: once something is typed and it is not a link.
  static String? linkedinLive(String? value) =>
      isLinkedin(value) ? null : ValidationStrings.linkedin;

  /// The digits of value (spaces and symbols removed), at most 9.
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

  static String? phone(String? value) {
    if (phoneDigits(value).isEmpty) return ValidationStrings.phoneRequired;
    return isPhone(value) ? null : ValidationStrings.phoneInvalid;
  }

  /// Edit profile.
  static String? phoneEdit(String? value) =>
      isPhone(value) ? null : ValidationStrings.phoneEdit;

  /// Optional: empty is fine.
  static bool isLinkedin(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return true;
    if (RegExp(r'\s').hasMatch(v)) return false;
    final withScheme =
        RegExp(r'^[a-z][a-z0-9+.\-]*://', caseSensitive: false).hasMatch(v)
        ? v
        : 'https://$v';
    final uri = Uri.tryParse(withScheme);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return false;
    }
    final host = uri.host.toLowerCase();
    if (host == 'lnkd.in' || host == 'www.lnkd.in') {
      return uri.pathSegments.where((p) => p.isNotEmpty).isNotEmpty;
    }
    if (!_linkedinHost.hasMatch(host)) return false;
    final segments = uri.pathSegments.where((p) => p.isNotEmpty).toList();
    // mobile links: /mwlite/in/NAME
    if (segments.isNotEmpty && segments.first.toLowerCase() == 'mwlite') {
      segments.removeAt(0);
    }
    if (segments.length < 2) return false;
    final kind = segments.first.toLowerCase();
    return (kind == 'in' || kind == 'company') && segments[1].isNotEmpty;
  }

  static String? linkedin(String? value) =>
      isLinkedin(value) ? null : ValidationStrings.linkedin;

  static List<FieldRule> passwordRules(String? value) {
    final p = value ?? '';
    return [
      FieldRule(ValidationStrings.ruleLength, p.length >= 8),
      FieldRule(ValidationStrings.ruleUpper, RegExp(r'[A-Z]').hasMatch(p)),
      FieldRule(ValidationStrings.ruleLower, RegExp(r'[a-z]').hasMatch(p)),
      FieldRule(ValidationStrings.ruleNumber, RegExp(r'[0-9]').hasMatch(p)),
      FieldRule(
        ValidationStrings.ruleSpecial,
        // A space is not a special character.
        RegExp(r'[^A-Za-z0-9\s]').hasMatch(p),
      ),
    ];
  }

  static bool isPassword(String? value) =>
      !RegExp(r'\s').hasMatch(value ?? '') &&
      passwordRules(value).every((r) => r.met);

  static bool confirmMatches(String? password, String? confirmation) =>
      (confirmation ?? '').isNotEmpty && confirmation == password;

  static String? city(String? value) =>
      (value ?? '').trim().isEmpty ? ValidationStrings.city : null;

  static String? sectors(Iterable<String> selected) =>
      selected.isEmpty ? ValidationStrings.sectors : null;

  /// Required free text: message when blank.
  static String? requiredText(String? value, String message) =>
      (value ?? '').trim().isEmpty ? message : null;

  /// The text typed after choosing "Other": required, at most maxOther.
  static bool isOtherText(String? value) {
    final v = (value ?? '').trim();
    return v.isNotEmpty && v.length <= maxOther;
  }
}
