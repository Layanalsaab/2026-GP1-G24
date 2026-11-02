import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../data_access/mock_data/prototype_seed.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/repositories/funding_round_repository.dart';
import '../../../data_access/repositories/matching_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/formatters.dart';
import '../../../helpers/round_limits.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/startup_validators.dart';
import '../../../models/funding_round.dart';
import '../../../models/home_item.dart';
import '../../../models/investor_profile.dart';
import '../../../models/list_entries.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';

/// State of Manage -> Rounds: the startup's rounds, the "Add round" form and
/// "Close round".
///
/// With a [startup], the rounds are loaded from Firestore and every action is
/// saved: "Add round" ticks Funding with the new amount (and moves the
/// startup's Stage to the round type), "Close round" unticks it. Both go
/// through StartupRepository.update, which opens / closes the round in the
/// same write, so the startup and its rounds always agree. [onStartupSaved]
/// gets the startup as saved.
///
/// Without a startup (tests), [rounds] (or the sample rounds) live in memory.
class RoundsViewModel extends ChangeNotifier with SafeNotifier {
  RoundsViewModel({
    Startup? startup,
    Startup Function()? currentStartup,
    List<FundingRound>? rounds,
    FundingRoundRepository? repository,
    StartupRepository? startups,
    MatchingRepository? matching,
    this.onStartupSaved,
    this.canManage = true,
    DateTime? now,
  }) : _startup = startup,
       _matchingOverride = matching,
       _currentStartupOf = currentStartup,
       _rounds = [
         ...(rounds ??
             (startup == null ? PrototypeSeed.sampleRounds : <FundingRound>[])),
       ],
       _repositoryOverride = repository,
       _startupsOverride = startups,
       _fixedNow = now {
    if (startup != null && rounds == null) load();
  }

  /// Called with the startup as saved after a round was added or closed.
  final void Function(Startup saved)? onStartupSaved;

  /// False for a team member: every action below does nothing (checked here,
  /// not only hidden in the screen).
  final bool canManage;
  final DateTime? _fixedNow;
  DateTime get _today => _fixedNow ?? DateTime.now();

  final FundingRoundRepository? _repositoryOverride;
  final StartupRepository? _startupsOverride;
  FundingRoundRepository get _roundsRepo =>
      _repositoryOverride ?? FundingRoundRepository.instance;
  StartupRepository get _startupRepo =>
      _startupsOverride ?? StartupRepository.instance;

  Startup? _startup;

  /// The startup as the screen has it now (it can change elsewhere, e.g. the
  /// Public switch), so a round save never puts back old values.
  final Startup Function()? _currentStartupOf;
  Startup? get _latest => _currentStartupOf?.call() ?? _startup;

  final List<FundingRound> _rounds;

  bool isLoading = false;
  bool loadFailed = false;
  bool isSaving = false;

  /// The message of the last failed save (the screen shows it once).
  String? error;

