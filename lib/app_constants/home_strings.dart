class HomeStrings {
  HomeStrings._();

  // Titles
  static const hubTitle = 'Start.sa Hub';
  static const exploreTitle = 'Explore';
  static const supportTitle = 'Support Channels';
  static const menuLabel = 'Open menu, 4 new notifications';

  // Switch
  static const startups = 'Startups';
  static const investors = 'Investors';
  static const switchLabels = [startups, investors];

  static const recommendedStartups = 'Recommended startups for you';
  static const recommendedInvestors = 'Recommended investors for you';
  static const forYouInfoInvestor =
      'Based on your sectors, stages, commerce models, how much you invest, your open tickets and what startups are raising. The more startups you bookmark, the more it follows your taste.';
  static const forYouInfoFounder =
      'Based on your startup’s sector, stage, commerce model, what you are raising and investors’ open tickets. The more investors you bookmark, the more it follows your taste.';
  static const newestStartups = 'Newest startups';
  static const noNewStartupsTitle = 'No new startups';
  static const noNewStartupsMessage =
      'No startups joined in this time range. Try a longer one.';
  static const top30 = 'Top 30 trending';
  static const results = 'Results';

  static const bookmarkRemoved = 'Removed from bookmarks';

  // Long lists are shown a page at a time
  static String showMore(int left) => 'Show more ($left more)';

  // Empty lists
  static String noResultsTitle(String query) => 'No results for “$query”';
  static const loadFailedTitle = 'Couldn’t load the list';
  static const loadFailedMessage = 'Check your connection and try again.';
  static const retry = 'Try again';
  static const noSupportTitle = 'No support channels yet';
  static const noSupportMessage =
      'Support channels are not available yet. Check back soon.';
  static const sortTitle = 'Sort by';
  static const sortNewest = 'Newest';
  static const sortOldest = 'Oldest';
  static const sortNameAZ = 'Name A–Z';
  static const sortNameZA = 'Name Z–A';
  static const nothingYetTitle = 'Nothing here yet';
  static const nothingYetMessage =
      'New startups and investors will appear here.';

  // Log out confirmation
  static const logOutTitle = 'Log out?';
  static const logOutMessage = 'Are you sure you want to log out?';
  static const logOut = 'Log out';
  static const cancel = 'Cancel';

  // Menu
  static const myStartups = 'My Startups';
  static const bookmarks = 'Bookmarks';
  static const askGemini = 'Ask Gemini';
  static const notifications = 'Notifications';
  static const settings = 'Settings';
  static const wallet = 'Investment Wallet';
  static const founderRole = 'Founder';
  static const investorRole = 'Angel Investor';

  // Bookmarks screen
  static const bookmarksTitle = 'Bookmarks';
  static const filterByTypeTitle = 'Filter by type';
  static const sortBookmarksTitle = sortTitle;
  static const allTypes = 'All types';
  static const typeStartups = 'Startups';
  static const typeInvestors = 'Investors';
  static const typePrograms = 'Support Channels';
  static const noBookmarksTitle = 'No bookmarks yet';
  static const noBookmarksMessage =
      'Tap the bookmark icon on any startup, investor or support channel to save it here.';
  static const explore = 'Explore';
  static String noSavedOfType(String plural) => 'No saved $plural yet.';
  static const showAllBookmarks = 'Show all bookmarks';

  // Counts
  static String resultCount(int n) => '$n ${n == 1 ? 'result' : 'results'}';
  static String matchCount(int n) => '$n ${n == 1 ? 'match' : 'matches'}';
}
