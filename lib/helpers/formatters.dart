import '../app_constants/startup_strings.dart';

/// Pure display formatters.
class Formatters {
  Formatters._();

  static const _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// A date as "8 Nov 2026" (the Closed banner).
  static String dayMonthYear(DateTime date) =>
      '${date.day} ${_monthsShort[date.month - 1]} ${date.year}';

  /// 1500000 -> "1,500,000".
  static String thousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// 1500000 -> "SAR 1,500,000".
  static String sar(int value) => '${StartupStrings.sar} ${thousands(value)}';

  /// 2400000000 -> "2.4B", 600000000 -> "600M", 24000 -> "24K".
  static String shortMoney(int value) {
    String trim(double v) {
      final t = v.toStringAsFixed(1);
      return t.endsWith('.0') ? t.substring(0, t.length - 2) : t;
    }

    if (value >= 999950000) return '${trim(value / 1000000000)}B';
    if (value >= 999500) return '${trim(value / 1000000)}M';
    if (value >= 1000) return '${(value / 1000).round()}K';
    return '$value';
  }

  /// "SAR 2.4B".
  static String sarShort(int value) =>
      '${StartupStrings.sar} ${shortMoney(value)}';

  /// Digits only: "1,200,000" -> 1200000, "" -> null.
  static int? parseMoney(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }
}
