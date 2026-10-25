import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/helpers/emoji_filter.dart';

void main() {
  test('emoji are removed, letters and Arabic are kept', () {
    expect(NoEmojiFormatter.strip('Hi 😀 there 👍🏽 ❤️'), 'Hi  there  ');
    expect(NoEmojiFormatter.strip('مرحبا Layan 123'), 'مرحبا Layan 123');
  });

  test('typing an emoji changes nothing', () {
    const f = NoEmojiFormatter();
    const old = TextEditingValue(
      text: 'ab',
      selection: TextSelection.collapsed(offset: 2),
    );
    const typed = TextEditingValue(
      text: 'ab😀',
      selection: TextSelection.collapsed(offset: 4),
    );
    final out = f.formatEditUpdate(old, typed);
    expect(out.text, 'ab');
    expect(out.selection.end, 2);
  });
}
