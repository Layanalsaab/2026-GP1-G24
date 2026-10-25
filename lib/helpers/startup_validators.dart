import '../app_constants/validation_strings.dart';
import '../models/startup_enums.dart';
import 'round_limits.dart';

/// Pure validators for the Add / Edit startup steps (docs/06 section 8).
/// Each returns the error message, or null when the value is valid. Inputs
/// are the raw text from the fields.
class StartupValidators {
  StartupValidators._();

  static const nameMax = 40;
  static const descriptionMax = 150;
  static const longTextMax = 1000;
  static const websiteMax = 100;
  static const firstFoundedYear = 1900;
  static const maxMoneyDigits = 13;

  static String? name(String v) =>
      v.trim().isEmpty ? ValidationStrings.startupName : null;

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

  /// A real web address: optional http:// or https:// (no other scheme),
  /// optional www., one or more domain parts (letters, numbers, inner
  /// hyphens) each followed by a dot, a top-level domain of 2+ letters, then
  /// an optional port and path. No spaces.
  static final _website = RegExp(
    r'^(https?:\/\/)?(www\.)?([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,24}(:[0-9]{2,5})?(\/\S*)?$',
    caseSensitive: false,
  );

  /// Optional: empty is fine; anything typed must be a valid website.
  static String? websiteUrl(String value) {
    if (value.trim().isEmpty) return null;
    return isWebsite(value) ? null : ValidationStrings.websiteInvalid;
  }

  static bool isWebsite(String value) => _website.hasMatch(value.trim());

  /// The trimmed address as saved, or null when it is not a valid website.
  /// (Opening it adds https:// when there is no scheme.)
  static String? normalizeUrl(String value) =>
      isWebsite(value) ? value.trim() : null;

  // ---- Step 2 ----
  static String? problem(String v) =>
      v.trim().isEmpty ? ValidationStrings.problem : null;
  static String? solution(String v) =>
      v.trim().isEmpty ? ValidationStrings.solution : null;
  static String? customers(String v) =>
      v.trim().isEmpty ? ValidationStrings.targetCustomers : null;
  static String? advantage(String v) =>
      v.trim().isEmpty ? ValidationStrings.different : null;

  /// Target market size: required, a positive SAR amount.
  static String? marketSize(String v) {
    final n = money(v);
    if (n == null) return ValidationStrings.marketSize;
    return n <= 0 ? ValidationStrings.marketSizeZero : null;
  }

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

  /// Required, and 0 is allowed.
  static bool valuationOk(String v) => money(v) != null;

  static String? valuation(String v) =>
      valuationOk(v) ? null : ValidationStrings.valuation;

  /// Revenue this financial year and the monthly burn: required, 0 allowed.
  static String? revenueNow(String v) =>
      money(v) == null ? ValidationStrings.revenueNow : null;
  static String? burn(String v) =>
      money(v) == null ? ValidationStrings.burn : null;

  static String? businessModelText(String v) =>
      v.trim().isEmpty ? ValidationStrings.businessModel : null;

  static String? leadInvestor(bool? answer) =>
      answer == null ? ValidationStrings.chooseOne : null;

  /// "How much are you raising?": required, and inside the limits of the
  /// round type ([stage]).
  static String? funding(String v, [StartupStage? stage]) {
    final amount = money(v);
    if (amount == null) return ValidationStrings.funding;
    return RoundLimits.error(stage, amount) ??
        (amount <= 0 ? ValidationStrings.funding : null);
  }

  /// "How much have you already raised in this round?": required (0 is
  /// fine) and not more than the amount being raised.
  static String? raisedInRound(String raised, String funding) {
    final r = money(raised);
    if (r == null) return ValidationStrings.raisedEmpty;
    final f = money(funding);
    return f != null && r > f ? ValidationStrings.raisedTooMuch : null;
  }

  static String? partnerTypes(Iterable<Object> selected) =>
      selected.isEmpty ? ValidationStrings.partnerTypes : null;
  static String? supportTypes(Iterable<Object> selected) =>
      selected.isEmpty ? ValidationStrings.supportTypes : null;

  static String? lookingFor(Iterable<Object> selected) =>
      selected.isEmpty ? ValidationStrings.selectAtLeastOne : null;
}
