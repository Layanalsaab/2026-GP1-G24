import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';
import '../../../models/investor_criteria.dart';
import '../../../models/startup_enums.dart';

/// The investor's two question steps after verifying their email (docs/05
/// A10-A11, docs/06 sections 3-4): "Your investments" and "Your interests".
/// One view model serves both screens so Back keeps every answer.
class InvestorOnboardingViewModel extends ChangeNotifier with SafeNotifier {
  InvestorOnboardingViewModel({
    required this.user,
    UserRepository? userRepository,
  }) : _users = userRepository ?? UserRepository.instance {
    for (final c in _controllers) {
      c.addListener(notifyListeners);
    }
  }

  static const otherLabel = 'Other';

  static final List<String> sectorOptions = [
    for (final s in Sector.values) s.label,
  ];
  static final List<String> modelOptions = [
    for (final m in BusinessModel.values) m.label,
  ];
  static const List<String> stageOptions = InvestorCriteria.stageOptions;

  /// The account that just verified its email.
  final AppUser user;
  final UserRepository _users;

  // ---- Step 3 ----
  String? deals;
  bool? hasLedRound;
  String? roundsLed;
  String? coInvest;
  String? ticketBand;
  final ticketOther = TextEditingController();
  final roundMin = TextEditingController();
  final roundMax = TextEditingController();
  bool step3Tried = false;

  // ---- Step 4 ----
  final Set<String> sectors = {};
  final sectorsOther = TextEditingController();
  final Set<String> stages = {};
  final stagesOther = TextEditingController();
  final Set<String> models = {};
  final modelsOther = TextEditingController();
  final offer = TextEditingController();
  final lookFor = TextEditingController();
  bool step4Tried = false;

  bool isSaving = false;
  String? formError;

  late final List<TextEditingController> _controllers = [
    ticketOther,
    roundMin,
    roundMax,
    sectorsOther,
    stagesOther,
    modelsOther,
    offer,
    lookFor,
  ];

  // ------------------------------------------------------------ step 3

