import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../models/investor_criteria.dart';
import '../../../models/startup_enums.dart';
import '../../../shared_ui/widgets/chips/chip_group.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/forms/money_field.dart';
import '../../../shared_ui/widgets/forms/select_field.dart';
import '../../../shared_ui/widgets/overlays/multi_picker_sheet.dart';
import '../../../shared_ui/widgets/overlays/picker_sheet.dart';
import '../view_models/investor_onboarding_view_model.dart';

/// The investor questions, built once and used by the sign-up steps 3 and 4
/// and by Edit profile, so the labels, limits, errors and spacing can never
/// drift apart. Each method returns the fields to put in a `FormFieldColumn`.
class InvestorFields {
  const InvestorFields._();

  static String _short(String model) {
    for (final m in BusinessModel.values) {
      if (m.label == model) return m.shortLabel;
    }
    return model;
  }

  /// "Other" shown as what was typed (or "Other" while it is blank).
  static String _typed(String label, String typed) =>
      label == InvestorOnboardingViewModel.otherLabel && typed.trim().isNotEmpty
      ? typed.trim()
      : label;

  // ------------------------------------------------------- investment background

  /// Startups invested in, round size (hidden for "0") and "led a round".
  static List<Widget> background(
    BuildContext context,
    InvestorOnboardingViewModel vm,
  ) {
    Future<void> pickDeals() async {
      FocusScope.of(context).unfocus();
      final result = await showPickerSheet(
        context,
        title: AuthStrings.dealsSheetTitle,
        options: InvestorCriteria.dealsOptions,
        selected: vm.deals,
      );
      if (result != null) vm.pickDeals(result.value);
    }

    Future<void> pickYears() async {
      FocusScope.of(context).unfocus();
      final result = await showPickerSheet(
        context,
        title: AuthStrings.yearsSheetTitle,
        options: InvestorCriteria.yearsOptions,
        selected: vm.years,
      );
      if (result != null) vm.pickYears(result.value);
    }

    return [
      AppField(
        label: AuthStrings.yearsQuestion,
        required: true,
        error: vm.yearsError,
        child: SelectField(
          placeholder: AuthStrings.dealsPlaceholder,
          value: vm.years,
          semanticLabel: AuthStrings.yearsQuestion,
          hasError: vm.yearsError != null,
          onTap: pickYears,
        ),
      ),
      AppField(
        label: AuthStrings.dealsQuestion,
        required: true,
        error: vm.dealsError,
        child: SelectField(
          placeholder: AuthStrings.dealsPlaceholder,
          value: vm.deals,
          semanticLabel: AuthStrings.dealsQuestion,
          hasError: vm.dealsError != null,
          onTap: pickDeals,
        ),
      ),
      if (vm.showRoundSize)
        AppField(
          label: AuthStrings.roundSizeQuestion,
          required: true,
          error: vm.roundSizeError,
          child: TrioField(
            dense: false,
            entries: [
              TrioEntry(
                label: AuthStrings.minimum,
                controller: vm.roundSize.min,
                hasError: vm.minHasError,
              ),
              TrioEntry(
                label: AuthStrings.maximum,
                controller: vm.roundSize.max,
                hasError: vm.maxHasError,
              ),
            ],
          ),
        ),
      ChipGroupField(
        label: AuthStrings.ledQuestion,
        required: true,
        info: AuthStrings.ledTip,
        options: const ['Yes', 'No'],
        selected: vm.hasLedRound == null
            ? const []
            : [vm.hasLedRound! ? 'Yes' : 'No'],
        onTap: vm.pickLed,
        error: vm.ledError,
      ),
    ];
  }

  // --------------------------------------------------------- investment interests

  /// Sectors, stages and commerce models: three required multi-selects.
  static List<Widget> interests(
    BuildContext context,
    InvestorOnboardingViewModel vm,
  ) {
    Future<void> pickSectors() async {
      FocusScope.of(context).unfocus();
      await showMultiPickerSheet(
        context,
        title: AuthStrings.sectorsSheetTitle,
        options: InvestorOnboardingViewModel.sectorOptions,
        selected: vm.sectors,
        onToggle: vm.toggleSector,
        searchHint: AuthStrings.sectorsSearch,
        noResultsText: AuthStrings.sectorsNone,
        otherLabel: InvestorOnboardingViewModel.otherLabel,
        otherNoun: AuthStrings.nounSector,
        otherHint: AuthStrings.sectorOtherHint,
        otherText: vm.sectorsOther.text,
        onOtherChanged: (v) => vm.sectorsOther.text = v,
        onUndoOther: () =>
            vm.toggleSector(InvestorOnboardingViewModel.otherLabel),
      );
    }

    Future<void> pickStages() async {
      FocusScope.of(context).unfocus();
      await showMultiPickerSheet(
        context,
        title: AuthStrings.stagesSheetTitle,
        options: InvestorOnboardingViewModel.stageOptions,
        selected: vm.stages,
        onToggle: vm.toggleStage,
      );
    }

    Future<void> pickModels() async {
      FocusScope.of(context).unfocus();
      await showMultiPickerSheet(
        context,
        title: AuthStrings.modelsSheetTitle,
        options: InvestorOnboardingViewModel.modelOptions,
        selected: vm.models,
        onToggle: vm.toggleModel,
        otherLabel: InvestorOnboardingViewModel.otherLabel,
        otherNoun: AuthStrings.nounModel,
        otherHint: AuthStrings.modelOtherHint,
        otherText: vm.modelsOther.text,
        onOtherChanged: (v) => vm.modelsOther.text = v,
        onUndoOther: () =>
            vm.toggleModel(InvestorOnboardingViewModel.otherLabel),
      );
    }

    // The same dropdown as the founder sign-up: the choices as text, with
    // the "Select all that apply" line.

    return [
      AppField(
        label: AuthStrings.investSectors,
        required: true,
        error: vm.sectorsError ?? vm.sectorsOtherError,
        child: SelectField(
          placeholder: AuthStrings.sectorsPlaceholder,
          value: [
            for (final o in InvestorOnboardingViewModel.sectorOptions)
              if (vm.sectors.contains(o)) _typed(o, vm.sectorsOther.text),
          ].join(', '),
          semanticLabel: AuthStrings.investSectors,
          hasError: vm.sectorsError != null || vm.sectorsOtherError != null,
          onTap: pickSectors,
        ),
      ),
      AppField(
        label: AuthStrings.investStages,
        required: true,
        error: vm.stagesError,
        child: SelectField(
          placeholder: AuthStrings.stagesPlaceholder,
          value: [
            for (final o in InvestorOnboardingViewModel.stageOptions)
              if (vm.stages.contains(o)) o,
          ].join(', '),
          semanticLabel: AuthStrings.investStages,
          hasError: vm.stagesError != null,
          onTap: pickStages,
        ),
      ),
      AppField(
        label: AuthStrings.investModels,
        required: true,
        error: vm.modelsError ?? vm.modelsOtherError,
        child: SelectField(
          placeholder: AuthStrings.modelsPlaceholder,
          value: [
            for (final o in InvestorOnboardingViewModel.modelOptions)
              if (vm.models.contains(o))
                o == InvestorOnboardingViewModel.otherLabel
                    ? _typed(o, vm.modelsOther.text)
                    : _short(o),
          ].join(', '),
          semanticLabel: AuthStrings.investModels,
          hasError: vm.modelsError != null || vm.modelsOtherError != null,
          onTap: pickModels,
        ),
      ),
    ];
  }
}
