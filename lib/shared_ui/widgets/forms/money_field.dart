import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'app_text_field.dart';

/// Digits-only input formatter that shows thousands separators
/// ("1200000" -> "1,200,000") and keeps at most [maxDigits] digits (13 for
/// money fields, 12 in the calculator).
class ThousandsFormatter extends TextInputFormatter {
  const ThousandsFormatter({this.maxDigits = 13});

  final int maxDigits;

  /// "1,200,000" -> 1200000 (null when empty).
  static int? parse(String text) {
    final d = text.replaceAll(RegExp('[^0-9]'), '');
    return d.isEmpty ? null : int.parse(d);
  }

  /// 1200000 -> "1,200,000".
  static String format(int n) => _group(n.toString());

  static String _group(String digits) {
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
      b.write(digits[i]);
    }
    return b.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    final cursor = newValue.selection.end.clamp(0, raw.length);
    var digits = '';
    var digitsBeforeCursor = 0;
    for (var i = 0; i < raw.length; i++) {
      final c = raw[i];
      if (c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57) {
        if (digits.length >= maxDigits) continue;
        digits += c;
        if (i < cursor) digitsBeforeCursor++;
      }
    }
    // Drop leading zeros except a single "0".
    while (digits.length > 1 && digits.startsWith('0')) {
      digits = digits.substring(1);
      if (digitsBeforeCursor > 0) digitsBeforeCursor--;
    }
    final text = _group(digits);
    var offset = 0;
    var seen = 0;
    while (offset < text.length && seen < digitsBeforeCursor) {
      if (text[offset] != ',') seen++;
      offset++;
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// A money input: digits only, thousands separators, at most [maxDigits]
/// (13) digits, optional prefix ("SAR" by default), placeholder "0".
/// Wraps [AppTextField]; wrap it in an `AppField` for label / error.
class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    this.controller,
    this.value,
    this.onChanged,
    this.prefix = 'SAR',
    this.hint = '0',
    this.maxDigits = 13,
    this.hasError = false,
    this.semanticLabel,
    this.dense = false,
  });

  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;

  /// Null removes the prefix (trio boxes).
  final String? prefix;
  final String hint;
  final int maxDigits;
  final bool hasError;
  final String? semanticLabel;

  /// 46 px trio box.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      value: value,
      onChanged: onChanged,
      hint: hint,
      prefix: prefix,
      semanticLabel: semanticLabel,
      hasError: hasError,
      dense: dense,
      keyboardType: TextInputType.number,
      inputFormatters: [ThousandsFormatter(maxDigits: maxDigits)],
    );
  }
}

/// One cell of a [TrioField].
class TrioEntry {
  const TrioEntry({
    required this.label,
    this.controller,
    this.value,
    this.onChanged,
    this.hasError = false,
  });

  /// "Year 1", "TAM", "Minimum"...
  final String label;
  final TextEditingController? controller;
  final String? value;
  final ValueChanged<String>? onChanged;
  final bool hasError;
}

/// How a [TrioField] arranges its cells.
enum TrioLayout {
  /// Side by side with the label above each box (Year 1/2/3, Minimum/Maximum).
  row,

  /// One row per cell with the label inline on the left (TAM / SAM / SOM).
  stack,
}

/// 2 or 3 money boxes (docs/02, 06): expected revenue Year 1/2/3, round sizes
/// Minimum/Maximum (both [TrioLayout.row], gap 8, label 12/600 grey above a 46
/// px box with placeholder "0") and the stacked TAM / SAM / SOM rows (label
/// 13 ink in a 40 px column, gap 12, boxes with the "SAR" prefix).
class TrioField extends StatelessWidget {
  const TrioField({
    super.key,
    required this.entries,
    this.layout = TrioLayout.row,
  });

  final List<TrioEntry> entries;
  final TrioLayout layout;

  @override
  Widget build(BuildContext context) {
    if (layout == TrioLayout.stack) {
      return Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    entries[i].label,
                    style: AppText.sans(size: 13, color: AppColors.ink),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _box(entries[i], prefix: 'SAR')),
              ],
            ),
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  entries[i].label,
                  style: AppText.sans(
                    size: 12,
                    weight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                _box(entries[i]),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _box(TrioEntry e, {String? prefix}) => MoneyField(
    controller: e.controller,
    value: e.value,
    onChanged: e.onChanged,
    prefix: prefix,
    dense: true,
    hasError: e.hasError,
    semanticLabel: e.label,
  );
}