  /// Loads the rounds again (also after the startup was edited: the Startup
  /// Ask may have opened, changed or closed a round).
  Future<void> load([Startup? updated]) async {
    if (updated != null) _startup = updated;
    final s = _startup;
    if (s == null) return;
    isLoading = true;
    loadFailed = false;
    notifyListeners();
    try {
      final loaded = await _roundsRepo.roundsOf(s.id);
      _rounds
        ..clear()
        ..addAll(loaded);
    } catch (e) {
      loadFailed = true;
      debugPrint('Loading the funding rounds failed: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Add round / Close round can be offered (the rounds are known).
  bool get ready => !isLoading && !loadFailed;

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

  /// True after the first tap on "Add round" with something missing.
  bool tried = false;

  /// The round types that can be picked: the SAME stage as the last round
  /// and the later ones (after a Seed round: Seed, Series A, Series B,
  /// Series C). Earlier stages are never offered.
  List<StartupStage> get allowedTypes {
    const all = StartupStage.picks;
    final from = _earliestIndex;
    return from < 0 ? all : all.sublist(from);
  }

  /// The earliest stage that can be picked: the last round's and, with a
  /// startup, its current Stage (opening a round sets the Stage, so it never
  /// goes back). -1 when anything goes.
  int get _earliestIndex {
    const all = StartupStage.picks;
    final last = _rounds.isEmpty ? -1 : all.indexOf(rounds.first.type);
    final s = _latest;
    final stage = s == null ? -1 : all.indexOf(s.stage);
    return last > stage ? last : stage;
  }

  /// The next stage after the last round (the form's default); with no
  /// rounds, the startup's Stage (or Pre-seed).
  StartupStage get defaultType {
    const all = StartupStage.picks;
    if (_rounds.isEmpty) {
      final s = _latest;
      final i = s == null ? -1 : all.indexOf(s.stage);
      return i < 0 ? all.first : all[i];
    }
    final i = all.indexOf(rounds.first.type);
    if (i < 0) return all.first;
    final next = all[i + 1 < all.length ? i + 1 : i];
    final from = _earliestIndex;
    return from > all.indexOf(next) ? all[from] : next;
  }

  // ----------------------------------------------------------- edit form

  /// The open round being edited (the Edit round form on the round page), or
  /// null. The form uses the same fields, limits and errors as Add round.
  FundingRound? editing;

  bool get editOpen => editing != null;

  /// Back on the rounds list: forgets an Edit round form without telling the
  /// screen (called when the Rounds tab is built again, so switching Manage
  /// tabs always shows the list and no half-open edit).
  void resetView() => editing = null;

  /// Opens "Edit round" for the OPEN round, pre-filled with its current
  /// values. Closed rounds can't be edited; a view-only member can't either.
  void openEdit() {
    if (!canManage || formOpen || editing != null) return;
    final open = openRound;
    if (open == null) return;
    editing = open;
    type = open.type;
    amount.text = Formatters.thousands(open.amount);
    raised.text = Formatters.thousands(open.raised);
    tried = false;
    _formBaseline = _formSignature();
    notifyListeners();
  }

  void cancelEdit() {
    editing = null;
    notifyListeners();
  }

  /// Saves the edited open round: the new type, amount and "already raised"
  /// go to the startup (Funding ask + Stage), and the repository updates the
  /// round in the same write (the same path as Add round / Close round), after
  /// the role was read again. Returns true when it was saved.
  Future<bool> saveEdit() async {
    if (!canManage || isSaving) return false;
    final edited = editing;
    if (edited == null) return false;
    tried = true;
    if (!formValid || openRound?.number != edited.number) {
      notifyListeners();
      return false;
    }
    final s = _latest;
    if (s != null) {
      final saved = await _save(
        s.copyWith(
          lookingFor: {...s.lookingFor, LookingFor.funding},
          fundingRequirement: amountValue!,
          raisedInRound: raisedValue!,
          stage: type!,
        ),
      );
      if (saved == null) return false;
    }
    final i = _rounds.indexWhere((r) => r.number == edited.number);
    if (i >= 0) {
      _rounds[i] = _rounds[i].copyWith(
        type: type!,
        amount: amountValue!,
        raised: raisedValue!,
      );
    }
    editing = null;
    notifyListeners();
    return true;
  }

  // -------------------------------------------------------------- matches

  /// How many investors the Matches section of a round shows.
  static const matchesShown = 5;

  final MatchingRepository? _matchingOverride;
  MatchingRepository get _matching =>
      _matchingOverride ?? MatchingRepository.instance;

  /// Bumps when the investors or startups changed (the list is computed again).
  ValueListenable<int> get matchChanges => _matching.changes;

  /// The top [matchesShown] investors for an OPEN [round]: the startup with
  /// the round's type as its stage and the round's amount as its ask, against
  /// the investors' interests, with the same score as the rest of matching
  /// (sector 0.41, stage 0.29, commerce model 0.18). Works for a private
  /// startup too. Throws AuthException when the investors can't be read.
  Future<List<HomeItem>> matchesFor(FundingRound round) async {
    final s = _latest;
    if (s == null || !round.isOpen) return const [];
    final target = s.copyWith(
      stage: round.type,
      fundingRequirement: round.amount,
    );
    final all = await _matching.investorsForStartup(target);
    return all.take(matchesShown).toList();
  }

  /// The profile of a matched investor shown in [matchesFor].
  InvestorProfile? matchedInvestor(String id) => _matching.investorById(id);

  /// The startup as the screen has it now.
  Startup? get startup => _latest;

  void openForm() {
    if (!canManage || editing != null) return;
    formOpen = true;
    type = defaultType;
    amount.clear();
    raised.clear();
    tried = false;
    _formBaseline = _formSignature();
    notifyListeners();
  }

  /// The form's values when it opened (to tell real changes from none).
  String _formBaseline = '';

  String _formSignature() => '${type?.value}|${amount.text}|${raised.text}';

  /// True when a value differs from how the form opened: the Cancel button
  /// asks "Discard changes?" only then.
  bool get formDirty =>
      (formOpen || editing != null) && _formSignature() != _formBaseline;

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

  /// The round type, the amount and what is already raised are all there.
  bool get formValid =>
      type != null &&
      StartupValidators.money(amount.text) != null &&
      (amountValue ?? 0) > 0 &&
      RoundLimits.allows(type, amountValue!) &&
      raisedValue != null &&
      raisedValue! <= amountValue!;

  /// Adds the round (opening it) when the form is valid; otherwise marks the
  /// errors. Returns true when it was added (and saved, with a startup).
  Future<bool> addRound() async {
    if (!canManage || isSaving) return false;
    tried = true;
    if (!formValid || openRound != null) {
      notifyListeners();
      return false;
    }
    final round = FundingRound(
      number: nextNumber,
      type: type!,
      amount: amountValue!,
      // The new open round starts at what is already raised.
      raised: raisedValue!,
      start: _today,
    );
    final s = _latest;
    if (s != null) {
      // Funding ticked with this round's answers; the Stage becomes the
      // round type. The repository opens the round in the same write.
      final saved = await _save(
        s.copyWith(
          lookingFor: {...s.lookingFor, LookingFor.funding},
          fundingRequirement: round.amount,
          raisedInRound: round.raised,
          stage: round.type,
        ),
      );
      if (saved == null) return false;
    }
    _rounds.add(round);
    formOpen = false;
    notifyListeners();
    return true;
  }

  // --------------------------------------------------------- close round

  /// Closes the open round (it moves to "Closed" in the list with what it
  /// raised)
  /// and, with a startup, removes Funding from its asks. Returns true when
  /// it was closed.
  Future<bool> closeOpenRound() async {
    if (!canManage || isSaving) return false;
    final open = openRound;
    if (open == null) return false;
    final s = _latest;
    if (s != null) {
      final saved = await _save(
        s.copyWith(
          lookingFor: {...s.lookingFor}..remove(LookingFor.funding),
          clearFunding: true,
        ),
      );
      if (saved == null) return false;
    }
    final closed = open.closed(_today);
    _rounds[_rounds.indexWhere((r) => r.number == open.number)] = closed;
    notifyListeners();
    return true;
  }

  /// The founder's / co-founder's CURRENT role, read again right before a
  /// write (not only when the screen opened). Offline: the rules decide.
  Future<bool> _stillAllowed(Startup s) async {
    final uid = AppSession.instance.user?.uid;
    if (uid == null) return true;
    try {
      final fresh = await _startupRepo.fetchById(s.id);
      if (fresh == null) return false;
      return StartupRole.of(fresh, uid)?.canManage ?? false;
    } catch (_) {
      return true;
    }
  }

  Future<Startup?> _save(Startup updated) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      if (!await _stillAllowed(updated)) {
        error = FounderToolsStrings.noPermissionAnymore;
        return null;
      }
      final saved = await _startupRepo.update(updated);
      _startup = saved;
      onStartupSaved?.call(saved);
      return saved;
    } catch (e) {
      debugPrint('Saving the funding round failed: $e');
      error = FounderToolsStrings.saveFailed;
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    amount.dispose();
    raised.dispose();
    super.dispose();
  }
}
