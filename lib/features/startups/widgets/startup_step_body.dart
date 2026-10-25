import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/founder_tools_strings.dart';
import '../../../helpers/startup_validators.dart';
import '../../../helpers/app_session.dart';
import '../../../models/startup.dart';
import '../../../models/startup_enums.dart';
import '../../../models/team_member.dart';
import '../view_models/startup_steps_view_model.dart';
import '../../../shared_ui/widgets/forms/checkbox_card.dart';
import '../../../shared_ui/widgets/overlays/multi_picker_sheet.dart';
import '../../../app_constants/validation_strings.dart';
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

  /// Editing one Details section (kept for the caller; each section is now
  /// its own step, so [step] already says what to show).
  final int? section;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) => switch (step) {
        0 => _Basics(vm: vm),
        1 => _ProblemSolution(vm: vm),
        2 => _TargetMarket(vm: vm),
        3 => _Finance(vm: vm),
        4 => _Ask(vm: vm),
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
  String? info,
  String? hint,
}) => AppField(
  label: label,
  required: required,
  sentenceCase: true,
  info: info,
  hint: hint,
  error: vm.errorOf(field),
  child: MoneyField(
    controller: controller,
    hasError: vm.hasError(field),
    semanticLabel: label,
  ),
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
          max: Startup.problemMax,
          field: StartupField.problem,
          multiline: true,
          sentenceCase: true,
        ),
        _text(
          vm,
          label: FounderToolsStrings.solutionLabel,
          controller: vm.solution,
          hint: FounderToolsStrings.solutionHint,
          max: Startup.solutionMax,
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

/// Step 6, Finance and Growth: every answer is required, labels in sentence
/// case, money fields with the SAR prefix and automatic commas.
class _Finance extends StatelessWidget {
  const _Finance({required this.vm});

  final StartupStepsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return FormFieldColumn(
      children: [
        _money(
          vm,
          label: FounderToolsStrings.revenueNowLabel,
          controller: vm.revenueNow,
          field: StartupField.revenueNow,
          info: FounderToolsStrings.revenueNowInfo,
        ),
        _money(
          vm,
          label: FounderToolsStrings.capitalLabel,
          controller: vm.capital,
          field: StartupField.capital,
        ),
        _money(
          vm,
          label: FounderToolsStrings.burnLabel,
          controller: vm.burn,
          field: StartupField.burn,
          info: FounderToolsStrings.burnInfo,
          // Live while typing: "About 6 months of runway".
          hint: vm.runwayLine,
        ),
        _money(
          vm,
          label: FounderToolsStrings.valuationLabel,
          controller: vm.valuation,
          field: StartupField.valuation,
          info: FounderToolsStrings.valuationInfo,
        ),
        AppField(
          label: FounderToolsStrings.revenueLabel,
          required: true,
          sentenceCase: true,
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
        LabeledTextField(
          label: FounderToolsStrings.modelTextLabel,
          required: true,
          sentenceCase: true,
          controller: vm.modelText,
          placeholder: FounderToolsStrings.modelTextHint,
          maxLength: FounderToolsStrings.modelTextMax,
          multiline: true,
          info: FounderToolsStrings.modelTextInfo,
          error: vm.errorOf(StartupField.modelText),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- step 5

/// Step 7, Startup Ask: Funding / Partnership / Support, each with its own
/// questions shown only while its box is ticked.
class _Ask extends StatelessWidget {
  const _Ask({required this.vm});

  final StartupStepsViewModel vm;

  Future<void> _pickTypes(
    BuildContext context, {
    required String title,
    required List<String> options,
    required Set<String> picked,
    required void Function(String) onToggle,
    required TextEditingController other,
    required String noun,
  }) async {
    // The sheet reads (and the toggle updates) this local copy.
    final live = {...picked};
    await showMultiPickerSheet(
      context,
      title: title,
      options: options,
      selected: live,
      onToggle: (label) {
        if (!live.remove(label)) live.add(label);
        onToggle(label);
      },
      otherLabel: 'Other',
      otherNoun: noun,
      otherHint: 'Type your other $noun',
      otherText: other.text,
      onOtherChanged: (v) => other.text = v,
      onUndoOther: () {
        live.remove('Other');
        onToggle('Other');
      },
    );
  }

  String _shown(
    Set<String> picked,
    TextEditingController other,
    List<String> order,
  ) => [
    for (final o in order)
      if (picked.contains(o))
        if (o != 'Other')
          o
        else if (other.text.trim().isNotEmpty)
          'Other: ${other.text.trim()}',
  ].join(', ');

  /// One option: its checkbox card, then (while ticked) its own questions
  /// directly under it, indented with a moss line on the left. Unticking
  /// only hides them; what was typed is kept.
  Widget _section(
    BuildContext context, {
    required LookingFor item,
    required bool open,
    required List<Widget> fields,
  }) {
    final duration = Motion.reduced(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CheckboxCard(
          title: item.label,
          checked: vm.lookingFor.contains(item),
          onChanged: (_) => vm.toggleLookingFor(item.label),
        ),
        AnimatedSize(
          duration: duration,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: open
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding: const EdgeInsets.only(left: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.moss100, width: 2),
                      ),
                    ),
                    child: FormFieldColumn(
                      padding: EdgeInsets.zero,
                      children: fields,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // One list, in this order: each card is followed by its own questions.
    final sections = <Widget>[
      _section(
        context,
        item: LookingFor.funding,
        open: vm.wantsFunding,
        fields: [
          _money(
            vm,
            label: FounderToolsStrings.fundingLabel,
            controller: vm.funding,
            field: StartupField.funding,
            info: FounderToolsStrings.fundingInfo,
            hint: vm.fundingHint,
          ),
          _money(
            vm,
            label: FounderToolsStrings.raisedLabel,
            controller: vm.raised,
            field: StartupField.raised,
            info: FounderToolsStrings.raisedInfo,
          ),
          ChipGroupField(
            label: FounderToolsStrings.leadLabel,
            required: true,
            sentenceCase: true,
            info: FounderToolsStrings.leadInfo,
            options: const [FounderToolsStrings.yes, FounderToolsStrings.no],
            selected: [
              if (vm.wantsLead != null)
                vm.wantsLead!
                    ? FounderToolsStrings.yes
                    : FounderToolsStrings.no,
            ],
            onTap: (label) => vm.setLead(label == FounderToolsStrings.yes),
            error: vm.errorOf(StartupField.lead),
          ),
        ],
      ),
      _section(
        context,
        item: LookingFor.partnership,
        open: vm.wantsPartner,
        fields: [
          AppField(
            label: FounderToolsStrings.partnerLabel,
            required: true,
            sentenceCase: true,
            error: vm.errorOf(StartupField.partnerTypes),
            child: SelectField(
              placeholder: FounderToolsStrings.partnerPlaceholder,
              semanticLabel: FounderToolsStrings.partnerLabel,
              value: _shown(
                vm.partnerSel,
                vm.partnerOther,
                FounderToolsStrings.partnerOptions,
              ),
              hasError: vm.hasError(StartupField.partnerTypes),
              onTap: () => _pickTypes(
                context,
                title: FounderToolsStrings.partnerTitle,
                options: FounderToolsStrings.partnerOptions,
                picked: vm.partnerSel,
                onToggle: vm.togglePartner,
                other: vm.partnerOther,
                noun: 'partner type',
              ),
            ),
          ),
        ],
      ),
      _section(
        context,
        item: LookingFor.support,
        open: vm.wantsSupport,
        fields: [
          AppField(
            label: FounderToolsStrings.supportLabel,
            required: true,
            sentenceCase: true,
            error: vm.errorOf(StartupField.supportTypes),
            child: SelectField(
              placeholder: FounderToolsStrings.supportPlaceholder,
              semanticLabel: FounderToolsStrings.supportLabel,
              value: _shown(
                vm.supportSel,
                vm.supportOther,
                FounderToolsStrings.supportOptions,
              ),
              hasError: vm.hasError(StartupField.supportTypes),
              onTap: () => _pickTypes(
                context,
                title: FounderToolsStrings.supportTitle,
                options: FounderToolsStrings.supportOptions,
                picked: vm.supportSel,
                onToggle: vm.toggleSupport,
                other: vm.supportOther,
                noun: 'support type',
              ),
            ),
          ),
        ],
      ),
    ];
    return FormFieldColumn(
      children: [
        AppField(
          label: FounderToolsStrings.lookingForLabel,
          required: true,
          sentenceCase: true,
          subLabel: 'Select all that apply',
          error: vm.errorOf(StartupField.lookingFor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                sections[i],
              ],
            ],
          ),
        ),
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

  /// Saves the member in the open editor; asks before inviting somebody who
  /// is not on Start.sa yet.
  Future<void> _save(BuildContext context) async {
    var result = await vm.saveMember();
    if (!context.mounted) return;
    if (result == MemberSave.needsInvite) {
      final email = vm.memberEmail.text.trim().toLowerCase();
      final send = await showInviteDialog(context, email);
      if (!send || !context.mounted) return;
      result = await vm.saveMember(inviteConfirmed: true);
      if (!context.mounted) return;
    }
    if (result == MemberSave.invited) {
      AppToast.confirm(context, FounderToolsStrings.invitationSent);
    }
  }

  String _titleOf(TeamMember? member) {
    if (member == null) return FounderToolsStrings.newMember;
    if (_isMe(member)) return FounderToolsStrings.titleYourDetails;
    if (member.isFounder) return FounderToolsStrings.titleEditFounder;
    return FounderToolsStrings.editMember;
  }

  @override
  Widget build(BuildContext context) {
    final newOpen = vm.editorOpen && vm.editingIndex == null;
    return FormFieldColumn(
      children: [
        AppField(
          label: FounderToolsStrings.teamLabel,
          sentenceCase: true,
          subLabel: FounderToolsStrings.teamSub,
          info: FounderToolsStrings.teamInfo,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < vm.team.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                // The editor takes the place of the member's own card.
                if (vm.editorOpen && vm.editingIndex == i)
                  _editor(context, vm.team[i])
                else
                  TeamMemberRow(
                    member: vm.team[i],
                    isYou: _isMe(vm.team[i]),
                    error: vm.team[i].isFounder && vm.founderRowError
                        ? ValidationStrings.founderRowIncomplete
                        : null,
                    onEdit: () => vm.openMemberEditor(i),
                  ),
              ],
              // A new member's editor sits above the Add button; while any
              // editor is open the Add button is hidden.
              if (newOpen) ...[
                if (vm.team.isNotEmpty) const SizedBox(height: 10),
                _editor(context, null),
              ] else if (!vm.editorOpen) ...[
                if (vm.team.isNotEmpty) const SizedBox(height: 10),
                AddMemberButton(onTap: () => vm.openMemberEditor()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _editor(BuildContext context, TeamMember? member) {
    final locked = member != null && vm.isLockedMember(member);
    return TeamMemberEditor(
      title: _titleOf(member),
      editing: member != null,
      lockedIdentity: locked,
      name: vm.memberName,
      email: vm.memberEmail,
      role: vm.memberRole,
      contribution: vm.memberContribution,
      coFounder: vm.memberCoFounder,
      onCoFounder: vm.setMemberCoFounder,
      complete: vm.memberComplete,
      errorOf: vm.memberError,
      onCancel: vm.cancelMemberEditor,
      onSave: () => _save(context),
      onRemove: vm.removeMember,
    );
  }
}

/// The signed-in user's own team row (matched by their account).
bool _isMe(TeamMember m) {
  final user = AppSession.instance.user;
  if (user == null) return false;
  if (m.uid != null) return m.uid == user.uid;
  final me = user.fullName.trim().toLowerCase();
  return me.isNotEmpty && m.name.trim().toLowerCase() == me;
}
