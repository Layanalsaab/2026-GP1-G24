/// User-facing text for the Services hub, startup management (My Startups,
/// Create/Edit, Profile), in one place.
/// Wording follows Figma "V2 · 24 / 25 / 25b / 35" where it exists.
class StartupStrings {
  StartupStrings._();

  static String added(String name) => '$name was added';
  static const saved = 'Changes saved.';

  static const cropLogoTitle = 'Crop logo';

  static const sar = 'SAR';

  static String deleted(String name) => '$name was deleted.';

  // Errors
  static const networkError =
      'No internet connection. Check your connection and try again.';
  static const permissionError =
      "You don't have permission to do this. Try logging in again.";
  static const notFoundError =
      'This startup no longer exists. It may have been deleted.';
  static const genericError = 'Something went wrong. Please try again.';
}
