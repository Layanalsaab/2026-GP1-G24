import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../helpers/startup_validators.dart';
import '../../../helpers/app_session.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';
import '../../../models/team_member.dart';
import '../view_models/startup_steps_view_model.dart';
import 'founder_ui.dart';
import 'team_member_widgets.dart';

/// The white card content of one step of the Add / Edit / onboarding form
/// (docs/05 D2, docs/06 section 8). Reads and writes [vm]; rebuilds with it.
/// [step] is 0-based.
class StartupStepBody extends StatelessWidget {
  const StartupStepBody({
    super.key,
    required this.vm,
    required this.step,
    this.section,
  });

  final StartupStepsViewModel vm;
  final int step;

  /// Editing one Details section: on the Funding & goals step only that
  /// half is shown (3 Finance and Growth, 4 Startup Ask). Null = all of it.
  final int? section;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => switch (step) {
        0 => _Basics(vm: vm),
        1 => _ProblemSolution(vm: vm),
        2 => _TargetMarket(vm: vm),
        3 => _Funding(vm: vm, section: section),
        _ => _Team(vm: vm),
      },
    );
  }
}

Widget _text(
  StartupStepsViewModel vm, {
  required String label,
  required TextEditingController controller,
  required String hint,
  required int max,
  required StartupField field,
  bool multiline = false,
  int rows = 4,
  bool sentenceCase = false,
}) => LabeledTextField(
  label: label,
  required: true,
  controller: controller,
  placeholder: hint,
  maxLength: max,
  multiline: multiline,
  rows: rows,
  sentenceCase: sentenceCase,
  error: vm.errorOf(field),
);

Widget _money(
  StartupStepsViewModel vm, {
  required String label,
  required TextEditingController controller,
  required StartupField field,
  bool required = true,
}) => AppField(
  label: label,
  required: required,
  error: vm.errorOf(field),
  child: MoneyField(controller: controller, hasError: vm.hasError(field)),
);

// ----------------------------------------------------------------- step 1

class _Basics extends StatelessWidget {
  const _Basics({required this.vm});

  final StartupStepsViewModel vm;

  Future<void> _pickSector(BuildContext context) async {
    final r = await showPickerSheet(
      context,
      title: FounderToolsStrings.sectorTitle,
      options: [for (final s in Sector.values) s.label],
      selected: vm.sector?.label,
      otherText: vm.sectorOther.text,
      searchHint: FounderToolsStrings.sectorSearch,
      noResultsText: FounderToolsStrings.sectorNoResults,
      otherNoun: FounderToolsStrings.sectorNoun,
      tall: true,
    );
    if (r != null) vm.selectSector(r.value, r.otherText);
  }

  Future<void> _pickStage(BuildContext context) async {
    final r = await showPickerSheet(
      context,
      title: FounderToolsStrings.stageTitle,
      options: [for (final s in StartupStage.picks) s.label],
      selected: vm.stage?.label,
    );
    if (r != null) vm.selectStage(r.value);
  }

  Future<void> _pickModel(BuildContext context) async {
    final r = await showPickerSheet(
      context,
      title: FounderToolsStrings.modelTitle,
      options: [for (final m in BusinessModel.picks) m.label],
      selected: vm.model?.label,
      otherText: vm.modelOther.text,
      otherNoun: FounderToolsStrings.modelNoun,
    );
    if (r != null) vm.selectModel(r.value, r.otherText);
  }

  Future<void> _pickCity(BuildContext context) async {
    final r = await showPickerSheet(
      context,
      title: FounderToolsStrings.cityTitle,
      options: [for (final c in StartupLocation.values) c.label],
      selected: vm.city?.label,
      searchHint: FounderToolsStrings.citySearch,
      noResultsText: FounderToolsStrings.cityNoResults,
      tall: true,
    );
    if (r != null) vm.selectCity(r.value);
  }

