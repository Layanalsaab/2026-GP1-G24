import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../app_constants/validation_strings.dart';
import '../../../data_access/device_services/logo_picker_service.dart';
import '../../../data_access/firebase_services/invite_relay_service.dart';
import '../../../data_access/repositories/invitation_repository.dart';
import '../../../data_access/repositories/startup_repository.dart';
import '../../../data_access/repositories/team_lookup.dart';
import '../../../data_access/repositories/user_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/other_check.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../helpers/startup_finance.dart';
import '../../../helpers/startup_validators.dart';
import '../../../helpers/validators.dart';
import '../../../models/list_entries.dart';
import '../../../models/invitation.dart';
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
  marketSize,
  advantage,
  revenueNow,
  capital,
  burn,
  valuation,
  revenue,
  modelText,
  lookingFor,
  funding,
  raised,
  partnerTypes,
  supportTypes,
}

/// What happened to the invitation e-mails when a startup was saved.
class InviteSummary {
  const InviteSummary({
    this.sent = 0,
    this.failed = 0,
    this.offline = false,
    this.limit = false,
  });

  final int sent;
  final int failed;

  /// No connection / Gmail's daily limit (each has its own message).
  final bool offline;
  final bool limit;

  bool get nothing => sent == 0 && failed == 0;
}

/// What happened when a team member was saved.
enum MemberSave {
  /// A field is wrong or empty (errors now show).
  invalid,

  /// Nobody is registered with that e-mail: ask before inviting.
  needsInvite,

  /// Saved (a linked account, or an existing member).
  saved,

