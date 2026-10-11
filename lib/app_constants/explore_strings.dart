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
  static const searchStartups = 'Search startups';
  static const searchInvestors = 'Search investors';
  static const matchesFor = 'Matches for';

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
  static const viewProfile = 'View profile';
  static const sendRequest = 'Send request';
  static const expressInterest = 'Express interest';
  static const viewDetails = 'View details';
  static const website = 'Website';
  static const stageLabel = 'Stage';
  static const sectorsLabel = 'Sectors';
  static const needsLabel = 'Needs';
  static const typeLabel = 'Type';
  static const focusLabel = 'Focus';
  static const basedOnCriteria = 'Based on your investment criteria';
  static const edit = 'Edit';
  static String invests(String stageRange) => 'Invests: $stageRange';
  static String matchPercent(int percent) => '$percent% match';

  // Investor profile (Figma "V2 · 15")
  static const investmentPreferences = 'Investment preferences';
  static const sectors = 'Sectors';
  static const stages = 'Stages';
  static const ticketSize = 'Ticket size';
  static const location = 'Location';
  static const locations = 'Locations';
  static const stage = 'Stage';
}
