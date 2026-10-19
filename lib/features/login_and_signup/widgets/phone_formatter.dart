import 'package:flutter/services.dart';

/// Phone input of the sign-up form: only digits and spaces are accepted and
/// the number is capped at 9 digits (spaces are not counted, docs/06 §1).
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter({this.maxDigits = 9});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final out = StringBuffer();
    var digits = 0;
    for (final unit in newValue.text.codeUnits) {
      final ch = String.fromCharCode(unit);
      if (unit >= 0x30 && unit <= 0x39) {
        if (digits < maxDigits) {
          out.write(ch);
          digits++;
        }
      } else if (ch == ' ') {
        out.write(ch);
      }
    }
    final text = out.toString();
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
