import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../helpers/safe_notifier.dart';

/// State and math of the Valuation calculator (docs/05 D4, docs/06 section 9).
///
/// post = funding ÷ (equity / 100); pre = post − funding;
/// you = ownership × (100 − equity) / 100;
/// others = (100 − ownership) × (100 − equity) / 100;
/// value of your share = post × you / 100. Errors are live.
class ValuationCalculatorViewModel extends ChangeNotifier with SafeNotifier {
  // valuation = the startup's current valuation, used as the pre-money.
  // if it's there, equity is worked out from it until the user types one.
  // from a request the equity is the investor's, so it doesn't follow.
  ValuationCalculatorViewModel({
    int? funding,
    double? equityPercent,
    int? valuation,
    bool ownershipUnknown = false,
  }) : _valuation = valuation != null && valuation > 0 ? valuation : null,
       _fixedEquity = equityPercent,
       _follow = equityPercent == null,
       _ownershipUnknown = ownershipUnknown {
    funds.text = funding == null ? '' : _group(funding);
    equity.text = _equityText(_follow ? _autoEquity : equityPercent);
    _shownEquity = equity.text;
    // starts fresh every time, nothing is saved
    ownership.text = ownershipUnknown ? '' : '100';
    _startFunds = funds.text;
    _startOwnership = ownership.text;
    for (final c in [funds, equity, ownership]) {
      c.addListener(_changed);
    }
  }

  late final String _startFunds;
  late final String _startOwnership;

  // last equity text we filled in ourselves
  String _shownEquity = '';
  bool _syncing = false;

  // A field only shows its error once the founder has typed in it: opening
  // the calculator with empty boxes must not look like a mistake.
  bool _fundsTouched = false;
  bool _equityTouched = false;
  bool _ownershipTouched = false;

  final int? _valuation;
  final double? _fixedEquity;
  final bool _follow;
  final bool _ownershipUnknown;

  // equity % = funding / (valuation + funding)
  static double? equityAt({int? funding, int? valuation}) {
    if (funding == null || valuation == null || valuation <= 0) return null;
    return _equityFor(funding.toDouble(), valuation);
  }

  static double? _equityFor(double funding, int valuation) =>
      funding.isNaN || funding <= 0
      ? null
      : funding * 100 / (valuation + funding);

  // 2 decimals max in the box
  static String _equityText(double? e) =>
      e == null ? '' : formatNumber((e * 100).round() / 100);

  double? get _autoEquity {
    final v = _valuation;
    return v == null ? null : _equityFor(fundingValue, v);
  }

  final funds = TextEditingController();
  final equity = TextEditingController();
  final ownership = TextEditingController();

  // hint under the ownership box when it's empty
  String? get ownershipHint =>
      _ownershipUnknown && ownership.text.trim().isEmpty
      ? FounderToolsStrings.calcOwnershipHint
      : null;

  void _changed() {
    if (_syncing) return;
    if (funds.text != _startFunds) _fundsTouched = true;
    if (equity.text != _shownEquity) _equityTouched = true;
    if (ownership.text != _startOwnership) _ownershipTouched = true;
    // user hasn't typed an equity yet, so keep it matching the funding
    if (!_equityTouched && _follow && _valuation != null) {
      final text = _equityText(_autoEquity);
      if (text != equity.text) {
        _syncing = true;
        equity.text = text;
        _syncing = false;
        _shownEquity = text;
      }
    }
    notifyListeners();
  }

  // percent boxes: a number from 0 to 100, one dot, 2 decimals at most
  // (same as shown), no extra zeros in front. anything else can't be typed.
  static final percentInput = TextInputFormatter.withFunction((
    oldValue,
    newValue,
  ) {
    final t = newValue.text;
    if (!RegExp(r'^(0|[1-9]\d{0,2})?(\.\d{0,2})?$').hasMatch(t)) {
      return oldValue;
    }
    final v = double.tryParse(t);
    return v != null && v > 100 ? oldValue : newValue;
  });

