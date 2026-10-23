import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/device_services/logo_picker_service.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/startup_validators.dart';
import '../../../helpers/validators.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';
import '../../../models/team_member.dart';
import 'startup_error_message.dart';

/// Every field of the 4-step startup form that can show an error.
enum StartupField {
  name,
  description,
  sector,
  sectorOther,
  stage,
  model,
  modelOther,
  city,
  founded,
  website,
  problem,
  solution,
  customers,
  advantage,
  growth,
  capital,
  revenue,
  valuation,
  lead,
  funding,
  lookingFor,
  lookingForOther,
}

/// What happened when the founder pressed the footer button.
enum StepAdvance {
  /// Moved to the next step.
  advanced,

  /// The step is not complete: errors are now shown (toast "Please fill in
  /// the required fields").
  incomplete,

  /// Step 3 with the team member editor open (toast "Save or cancel the team
  /// member first").
  memberOpen,

  /// The last step is complete: call [StartupStepsViewModel.save].
  readyToSave,
}

/// State of the Add / Edit startup form and the onboarding steps (docs/06
/// section 8): four steps, a "tried" flag per step that makes errors appear,
/// the team member editor and the save.
class StartupStepsViewModel extends ChangeNotifier with SafeNotifier {
  StartupStepsViewModel({
    this.initial,
    StartupRepository? repository,
    UserRepository? users,
    LogoPickerService? logoPicker,
    DateTime? now,
  }) : _repository = repository ?? StartupRepository.instance,
       _users = users ?? UserRepository.instance,
       _logoPickerOverride = logoPicker,
       _now = now ?? DateTime.now() {
    _fillFrom(initial);
    _baseline = _signature();
    for (final c in _controllers) {
      c.addListener(notifyListeners);
    }
  }

  // ---------------------------------------------------------------- drafts

  late String _baseline;

  /// A comparable fingerprint of everything the founder can type or pick.
  String _signature() => jsonEncode(_state());

  Map<String, Object?> _state() => {
    'name': name.text,
    'description': description.text,
    'founded': founded.text,
    'website': website.text,
    'sector': sector?.value,
    'sectorOther': sectorOther.text,
    'stage': stage?.value,
    'model': model?.value,
    'modelOther': modelOther.text,
    'city': city?.value,
    'problem': problem.text,
    'solution': solution.text,
    'customers': customers.text,
    'advantage': advantage.text,
    'tam': tam.text,
    'sam': sam.text,
    'som': som.text,
    'team': [for (final m in team) m.toMap()],
    'growth': growth.text,
    'capital': capital.text,
    'rev1': rev1.text,
    'rev2': rev2.text,
    'rev3': rev3.text,
    'valuation': valuation.text,
    'funding': funding.text,
    'lookingFor': [
      for (final l in LookingFor.values)
        if (lookingFor.contains(l)) l.value,
    ],
    'lookingForOther': lookingForOther.text,
    'wantsLead': wantsLead,
    'isPublic': isPublic,
  };

  /// True when anything differs from how the form opened (a new logo counts).
  bool get isDirty =>
      newLogo != null || removeLogo || _signature() != _baseline;

  /// The form as a draft (the logo is not kept).
  Map<String, Object?> toDraft() => {..._state(), 'step': furthestStep};

  /// Fills the form from [toDraft] output and makes that the new starting
  /// point, so opening a draft and leaving at once asks nothing.
  void loadDraft(Map<String, Object?> d) {
    String t(String k) => (d[k] as String?) ?? '';
    name.text = t('name');
    // Older drafts kept a one-line pitch next to the description.
    description.text = t('description').isNotEmpty
        ? t('description')
        : t('pitch');
    founded.text = t('founded');
    website.text = t('website');
    sector = Sector.fromValue(d['sector']);
    sectorOther.text = t('sectorOther');
    final draftStage = StartupStage.fromValue(d['stage']);
    stage = StartupStage.picks.contains(draftStage) ? draftStage : null;
    final draftModel = BusinessModel.fromValue(d['model']);
    model = BusinessModel.picks.contains(draftModel) ? draftModel : null;
    modelOther.text = t('modelOther');
    city = StartupLocation.fromValue(d['city']);
    problem.text = t('problem');
    solution.text = t('solution');
    customers.text = t('customers');
    advantage.text = t('advantage');
    tam.text = t('tam');
    sam.text = t('sam');
    som.text = t('som');
    team = [
      if (d['team'] is List)
        for (final raw in d['team'] as List) ?TeamMember.fromMap(raw),
    ];
    growth.text = t('growth');
    capital.text = t('capital');
    rev1.text = t('rev1');
    rev2.text = t('rev2');
    rev3.text = t('rev3');
    valuation.text = t('valuation');
    funding.text = t('funding');
    lookingFor = {
      if (d['lookingFor'] is List)
        for (final raw in d['lookingFor'] as List) ?LookingFor.fromValue(raw),
    };
    lookingForOther.text = t('lookingForOther');
    wantsLead = d['wantsLead'] as bool?;
    isPublic = d['isPublic'] != false;
    step = ((d['step'] as num?)?.toInt() ?? 0).clamp(0, stepCount - 1);
    furthestStep = step;
    _baseline = _signature();
    notifyListeners();
  }

