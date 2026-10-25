import '../models/startup_enums.dart';

/// How much a funding round of each type may raise (SAR). One shared helper
/// for the Startup Ask step and the Manage -> Rounds form.
///
/// | Round type | Allowed amount                          |
/// | Pre-seed   | 150,000 to 2,000,000 (both inclusive)   |
/// | Seed       | more than 2,000,000, up to 7,500,000    |
/// | Series A   | more than 7,500,000, up to 55,000,000   |
/// | Series B   | more than 55,000,000, up to 190,000,000 |
/// | Series C   | more than 190,000,000, no maximum       |
class RoundLimits {
  RoundLimits._();

  static ({int low, int? high, bool lowInclusive})? _of(
    StartupStage? stage,
  ) => switch (stage) {
    StartupStage.preSeed => (low: 150000, high: 2000000, lowInclusive: true),
    StartupStage.seed => (low: 2000000, high: 7500000, lowInclusive: false),
    StartupStage.seriesA => (low: 7500000, high: 55000000, lowInclusive: false),
    StartupStage.seriesB => (
      low: 55000000,
      high: 190000000,
      lowInclusive: false,
    ),
    StartupStage.seriesC => (low: 190000000, high: null, lowInclusive: false),
    _ => null,
  };

  /// "150,000" style grouping.
  static String commas(int v) {
    final digits = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
      b.write(digits[i]);
    }
    return b.toString();
  }

  static String _sar(int v) => 'SAR ${commas(v)}';

  /// True when [amount] is allowed for [stage] (no limits for an unknown one).
  static bool allows(StartupStage? stage, int amount) {
    final r = _of(stage);
    if (r == null) return true;
    final aboveLow = r.lowInclusive ? amount >= r.low : amount > r.low;
    return aboveLow && (r.high == null || amount <= r.high!);
  }

  /// The one-line hint under the amount field.
  static String? hint(StartupStage? stage) {
    final r = _of(stage);
    if (r == null || stage == null) return null;
    final name = stage.label;
    if (r.high == null) return '$name: over ${_sar(r.low)}';
    return r.lowInclusive
        ? '$name: ${_sar(r.low)} to ${commas(r.high!)}'
        : '$name: over ${_sar(r.low)} to ${commas(r.high!)}';
  }

  /// The message for an amount outside the range, or null when it fits.
  static String? error(StartupStage? stage, int amount) {
    final r = _of(stage);
    if (r == null || stage == null || allows(stage, amount)) return null;
    final name = stage.label;
    final lead = 'That amount isn’t in the $name range.';
    if (r.high == null) return '$lead Enter more than ${_sar(r.low)}.';
    return r.lowInclusive
        ? '$lead Enter between ${_sar(r.low)} and ${_sar(r.high!)}.'
        : '$lead Enter more than ${_sar(r.low)} and up to ${_sar(r.high!)}.';
  }
}
