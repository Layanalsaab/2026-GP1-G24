/// User-facing text for the authentication flow, in one place.
class AppStrings {
  AppStrings._();

  // Common
  static const genericError = 'Something went wrong. Please try again.';
  static const networkError =
      'No internet connection. Check your connection and try again.';
  static const tooManyRequests =
      'Too many attempts. Please wait a moment and try again.';

  static const resendTooMany =
      'Too many attempts. Please wait a few minutes and try again.';

  static const phoneCountryCode = '+966';
  static const otherSector = 'Other';

  static const emailInUse = 'An account with this email already exists.';
  static const weakPassword = 'Choose a stronger password.';
  static const profileSaveFailed =
      "We couldn't finish creating your account. Please try again.";

  static const profileMissing =
      "We couldn't find your account details. Please contact support.";

  /// The full city list of the Create Account city picker (Figma "City
  /// dropdown"), in alphabetical order.
  static const allCities = [
    'Abha',
    'Al Ahsa',
    'Al Baha',
    'Al Jubail',
    'Al Kharj',
    'Al Khobar',
    'Al Qatif',
    'Arar',
    'Buraydah',
    'Dammam',
    'Dhahran',
    'Hafar Al Batin',
    'Hail',
    'Jazan',
    'Jeddah',
    'Khamis Mushait',
    'Makkah',
    'Madinah',
    'Najran',
    'Riyadh',
    'Sakaka',
    'Tabuk',
  ];
}