  final Startup? initial;
  final StartupRepository _repository;
  final UserRepository _users;
  final LogoPickerService? _logoPickerOverride;
  final DateTime _now;

  LogoPickerService? _logoPickerCache;
  LogoPickerService get _logoPicker =>
      _logoPickerOverride ?? (_logoPickerCache ??= LogoPickerService());

  bool get isEditing => initial != null;

  static const stepCount = 4;

  /// The current step, 0-based.
  int step = 0;

  /// The furthest step the founder reached (Back moves [step] down, but a
  /// saved draft should reopen where they got to).
  int furthestStep = 0;
  final Set<int> _tried = {};

  // ---- Step 1
  final name = TextEditingController();
  final description = TextEditingController();
  final founded = TextEditingController();
  final website = TextEditingController();
  final sectorOther = TextEditingController();
  final modelOther = TextEditingController();
  Sector? sector;
  StartupStage? stage;
  BusinessModel? model;
  StartupLocation? city;
  File? newLogo;
  bool removeLogo = false;
  bool isPickingLogo = false;

  // ---- Step 2
  final problem = TextEditingController();
  final solution = TextEditingController();
  final customers = TextEditingController();
  final advantage = TextEditingController();

  // ---- Step 3
  final tam = TextEditingController();
  final sam = TextEditingController();
  final som = TextEditingController();
  List<TeamMember> team = [];

  /// The member editor: null index with [editorOpen] = adding.
  bool editorOpen = false;
  int? editingIndex;
  bool memberTried = false;
  final memberName = TextEditingController();
  final memberRole = TextEditingController();
  final memberSpec = TextEditingController();
  final memberYears = TextEditingController();
  final memberBio = TextEditingController();

  // ---- Step 4
  final growth = TextEditingController();
  final capital = TextEditingController();
  final rev1 = TextEditingController();
  final rev2 = TextEditingController();
  final rev3 = TextEditingController();
  final valuation = TextEditingController();
  final funding = TextEditingController();
  final lookingForOther = TextEditingController();
  bool? wantsLead;
  Set<LookingFor> lookingFor = {LookingFor.funding};
  bool isPublic = true;

  // ---- Async
  bool isSaving = false;
  String? saveError;
  String? logoError;

  List<TextEditingController> get _controllers => [
    name,
    description,
    founded,
    website,
    sectorOther,
    modelOther,
    problem,
    solution,
    customers,
    advantage,
    tam,
    sam,
    som,
    memberName,
    memberRole,
    memberSpec,
    memberYears,
    memberBio,
    growth,
    capital,
    rev1,
    rev2,
    rev3,
    valuation,
    funding,
    lookingForOther,
  ];

  bool get isSectorOther => sector == Sector.other;
  bool get isModelOther => model == BusinessModel.other;
  bool get isLookingForOther => lookingFor.contains(LookingFor.other);

  String? get existingLogoUrl => removeLogo ? null : initial?.logoUrl;
  bool get hasLogo => newLogo != null || existingLogoUrl != null;

  // ------------------------------------------------------------ validation

  static bool _blank(TextEditingController c) => c.text.trim().isEmpty;

