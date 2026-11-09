import '../app_constants/startup_strings.dart';

/// Pure display formatters.
class Formatters {
  Formatters._();

  static const _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
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

  /// 500000 -> "SAR 500K", 1200000 -> "SAR 1.2M" (card tags).
  static String compactSar(int value) {
    if (value >= 1000000000) {
      // Billions stay in millions here ("SAR 2400M"), as before.
      final millions = value / 1000000;
      final text = millions == millions.roundToDouble()
          ? millions.toStringAsFixed(0)
          : millions.toStringAsFixed(1);
      return '${StartupStrings.sar} ${text}M';
    }
    // Below a billion this is [shortMoney], so 999,999 reads "SAR 1M" (not
    // "SAR 1000K").
    if (value >= 1000) return '${StartupStrings.sar} ${shortMoney(value)}';
    return sar(value);
  }

  /// 2400000000 -> "2.4B", 600000000 -> "600M", 24000 -> "24K". One decimal
  /// for B and M (a trailing ".0" is dropped), whole numbers for K. The
  /// prototype's `shortMoney`: used in the market-size legend, revenue bars
  /// and on cards. A value that rounds up to the next unit uses it
  /// (999,999 -> "1M", not "1000K").
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

  /// "https://www.example.com/" -> "example.com", for display.
  static String shortUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    final host = uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
    final path = uri.path == '/' ? '' : uri.path;
    return '$host$path';
  }
}
