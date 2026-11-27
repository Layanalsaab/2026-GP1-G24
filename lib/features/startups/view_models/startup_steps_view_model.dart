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

  incomplete,

  memberOpen,

  /// The last step is complete: call StartupStepsViewModel.save.
  readyToSave,
}

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
    'marketSize': marketSize.text,
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

  bool get isDirty =>
      newLogo != null || removeLogo || _signature() != _baseline;

  final Startup? initial;

  final int? onlySection;
  bool get isSectionEdit => onlySection != null;

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

  static int get stepCount => FounderToolsStrings.stepTitles.length;

  static int get teamStep => stepCount - 2;

  /// The Startup Ask: the last step ("Create startup" / "Save changes").
  static int get askStep => stepCount - 1;

  /// The current step, 0-based.
  int step = 0;

  final Set<int> _tried = {};

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
    StartupField.marketSize => marketSize,
    StartupField.modelText => modelText,
    StartupField.revenueNow => revenueNow,
    StartupField.capital => capital,
    StartupField.burn => burn,
    StartupField.valuation => valuation,
    StartupField.funding => funding,
    StartupField.raised => raised,
    _ => null,
  };

  FocusNode focusOf(StartupField f) {
    final existing = _focus[f];
    if (existing != null) return existing;
    final node = FocusNode();
    final c = _textOf(f);
    _lastText[f] = c?.text ?? '';
    node.addListener(() {
      final text = c?.text ?? '';
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

  final name = TextEditingController();
  final description = TextEditingController();
  final founded = TextEditingController();
  final website = TextEditingController();
  final sectorOther = TextEditingController();
  final modelOther = TextEditingController();

  final List<String> sectorPicks = [];

  /// The main sector: the first one picked.
  Sector? get sector =>
      sectorPicks.isEmpty ? null : Sector.fromLabel(sectorPicks.first);
  StartupStage? stage;
  CommerceModel? model;
  StartupLocation? city;
  File? newLogo;
  bool removeLogo = false;
  bool isPickingLogo = false;

  final problem = TextEditingController();
  final solution = TextEditingController();
  final customers = TextEditingController();
  final advantage = TextEditingController();

  final marketSize = TextEditingController();
  List<TeamMember> team = [];

  /// The member editor: null index with editorOpen = adding.
  bool editorOpen = false;
  int? editingIndex;
  bool memberTried = false;
  final memberName = TextEditingController();
  final memberRole = TextEditingController();
  final memberEmail = TextEditingController();

  /// The e-mail of an investor account that was refused as a member.
  String? _blockedEmail;
  final memberContribution = TextEditingController();

  /// null until a new member's Team member / Co-founder choice is made.
  bool? memberCoFounder;

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

  /// Funding / Partnership / Support.
  Set<LookingFor> lookingFor = {};

  Set<String> partnerSel = {};
  Set<String> supportSel = {};
  bool isPublic = true;

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
    marketSize,
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

  static final List<String> _sectorLabels = [
    for (final s in Sector.values) s.label,
  ];
  static final List<String> _modelLabels = [
    for (final m in CommerceModel.picks) ...[m.label, m.shortLabel],
  ];

  static final Map<String, String> modelAlsoCountsAs = {
    for (final m in CommerceModel.picks) ...{
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
  bool get isModelOther => model == CommerceModel.other;
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

  /// The live value under the burn rate ("About 6 months").
  String? get runwayLine => Runway.line(
    StartupValidators.money(capital.text),
    StartupValidators.money(burn.text),
  );

  static List<String> _ordered(Set<String> picked, List<String> order) => [
    for (final o in order)
      if (picked.contains(o)) o,
  ];

  /// The saved logo (base64) of the startup being edited, until removed.
  String? get existingLogoData => removeLogo ? null : initial?.logoData;

  bool get hasLogo => newLogo != null || existingLogoData != null;

  static bool _blank(TextEditingController c) => c.text.trim().isEmpty;

  /// The raw error of f (null when valid), regardless of "tried".
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
        return StartupValidators.marketSize(marketSize.text);
      case StartupField.advantage:
        return StartupValidators.advantage(advantage.text);
      case StartupField.revenueNow:
        return StartupValidators.revenueNow(revenueNow.text);
      case StartupField.capital:
        return StartupValidators.capital(capital.text);
      case StartupField.burn:
        return StartupValidators.burn(burn.text);
      case StartupField.modelText:
        return StartupValidators.revenueModel(modelText.text);
      case StartupField.revenue:
        return StartupValidators.revenue(rev1.text, rev2.text, rev3.text);
      case StartupField.valuation:
        return StartupValidators.valuation(valuation.text);
      case StartupField.funding:
        return StartupValidators.funding(funding.text);
      case StartupField.raised:
        return StartupValidators.raisedInRound(raised.text, funding.text);
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
    [],
    [
      StartupField.funding,
      StartupField.raised,
      StartupField.partnerTypes,
      StartupField.supportTypes,
    ],
  ];

  /// The fields that must be valid on step s right now.
  List<StartupField> _fieldsOf(int s) {
    if (s != askStep) return _stepFields[s];
    return [
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

  String? errorOf(StartupField f) {
    final raw = _rawError(f);
    if (raw == null) return null;
    if (f == StartupField.founded && founded.text.trim().length >= 4) {
      return raw;
    }
    if (f == StartupField.partnerTypes && partnerOtherRepeats) return raw;
    if (f == StartupField.supportTypes && supportOtherRepeats) return raw;
    if (f == StartupField.sectorOther && sectorOtherRepeats) return raw;
    if (f == StartupField.modelOther && modelOtherRepeats) return raw;
    if (f == StartupField.funding &&
        StartupValidators.money(funding.text) != null) {
      return raw;
    }
    if (f == StartupField.raised &&
        StartupValidators.money(raised.text) != null) {
      return raw;
    }
    if (f == StartupField.revenue &&
        StartupValidators.revenueTooLow(rev1.text, rev2.text, rev3.text)) {
      return raw;
    }
    if (f == StartupField.marketSize && marketSize.text.trim().isNotEmpty) {
      return raw;
    }
    if (f == StartupField.website && website.text.trim().isNotEmpty) {
      return raw;
    }
    return _tried.contains(_stepOf(f)) || _left.contains(f) ? raw : null;
  }

  /// True when f should be drawn in the error style.
  bool hasError(StartupField f) => errorOf(f) != null;

  /// Every required answer of s (0-based) is given.
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

  /// The fields of Details section section (see sectionSteps).
  List<StartupField> _sectionFields(int section) =>
      section == teamStep ? const [] : _fieldsOf(section);

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

  void selectStage(String label) => _touch(() {
    stage = StartupStage.picks.firstWhere((s) => s.label == label);
  });

  void selectModel(String label, String? other) => _touch(() {
    model = CommerceModel.picks.firstWhere((m) => m.label == label);
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

  void clearLogo() => _touch(() {
    newLogo = null;
    logoError = null;
    removeLogo = initial?.logoData != null;
  });

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
      _openFounderIfNeeded();
      notifyListeners();
      return StepAdvance.advanced;
    }
    return StepAdvance.readyToSave;
  }

  /// The signed-in founder's row, always first.
  void _ensureFounder() {
    final user = AppSession.instance.user;
    if (user == null || !user.isFounder) return;
    if (initial != null && initial!.founderId != user.uid) return;
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

  void _openFounderIfNeeded() {
    if (step != teamStep || editorOpen || founderComplete) return;
    final i = team.indexWhere((m) => m.isFounder);
    if (i >= 0) openMemberEditor(i);
  }

  TeamMember? get founderMember {
    final i = team.indexWhere((m) => m.isFounder);
    return i < 0 ? null : team[i];
  }

  bool get founderComplete {
    final f = founderMember;
    return f == null ||
        (f.role.trim().isNotEmpty && f.contribution.trim().isNotEmpty);
  }

  /// Show the "add your role and contribution" line under the founder card.
  bool get founderRowError => _tried.contains(teamStep) && !founderComplete;

  bool isLockedMember(TeamMember m) {
    if (m.isFounder) return true;
    final uid = AppSession.instance.user?.uid;
    return uid != null && m.uid == uid;
  }

  bool isLinkedMember(TeamMember m) =>
      !m.isFounder && !m.invited && m.uid != null;

  /// The signed-in user owns the startup being edited (or is creating it).
  bool get editorIsOwner {
    final s = initial;
    if (s == null) return true;
    final uid = AppSession.instance.user?.uid;
    return uid != null && uid == s.founderId;
  }

  /// m joined as a co-founder.
  bool _joinedCoFounder(TeamMember m) =>
      !m.invited &&
      m.uid != null &&
      (initial?.memberRoles[m.uid] == 'coFounder' || m.coFounder);

  /// "Remove this member" on m's card.
  bool canRemoveMember(TeamMember m) {
    final me = AppSession.instance.user?.uid;
    final owner = initial?.founderId;
    if (m.uid != null && (m.uid == me || m.uid == owner)) return false;
    if (m.isFounder) return m.uid != null && initial != null && editorIsOwner;
    if (_joinedCoFounder(m)) return editorIsOwner;
    return true;
  }

  /// The Co-founder box on m's card.
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

  bool get _emailValid => Validators.isEmail(memberEmail.text);

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
        roleOk &&
        memberCoFounder != null;
  }

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
    memberCoFounder = m?.coFounder;
    _memberBaseline = _memberSignature();
  });

  /// The member editor's values when it opened.
  String _memberBaseline = '';

  String _memberSignature() =>
      '${memberName.text}|${memberEmail.text}|${memberRole.text}|'
      '${memberContribution.text}|$memberCoFounder';

  bool get memberDirty => editorOpen && _memberSignature() != _memberBaseline;

  void setMemberCoFounder(bool v) => _touch(() => memberCoFounder = v);

  void cancelMemberEditor() => _touch(() {
    editorOpen = false;
    editingIndex = null;
    memberTried = false;
    _memberEdited.clear();
    _memberLeft.clear();
  });

  final Set<String> _registeredEmails = {};

  /// "Add member" / "Save member".
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
          coFounder: memberCoFounder ?? old.coFounder,
        ),
      );
      return MemberSave.saved;
    }
    final emailOk = _emailValid && !memberDuplicate;
    final rest =
        !_blank(memberRole) &&
        !Validators.hasDigit(memberRole.text) &&
        !_blank(memberContribution) &&
        memberCoFounder != null;
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
      final alreadyInvited = old != null && old.invited && old.email == email;
      memberName.text = account.name;
      _commitMember(
        TeamMember(
          name: account.name,
          email: email,
          role: memberRole.text.trim(),
          contribution: memberContribution.text.trim(),
          coFounder: memberCoFounder!,
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
        coFounder: memberCoFounder!,
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

  /// Saves the startup (create or update).
  Future<Startup?> save() async {
    if (isSaving) return null;
    isSaving = true;
    saveError = null;
    lostPermission = false;
    notifyListeners();
    try {
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

  /// What happened to the invitation e-mails of the last save.
  InviteSummary inviteSummary = const InviteSummary();

  Map<String, InvitationStatus> inviteStatus = const {};

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

  Startup _build() {
    final websiteText = website.text.trim();
    return Startup(
      id: initial?.id ?? '',
      founderId: initial?.founderId ?? '',
      name: name.text.trim(),
      description: description.text.trim(),
      sector: sector ?? initial!.sector,
      sectorOther: sector == Sector.other ? sectorOther.text.trim() : null,
      otherSectors: [
        for (final p in sectorPicks.skip(1))
          if (p != _other)
            p
          else if (sectorOther.text.trim().isNotEmpty)
            sectorOther.text.trim(),
      ],
      stage: stage ?? initial!.stage,
      commerceModel: model ?? initial!.commerceModel,
      commerceModelOther: isModelOther ? modelOther.text.trim() : null,
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
      logoData: initial?.logoData,
      createdAt: initial?.createdAt,
      updatedAt: initial?.updatedAt,
      problem: problem.text.trim(),
      solution: solution.text.trim(),
      customers: customers.text.trim(),
      advantage: advantage.text.trim(),
      marketSize: StartupValidators.money(marketSize.text),
      team: team,
      revenueThisYear: StartupValidators.money(revenueNow.text),
      monthlyBurn: StartupValidators.money(burn.text),
      revenueModel: modelText.text.trim(),
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
      // Editing a startup keeps its co-founders and team members.
      memberRoles: _roles(),
      // Whether it is closed never changes here.
      isClosed: initial?.isClosed ?? false,
    );
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
        if (v != 'Other') typed.add(v);
      }
    }
    return (picked, typed.join(', '));
  }

  Map<String, String> _roles() {
    final roles = {...?initial?.memberRoles};
    final owner = initial?.founderId;
    final inTeam = <String>{};
    for (final m in team) {
      final uid = m.uid;
      // The owner is never in memberRoles.
      if (uid == null || m.invited || uid == owner) continue;
      inTeam.add(uid);
      // Only people who already have access change role.
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
    stage = StartupStage.picks.contains(s.stage) ? s.stage : null;
    model = CommerceModel.picks.contains(s.commerceModel)
        ? s.commerceModel
        : null;
    modelOther.text = s.commerceModelOther ?? '';
    city = s.location;
    problem.text = s.problem;
    solution.text = s.solution;
    customers.text = s.customers;
    advantage.text = s.advantage;
    marketSize.text = _money(s.marketSize);
    team = [...s.team];
    revenueNow.text = _money(s.revenueThisYear);
    capital.text = _money(s.capital);
    burn.text = _money(s.monthlyBurn);
    modelText.text = s.revenueModel;
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