  /// The raw error of [f] (null when valid), regardless of "tried".
  String? _rawError(StartupField f) {
    switch (f) {
      case StartupField.name:
        return StartupValidators.name(name.text);
      case StartupField.description:
        return StartupValidators.description(description.text);
      case StartupField.sector:
        return StartupValidators.selected(
          sector,
          ValidationStrings.startupSector,
        );
      case StartupField.sectorOther:
        return isSectorOther && _blank(sectorOther)
            ? ValidationStrings.otherSelect(FounderToolsStrings.sectorNoun)
            : null;
      case StartupField.stage:
        return StartupValidators.selected(
          stage,
          ValidationStrings.startupStage,
        );
      case StartupField.model:
        return StartupValidators.selected(
          model,
          ValidationStrings.startupModel,
        );
      case StartupField.modelOther:
        return isModelOther && _blank(modelOther)
            ? ValidationStrings.otherSelect(FounderToolsStrings.modelNoun)
            : null;
      case StartupField.city:
        return StartupValidators.selected(city, ValidationStrings.startupCity);
      case StartupField.founded:
        return StartupValidators.foundedYear(founded.text, now: _now);
      case StartupField.website:
        return StartupValidators.websiteUrl(website.text);
      case StartupField.problem:
        return StartupValidators.problem(problem.text);
      case StartupField.solution:
        return StartupValidators.solution(solution.text);
      case StartupField.customers:
        return StartupValidators.customers(customers.text);
      case StartupField.advantage:
        return StartupValidators.advantage(advantage.text);
      case StartupField.growth:
        return StartupValidators.growth(growth.text);
      case StartupField.capital:
        return StartupValidators.capital(capital.text);
      case StartupField.revenue:
        return StartupValidators.revenue(rev1.text, rev2.text, rev3.text);
      case StartupField.valuation:
        return StartupValidators.valuationOk(valuation.text) ? null : '';
      case StartupField.lead:
        return StartupValidators.leadInvestor(wantsLead);
      case StartupField.funding:
        return StartupValidators.funding(funding.text);
      case StartupField.lookingFor:
        return StartupValidators.lookingFor(lookingFor);
      case StartupField.lookingForOther:
        return isLookingForOther && _blank(lookingForOther)
            ? ValidationStrings.otherChips('option')
            : null;
    }
  }

  static const _stepFields = <List<StartupField>>[
    [
      StartupField.name,
      StartupField.description,
      StartupField.sector,
      StartupField.sectorOther,
      StartupField.stage,
      StartupField.model,
      StartupField.modelOther,
      StartupField.city,
      StartupField.founded,
      StartupField.website,
    ],
    [
      StartupField.problem,
      StartupField.solution,
      StartupField.customers,
      StartupField.advantage,
    ],
    [],
    [
      StartupField.growth,
      StartupField.capital,
      StartupField.revenue,
      StartupField.valuation,
      StartupField.lead,
      StartupField.funding,
      StartupField.lookingFor,
      StartupField.lookingForOther,
    ],
  ];

  int _stepOf(StartupField f) {
    for (var i = 0; i < _stepFields.length; i++) {
      if (_stepFields[i].contains(f)) return i;
    }
    return 0;
  }

  /// The error to show under [f]: only after the step was tried (the founded
  /// year also shows as soon as 4 digits are typed). Empty string for the
  /// valuation (it only turns the button grey, no text).
  String? errorOf(StartupField f) {
    final raw = _rawError(f);
    if (raw == null) return null;
    if (f == StartupField.valuation) return null;
    if (f == StartupField.founded && founded.text.trim().length == 4) {
      return raw;
    }
    // The website shows its message from the first character typed.
    if (f == StartupField.website && website.text.trim().isNotEmpty) {
      return raw;
    }
    return _tried.contains(_stepOf(f)) ? raw : null;
  }

  /// True when [f] should be drawn in the error style (valuation turns red
  /// without a line of text once tried).
  bool hasError(StartupField f) {
    if (f == StartupField.valuation) {
      return _rawError(f) != null && _tried.contains(3);
    }
    return errorOf(f) != null;
  }

  /// Every required answer of [s] (0-based) is given.
  bool stepComplete(int s) {
    if (s == 2) return !editorOpen;
    for (final f in _stepFields[s]) {
      if (_rawError(f) != null) return false;
    }
    return true;
  }

  bool get currentComplete => stepComplete(step);

  // --------------------------------------------------------------- changes

  /// Rebuilds after a selection change.
  void _touch(VoidCallback change) {
    change();
    notifyListeners();
  }

  void selectSector(String label, String? other) => _touch(() {
    sector = Sector.fromLabel(label);
    sectorOther.text = other ?? '';
  });

  void selectStage(String label) => _touch(() {
    stage = StartupStage.picks.firstWhere((s) => s.label == label);
  });

