import '../app_constants/validation_strings.dart';

/// Pure validators for the Add / Edit startup steps (docs/06 section 8).
/// Each returns the error message, or null when the value is valid. Inputs
/// are the raw text from the fields.
class StartupValidators {
  StartupValidators._();

  static const nameMax = 40;
  static const pitchMax = 120;
  static const descriptionMax = 1500;
  static const longTextMax = 1000;
  static const websiteMax = 100;
  static const firstFoundedYear = 1900;
  static const maxMoneyDigits = 13;

  static String? name(String v) =>
      v.trim().isEmpty ? ValidationStrings.startupName : null;

  static String? pitch(String v) =>
      v.trim().isEmpty ? ValidationStrings.startupPitch : null;

  static String? description(String v) =>
      v.trim().isEmpty ? ValidationStrings.startupDescription : null;

  /// A required select: [message] when nothing is chosen.
  static String? selected(Object? value, String message) =>
      value == null || (value is String && value.isEmpty) ? message : null;

  /// Required, 1900 up to the current year. [now] is injectable for tests.
  static String? foundedYear(String value, {DateTime? now}) {
    final text = value.trim();
    if (text.isEmpty) return ValidationStrings.foundedRequired;
    final last = (now ?? DateTime.now()).year;
    final year = int.tryParse(text);
    if (text.length == 4 &&
        (year == null || year < firstFoundedYear || year > last)) {
      return ValidationStrings.foundedRange(last);
    }
    if (text.length < 4) return ValidationStrings.foundedRange(last);
    return null;
  }

  /// True when [value] is a complete, valid year (for the green check).
  static bool isFoundedYear(String value, {DateTime? now}) =>
      foundedYear(value, now: now) == null;

  /// Optional. Accepts addresses without a scheme ("example.com").
  static String? websiteUrl(String value) {
    if (value.trim().isEmpty) return null;
    return normalizeUrl(value) == null
        ? ValidationStrings.websiteInvalid
        : null;
  }

  /// "example.com" -> "https://example.com". Null when it isn't a usable
  /// http(s) address with a real domain (something.tld).
  static String? normalizeUrl(String value) {
    final text = value.trim();
    if (text.isEmpty || text.contains(' ')) return null;
    final withScheme = text.contains('://') ? text : 'https://$text';
    final uri = Uri.tryParse(withScheme);
    if (uri == null) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    final labels = uri.host.split('.');
    final looksLikeDomain =
        labels.length >= 2 &&
        labels.every(
          (l) => RegExp(
            r'^[\p{L}\p{N}](?:[\p{L}\p{N}-]*[\p{L}\p{N}])?$',
            unicode: true,
          ).hasMatch(l),
        ) &&
        RegExp(r'^[a-zA-Z]{2,}$').hasMatch(labels.last);
    return looksLikeDomain ? uri.toString() : null;
  }

  // ---- Step 2 ----
  static String? problem(String v) =>
      v.trim().isEmpty ? ValidationStrings.problem : null;
  static String? solution(String v) =>
      v.trim().isEmpty ? ValidationStrings.solution : null;
  static String? customers(String v) =>
      v.trim().isEmpty ? ValidationStrings.targetCustomers : null;
  static String? advantage(String v) =>
      v.trim().isEmpty ? ValidationStrings.different : null;

  // ---- Step 4 ----
  static String? growth(String v) =>
      v.trim().isEmpty ? ValidationStrings.growth : null;

  /// A money field's digits, or null when empty. "1,200,000" -> 1200000.
  static int? money(String v) {
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  static String? capital(String v) =>
      money(v) == null ? ValidationStrings.capital : null;

  static String? revenue(String y1, String y2, String y3) =>
      money(y1) != null && money(y2) != null && money(y3) != null
      ? null
      : ValidationStrings.revenue;

  /// Required, and 0 is allowed. Shows no error text: it only keeps Next
  /// grey, so this returns a bool.
  static bool valuationOk(String v) => money(v) != null;

  static String? leadInvestor(bool? answer) =>
      answer == null ? ValidationStrings.chooseOne : null;

  static String? funding(String v) {
    final amount = money(v);
    return amount == null || amount <= 0 ? ValidationStrings.funding : null;
  }

  static String? lookingFor(Iterable<Object> selected) =>
      selected.isEmpty ? ValidationStrings.selectAtLeastOneOption : null;
}
