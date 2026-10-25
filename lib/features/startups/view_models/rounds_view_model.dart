import 'package:flutter/material.dart';

import '../../../data_access/mock_data/prototype_seed.dart';
import '../../../helpers/formatters.dart';
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

  /// Newest round first.
  List<FundingRound> get rounds {
    final list = [..._rounds]..sort((a, b) => b.number.compareTo(a.number));
    return list;
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

  void setLead(bool value) {
    wantsLead = value;
    notifyListeners();
  }

  int? get amountValue => Formatters.parseMoney(amount.text);

  /// "Please enter the round amount." when the amount is empty or zero.
  String? get amountError {
    if (!tried) return null;
    final v = amountValue;
    return v == null || v <= 0 ? 'Please enter the round amount.' : null;
  }

  /// "Please choose one." until Yes or No is picked.
  String? get leadError =>
      tried && wantsLead == null ? 'Please choose one.' : null;

  /// The round type, the amount and the lead-investor answer are all there.
  bool get formValid =>
      type != null &&
      StartupValidators.money(amount.text) != null &&
      (amountValue ?? 0) > 0 &&
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
    super.dispose();
  }
}
