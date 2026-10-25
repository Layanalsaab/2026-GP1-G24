import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/investor_draft_store.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/validators.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';
import '../../../models/investor_criteria.dart';
import '../../../models/startup_enums.dart';
import '../../../shared_ui/widgets/forms/money_field.dart';

/// A Minimum / Maximum pair of SAR boxes with its rules (used by the round
/// size on step 3 and by the ticket amount on step 5): the minimum is at
/// least SAR 1,000 and never above the maximum. One message at a time:
/// min above max and min under 1,000 show as soon as they are typed, the
/// empty ones after Next.
class MoneyRange {
  MoneyRange();

  static const minimum = 1000;

  final min = TextEditingController();
  final max = TextEditingController();

  static int? _money(String text) =>
      int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), ''));

  int? get minAmount => _money(min.text);
  int? get maxAmount => _money(max.text);

  void setValues(int? lo, int? hi) {
    min.text = lo == null ? '' : ThousandsFormatter.format(lo);
    max.text = hi == null ? '' : ThousandsFormatter.format(hi);
  }

  bool get rangeBad {
    final lo = minAmount ?? 0;
    final hi = maxAmount ?? 0;
    return lo > 0 && hi > 0 && lo > hi;
  }

  bool get _minLow => minAmount != null && minAmount! < minimum;

  String? error({required bool tried}) {
    if (rangeBad) return ValidationStrings.roundRange;
    if (_minLow) return ValidationStrings.roundMinLow;
    if (!tried) return null;
    if (minAmount == null) return ValidationStrings.roundMinEmpty;
    if (maxAmount == null) return ValidationStrings.roundMaxEmpty;
    return null;
  }

  bool minHasError({required bool tried}) {
    final e = error(tried: tried);
    return e != null && e != ValidationStrings.roundMaxEmpty;
  }

  bool maxHasError({required bool tried}) {
    final e = error(tried: tried);
    return e == ValidationStrings.roundRange ||
        e == ValidationStrings.roundMaxEmpty;
  }

  bool get valid =>
      minAmount != null && maxAmount != null && !_minLow && !rangeBad;

  List<TextEditingController> get controllers => [min, max];
}

/// The investor's question steps after verifying their email: step 3
/// "Investment Background" and step 4 "Investment Interests". One view model
/// serves both screens (and Edit
/// profile) so Back keeps every answer. Nothing is pre-selected.
class InvestorOnboardingViewModel extends ChangeNotifier with SafeNotifier {
  /// [initial] pre-fills every answer (Edit profile, or an investor who comes
  /// back to finish; null reads as "nothing answered yet", never a crash).
  InvestorOnboardingViewModel({
    required this.user,
    UserRepository? userRepository,
    InvestorCriteria? initial,
    this.keepDraft = false,
    InvestorDraftStore? draftStore,
  }) : _users = userRepository ?? UserRepository.instance,
       _draftStore = draftStore ?? InvestorDraftStore.instance,
       _initial = initial {
    if (initial != null) _load(initial);
    if (keepDraft) addListener(_saveDraft);
    for (final c in _controllers) {
      c.addListener(notifyListeners);
    }
  }

  void _load(InvestorCriteria c) {
    years = yearsOptions.contains(c.yearsInvesting) ? c.yearsInvesting : null;
    deals = dealsOptions.contains(c.dealsCount) ? c.dealsCount : null;
    hasLedRound = c.hasLedRound;
    roundSize.setValues(c.roundMin, c.roundMax);
    sectors.addAll(c.sectors.where(sectorOptions.contains));
    sectorsOther.text = c.sectorsOther ?? '';
    stages.addAll(c.stages.where(stageOptions.contains));
    stagesOther.text = c.stagesOther ?? '';
    models.addAll(c.commerceModels.where(modelOptions.contains));
    modelsOther.text = c.commerceModelsOther ?? '';
  }

  final InvestorCriteria? _initial;
  final InvestorDraftStore _draftStore;

  /// True on the sign-up steps: every change is kept on the phone so the
  /// investor can leave and come back (see [InvestorDraftStore]).
  final bool keepDraft;

  /// Fills the answers saved on the phone, if any (before the first frame
  /// of the step the investor lands on).
  Future<void> restoreDraft() async {
    final saved = await _draftStore.load(user.uid);
    if (saved != null) {
      _load(saved);
      notifyListeners();
    }
  }

  void _saveDraft() {
    _draftStore.save(user.uid, buildCriteria());
  }

  static const yearsOptions = InvestorCriteria.yearsOptions;
  static const dealsOptions = InvestorCriteria.dealsOptions;

  static const otherLabel = 'Other';

