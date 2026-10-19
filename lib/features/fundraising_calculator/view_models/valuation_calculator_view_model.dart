import 'package:flutter/widgets.dart';

import '../../../app_constants/validation_strings.dart';
import '../../../helpers/safe_notifier.dart';

/// State and math of the Valuation calculator (docs/05 D4, docs/06 section 9).
///
/// post = funding ÷ (equity / 100); pre = post − funding;
/// you = ownership × (100 − equity) / 100;
/// others = (100 − ownership) × (100 − equity) / 100;
/// value of your share = post × you / 100. Errors are live.
class ValuationCalculatorViewModel extends ChangeNotifier with SafeNotifier {
  ValuationCalculatorViewModel({int? funding, double? equityPercent}) {
    funds.text = funding == null ? '' : _group(funding);
    equity.text = equityPercent == null ? '' : formatNumber(equityPercent);
    ownership.text = lastOwnership;
    for (final c in [funds, equity, ownership]) {
      c.addListener(_changed);
    }
  }

  /// The ownership typed last, kept for the next time the calculator opens
  /// from Manage (default 100).
  static String lastOwnership = '100';

  final funds = TextEditingController();
  final equity = TextEditingController();
  final ownership = TextEditingController();

  void _changed() {
    lastOwnership = ownership.text;
    notifyListeners();
  }

  /// JavaScript-like `parseFloat` of the digits and dots in [text]; NaN when
  /// there is nothing to read.
  static double parse(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9.]'), '');
    final m = RegExp(r'^\d*\.?\d*').firstMatch(clean)?.group(0) ?? '';
    return double.tryParse(m) ?? double.nan;
  }

  double get fundingValue => parse(funds.text);
  double get equityValue => parse(equity.text);
  double get ownershipValue => parse(ownership.text);

  String? get fundingError =>
      fundingValue > 0 ? null : ValidationStrings.calcFunding;

  String? get equityError => (equityValue > 0 && equityValue < 100)
      ? null
      : ValidationStrings.calcEquity;

  String? get ownershipError =>
      (ownershipValue.isNaN || ownershipValue < 0 || ownershipValue > 100)
      ? ValidationStrings.calcOwnership
      : null;

  bool get isValid =>
      fundingError == null && equityError == null && ownershipError == null;

  double get post => isValid ? fundingValue / (equityValue / 100) : 0;
  double get pre => post - (isValid ? fundingValue : 0);
  double get you => isValid ? ownershipValue * (100 - equityValue) / 100 : 0;
  double get others =>
      isValid ? (100 - ownershipValue) * (100 - equityValue) / 100 : 0;
  double get newInvestors => isValid ? equityValue : 0;
  double get shareValue => post * you / 100;

  /// The "Other existing owners" row only shows below 100 % ownership.
  bool get hasOthers => isValid && ownershipValue < 100;

  // ---- Formatting

  static String _group(int n) {
    final digits = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
      b.write(digits[i]);
    }
    return b.toString();
  }

  /// 10 -> "10", 12.5 -> "12.5".
  static String formatNumber(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  /// 5000000 -> "SAR 5,000,000".
  static String sar(double n) => 'SAR ${_group(n.round())}';

  /// 72 -> "72%", 17.55 -> "17.6%" (one decimal, no trailing ".0").
  static String pct(double n) => '${formatNumber((n * 10).round() / 10)}%';

  String get postText => isValid ? sar(post) : 'SAR —';
  String get workText => isValid
      ? '${sar(fundingValue)} ÷ ${formatNumber(equityValue)}%'
      : 'Fill in the fields above';
  String get preText => isValid ? sar(pre) : 'SAR —';
  String get shareText => isValid ? sar(shareValue) : 'SAR —';
  String get youWork =>
      '${formatNumber(ownershipValue)}% × ${formatNumber(100 - equityValue)}%';
  String get othersWork =>
      '${formatNumber(100 - ownershipValue)}% × ${formatNumber(100 - equityValue)}%';

  @override
  void dispose() {
    for (final c in [funds, equity, ownership]) {
      c.removeListener(_changed);
      c.dispose();
    }
    super.dispose();
  }
}
