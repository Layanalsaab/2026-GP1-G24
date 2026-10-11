/// Labels for the bottom navigation bar and the side menu (Figma
/// "Nav · 3 tabs" and "V2 · 41 · Menu").
class NavigationStrings {
  NavigationStrings._();

  // Bottom bar
  static const supportSystems = 'Support Systems';
  static const hub = 'Hub';
  static const explore = 'Explore';

  // Side menu
  static const menuProfile = 'Profile';
  static const menuMyStartups = 'My Startups';
  static const menuInvestmentWallet = 'Investment Wallet';
  static const menuAssociations = 'Associations';
  static const menuMyRequests = 'My Requests';
  static const menuAskGemini = 'Ask Gemini';
  static const menuExpressionsOfInterest = 'Expressions of Interest';
  static const menuBookmarks = 'Bookmarks';
  static const menuNotifications = 'Notifications';
  static const menuSettings = 'Settings';
  static const menuLogOut = 'Log out';
  static const menuExit = 'Exit';
  static const guest = 'Guest';
  static const openMenu = 'Open menu';
  static const notificationsLabel = 'Notifications';

  static String startupCount(int n) => n == 1 ? 'Startup' : 'Startups';
}