  /// JavaScript-like `parseFloat` of the digits and dots in [text]; NaN when
  /// there is nothing to read.
  static double parse(String text) {
    final clean = text.replaceAll(RegExp(r'[^0-9.]'), '');
    // more than one dot isn't a number
    if ('.'.allMatches(clean).length > 1) return double.nan;
    return double.tryParse(clean) ?? double.nan;
  }

  double get fundingValue => parse(funds.text);
  double get equityValue {
    if (_equityTouched) return parse(equity.text);
    if (_follow && _valuation != null) return _autoEquity ?? double.nan;
    return _fixedEquity ?? parse(equity.text);
  }

  double get ownershipValue => parse(ownership.text);

  // same minimum as the other money boxes in the app
  static const minFunding = 1000;

  bool get _fundingBad => !(fundingValue >= minFunding);
  bool get _equityBad => !(equityValue > 0 && equityValue < 100);
  // a founder can't own 0%
  bool get _ownershipBad => !(ownershipValue > 0 && ownershipValue <= 100);

  /// The messages shown under the boxes: only for a box the founder has
  /// typed in (an untouched, empty box is not red).
  String? get fundingError =>
      _fundingBad && (_fundsTouched || funds.text.isNotEmpty)
      ? (fundingValue > 0
            ? ValidationStrings.calcFundingMin
            : ValidationStrings.calcFunding)
      : null;

  String? get equityError =>
      _equityBad && (_equityTouched || equity.text.isNotEmpty)
      ? ValidationStrings.calcEquity
      : null;

  String? get ownershipError =>
      _ownershipBad && (_ownershipTouched || ownership.text.isNotEmpty)
      ? ValidationStrings.calcOwnership
      : null;

  /// All three boxes are valid (the result card uses this, not the messages).
  bool get isValid => !_fundingBad && !_equityBad && !_ownershipBad;

  double get post => isValid ? fundingValue / (equityValue / 100) : 0;
  double get pre => post - (isValid ? fundingValue : 0);
  double get you => isValid ? ownershipValue * (100 - equityValue) / 100 : 0;
  double get others =>
      isValid ? (100 - ownershipValue) * (100 - equityValue) / 100 : 0;
  double get newInvestors => isValid ? equityValue : 0;
  double get shareValue => post * you / 100;

  // the note under the green card when these terms don't match the
  // startup's own valuation. null when they match or there's no valuation.
  bool? get valuationLower {
    final v = _valuation;
    if (v == null || !isValid) return null;
    final own = _equityFor(fundingValue, v);
    // compare what's shown (2 decimals) so rounding never makes a note
    if (own == null || _two(own) == _two(equityValue)) return null;
    return equityValue > own;
  }

  String? get valuationNote {
    final lower = valuationLower;
    final v = _valuation;
    if (lower == null || v == null) return null;
    final own = _equityFor(fundingValue, v)!;
    return FounderToolsStrings.calcValuationNote(
      lower: lower,
      valuation: sar(v.toDouble()),
      funding: sar(fundingValue),
      own: '${_two(own)}%',
      shown: '${_two(equityValue)}%',
    );
  }

  // dilution box under the ownership card: "15 pts" and "60% → 45%"
  String get dilutionText =>
      '${formatNumber(((ownershipValue - you) * 10).round() / 10)} pts';
  String get ownershipChangeText => '${pct(ownershipValue)} → ${pct(you)}';

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
      ? '${sar(fundingValue)} ÷ ${_two(equityValue)}%'
      : 'Fill in the fields above';
  String get preText => isValid ? sar(pre) : 'SAR —';
  String get shareText => isValid ? sar(shareValue) : 'SAR —';
  String get youWork =>
      '${_two(ownershipValue)}% × ${_two(100 - equityValue)}%';
  String get othersWork =>
      '${_two(100 - ownershipValue)}% × ${_two(100 - equityValue)}%';

  // round to 2 decimals so it doesn't show 33.400000000000006
  static String _two(double v) => formatNumber((v * 100).round() / 100);

  @override
  void dispose() {
    for (final c in [funds, equity, ownership]) {
      c.removeListener(_changed);
      c.dispose();
    }
    super.dispose();
  }
}
