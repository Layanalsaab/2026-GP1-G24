import '../app_constants/validation_strings.dart';

/// How much a funding round may raise (SAR).
class RoundLimits {
  RoundLimits._();

  /// The least a round can raise: SAR 1,000.
  static const int min = 1000;

  /// True when amount is allowed.
  static bool allows(int amount) => amount >= min;

  /// The message for an amount under min, or null when it is fine.
  static String? error(int amount) =>
      allows(amount) ? null : ValidationStrings.fundingMin;
}
