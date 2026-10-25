import 'package:flutter/material.dart';

import '../../../data_access/mock_data/prototype_seed.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../helpers/formatters.dart';
import '../../../helpers/round_limits.dart';
import '../../../helpers/startup_validators.dart';
import '../../../models/funding_round.dart';
import '../../../models/startup_enums.dart';

/// State of Manage -> Rounds (INTERFACE ONLY): the list of rounds in local
/// memory, the "Add round" form and "Close round".
///
/// [rounds] starts from `PrototypeSeed.sampleRounds`; pass the real rounds
/// (and listen to [onAdd] / [onClose] to save them) when the backend is
/// connected. The screen does not change.
class RoundsViewModel extends ChangeNotifier {
  RoundsViewModel({
    List<FundingRound>? rounds,
    this.onAdd,
    this.onClose,
    this.canManage = true,
    DateTime? now,
  }) : _rounds = [...(rounds ?? PrototypeSeed.sampleRounds)],
       _now = now ?? DateTime.now();

  /// Called when a round is added / closed (the real saving goes here).
  final void Function(FundingRound added)? onAdd;
  final void Function(FundingRound closed)? onClose;

  /// False for a team member: every action below does nothing (checked here,
  /// not only hidden in the screen).
  final bool canManage;
  final DateTime _now;

  final List<FundingRound> _rounds;

  /// The startup's "already raised in this round" (from the Startup Ask), or
  /// the accepted requests total when that is higher. When set, it is what
  /// the OPEN round's Raised column shows. Null leaves the round's own value.
  int? openRaised;

  /// Newest round first.
  List<FundingRound> get rounds {
    final list = [..._rounds]..sort((a, b) => b.number.compareTo(a.number));
    final raised = openRaised;
    if (raised == null) return list;
    return [
      for (final r in list)
        if (r.isOpen) r.withRaised(raised) else r,
    ];
  }

  /// The open round, or null when every round is closed (or there are none).
  FundingRound? get openRound {
    for (final r in rounds) {
      if (r.isOpen) return r;
    }
    return null;
  }

  int get nextNumber => _rounds.isEmpty ? 1 : rounds.first.number + 1;

  // ------------------------------------------------------------ add form

  bool formOpen = false;
  StartupStage? type;
  final amount = TextEditingController();
  final raised = TextEditingController();
  bool? wantsLead;

  /// True after the first tap on "Add round" with something missing.
  bool tried = false;

  /// The round types that can be picked: the SAME stage as the last round
  /// and the later ones (after a Seed round: Seed, Series A, Series B,
  /// Series C). Earlier stages are never offered.
  List<StartupStage> get allowedTypes {
    const all = StartupStage.picks;
    if (_rounds.isEmpty) return all;
    final last = rounds.first.type;
    final from = all.indexOf(last);
    return from < 0 ? all : all.sublist(from);
  }

  /// The next stage after the last round (the form's default).
  StartupStage get defaultType {
    const all = StartupStage.picks;
    if (_rounds.isEmpty) return all.first;
    final i = all.indexOf(rounds.first.type);
    if (i < 0) return all.first;
    return all[i + 1 < all.length ? i + 1 : i];
  }

  void openForm() {
    if (!canManage) return;
    formOpen = true;
    type = defaultType;
    amount.clear();
    raised.clear();
    wantsLead = null;
    tried = false;
    notifyListeners();
  }

  void cancelForm() {
    formOpen = false;
    notifyListeners();
  }

  void setType(StartupStage value) {
    type = value;
    notifyListeners();
  }

  void setAmount(String _) => notifyListeners();
  void setRaised(String _) => notifyListeners();

  void setLead(bool value) {
    wantsLead = value;
    notifyListeners();
  }

  int? get amountValue => Formatters.parseMoney(amount.text);

  int? get raisedValue => Formatters.parseMoney(raised.text);

  /// The hint under "How much are you raising?" for the chosen round type.
  String? get amountHint => RoundLimits.hint(type);

  /// Empty (after "Add round" was tried) or outside the range of the round
  /// type: the same limits and wording as the Startup Ask step. A number
  /// outside the range says so at once.
  String? get amountError {
    final v = amountValue;
    if (v == null) return tried ? ValidationStrings.funding : null;
    return RoundLimits.error(type, v) ??
        (v <= 0 ? ValidationStrings.funding : null);
  }

  /// "How much have you already raised in this round?": required (0 is
  /// fine), and not more than the amount being raised.
  String? get raisedError {
    final r = raisedValue;
    if (r == null) return tried ? ValidationStrings.raisedEmpty : null;
    final f = amountValue;
    return f != null && r > f ? ValidationStrings.raisedTooMuch : null;
  }

  /// "Please choose one." until Yes or No is picked.
  String? get leadError =>
      tried && wantsLead == null ? 'Please choose one.' : null;

  /// The round type, the amount and the lead-investor answer are all there.
  bool get formValid =>
      type != null &&
      StartupValidators.money(amount.text) != null &&
      (amountValue ?? 0) > 0 &&
      RoundLimits.allows(type, amountValue!) &&
      raisedValue != null &&
      raisedValue! <= amountValue! &&
      wantsLead != null;

  /// Adds the round (opening it) when the form is valid; otherwise marks the
  /// errors. Returns true when it was added.
  bool addRound() {
    if (!canManage) return false;
    tried = true;
    if (!formValid) {
      notifyListeners();
      return false;
    }
    final round = FundingRound(
      number: nextNumber,
      type: type!,
      amount: amountValue!,
      // The new open round starts at what is already raised.
      raised: raisedValue!,
      start: _now,
      wantsLeadInvestor: wantsLead,
    );
    _rounds.add(round);
    formOpen = false;
    onAdd?.call(round);
    notifyListeners();
    return true;
  }

  // --------------------------------------------------------- close round

  /// Closes the open round (it moves to "Closed" in the list).
  void closeOpenRound() {
    if (!canManage) return;
    final open = openRound;
    if (open == null) return;
    final closed = open.closed(_now);
    _rounds[_rounds.indexWhere((r) => r.number == open.number)] = closed;
    onClose?.call(closed);
    notifyListeners();
  }

  @override
  void dispose() {
    amount.dispose();
    raised.dispose();
    super.dispose();
  }
}