  static final List<String> sectorOptions = [
    for (final s in Sector.values) s.label,
  ];
  static final List<String> modelOptions = [
    for (final m in BusinessModel.picks) m.label,
  ];
  static const List<String> stageOptions = InvestorCriteria.stageOptions;

  /// The account that just verified its email.
  final AppUser user;
  final UserRepository _users;

  // ---- Step 3 ----
  String? years;
  String? deals;
  bool? hasLedRound;
  final roundSize = MoneyRange();
  bool step3Tried = false;

  // ---- Step 4 ----
  final Set<String> sectors = {};
  final sectorsOther = TextEditingController();
  final Set<String> stages = {};
  final stagesOther = TextEditingController();
  final Set<String> models = {};
  final modelsOther = TextEditingController();
  bool step4Tried = false;

  bool isSaving = false;
  String? formError;

  late final List<TextEditingController> _controllers = [
    ...roundSize.controllers,
    sectorsOther,
    stagesOther,
    modelsOther,
  ];

  // ------------------------------------------------------------ step 3

  /// The size question is asked only after a range other than "0".
  bool get showRoundSize => deals != null && deals != '0';

  String? get roundSizeError =>
      showRoundSize ? roundSize.error(tried: step3Tried) : null;
  bool get minHasError =>
      showRoundSize && roundSize.minHasError(tried: step3Tried);
  bool get maxHasError =>
      showRoundSize && roundSize.maxHasError(tried: step3Tried);

  String? get yearsError =>
      step3Tried && years == null ? ValidationStrings.selectOne : null;
  String? get dealsError =>
      step3Tried && deals == null ? ValidationStrings.selectOne : null;
  String? get ledError =>
      step3Tried && hasLedRound == null ? ValidationStrings.chooseOne : null;

  bool get step3Complete =>
      years != null &&
      deals != null &&
      hasLedRound != null &&
      (!showRoundSize || roundSize.valid);

  void pickYears(String v) => _set(() => years = v);
  void pickDeals(String v) => _set(() => deals = v);
  void pickLed(String v) => _set(() => hasLedRound = v == 'Yes');

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
    bool tried,
    bool picked,
    TextEditingController text,
    String noun,
  ) => tried && picked && !Validators.isOtherText(text.text)
      ? 'Tell us your other $noun — it can’t be blank.'
      : null;

  String? get sectorsOtherError => _otherError(
    step4Tried,
    sectors.contains(otherLabel),
    sectorsOther,
    'sector',
  );
  String? get stagesOtherError => _otherError(
    step4Tried,
    stages.contains(otherLabel),
    stagesOther,
    'stage',
  );
  String? get modelsOtherError => _otherError(
    step4Tried,
    models.contains(otherLabel),
    modelsOther,
    'commerce model',
  );

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

  /// Tapping Next on step 4: true when the user may continue.
  bool tryStep4() {
    if (step4Complete) return true;
    step4Tried = true;
    notifyListeners();
    return false;
  }

  void _set(VoidCallback change) {
    change();
    notifyListeners();
  }

  // ------------------------------------------------------------ finish

  /// The answers as stored in `users/{uid}` (see [InvestorCriteria.toFields]).
  InvestorCriteria buildCriteria({String? lookFor}) {
    List<String> ordered(Set<String> chosen, List<String> options) => [
      for (final o in options)
        if (chosen.contains(o)) o,
    ];
    return InvestorCriteria(
      yearsInvesting: years,
      dealsCount: deals,
      hasLedRound: hasLedRound,
      roundsLed: _initial?.roundsLed,
      coInvest: _initial?.coInvest,
      ticketBand: _initial?.ticketBand,
      ticketOther: _initial?.ticketOther,
      roundMin: showRoundSize ? roundSize.minAmount : null,
      roundMax: showRoundSize ? roundSize.maxAmount : null,
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
      lookFor: (lookFor ?? user.gain).trim(),
    );
  }

  /// Edit profile: shows every error of the three question groups; true when
  /// all of it is valid.
  bool validateAll() {
    step3Tried = true;
    step4Tried = true;
    notifyListeners();
    return step3Complete && step4Complete;
  }

  /// Tapping Finish (step 4): validates, saves every answer and marks
  /// onboarding done. Returns the updated profile, or null (see
  /// [step4Complete], [formError]).
  Future<AppUser?> finish() async {
    if (isSaving) return null;
    formError = null;
    if (!step4Complete) {
      step4Tried = true;
      notifyListeners();
      return null;
    }
    final criteria = buildCriteria();
    isSaving = true;
    notifyListeners();
    try {
      await _users.saveInvestorOnboarding(uid: user.uid, criteria: criteria);
      await _draftStore.clear(user.uid);
      return user.copyWith(
        onboardingCompleted: true,
        investorCriteria: criteria,
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
