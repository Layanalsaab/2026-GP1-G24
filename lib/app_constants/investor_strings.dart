/// User-facing text for the investor's investment criteria: the investor
/// onboarding, the criteria card on the Account tab and Edit criteria.
///
/// Sectors, stages and cities reuse the founder lists in AppStrings, so both
/// sides of a match always use the same values.
class InvestorStrings {
  InvestorStrings._();

  /// Figma "V2 · 07 · Onboarding — Investor". Stored exactly as written.
  static const ticketSizes = [
    '< SAR 100K',
    'SAR 100K–500K',
    'SAR 500K–2M',
    '> SAR 2M',
  ];

  // Questions (onboarding and Edit criteria)
  static const sectorsTitle = 'What sectors interest you?';
  static const stagesTitle = 'What stages do you invest in?';
  static const ticketTitle = 'Typical ticket size?';
  static const chooseOneOrMore = 'Choose one or more.';
  static const chooseOne = 'Choose one.';

  // Onboarding
  static const onboardingHint =
      'Choose one or more. This helps us match you with the right startups.';
  static const onboardingIncomplete =
      'Please choose at least one sector and one stage, a ticket size, '
      'and a city.';

  // Account tab card
  static const criteriaTitle = 'Investment criteria';
  static const edit = 'Edit';
  static const sectorsLabel = 'Sectors';
  static const stagesLabel = 'Stages';
  static const ticketLabel = 'Ticket size';
  static const notSetYet = 'Not set yet';

  // Edit criteria
  static const editCriteriaTitle = 'Investment criteria';
  static const editCriteriaIntro =
      'These criteria are used to match you with startups.';
  static const saveCriteria = 'Save criteria';
  static const criteriaIncomplete =
      'Please choose at least one sector and one stage, and a ticket size.';
  static const criteriaSaved = 'Your investment criteria have been saved.';
}