  static int? _money(String text) =>
      int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));

  int? get minAmount => _money(roundMin.text);
  int? get maxAmount => _money(roundMax.text);

  /// "The minimum can’t be more than the maximum." (live; blocks Next).
  bool get rangeBad {
    final lo = minAmount ?? 0;
    final hi = maxAmount ?? 0;
    return lo > 0 && hi > 0 && lo > hi;
  }

  String? get rangeError => rangeBad ? ValidationStrings.roundRange : null;

  String? _chooseOne(bool tried, bool missing) =>
      tried && missing ? ValidationStrings.chooseOne : null;

  String? get dealsError => _chooseOne(step3Tried, deals == null);
  String? get ledError => _chooseOne(step3Tried, hasLedRound == null);
  String? get coInvestError => _chooseOne(step3Tried, coInvest == null);
  String? get ticketError => _chooseOne(step3Tried, ticketBand == null);

  String? get ticketOtherError =>
      step3Tried &&
          ticketBand == otherLabel &&
          !Validators.isOtherText(ticketOther.text)
      ? ValidationStrings.otherChips('amount')
      : null;

  bool get step3Complete =>
      deals != null &&
      hasLedRound != null &&
      coInvest != null &&
      ticketBand != null &&
      (ticketBand != otherLabel || Validators.isOtherText(ticketOther.text)) &&
      !rangeBad;

  void pickDeals(String v) => _set(() => deals = v);
  void pickLed(String v) => _set(() {
    hasLedRound = v == 'Yes';
    if (!hasLedRound!) roundsLed = null;
  });
  void pickRoundsLed(String v) => _set(() => roundsLed = v);
  void pickCoInvest(String v) => _set(() => coInvest = v);
  void pickTicket(String v) => _set(() => ticketBand = v);

  /// Tapping Next on step 3: true when the user may continue.
  bool tryStep3() {
    if (step3Complete) return true;
    step3Tried = true;
    notifyListeners();
    return false;
  }

  // ------------------------------------------------------------ step 4

  String? get sectorsError =>
      step4Tried && sectors.isEmpty ? ValidationStrings.sectors : null;
  String? get stagesError => step4Tried && stages.isEmpty
      ? ValidationStrings.selectAtLeastOneStage
      : null;
  String? get modelsError => step4Tried && models.isEmpty
      ? ValidationStrings.selectAtLeastOneModel
      : null;

  String? _otherError(
    Set<String> chosen,
    TextEditingController text,
    String noun,
  ) =>
      step4Tried &&
          chosen.contains(otherLabel) &&
          !Validators.isOtherText(text.text)
      ? ValidationStrings.otherChips(noun)
      : null;

  String? get sectorsOtherError => _otherError(sectors, sectorsOther, 'sector');
  String? get stagesOtherError => _otherError(stages, stagesOther, 'stage');
  String? get modelsOtherError =>
      _otherError(models, modelsOther, 'commerce model');

  bool _groupOk(Set<String> chosen, TextEditingController text) =>
      chosen.isNotEmpty &&
      (!chosen.contains(otherLabel) || Validators.isOtherText(text.text));

  bool get step4Complete =>
      _groupOk(sectors, sectorsOther) &&
      _groupOk(stages, stagesOther) &&
      _groupOk(models, modelsOther);

  void toggleSector(String v) => _toggle(sectors, v);
  void toggleStage(String v) => _toggle(stages, v);
  void toggleModel(String v) => _toggle(models, v);

  void _toggle(Set<String> set, String v) =>
      _set(() => set.contains(v) ? set.remove(v) : set.add(v));

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }

  // ------------------------------------------------------------ finish

  /// The answers as stored in `users/{uid}.investorCriteria`.
  InvestorCriteria buildCriteria() {
    List<String> ordered(Set<String> chosen, List<String> options) => [
      for (final o in options)
        if (chosen.contains(o)) o,
    ];
    return InvestorCriteria(
      dealsCount: deals,
      hasLedRound: hasLedRound,
      roundsLed: hasLedRound == true ? roundsLed : null,
      coInvest: coInvest,
      ticketBand: ticketBand,
      ticketOther: ticketBand == otherLabel ? ticketOther.text.trim() : null,
      roundMin: minAmount,
      roundMax: maxAmount,
      sectors: ordered(sectors, sectorOptions),
      sectorsOther: sectors.contains(otherLabel)
          ? sectorsOther.text.trim()
          : null,
      stages: ordered(stages, stageOptions),
      stagesOther: stages.contains(otherLabel) ? stagesOther.text.trim() : null,
      commerceModels: ordered(models, modelOptions),
      commerceModelsOther: models.contains(otherLabel)
          ? modelsOther.text.trim()
          : null,
      lookFor: lookFor.text.trim(),
    );
  }

  /// Tapping Finish: validates, saves the criteria and marks onboarding done.
  /// Returns the updated profile, or null (see [step4Complete], [formError]).
  Future<AppUser?> finish() async {
    if (isSaving) return null;
    formError = null;
    if (!step4Complete) {
      step4Tried = true;
      notifyListeners();
      return null;
    }
    final criteria = buildCriteria();
    final offered = offer.text.trim();
    isSaving = true;
    notifyListeners();
    try {
      await _users.saveInvestorOnboarding(
        uid: user.uid,
        criteria: criteria,
        valueOffered: offered,
      );
      return user.copyWith(
        onboardingCompleted: true,
        investorCriteria: criteria,
        valueOffered: offered,
      );
    } on AuthException catch (e) {
      formError = e.failure == AuthFailure.network
          ? AppStrings.networkError
          : AppStrings.genericError;
    } catch (_) {
      formError = AppStrings.genericError;
    } finally {
      isSaving = false;
      notifyListeners();
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(notifyListeners);
      c.dispose();
    }
    super.dispose();
  }
}