  void selectModel(String label, String? other) => _touch(() {
    model = BusinessModel.picks.firstWhere((m) => m.label == label);
    modelOther.text = other ?? '';
  });

  void selectCity(String label) => _touch(() {
    city = StartupLocation.values.firstWhere((c) => c.label == label);
  });

  void setLead(bool value) => _touch(() => wantsLead = value);

  /// Toggles a Looking for chip by its label.
  void toggleLookingFor(String label) => _touch(() {
    final item = LookingFor.values.firstWhere((l) => l.label == label);
    final next = {...lookingFor};
    if (!next.remove(item)) next.add(item);
    lookingFor = next;
  });

  void setPublic(bool value) => _touch(() => isPublic = value);

  Future<void> pickLogo() async {
    if (isPickingLogo || isSaving) return;
    isPickingLogo = true;
    logoError = null;
    notifyListeners();
    try {
      final file = await _logoPicker.pickSquareLogo();
      if (file != null) {
        newLogo = file;
        removeLogo = false;
      }
    } on LogoPickException catch (e) {
      logoError = e.failure == LogoPickFailure.tooLarge
          ? FounderToolsStrings.logoTooLarge
          : FounderToolsStrings.logoFailed;
    } catch (_) {
      logoError = FounderToolsStrings.logoFailed;
    } finally {
      isPickingLogo = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------ steps

  /// Goes back one step; false when already on the first step.
  bool previous() {
    if (step == 0) return false;
    step--;
    notifyListeners();
    return true;
  }

  /// The footer button: advances, or marks the step as tried.
  StepAdvance next() {
    if (!currentComplete) {
      _tried.add(step);
      notifyListeners();
      return step == 2 ? StepAdvance.memberOpen : StepAdvance.incomplete;
    }
    if (step < stepCount - 1) {
      step++;
      if (step > furthestStep) furthestStep = step;
      notifyListeners();
      return StepAdvance.advanced;
    }
    return StepAdvance.readyToSave;
  }

  // ----------------------------------------------------------- team members

  bool get memberComplete =>
      Validators.isFullName(memberName.text) &&
      !_blank(memberRole) &&
      !_blank(memberSpec) &&
      !_blank(memberYears) &&
      !_blank(memberBio);

  /// "Required" under an empty member field after "Add member" was tried.
  String? memberError(TextEditingController c) {
    if (c == memberName && !_blank(c) && !Validators.isFullName(c.text)) {
      // Live: a team member needs a first and last name.
      return ValidationStrings.fullName;
    }
    return memberTried && _blank(c) ? FounderToolsStrings.required : null;
  }

  void openMemberEditor([int? index]) => _touch(() {
    editorOpen = true;
    editingIndex = index;
    memberTried = false;
    final m = index == null ? null : team[index];
    memberName.text = m?.name ?? '';
    memberRole.text = m?.role ?? '';
    memberSpec.text = m?.specialization ?? '';
    memberYears.text = m == null ? '' : '${m.yearsExperience}';
    memberBio.text = m?.bio ?? '';
  });

  void cancelMemberEditor() => _touch(() {
    editorOpen = false;
    editingIndex = null;
    memberTried = false;
  });

  /// "Add member" / "Save member": returns false (and shows "Required")
  /// while a field is empty.
  bool saveMember() {
    if (!memberComplete) {
      _touch(() => memberTried = true);
      return false;
    }
    final member = TeamMember(
      name: memberName.text.trim(),
      role: memberRole.text.trim(),
      specialization: memberSpec.text.trim(),
      yearsExperience: int.tryParse(memberYears.text.trim()) ?? 0,
      bio: memberBio.text.trim(),
    );
    _touch(() {
      final list = [...team];
      if (editingIndex == null) {
        list.add(member);
      } else {
        list[editingIndex!] = member;
      }
      team = list;
      editorOpen = false;
      editingIndex = null;
      memberTried = false;
    });
    return true;
  }

  void removeMember() {
    final i = editingIndex;
    if (i == null) return;
    _touch(() {
      team = [...team]..removeAt(i);
      editorOpen = false;
      editingIndex = null;
    });
  }

  // ------------------------------------------------------------------- save

  /// Saves the startup (create or update). Returns it, or null with
  /// [saveError] set.
  Future<Startup?> save() async {
    if (isSaving) return null;
    isSaving = true;
    saveError = null;
    notifyListeners();
    try {
      final startup = _build();
      final saved = isEditing
          ? await _repository.update(
              startup,
              newLogo: newLogo,
              removeLogo: removeLogo,
            )
          : await _repository.create(startup, logo: newLogo);
      newLogo = null;
      removeLogo = false;
      if (!isEditing) {
        AppSession.instance.setOwnStartupIds({
          ...AppSession.instance.ownStartupIds,
          saved.id,
        });
      }
      return saved;
    } catch (e) {
      saveError = FounderToolsStrings.saveFailed;
      debugPrint('Saving the startup failed: $e (${startupErrorMessage(e)})');
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Onboarding only: marks the founder's onboarding as done.
  Future<void> completeOnboarding(Startup saved) async {
    final uid = saved.founderId.isNotEmpty
        ? saved.founderId
        : AppSession.instance.user?.uid;
    if (uid == null) return;
    try {
      await _users.completeOnboarding(uid);
    } catch (e) {
      debugPrint('Could not mark onboarding as completed: $e');
    }
  }

  Startup _build() {
    final websiteText = website.text.trim();
    return Startup(
      id: initial?.id ?? '',
      founderId: initial?.founderId ?? '',
      name: name.text.trim(),
      description: description.text.trim(),
      sector: sector!,
      sectorOther: isSectorOther ? sectorOther.text.trim() : null,
      stage: stage!,
      businessModel: model!,
      businessModelOther: isModelOther ? modelOther.text.trim() : null,
      location: city!,
      foundedYear: int.tryParse(founded.text.trim()),
      websiteUrl: websiteText.isEmpty
          ? null
          : StartupValidators.normalizeUrl(websiteText),
      lookingFor: lookingFor,
      lookingForOther: isLookingForOther ? lookingForOther.text.trim() : null,
      fundingRequirement: StartupValidators.money(funding.text),
      isPublic: isPublic,
      logoUrl: initial?.logoUrl,
      createdAt: initial?.createdAt,
      updatedAt: initial?.updatedAt,
      problem: problem.text.trim(),
      solution: solution.text.trim(),
      customers: customers.text.trim(),
      advantage: advantage.text.trim(),
      tam: StartupValidators.money(tam.text),
      sam: StartupValidators.money(sam.text),
      som: StartupValidators.money(som.text),
      team: team,
      growth: growth.text.trim(),
      capital: StartupValidators.money(capital.text),
      revenueYear1: StartupValidators.money(rev1.text),
      revenueYear2: StartupValidators.money(rev2.text),
      revenueYear3: StartupValidators.money(rev3.text),
      valuation: StartupValidators.money(valuation.text),
      wantsLeadInvestor: wantsLead,
    );
  }

  static String _money(int? v) {
    if (v == null) return '';
    final digits = v.toString();
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(',');
      b.write(digits[i]);
    }
    return b.toString();
  }

  void _fillFrom(Startup? s) {
    if (s == null) return;
    name.text = s.name;
    // One brief description (older startups had a pitch and a description).
    description.text = s.briefDescription;
    founded.text = s.foundedYear?.toString() ?? '';
    website.text = s.websiteUrl ?? '';
    sector = s.sector;
    sectorOther.text = s.sectorOther ?? '';
    // A stage or commerce model that is no longer offered stays empty, so
    // the founder picks a real one the next time.
    stage = StartupStage.picks.contains(s.stage) ? s.stage : null;
    model = BusinessModel.picks.contains(s.businessModel)
        ? s.businessModel
        : null;
    modelOther.text = s.businessModelOther ?? '';
    city = s.location;
    problem.text = s.problem;
    solution.text = s.solution;
    customers.text = s.customers;
    advantage.text = s.advantage;
    tam.text = _money(s.tam);
    sam.text = _money(s.sam);
    som.text = _money(s.som);
    team = [...s.team];
    growth.text = s.growth;
    capital.text = _money(s.capital);
    rev1.text = _money(s.revenueYear1);
    rev2.text = _money(s.revenueYear2);
    rev3.text = _money(s.revenueYear3);
    valuation.text = _money(s.valuation);
    funding.text = _money(s.fundingRequirement);
    lookingFor = {...s.lookingFor};
    lookingForOther.text = s.lookingForOther ?? '';
    wantsLead = s.wantsLeadInvestor;
    isPublic = s.isPublic;
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
