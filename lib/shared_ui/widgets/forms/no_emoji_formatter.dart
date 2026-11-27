import 'package:flutter/services.dart';

/// Typing or pasting anything with an emoji does nothing, including the
/// space some keyboards add right after an emoji.
class NoEmojiFormatter extends TextInputFormatter {
  const NoEmojiFormatter();

  static const _pattern =
      r'[\p{Extended_Pictographic}\p{Regional_Indicator}\p{Emoji_Modifier}'
      r'⃣️‍\u{E0020}-\u{E007F}]';
  static final _emoji = RegExp(_pattern, unicode: true);

  static const _spaceWindow = Duration(milliseconds: 600);
  static DateTime? _rejectedAt;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_emoji.allMatches(newValue.text).length >
        _emoji.allMatches(oldValue.text).length) {
      _rejectedAt = DateTime.now();
      return oldValue;
    }
    final rejectedAt = _rejectedAt;
    if (rejectedAt != null &&
        DateTime.now().difference(rejectedAt) < _spaceWindow &&
        _addsOneSpace(oldValue, newValue)) {
      _rejectedAt = null;
      return oldValue;
    }
    return newValue;
  }

  static bool _addsOneSpace(TextEditingValue a, TextEditingValue b) {
    final at = a.selection.end;
    if (at < 0 || b.text.length != a.text.length + 1) return false;
    return b.text == '${a.text.substring(0, at)} ${a.text.substring(at)}';
  }
}