  @override
  Widget build(BuildContext context) {
    final foundedError = vm.errorOf(StartupField.founded);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LogoPickerRow(
          onTap: vm.pickLogo,
          hasLogo: vm.hasLogo,
          initials: Startup.initialsOf(vm.name.text),
          image: vm.newLogo != null
              ? FileImage(vm.newLogo!)
              : (vm.existingLogoUrl != null
                    ? NetworkImage(vm.existingLogoUrl!)
                    : null),
        ),
        if (vm.logoError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(vm.logoError!, style: AppText.error),
          ),
        FormFieldColumn(
          children: [
            _text(
              vm,
              label: FounderToolsStrings.nameLabel,
              controller: vm.name,
              hint: FounderToolsStrings.nameHint,
              max: Startup.nameMax,
              field: StartupField.name,
            ),
            _text(
              vm,
              label: FounderToolsStrings.descriptionLabel,
              controller: vm.description,
              hint: FounderToolsStrings.descriptionHint,
              max: Startup.descriptionMax,
              field: StartupField.description,
              multiline: true,
            ),
            AppField(
              label: FounderToolsStrings.sectorLabel,
              required: true,
              error:
                  vm.errorOf(StartupField.sector) ??
                  vm.errorOf(StartupField.sectorOther),
              child: SelectField(
                placeholder: FounderToolsStrings.sectorHint,
                semanticLabel: FounderToolsStrings.sectorLabel,
                value: vm.sector == null
                    ? null
                    : (vm.isSectorOther
                          ? SelectField.otherText(vm.sectorOther.text)
                          : vm.sector!.label),
                hasError:
                    vm.hasError(StartupField.sector) ||
                    vm.hasError(StartupField.sectorOther),
                onTap: () => _pickSector(context),
              ),
            ),
            AppField(
              label: FounderToolsStrings.stageLabel,
              required: true,
              error: vm.errorOf(StartupField.stage),
              child: SelectField(
                placeholder: FounderToolsStrings.stageHint,
                semanticLabel: FounderToolsStrings.stageLabel,
                value: vm.stage?.label,
                hasError: vm.hasError(StartupField.stage),
                onTap: () => _pickStage(context),
              ),
            ),
            AppField(
              label: FounderToolsStrings.modelLabel,
              required: true,
              error:
                  vm.errorOf(StartupField.model) ??
                  vm.errorOf(StartupField.modelOther),
              child: SelectField(
                placeholder: FounderToolsStrings.modelHint,
                semanticLabel: FounderToolsStrings.modelLabel,
                value: vm.model == null
                    ? null
                    : (vm.isModelOther
                          ? SelectField.otherText(vm.modelOther.text)
                          : vm.model!.label),
                hasError:
                    vm.hasError(StartupField.model) ||
                    vm.hasError(StartupField.modelOther),
                onTap: () => _pickModel(context),
              ),
            ),
            AppField(
              label: FounderToolsStrings.cityLabel,
              required: true,
              error: vm.errorOf(StartupField.city),
              child: SelectField(
                placeholder: FounderToolsStrings.cityHint,
                semanticLabel: FounderToolsStrings.cityLabel,
                value: vm.city?.label,
                hasError: vm.hasError(StartupField.city),
                onTap: () => _pickCity(context),
              ),
            ),
            LabeledTextField(
              label: FounderToolsStrings.foundedLabel,
              required: true,
              controller: vm.founded,
              placeholder: FounderToolsStrings.foundedHint,
              maxLength: 4,
              showCounter: false,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              valid: foundedError == null && vm.founded.text.length == 4,
              error: foundedError,
            ),
            LabeledTextField(
              label: FounderToolsStrings.websiteLabel,
              controller: vm.website,
              placeholder: FounderToolsStrings.websiteHint,
              maxLength: Startup.websiteMax,
              valid:
                  vm.website.text.trim().isNotEmpty &&
                  vm.errorOf(StartupField.website) == null &&
                  StartupValidators.isWebsite(vm.website.text),
              keyboardType: TextInputType.url,
              error: vm.errorOf(StartupField.website),
            ),
            AppField(
              label: FounderToolsStrings.visibilityLabel,
              child: ToggleCard(
                icon: vm.isPublic ? AppIcons.globe : AppIcons.lock,
                title: vm.isPublic
                    ? FounderToolsStrings.visibilityPublicTitle
                    : FounderToolsStrings.visibilityPrivateTitle,
                description: vm.isPublic
                    ? FounderToolsStrings.visibilityPublicText
                    : FounderToolsStrings.visibilityPrivateText,
                value: vm.isPublic,
                onChanged: vm.setPublic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- step 2

class _ProblemSolution extends StatelessWidget {
  const _ProblemSolution({required this.vm});

  final StartupStepsViewModel vm;

  @override
  Widget build(BuildContext context) {
    // Exactly three questions, shown in sentence case (not Title Case).
    return FormFieldColumn(
      children: [
        _text(
          vm,
          label: FounderToolsStrings.problemLabel,
          controller: vm.problem,
          hint: FounderToolsStrings.problemHint,
          max: Startup.longTextMax,
          field: StartupField.problem,
          multiline: true,
          sentenceCase: true,
        ),
        _text(
          vm,
          label: FounderToolsStrings.solutionLabel,
          controller: vm.solution,
          hint: FounderToolsStrings.solutionHint,
          max: Startup.longTextMax,
          field: StartupField.solution,
          multiline: true,
          sentenceCase: true,
        ),
        _text(
          vm,
          label: FounderToolsStrings.advantageLabel,
          controller: vm.advantage,
          hint: FounderToolsStrings.advantageHint,
          max: Startup.longTextMax,
          field: StartupField.advantage,
          multiline: true,
          sentenceCase: true,
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- step 3

/// Target Market: who the customers are and how big their yearly spend is.
/// Both labels are shown in sentence case.
class _TargetMarket extends StatelessWidget {
  const _TargetMarket({required this.vm});

  final StartupStepsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FormFieldColumn(
      children: [
        _text(
          vm,
          label: FounderToolsStrings.customersLabel,
          controller: vm.customers,
          hint: FounderToolsStrings.customersHint,
          max: Startup.customersMax,
          field: StartupField.customers,
          multiline: true,
          sentenceCase: true,
        ),
        // One SAR amount (no K/M/B picker, no hint under it: the explanation
        // is in the "i"). Stored in the existing `tam` value.
        AppField(
          label: FounderToolsStrings.marketLabel,
          required: true,
          sentenceCase: true,
          info: FounderToolsStrings.marketInfo,
          error: vm.errorOf(StartupField.marketSize),
          child: MoneyField(
            controller: vm.tam,
            hasError: vm.hasError(StartupField.marketSize),
            semanticLabel: FounderToolsStrings.marketLabel,
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- step 4

/// Funding & goals. It holds two halves that the Details tab edits one at a
/// time: Finance and Growth (growth plan, capital, expected revenue,
/// valuation) and Startup Ask (lead investor, funding amount, what the
/// startup looks for). In the normal form both are shown, one after the
/// other; when editing one Details [section] only that half is.
class _Funding extends StatelessWidget {
  const _Funding({required this.vm, this.section});

  final StartupStepsViewModel vm;
  final int? section;

  @override
  Widget build(BuildContext context) {
    final finance = <Widget>[
      _text(
        vm,
        label: FounderToolsStrings.growthLabel,
        controller: vm.growth,
        hint: FounderToolsStrings.growthHint,
        max: Startup.longTextMax,
        field: StartupField.growth,
        multiline: true,
      ),
      _money(
        vm,
        label: FounderToolsStrings.capitalLabel,
        controller: vm.capital,
        field: StartupField.capital,
      ),
      AppField(
        label: FounderToolsStrings.revenueLabel,
        required: true,
        hint: FounderToolsStrings.revenueHint,
        error: vm.errorOf(StartupField.revenue),
        child: TrioField(
          entries: [
            TrioEntry(
              label: 'Year 1',
              controller: vm.rev1,
              hasError: vm.hasError(StartupField.revenue),
            ),
            TrioEntry(
              label: 'Year 2',
              controller: vm.rev2,
              hasError: vm.hasError(StartupField.revenue),
            ),
            TrioEntry(
              label: 'Year 3',
              controller: vm.rev3,
              hasError: vm.hasError(StartupField.revenue),
            ),
          ],
        ),
      ),
      _money(
        vm,
        label: FounderToolsStrings.valuationLabel,
        controller: vm.valuation,
        field: StartupField.valuation,
      ),
    ];
    final ask = <Widget>[
      ChipGroupField(
        label: FounderToolsStrings.leadLabel,
        required: true,
        info: FounderToolsStrings.leadInfo,
        options: const [FounderToolsStrings.yes, FounderToolsStrings.no],
        selected: [
          if (vm.wantsLead != null)
            vm.wantsLead! ? FounderToolsStrings.yes : FounderToolsStrings.no,
        ],
        onTap: (label) => vm.setLead(label == FounderToolsStrings.yes),
        error: vm.errorOf(StartupField.lead),
      ),
      _money(
        vm,
        label: FounderToolsStrings.fundingLabel,
        controller: vm.funding,
        field: StartupField.funding,
      ),
      ChipGroupField(
        label: FounderToolsStrings.lookingForLabel,
        required: true,
        multi: true,
        options: [for (final l in LookingFor.values) l.label],
        selected: [for (final l in vm.lookingFor) l.label],
        onTap: vm.toggleLookingFor,
        error: vm.errorOf(StartupField.lookingFor),
        otherController: vm.lookingForOther,
        otherHint: FounderToolsStrings.lookingForOtherHint,
        otherError: vm.errorOf(StartupField.lookingForOther),
      ),
    ];
    return FormFieldColumn(
      children: [
        if (section == null || section == 3) ...finance,
        if (section == null || section == 4) ...ask,
      ],
    );
  }
}

// ---------------------------------------------------------------- last step

/// Startup Team: the team member list and editor (moved here from the old
/// "Market & team" step; otherwise unchanged).
class _Team extends StatelessWidget {
  const _Team({required this.vm});

  final StartupStepsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FormFieldColumn(
      children: [
        AppField(
          label: FounderToolsStrings.teamLabel,
          info: FounderToolsStrings.teamInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < vm.team.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                // The editor opens inside the member's own card.
                if (vm.editorOpen && vm.editingIndex == i)
                  _editor(vm, nameLocked: _isMe(vm.team[i]))
                else
                  TeamMemberRow(
                    member: vm.team[i],
                    onEdit: () => vm.openMemberEditor(i),
                  ),
              ],
              if (vm.team.isNotEmpty) const SizedBox(height: 14),
              // "Add team member" opens its editor at the bottom.
              if (vm.editorOpen && vm.editingIndex == null)
                _editor(vm)
              else
                AddMemberButton(onTap: () => vm.openMemberEditor()),
            ],
          ),
        ),
      ],
    );
  }
}

/// The signed-in user's own team row (matched by their account name).
bool _isMe(TeamMember m) {
  final user = AppSession.instance.user;
  if (user == null) return false;
  if (m.uid != null) return m.uid == user.uid;
  final me = user.fullName.trim().toLowerCase();
  return me.isNotEmpty && m.name.trim().toLowerCase() == me;
}

Widget _editor(StartupStepsViewModel vm, {bool nameLocked = false}) =>
    TeamMemberEditor(
      editing: vm.editingIndex != null,
      nameLocked: nameLocked,
      name: vm.memberName,
      role: vm.memberRole,
      specialization: vm.memberSpec,
      years: vm.memberYears,
      bio: vm.memberBio,
      complete: vm.memberComplete,
      errorOf: vm.memberError,
      onCancel: vm.cancelMemberEditor,
      onSave: vm.saveMember,
      onRemove: vm.removeMember,
    );
