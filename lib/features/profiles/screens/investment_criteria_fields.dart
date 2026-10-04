import 'package:flutter/material.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/investor_strings.dart';
import '../../../shared_ui/common_widgets/selection_chip.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/investment_criteria_form.dart';

/// The sectors, stages and ticket size questions, shared by the investor
/// onboarding and Edit criteria so both always look and behave the same.
/// [sectorsHeading] goes above the sector chips (each screen words it
/// differently).
class InvestmentCriteriaFields extends StatelessWidget {
  const InvestmentCriteriaFields({
    super.key,
    required this.form,
    required this.sectorsHeading,
  });

  final InvestmentCriteriaForm form;
  final Widget sectorsHeading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectorsHeading,
        const SizedBox(height: 20),
        ChoiceChips(
          options: AppStrings.sectors,
          isSelected: form.sectors.contains,
          onTap: form.toggleSector,
        ),
        const SizedBox(height: 24),
        const CriteriaSectionTitle(
          title: InvestorStrings.stagesTitle,
          hint: InvestorStrings.chooseOneOrMore,
        ),
        const SizedBox(height: 16),
        ChoiceChips(
          options: AppStrings.stages,
          isSelected: form.stages.contains,
          onTap: form.toggleStage,
        ),
        const SizedBox(height: 24),
        const CriteriaSectionTitle(
          title: InvestorStrings.ticketTitle,
          hint: InvestorStrings.chooseOne,
        ),
        const SizedBox(height: 16),
        ChoiceChips(
          options: InvestorStrings.ticketSizes,
          isSelected: (option) => option == form.ticketSize,
          onTap: form.selectTicketSize,
        ),
      ],
    );
  }
}

/// A question title with a short grey hint under it.
class CriteriaSectionTitle extends StatelessWidget {
  const CriteriaSectionTitle({
    super.key,
    required this.title,
    required this.hint,
  });

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppText.sans(
            size: 16,
            color: AppColors.ink,
            weight: FontWeight.w600,
            height: 24,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          hint,
          style: AppText.sans(size: 13, color: AppColors.grey, height: 18),
        ),
      ],
    );
  }
}

/// Person 1's selection chips laid out in rows. Works for one choice or
/// several: [isSelected] says which are on, [onTap] changes them.
class ChoiceChips extends StatelessWidget {
  const ChoiceChips({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onTap,
  });

  final List<String> options;
  final bool Function(String option) isSelected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final option in options)
            // Lets screen readers hear the chip as a button and whether it's
            // chosen.
            MergeSemantics(
              child: Semantics(
                button: true,
                selected: isSelected(option),
                child: SelectionChip(
                  label: option,
                  selected: isSelected(option),
                  onTap: () => onTap(option),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