  /// Saved as an invited person ("Invitation sent").
  invited,
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
    InvitationRepository? invitations,
    LogoPickerService? logoPicker,
    DateTime? now,
    this.onlySection,
  }) : _repository = repository ?? StartupRepository.instance,
       _users = users ?? UserRepository.instance,
       _invitations = invitations ?? InvitationRepository.instance,
       _logoPickerOverride = logoPicker,
       _now = now ?? DateTime.now() {
    _fillFrom(initial);
    _ensureFounder();
    if (onlyStep != null) step = onlyStep!;
    _openFounderIfNeeded();
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
    'sectors': sectorPicks,
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
    'revenueNow': revenueNow.text,
    'capital': capital.text,
    'burn': burn.text,
    'modelText': modelText.text,
    'raised': raised.text,
    'partners': _ordered(partnerSel, FounderToolsStrings.partnerOptions),
    'partnerOther': partnerOther.text,
    'supports': _ordered(supportSel, FounderToolsStrings.supportOptions),
    'supportOther': supportOther.text,
    'rev1': rev1.text,
    'rev2': rev2.text,
    'rev3': rev3.text,
    'valuation': valuation.text,
    'funding': funding.text,
    'lookingFor': [
      for (final l in LookingFor.values)
        if (lookingFor.contains(l)) l.value,
    ],
    'isPublic': isPublic,
  };

  /// True when anything differs from how the form opened (a new logo counts).
  bool get isDirty =>
      newLogo != null || removeLogo || _signature() != _baseline;

  /// The form as a draft (the logo is not kept).
  Map<String, Object?> toDraft() => {
    ..._state(),
    'step': furthestStep,
    // 2 = Startup Team before Startup Ask (older drafts have no marker).
    'order': 2,
  };

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
    sectorPicks.clear();
    if (d['sectors'] is List) {
      sectorPicks.addAll([
        for (final v in d['sectors'] as List)
          if (v is String && !sectorPicks.contains(v)) v,
      ]);
    } else if (Sector.fromValue(d['sector']) case final old?) {
      // A draft saved when only one sector could be picked.
      sectorPicks.add(old.label);
    }
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
    revenueNow.text = t('revenueNow');
    capital.text = t('capital');
    burn.text = t('burn');
    modelText.text = t('modelText');
    raised.text = t('raised');
    partnerSel = {
      if (d['partners'] is List)
        for (final v in d['partners'] as List) '$v',
    };
    partnerOther.text = t('partnerOther');
    supportSel = {
      if (d['supports'] is List)
        for (final v in d['supports'] as List) '$v',
    };
    supportOther.text = t('supportOther');
    rev1.text = t('rev1');
    rev2.text = t('rev2');
    rev3.text = t('rev3');
    valuation.text = t('valuation');
    funding.text = t('funding');
    lookingFor = {
      if (d['lookingFor'] is List)
        for (final raw in d['lookingFor'] as List) ?LookingFor.fromValue(raw),
    };
    isPublic = d['isPublic'] != false;
    _ensureFounder();
    var savedStep = (d['step'] as num?)?.toInt() ?? 0;
    // A draft from before the two last steps swapped places: Startup Ask was
    // step 4 and Startup Team step 5.
    if (d['order'] != 2) {
      if (savedStep == 4) {
        savedStep = 5;
      } else if (savedStep == 5) {
        savedStep = 4;
      }
    }
    step = savedStep.clamp(0, stepCount - 1);
    furthestStep = step;
    _openFounderIfNeeded();
    _baseline = _signature();
    notifyListeners();
  }

  final Startup? initial;

  /// Editing ONE section of a saved startup (Manage -> Details -> Edit): the
  /// section number is its position in the Details tab (0 Overview, 1 Startup
  /// Description, 2 Target Market, 3 Finance and Growth, 4 Startup Team, 5
  /// Startup Ask). Only that section's fields are shown, with a "Save"
  /// button instead of Next. Null = the normal form. The onboarding steps
  /// themselves are not changed by this.
  final int? onlySection;
  bool get isSectionEdit => onlySection != null;

  /// The form step that holds each Details section (each section is its own
  /// step: Finance and Growth is step 3, Startup Team step 4, Startup Ask 5).
  static const sectionSteps = [0, 1, 2, 3, 4, 5];
  int? get onlyStep => onlySection == null ? null : sectionSteps[onlySection!];
  final StartupRepository _repository;
  final UserRepository _users;
  final InvitationRepository _invitations;
  final LogoPickerService? _logoPickerOverride;
  final DateTime _now;

  LogoPickerService? _logoPickerCache;
  LogoPickerService get _logoPicker =>
      _logoPickerOverride ?? (_logoPickerCache ??= LogoPickerService());

  bool get isEditing => initial != null;

  /// One step per title: Startup Overview, Startup Description, Target
  /// Market, Finance and Growth, Startup Team, Startup Ask. Built from the
  /// list so a new step only needs a new title.
  static int get stepCount => FounderToolsStrings.stepTitles.length;

  /// The step that holds the team member list and editor (the one before
  /// the last).
  static int get teamStep => stepCount - 2;

  /// The Startup Ask: the last step ("Create startup" / "Save changes").
  static int get askStep => stepCount - 1;

  /// The current step, 0-based.
  int step = 0;

  /// The furthest step the founder reached (Back moves [step] down, but a
  /// saved draft should reopen where they got to).
  int furthestStep = 0;
  final Set<int> _tried = {};

  // ---- "Required" errors after leaving a field
  //
  // A FORMAT error shows from the first keystroke. A REQUIRED error (the field
  // is empty) shows after Next / Save is pressed, or after the person typed in
  // the field and then left it. A form nobody touched is never full of red.

  final Map<StartupField, FocusNode> _focus = {};
  final Map<StartupField, String> _lastText = {};
  final Set<StartupField> _edited = {};
  final Set<StartupField> _left = {};

  /// The text controller behind a plain text field (null for the others).
  TextEditingController? _textOf(StartupField f) => switch (f) {
    StartupField.name => name,
    StartupField.description => description,
    StartupField.founded => founded,
    StartupField.website => website,
    StartupField.problem => problem,
    StartupField.solution => solution,
    StartupField.customers => customers,
    StartupField.advantage => advantage,
    StartupField.marketSize => tam,
    StartupField.modelText => modelText,
    StartupField.revenueNow => revenueNow,
    StartupField.capital => capital,
    StartupField.burn => burn,
    StartupField.valuation => valuation,
    StartupField.funding => funding,
    StartupField.raised => raised,
    _ => null,
  };

  /// The focus node of a text field: give it to the field, so leaving it
  /// after typing can show its "required" message.
  FocusNode focusOf(StartupField f) {
    final existing = _focus[f];
    if (existing != null) return existing;
    final node = FocusNode();
    final c = _textOf(f);
    _lastText[f] = c?.text ?? '';
    node.addListener(() {
      final text = c?.text ?? '';
      // A change of the TEXT counts as typing (a caret move does not).
      if (text != _lastText[f]) {
        _lastText[f] = text;
        _edited.add(f);
      }
      if (!node.hasFocus && _edited.contains(f) && _left.add(f)) {
        notifyListeners();
      }
    });
    c?.addListener(() {
      if (c.text != _lastText[f]) {
        _lastText[f] = c.text;
        _edited.add(f);
      }
    });
    return _focus[f] = node;
  }

  // ---- Step 1
  final name = TextEditingController();
  final description = TextEditingController();
  final founded = TextEditingController();
  final website = TextEditingController();
  final sectorOther = TextEditingController();
  final modelOther = TextEditingController();

  /// The sectors picked, in the order they were picked (the labels; "Other"
  /// stands for the typed [sectorOther]). The FIRST one is the main sector.
  final List<String> sectorPicks = [];

  /// The main sector: the first one picked.
  Sector? get sector =>
      sectorPicks.isEmpty ? null : Sector.fromLabel(sectorPicks.first);
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
  final memberEmail = TextEditingController();

  /// The e-mail of an investor account that was refused as a member.
  String? _blockedEmail;
  final memberContribution = TextEditingController();
  bool memberCoFounder = false;

  // ---- Step 4
  final revenueNow = TextEditingController();
  final capital = TextEditingController();
  final burn = TextEditingController();
  final modelText = TextEditingController();
  final raised = TextEditingController();
  final partnerOther = TextEditingController();
  final supportOther = TextEditingController();
  final rev1 = TextEditingController();
  final rev2 = TextEditingController();
  final rev3 = TextEditingController();
  final valuation = TextEditingController();
  final funding = TextEditingController();

  /// Funding / Partnership / Support. Nothing is ticked by default.
  Set<LookingFor> lookingFor = {};

  /// The picked partner / support types ("Other" stands for what was typed).
  Set<String> partnerSel = {};
  Set<String> supportSel = {};
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
    memberEmail,
    memberContribution,
    revenueNow,
    capital,
    burn,
    modelText,
    raised,
    partnerOther,
    supportOther,
    rev1,
    rev2,
    rev3,
    valuation,
    funding,
  ];

  /// The labels the Sector and Commerce model pickers list (the "Other"
  /// write-in can't repeat one of them).
  static final List<String> _sectorLabels = [
    for (final s in Sector.values) s.label,
  ];
  static final List<String> _modelLabels = [
    for (final m in BusinessModel.picks) ...[m.label, m.shortLabel],
  ];

  /// What else counts as a listed commerce model: its abbreviation ("B2B")
  /// and its name without the brackets ("Business-to-Business").
  static final Map<String, String> modelAlsoCountsAs = {
    for (final m in BusinessModel.picks) ...{
      m.shortLabel: m.label,
      m.label.replaceAll(RegExp(r'\s*\(.*\)'), ''): m.label,
    },
  };

  bool get sectorOtherRepeats =>
      isSectorOther && OtherCheck.repeats(sectorOther.text, _sectorLabels);
  bool get modelOtherRepeats =>
      isModelOther &&
      OtherCheck.repeats(modelOther.text, [
        ..._modelLabels,
        ...modelAlsoCountsAs.keys,
      ]);

  /// "Other" is ticked (in any position).
  bool get isSectorOther => sectorPicks.contains(_other);

  static const _other = 'Other';
  bool get isModelOther => model == BusinessModel.other;
  bool get wantsFunding => lookingFor.contains(LookingFor.funding);
  bool get wantsPartner => lookingFor.contains(LookingFor.partnership);
  bool get wantsSupport => lookingFor.contains(LookingFor.support);

  /// The "Other" write-in repeats a listed type (it can't).
  bool get partnerOtherRepeats =>
      partnerSel.contains('Other') &&
      OtherCheck.repeats(partnerOther.text, FounderToolsStrings.partnerOptions);
  bool get supportOtherRepeats =>
      supportSel.contains('Other') &&
      OtherCheck.repeats(supportOther.text, FounderToolsStrings.supportOptions);

  bool get isPartnerOther => partnerSel.contains('Other');
  bool get isSupportOther => supportSel.contains('Other');

  /// The round type the funding amount is checked against: the Stage picked
  /// on the Overview step (or the saved one when only this step is edited).
  StartupStage? get roundStage => stage ?? initial?.stage;

  /// The live value under the burn rate ("About 6 months").
  String? get runwayLine => Runway.line(
    StartupValidators.money(capital.text),
    StartupValidators.money(burn.text),
  );

  static List<String> _ordered(Set<String> picked, List<String> order) => [
    for (final o in order)
      if (picked.contains(o)) o,
  ];

  String? get existingLogoUrl => removeLogo ? null : initial?.logoUrl;

  /// The saved logo (base64) of the startup being edited, until removed.
  String? get existingLogoData => removeLogo ? null : initial?.logoData;

  bool get hasLogo =>
      newLogo != null || existingLogoUrl != null || existingLogoData != null;

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
        return sectorPicks.isEmpty ? ValidationStrings.startupSector : null;
      case StartupField.sectorOther:
        if (sectorOtherRepeats) return ValidationStrings.otherRepeats;
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
        if (modelOtherRepeats) return ValidationStrings.otherRepeats;
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
      case StartupField.marketSize:
        return StartupValidators.marketSize(tam.text);
      case StartupField.advantage:
        return StartupValidators.advantage(advantage.text);
      case StartupField.revenueNow:
        return StartupValidators.revenueNow(revenueNow.text);
      case StartupField.capital:
        return StartupValidators.capital(capital.text);
      case StartupField.burn:
        return StartupValidators.burn(burn.text);
      case StartupField.modelText:
        return StartupValidators.businessModelText(modelText.text);
      case StartupField.revenue:
        return StartupValidators.revenue(rev1.text, rev2.text, rev3.text);
      case StartupField.valuation:
        return StartupValidators.valuation(valuation.text);
      case StartupField.funding:
        return StartupValidators.funding(funding.text);
      case StartupField.raised:
        return StartupValidators.raisedInRound(raised.text, funding.text);
      case StartupField.lookingFor:
        // A new startup says what it needs. An existing one may need nothing
        // right now (e.g. its funding round just closed and Funding was its
        // only ask): it then shows "Not raising right now".
        return isEditing ? null : StartupValidators.lookingFor(lookingFor);
      case StartupField.partnerTypes:
        if (partnerOtherRepeats) return ValidationStrings.otherRepeats;
        return _typesError(
          partnerSel,
          partnerOther,
          StartupValidators.partnerTypes,
          'partner type',
        );
      case StartupField.supportTypes:
        if (supportOtherRepeats) return ValidationStrings.otherRepeats;
        return _typesError(
          supportSel,
          supportOther,
          StartupValidators.supportTypes,
          'support type',
        );
    }
  }

  /// "Select at least one ..." or the blank "Other" write-in message.
  String? _typesError(
    Set<String> picked,
    TextEditingController other,
    String? Function(Iterable<Object>) atLeastOne,
    String noun,
  ) {
    final none = atLeastOne(picked);
    if (none != null) return none;
    return picked.contains('Other') && _blank(other)
        ? ValidationStrings.otherSelect(noun)
        : null;
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
    [StartupField.problem, StartupField.solution, StartupField.advantage],
    // Target Market: who the customers are and how big the market is.
    [StartupField.customers, StartupField.marketSize],
    // Finance and Growth.
    [
      StartupField.revenueNow,
      StartupField.capital,
      StartupField.burn,
      StartupField.valuation,
      StartupField.revenue,
      StartupField.modelText,
    ],
    // Startup Team: no required field (the member editor must be closed).
    [],
    // Startup Ask, the last step (the funding / partner / support fields
    // only count while their box is ticked: see [_fieldsOf]).
    [
      StartupField.lookingFor,
      StartupField.funding,
      StartupField.raised,
      StartupField.partnerTypes,
      StartupField.supportTypes,
    ],
  ];

  /// The fields that must be valid on step [s] right now.
  List<StartupField> _fieldsOf(int s) {
    if (s != askStep) return _stepFields[s];
    return [
      StartupField.lookingFor,
      if (wantsFunding) ...[StartupField.funding, StartupField.raised],
      if (wantsPartner) StartupField.partnerTypes,
      if (wantsSupport) StartupField.supportTypes,
    ];
  }

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
    // A year outside 2000..this year says so as soon as 4 digits are typed;
    // fewer digits or an empty field wait for Next (or for leaving the field).
    if (f == StartupField.founded && founded.text.trim().length >= 4) {
      return raw;
    }
    // The "Other" write-in repeating a listed option says so at once.
    if (f == StartupField.partnerTypes && partnerOtherRepeats) return raw;
    if (f == StartupField.supportTypes && supportOtherRepeats) return raw;
    if (f == StartupField.sectorOther && sectorOtherRepeats) return raw;
    if (f == StartupField.modelOther && modelOtherRepeats) return raw;
    // The range error shows as soon as a number is entered (and follows the
    // Stage if it changes); an empty field waits for Next.
    if (f == StartupField.funding &&
        StartupValidators.money(funding.text) != null) {
      return raw;
    }
    // "Already raised" can't pass the amount being raised: says so at once.
    if (f == StartupField.raised &&
        StartupValidators.money(raised.text) != null) {
      return raw;
    }
    // A year under SAR 1,000 says so at once (empty boxes wait for Next).
    if (f == StartupField.revenue &&
        StartupValidators.revenueTooLow(rev1.text, rev2.text, rev3.text)) {
      return raw;
    }
    // A typed zero says so at once (an empty field waits for Next).
    if (f == StartupField.marketSize && tam.text.trim().isNotEmpty) {
      return raw;
    }
    // The website is checked from the first character (it is optional, so
    // an empty one is never an error).
    if (f == StartupField.website && website.text.trim().isNotEmpty) {
      return raw;
    }
    return _tried.contains(_stepOf(f)) || _left.contains(f) ? raw : null;
  }

  /// True when [f] should be drawn in the error style.
  bool hasError(StartupField f) => errorOf(f) != null;

  /// Every required answer of [s] (0-based) is given.
  bool stepComplete(int s) {
    if (s == teamStep && (editorOpen || !founderComplete)) return false;
    // Editing one section checks only that section's fields.
    final fields = isSectionEdit && s == onlyStep
        ? _sectionFields(onlySection!)
        : _fieldsOf(s);
    for (final f in fields) {
      if (_rawError(f) != null) return false;
    }
    return true;
  }

  bool get currentComplete => stepComplete(step);

  /// The fields of Details section [section] (see [sectionSteps]).
  List<StartupField> _sectionFields(int section) =>
      section == teamStep ? const [] : _fieldsOf(section);

  // --------------------------------------------------------------- changes

  /// Rebuilds after a selection change.
  void _touch(VoidCallback change) {
    change();
    notifyListeners();
  }

  /// Ticks / unticks one sector (the first one ticked is the main one).
  void toggleSector(String label) => _touch(() {
    if (!sectorPicks.remove(label)) {
      sectorPicks.add(label);
    } else if (label == _other) {
      sectorOther.clear();
    }
  });

  /// Sets ONE sector (and the typed text for "Other").
  void selectSector(String label, String? other) => _touch(() {
    sectorPicks
      ..clear()
      ..add(label);
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

  /// Toggles a Looking for chip by its label.
  void toggleLookingFor(String label) => _touch(() {
    final item = LookingFor.values.firstWhere((l) => l.label == label);
    final next = {...lookingFor};
    if (!next.remove(item)) next.add(item);
    lookingFor = next;
  });

  void togglePartner(String label) => _touch(() {
    final next = {...partnerSel};
    if (!next.remove(label)) next.add(label);
    partnerSel = next;
  });

  void toggleSupport(String label) => _touch(() {
    final next = {...supportSel};
    if (!next.remove(label)) next.add(label);
    supportSel = next;
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
    if (step == 0 || isSectionEdit) return false;
    step--;
    notifyListeners();
    return true;
  }

  /// The footer button: advances, or marks the step as tried.
  StepAdvance next() {
    if (!currentComplete) {
      _tried.add(step);
      notifyListeners();
      return step == teamStep && editorOpen
          ? StepAdvance.memberOpen
          : StepAdvance.incomplete;
    }
    if (!isSectionEdit && step < stepCount - 1) {
      step++;
      if (step > furthestStep) furthestStep = step;
      _openFounderIfNeeded();
      notifyListeners();
      return StepAdvance.advanced;
    }
    return StepAdvance.readyToSave;
  }

  // ----------------------------------------------------------- team members

  /// The signed-in founder's row, always first. Name and e-mail come from
  /// the account (locked); the founder fills in the role and contribution.
  void _ensureFounder() {
    final user = AppSession.instance.user;
    if (user == null || !user.isFounder) return;
    // Only the person who created the startup has the Founder card (an owner
    // it was handed to is a co-founder).
    if (initial != null && initial!.originalFounderId != user.uid) return;
    final list = [...team];
    var i = list.indexWhere((m) => m.isFounder);
    if (i < 0) {
      i = list.indexWhere(
        (m) =>
            m.uid == user.uid ||
            (m.uid == null &&
                m.name.trim().toLowerCase() ==
                    user.fullName.trim().toLowerCase()),
      );
    }
    final me = TeamMember(
      name: user.fullName,
      email: user.email.trim().toLowerCase(),
      role: i < 0 ? '' : list[i].role,
      contribution: i < 0 ? '' : list[i].contribution,
      isFounder: true,
      uid: user.uid,
    );
    if (i < 0) {
      list.insert(0, me);
    } else {
      list
        ..removeAt(i)
        ..insert(0, me);
    }
    team = list;
  }

  /// On the team step, the founder's own details open straight away while
  /// their role or contribution is still empty, so they see what to fill in.
  void _openFounderIfNeeded() {
    if (step != teamStep || editorOpen || founderComplete) return;
    final i = team.indexWhere((m) => m.isFounder);
    if (i >= 0) openMemberEditor(i);
  }

  TeamMember? get founderMember {
    final i = team.indexWhere((m) => m.isFounder);
    return i < 0 ? null : team[i];
  }

  /// The founder filled in their role and contribution (or there is no
  /// founder row, e.g. a co-founder editing).
  bool get founderComplete {
    final f = founderMember;
    return f == null ||
        (f.role.trim().isNotEmpty && f.contribution.trim().isNotEmpty);
  }

  /// Show the "add your role and contribution" line under the founder card.
  bool get founderRowError => _tried.contains(teamStep) && !founderComplete;

  /// True for the founder's own row and for my own row: their name and
  /// e-mail come from the account and are locked (only the role and the
  /// contribution can be edited).
  bool isLockedMember(TeamMember m) {
    if (m.isFounder) return true;
    final uid = AppSession.instance.user?.uid;
    return uid != null && m.uid == uid;
  }

  /// Somebody who joined through their account: their name and e-mail are
  /// theirs, so the founder can't edit them.
  bool isLinkedMember(TeamMember m) =>
      !m.isFounder && !m.invited && m.uid != null;

  /// The signed-in user owns the startup being edited (or is creating it).
  bool get editorIsOwner {
    final s = initial;
    if (s == null) return true;
    final uid = AppSession.instance.user?.uid;
    return uid != null && uid == s.founderId;
  }

  /// [m] joined as a co-founder.
  bool _joinedCoFounder(TeamMember m) =>
      !m.invited &&
      m.uid != null &&
      (initial?.memberRoles[m.uid] == 'coFounder' || m.coFounder);

  /// "Remove this member" on [m]'s card. Nobody removes their own card (they
  /// leave instead) or the owner's; only the owner removes a co-founder who
  /// joined, or the founder after the startup was handed over (her card then
  /// stays as "Founder (former)"). Co-founders can remove members.
  bool canRemoveMember(TeamMember m) {
    final me = AppSession.instance.user?.uid;
    final owner = initial?.founderId;
    if (m.uid != null && (m.uid == me || m.uid == owner)) return false;
    if (m.isFounder) return m.uid != null && initial != null && editorIsOwner;
    if (_joinedCoFounder(m)) return editorIsOwner;
    return true;
  }

  /// The Co-founder box on [m]'s card. Only the owner changes it for someone
  /// who already joined (it decides who can edit and who blocks a delete);
  /// the founder and the owner never have one.
  bool canChangeCoFounder(TeamMember m) {
    if (isLockedMember(m)) return false;
    final owner = initial?.founderId;
    if (m.uid != null && m.uid == owner) return false;
    if (!m.invited && m.uid != null) return editorIsOwner;
    return true;
  }

  bool get editingLinked =>
      editorOpen && editingIndex != null && isLinkedMember(team[editingIndex!]);

  bool get editingFounder =>
      editorOpen && editingIndex != null && isLockedMember(team[editingIndex!]);

  bool _validName(String v) => Validators.isFullName(v);

  // ---- the editor's "required" messages after leaving a field (the same
  // rule as the steps: a format error shows from the first keystroke, an
  // empty field only after "Add member" or after typing in it and leaving).
  final Map<TextEditingController, FocusNode> _memberFocus = {};
  final Set<TextEditingController> _memberEdited = {};
  final Set<TextEditingController> _memberLeft = {};

  /// The focus node of an editor field (give it to the field).
  FocusNode memberFocusOf(TextEditingController c) {
    final existing = _memberFocus[c];
    if (existing != null) return existing;
    var last = c.text;
    c.addListener(() {
      if (c.text == last) return;
      last = c.text;
      _memberEdited.add(c);
    });
    final node = FocusNode();
    node.addListener(() {
      if (!node.hasFocus && _memberEdited.contains(c) && _memberLeft.add(c)) {
        notifyListeners();
      }
    });
    return _memberFocus[c] = node;
  }

  bool _memberRequiredShown(TextEditingController c) =>
      memberTried || _memberLeft.contains(c);

  /// The same e-mail rule as sign-up: a common provider or a university
  /// address, with its real extension.
  bool get _emailValid => Validators.isSignupEmail(memberEmail.text);

  /// Another member (not the one being edited) already has this e-mail.
  bool get memberDuplicate {
    final e = memberEmail.text.trim().toLowerCase();
    if (e.isEmpty) return false;
    for (var i = 0; i < team.length; i++) {
      if (i == editingIndex) continue;
      if (team[i].email == e) return true;
    }
    return false;
  }

  /// Every field of the editor is filled and valid (the founder's own row
  /// only needs the role and the contribution).
  bool get memberComplete {
    final roleOk =
        !_blank(memberRole) &&
        !Validators.hasDigit(memberRole.text) &&
        !_blank(memberContribution);
    if (editingFounder || editingLinked) return roleOk;
    return _validName(memberName.text) &&
        !Validators.hasDigit(memberName.text) &&
        _emailValid &&
        !memberDuplicate &&
        roleOk;
  }

  /// The error under an editor field: empty ones after "Add member" was
  /// tried; format and duplicate errors show as soon as they apply.
  String? memberError(TextEditingController c) {
    if ((editingFounder || editingLinked) &&
        (c == memberName || c == memberEmail)) {
      return null;
    }
    if (c == memberName) {
      if (_blank(c)) {
        return _memberRequiredShown(c)
            ? ValidationStrings.memberNameRequired
            : null;
      }
      // Live: no numbers, and a first and last name.
      if (Validators.hasDigit(c.text)) return ValidationStrings.nameNoNumbers;
      return _validName(c.text) ? null : ValidationStrings.fullName;
    }
    if (c == memberEmail) {
      if (_blockedEmail != null &&
          c.text.trim().toLowerCase() == _blockedEmail) {
        return ValidationStrings.memberIsInvestor;
      }
      if (_blank(c)) {
        return _memberRequiredShown(c)
            ? ValidationStrings.memberEmailRequired
            : null;
      }
      if (!_emailValid) return ValidationStrings.memberEmailInvalid;
      return memberDuplicate ? ValidationStrings.memberDuplicate : null;
    }
    if (c == memberRole) {
      // Live: no numbers.
      if (Validators.hasDigit(c.text)) {
        return ValidationStrings.memberRoleNoNumbers;
      }
      return _memberRequiredShown(c) && _blank(c)
          ? ValidationStrings.memberRoleRequired
          : null;
    }
    return _memberRequiredShown(c) && _blank(c)
        ? ValidationStrings.memberContributionRequired
        : null;
  }

  void openMemberEditor([int? index]) => _touch(() {
    // A team is full at 20 people (the rules allow no more).
    if (index == null && team.length >= TeamMember.teamMax) return;
    editorOpen = true;
    editingIndex = index;
    memberTried = false;
    _memberEdited.clear();
    _memberLeft.clear();
    final m = index == null ? null : team[index];
    memberName.text = m?.name ?? '';
    memberEmail.text = m?.email ?? '';
    memberRole.text = m?.role ?? '';
    memberContribution.text = m?.contribution ?? '';
    memberCoFounder = m?.coFounder ?? false;
    _memberBaseline = _memberSignature();
  });

  /// The member editor's values when it opened.
  String _memberBaseline = '';

  String _memberSignature() =>
      '${memberName.text}|${memberEmail.text}|${memberRole.text}|'
      '${memberContribution.text}|$memberCoFounder';

  /// True when a value of the open member editor differs from how it opened:
  /// its Cancel asks "Discard changes?" only then.
  bool get memberDirty => editorOpen && _memberSignature() != _memberBaseline;

  void setMemberCoFounder(bool v) => _touch(() => memberCoFounder = v);

  void cancelMemberEditor() => _touch(() {
    editorOpen = false;
    editingIndex = null;
    memberTried = false;
    _memberEdited.clear();
    _memberLeft.clear();
  });

  /// E-mails found to be registered accounts while adding members: their
  /// invitation is not a "create your account" one.
  final Set<String> _registeredEmails = {};

  /// "Add member" / "Save member".
  ///
  /// - [MemberSave.invalid]: a field is wrong or empty (errors now show).
  /// - [MemberSave.needsInvite]: nobody is registered with that e-mail; the
  ///   screen asks "This person isn't on Start.sa yet" and, on "Send
  ///   invite", calls this again with [inviteConfirmed].
  /// - [MemberSave.saved]: the member is in the list.
  Future<MemberSave> saveMember({bool inviteConfirmed = false}) async {
    final i = editingIndex;
    final old = i == null ? null : team[i];
    if (editingFounder) {
      if (!memberComplete) {
        _touch(() => memberTried = true);
        return MemberSave.invalid;
      }
      _commitMember(
        old!.copyWith(
          role: memberRole.text.trim(),
          contribution: memberContribution.text.trim(),
        ),
      );
      return MemberSave.saved;
    }
    // Somebody who already joined: only the role, the contribution and the
    // Co-founder box change (their name and e-mail are theirs).
    if (old != null && !old.invited && old.uid != null) {
      if (_blank(memberRole) ||
          Validators.hasDigit(memberRole.text) ||
          _blank(memberContribution)) {
        _touch(() => memberTried = true);
        return MemberSave.invalid;
      }
      _commitMember(
        old.copyWith(
          role: memberRole.text.trim(),
          contribution: memberContribution.text.trim(),
          coFounder: memberCoFounder,
        ),
      );
      return MemberSave.saved;
    }
    final emailOk = _emailValid && !memberDuplicate;
    final rest =
        !_blank(memberRole) &&
        !Validators.hasDigit(memberRole.text) &&
        !_blank(memberContribution);
    if (!emailOk || !rest) {
      _touch(() => memberTried = true);
      return MemberSave.invalid;
    }
    final email = memberEmail.text.trim().toLowerCase();
    final account = await TeamLookup.instance.findByEmail(email);
    if (account != null && !account.isFounder) {
      // An investor account can't be on a startup's team.
      _touch(() => _blockedEmail = email);
      return MemberSave.invalid;
    }
    if (account != null) {
      _registeredEmails.add(email);
      // Already on Start.sa: they get an invitation to accept (no dialog
      // needed); their account name replaces the typed one.
      final alreadyInvited = old != null && old.invited && old.email == email;
      memberName.text = account.name;
      _commitMember(
        TeamMember(
          name: account.name,
          email: email,
          role: memberRole.text.trim(),
          contribution: memberContribution.text.trim(),
          coFounder: memberCoFounder,
          invited: true,
        ),
      );
      return alreadyInvited ? MemberSave.saved : MemberSave.invited;
    }
    if (!_validName(memberName.text) || Validators.hasDigit(memberName.text)) {
      _touch(() => memberTried = true);
      return MemberSave.invalid;
    }
    final alreadyInvited = old != null && old.invited && old.email == email;
    if (!inviteConfirmed && !alreadyInvited) return MemberSave.needsInvite;
    _commitMember(
      TeamMember(
        name: memberName.text.trim(),
        email: email,
        role: memberRole.text.trim(),
        contribution: memberContribution.text.trim(),
        coFounder: memberCoFounder,
        invited: true,
      ),
    );
    return alreadyInvited ? MemberSave.saved : MemberSave.invited;
  }

  void _commitMember(TeamMember member) => _touch(() {
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
    _memberEdited.clear();
    _memberLeft.clear();
  });

  void removeMember() {
    final i = editingIndex;
    if (i == null || !canRemoveMember(team[i])) return;
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
    lostPermission = false;
    notifyListeners();
    try {
      // Editing: my CURRENT role is read again right before writing. If I was
      // removed (or turned into a team member) nothing is saved.
      if (isEditing && !await _stillAllowed()) {
        lostPermission = true;
        saveError = FounderToolsStrings.noPermissionAnymore;
        return null;
      }
      final startup = _build();
      inviteSummary = const InviteSummary();
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
      inviteSummary = await _sendInvitations(saved);
      return saved;
    } catch (e) {
      // In a debug build the real reason is appended, so a failure can be
      // diagnosed from the screen (the plain message ships in release).
      saveError = FounderToolsStrings.saveFailed;
      debugPrint('Saving the startup failed: $e (${startupErrorMessage(e)})');
      return null;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Why the last invitation e-mail was refused (shown in debug builds).
  String? lastInviteError;

  /// What happened to the invitation e-mails of the last [save].
  InviteSummary inviteSummary = const InviteSummary();

  /// The status of each invitation I sent for this startup, by e-mail (to
  /// show "Declined" on a card).
  Map<String, InvitationStatus> inviteStatus = const {};

  /// Reads the invitations of this startup and, when somebody accepted while
  /// the startup was private, fixes their card.
  Future<void> loadInvitations() async {
    final s = initial;
    if (s == null) return;
    try {
      final sent = await _invitations.sentFor(s.id);
      inviteStatus = {for (final i in sent) i.emailLower: i.status};
      final fixed = await _invitations.reconcileTeam(s.copyWith(team: team));
      if (fixed != null) {
        team = fixed;
        _baseline = _signature();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Could not read the invitations: $e');
    }
  }

  /// Creates the invitations of every invited member, cancels the ones of
  /// members that were removed, and sends the e-mails not sent yet.
  Future<InviteSummary> _sendInvitations(Startup saved) async {
    var sent = 0, failed = 0;
    var offline = false, limit = false;
    final byEmail = {
      for (final m in saved.team)
        if (m.invited && !m.isFounder && m.email.isNotEmpty) m.email: m,
    };
    try {
      for (final old in initial?.team ?? const <TeamMember>[]) {
        if (old.invited &&
            old.email.isNotEmpty &&
            !byEmail.containsKey(old.email)) {
          await _invitations.cancel(saved.id, old.email);
        }
      }
    } catch (e) {
      debugPrint('Could not cancel an invitation: $e');
    }
    final myName = AppSession.instance.user?.fullName ?? '';
    for (final m in byEmail.values) {
      try {
        final inv = await _invitations.ensure(
          startup: saved,
          member: m,
          invitedByName: myName,
          newUser: !_registeredEmails.contains(m.email),
        );
        if (!inv.isPending || inv.emailSent) continue;
        final outcome = await _invitations.sendEmail(inv);
        if (outcome != InviteSendResult.sent) {
          lastInviteError = InviteRelayService.lastError;
        }
        switch (outcome) {
          case InviteSendResult.sent:
            sent++;
          case InviteSendResult.notConfigured:
            failed++;
          case InviteSendResult.offline:
            offline = true;
            failed++;
          case InviteSendResult.dailyLimit:
            limit = true;
            failed++;
          case InviteSendResult.tooSoon:
            break;
          case InviteSendResult.failed:
            failed++;
        }
      } catch (e) {
        debugPrint('Could not create an invitation: $e');
        lastInviteError = 'invitation: $e';
        failed++;
      }
    }
    return InviteSummary(
      sent: sent,
      failed: failed,
      offline: offline,
      limit: limit,
    );
  }

  /// True when the editor opened because of a role that no longer exists.
  bool lostPermission = false;

  Future<bool> _stillAllowed() async {
    final uid = AppSession.instance.user?.uid;
    if (uid == null) return true;
    try {
      final fresh = await _repository.fetchById(initial!.id);
      if (fresh == null || fresh.isClosed) return false;
      return StartupRole.of(fresh, uid)?.canManage ?? false;
    } catch (_) {
      // Offline: the rules still decide when the write is sent.
      return true;
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

  /// What [save] would write (used by the tests).
  Startup startupToSave() => _build();

  Startup _build() {
    final websiteText = website.text.trim();
    return Startup(
      id: initial?.id ?? '',
      founderId: initial?.founderId ?? '',
      name: name.text.trim(),
      description: description.text.trim(),
      sector: sector ?? initial!.sector,
      // The typed text belongs to the main sector only when "Other" is it.
      sectorOther: sector == Sector.other ? sectorOther.text.trim() : null,
      // The other picks, in order ("Other" replaced by what was typed).
      otherSectors: [
        for (final p in sectorPicks.skip(1))
          if (p != _other)
            p
          else if (sectorOther.text.trim().isNotEmpty)
            sectorOther.text.trim(),
      ],
      stage: stage ?? initial!.stage,
      businessModel: model ?? initial!.businessModel,
      businessModelOther: isModelOther ? modelOther.text.trim() : null,
      location: city ?? initial!.location,
      foundedYear: int.tryParse(founded.text.trim()),
      websiteUrl: websiteText.isEmpty
          ? null
          : StartupValidators.normalizeUrl(websiteText),
      lookingFor: lookingFor,
      fundingRequirement: wantsFunding
          ? StartupValidators.money(funding.text)
          : null,
      isPublic: isPublic,
      logoUrl: initial?.logoUrl,
      logoData: initial?.logoData,
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
      growth: initial?.growth ?? '',
      revenueThisYear: StartupValidators.money(revenueNow.text),
      monthlyBurn: StartupValidators.money(burn.text),
      businessModelText: modelText.text.trim(),
      raisedInRound: wantsFunding ? StartupValidators.money(raised.text) : null,
      partnerTypes: wantsPartner
          ? _typesToSave(
              partnerSel,
              partnerOther,
              FounderToolsStrings.partnerOptions,
            )
          : const [],
      supportTypes: wantsSupport
          ? _typesToSave(
              supportSel,
              supportOther,
              FounderToolsStrings.supportOptions,
            )
          : const [],
      capital: StartupValidators.money(capital.text),
      revenueYear1: StartupValidators.money(rev1.text),
      revenueYear2: StartupValidators.money(rev2.text),
      revenueYear3: StartupValidators.money(rev3.text),
      valuation: StartupValidators.money(valuation.text),
      // The old lead-investor answer is no longer asked; what an existing
      // startup already saved stays as it is.
      wantsLeadInvestor: initial?.wantsLeadInvestor,
      // Editing a startup keeps its co-founders and team members.
      memberRoles: _roles(),
      // Who created it and whether it is closed never change here.
      foundedBy: initial?.originalFounderId,
      formerFounderId: _formerFounderAfterSave(),
      isClosed: initial?.isClosed ?? false,
    );
  }

  /// The owner removed the founder (after the startup was handed over): her
  /// card stays on the team as "Founder (former)" (she can remove it from her
  /// profile). Otherwise what was saved.
  String? _formerFounderAfterSave() {
    final s = initial;
    if (s == null) return null;
    final founder = s.originalFounderId;
    final wasOnTeam = s.memberRoles.containsKey(founder);
    final stillOnTeam = team.any((m) => m.uid == founder && !m.invited);
    if (founder != s.founderId && wasOnTeam && !stillOnTeam) return founder;
    return s.formerFounderId;
  }

  /// The picked types in list order, "Other" replaced by what was typed.
  static List<String> _typesToSave(
    Set<String> picked,
    TextEditingController other,
    List<String> order,
  ) => [
    for (final o in order)
      if (picked.contains(o))
        if (o != 'Other')
          o
        else if (other.text.trim().isNotEmpty)
          other.text.trim(),
  ];

  /// The reverse of [_typesToSave]: saved texts that are not in [order] were
  /// typed under "Other".
  static (Set<String>, String) _typesFromSaved(
    List<String> saved,
    List<String> order,
  ) {
    final picked = <String>{};
    final typed = <String>[];
    for (final v in saved) {
      if (order.contains(v) && v != 'Other') {
        picked.add(v);
      } else {
        picked.add('Other');
        // An older value that is not in the list any more is shown under
        // "Other" (all of them, not only the last one).
        if (v != 'Other') typed.add(v);
      }
    }
    return (picked, typed.join(', '));
  }

  /// Who has access: the startup's current members, updated by the team list.
  /// A person who joined gets the role of their Co-founder box; a joined
  /// person removed from the list loses access.
  Map<String, String> _roles() {
    final roles = {...?initial?.memberRoles};
    final owner = initial?.founderId;
    final inTeam = <String>{};
    for (final m in team) {
      final uid = m.uid;
      // The owner is never in memberRoles.
      if (uid == null || m.invited || uid == owner) continue;
      inTeam.add(uid);
      // Only people who already have access change role. The person who
      // created the startup stays a co-founder after handing it over.
      if (roles.containsKey(uid)) {
        roles[uid] = m.coFounder || m.isFounder ? 'coFounder' : 'member';
      }
    }
    final before = {
      for (final m in initial?.team ?? const <TeamMember>[]) m.uid,
    };
    roles.removeWhere(
      (uid, _) => !inTeam.contains(uid) && before.contains(uid),
    );
    return roles;
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
    sectorPicks
      ..clear()
      ..add(s.sector.label);
    sectorOther.text = s.sector == Sector.other ? (s.sectorOther ?? '') : '';
    for (final o in s.otherSectors) {
      if (Sector.fromLabel(o) != null) {
        if (!sectorPicks.contains(o)) sectorPicks.add(o);
      } else if (!sectorPicks.contains(_other)) {
        // A typed "Other" sector.
        sectorPicks.add(_other);
        sectorOther.text = o;
      }
    }
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
    revenueNow.text = _money(s.revenueThisYear);
    capital.text = _money(s.capital);
    burn.text = _money(s.monthlyBurn);
    modelText.text = s.businessModelText;
    raised.text = _money(s.raisedInRound);
    final (partners, partnerText) = _typesFromSaved(
      s.partnerTypes,
      FounderToolsStrings.partnerOptions,
    );
    partnerSel = partners;
    partnerOther.text = partnerText;
    final (supports, supportText) = _typesFromSaved(
      s.supportTypes,
      FounderToolsStrings.supportOptions,
    );
    supportSel = supports;
    supportOther.text = supportText;
    rev1.text = _money(s.revenueYear1);
    rev2.text = _money(s.revenueYear2);
    rev3.text = _money(s.revenueYear3);
    valuation.text = _money(s.valuation);
    funding.text = _money(s.fundingRequirement);
    lookingFor = {...s.lookingFor};
    isPublic = s.isPublic;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.removeListener(notifyListeners);
      c.dispose();
    }
    for (final n in _focus.values) {
      n.dispose();
    }
    for (final n in _memberFocus.values) {
      n.dispose();
    }
    super.dispose();
  }
}
