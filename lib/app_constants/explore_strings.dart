/// Text for Explore, Hub and the investor profile. Wording follows Figma
/// "V2 · 09b / 10 / 12 / 12b / 15".
class ExploreStrings {
  ExploreStrings._();

  // Explore
  static const exploreTitle = 'Explore';
  static const tabForYou = 'For You';
  static const tabTrending = 'Trending';
  static const tabMatches = 'Matches';
  static const askGemini = 'Ask Gemini';

  // Hub
  static const hubTitle = 'Hub';
  static const searchHint = 'Search startups, investors...';

  // Sector filters (Explore and Hub)
  static const filterAll = 'All';
  static const filters = [
    filterAll,
    'HealthTech',
    'Fintech',
    'EdTech',
    'Logistics',
  ];

  // Cards
  static const viewProfile = 'View Profile';
  static const sendRequest = 'Send Request';
  static String invests(String stageRange) => 'Invests: $stageRange';
  static String matchPercent(int percent) => '$percent% match';

  // Investor profile (Figma "V2 · 15")
  static const investorProfileTitle = 'Investor Profile';
  static const investmentPreferences = 'Investment Preferences';
  static const sectors = 'Sectors';
  static const stages = 'Stages';
  static const ticketSize = 'Ticket size';
  static const location = 'Location';
  static const sendInvestmentRequest = 'Send Investment Request';
  static const sendAssociationRequest = 'Send Association Request';
}
