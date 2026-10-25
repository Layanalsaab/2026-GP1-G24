import 'package:flutter/services.dart';

/// Removes emoji and pictographs from what is typed or pasted. Letters (also
/// Arabic), digits and normal punctuation are kept.
class NoEmojiFormatter extends TextInputFormatter {
  const NoEmojiFormatter();

  static bool _isEmoji(int r) =>
      (r >= 0x1F000 && r <= 0x1FAFF) || // pictographs, emoticons, flags
      (r >= 0x2600 && r <= 0x27BF) || // misc symbols, dingbats
      (r >= 0x2B00 && r <= 0x2BFF) || // arrows, stars
      (r >= 0x2190 && r <= 0x21FF) ||
      (r >= 0x2300 && r <= 0x23FF) ||
      r == 0x200D || // zero width joiner
      r == 0x20E3 || // keycap
      (r >= 0xFE00 && r <= 0xFE0F) || // variation selectors
      r == 0x00A9 ||
      r == 0x00AE ||
      r == 0x203C ||
      r == 0x2049 ||
      r == 0x2122 ||
      r == 0x2139 ||
      (r >= 0xE0000 && r <= 0xE007F); // tag characters

  /// [text] without emoji.
  static String strip(String text) =>
      String.fromCharCodes(text.runes.where((r) => !_isEmoji(r)));

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final clean = strip(newValue.text);
    if (clean == newValue.text) return newValue;
    // Keep the cursor after the characters that were kept before it.
    final before = strip(
      newValue.text.substring(
        0,
        newValue.selection.end.clamp(0, newValue.text.length),
      ),
    );
    return TextEditingValue(
      text: clean,
      selection: TextSelection.collapsed(offset: before.length),
    );
  }
}
