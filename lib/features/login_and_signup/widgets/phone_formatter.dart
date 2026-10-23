import 'package:flutter/services.dart';

/// Phone input of the sign-up form: digits only, capped at 9 (the digits are
/// what count), shown as "5X XXX XXXX" while typing. A pasted number such as
/// "+966 55-123-4567" or "0551234567" keeps working: the country code and a
/// leading zero are dropped first.
class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter({this.maxDigits = 9});

  final int maxDigits;

  /// The digits of [text] without a pasted "966" / "00966" / "0" prefix,
  /// at most [maxDigits].
  String digitsOf(String text) {
    var digits = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00966')) {
      digits = digits.substring(5);
    } else if (digits.startsWith('966') && digits.length > maxDigits) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0') && digits.length > maxDigits) {
      digits = digits.substring(1);
    }
    return digits.length > maxDigits ? digits.substring(0, maxDigits) : digits;
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOf(newValue.text);
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      // 5X XXX XXXX
      if (i == 2 || i == 5) out.write(' ');
      out.write(digits[i]);
    }
    final text = out.toString();
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
