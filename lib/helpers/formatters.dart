import '../app_constants/startup_strings.dart';

/// Pure display formatters.
class Formatters {
  Formatters._();

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

  /// "https://www.example.com/" -> "example.com", for display.
  static String shortUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    final host = uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;
    final path = uri.path == '/' ? '' : uri.path;
    return '$host$path';
  }

  /// "just now", "5 minutes ago", "yesterday", "on 3 Mar 2026".
  static String relativeTime(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inMinutes < 1) return StartupStrings.justNow;
    if (diff.inHours < 1) return StartupStrings.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return StartupStrings.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return StartupStrings.daysAgo(diff.inDays);
    final month = StartupStrings.months[time.month - 1];
    return StartupStrings.onDate('${time.day} $month ${time.year}');
  }
}
