import 'package:flutter/services.dart';

class PhoneInputFormatter extends TextInputFormatter {
  const PhoneInputFormatter({this.maxDigits = 9});

  final int maxDigits;

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
