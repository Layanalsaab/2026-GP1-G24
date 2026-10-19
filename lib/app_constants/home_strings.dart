/// Copy of the home shell: Hub, Explore, Support Channels, the side menu and
/// the toasts (docs/05 section B and E).
class HomeStrings {
  HomeStrings._();

  // Titles
  static const hubTitle = 'Hub';
  static const exploreTitle = 'Explore';
  static const supportTitle = 'Support Channels';
  static const menuLabel = 'Open menu, 4 new notifications';

  // Switch
  static const startups = 'Startups';
  static const investors = 'Investors';
  static const switchLabels = [startups, investors];

  // Sections
  static const newOnStartSa = 'New on Start.sa';
  static const recommended = 'Recommended for you';
  static const top30 = 'Top 30 trending';
  static const results = 'Results';
  static const forYouBack = 'For You';
  static const seeAll = 'See all';
  static const matchesFor = 'Matches for';

  // Toasts
  static const linkCopied = 'Link copied';
  static const bookmarkAdded = 'Added to bookmarks';
  static const bookmarkRemoved = 'Removed from bookmarks';
  static String opensInFullApp(String item) => '$item opens in the full app';

  // Menu
  static const myStartups = 'My Startups';
  static const bookmarks = 'Bookmarks';
  static const askGemini = 'Ask Gemini';
  static const notifications = 'Notifications';
  static const settings = 'Settings';
  static const wallet = 'Investment Wallet';
  static const founderRole = 'Founder';
  static const investorRole = 'Investor';
  static const notificationCount = 4;

  // Counts
  static String resultCount(int n) => '$n ${n == 1 ? 'result' : 'results'}';
  static String matchCount(int n) => '$n ${n == 1 ? 'match' : 'matches'}';

  // Trending ranges (label, note tail) come from TrendingRange.
  static String kicker(int rank, String tag) => '$rank · Trending in $tag';
}
