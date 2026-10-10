/// User-facing text for the investor's investment criteria: the criteria card
/// on the Account tab and Edit criteria.
///
/// Sectors, stages and cities reuse the founder lists in AppStrings, so both
/// sides of a match always use the same values.
class InvestorStrings {
  InvestorStrings._();

  /// Stored exactly as written.
  static const ticketSizes = [
    '< SAR 100K',
    'SAR 100K–500K',
    'SAR 500K–2M',
    '> SAR 2M',
  ];

  // Questions (Edit criteria)
  static const sectorsTitle = 'What sectors interest you?';
  static const stagesTitle = 'What stages do you invest in?';
  static const ticketTitle = 'Typical ticket size?';
  static const chooseOneOrMore = 'Choose one or more.';
  static const chooseOne = 'Choose one.';

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
