import '../models/app_user.dart';

/// User-facing text for the authentication flow, in one place.
class AppStrings {
  AppStrings._();

  static String roleName(AccountRole role) => switch (role) {
        AccountRole.founder => 'Founder',
        AccountRole.investor => 'Investor',
      };

  // Common
  static const genericError = 'Something went wrong. Please try again.';
  static const networkError =
      'No internet connection. Check your connection and try again.';
  static const tooManyRequests =
      'Too many attempts. Please wait a moment and try again.';

  // Field labels and hints
  static const fullNameLabel = 'Full name';
  static const fullNameHint = 'e.g. Mohammed Ahmed';
  static const emailLabel = 'Email address';
  static const emailHint = 'e.g. example@gmail.com';
  static const passwordLabel = 'Password';
  static const passwordHint = 'e.g. 12345678'; // matches the Figma placeholder
  static const loginPasswordHint = 'Enter your password';
  static const confirmPasswordLabel = 'Confirm password';
  static const confirmPasswordHint = 'Re-enter your password';
  static const phoneLabel = 'Phone number';
  static const phoneHint = '5X XXX XXXX';
  static const phoneCountryCode = '+966';
  static const cityLabel = 'Which city are you in?';
  static const cityHint = 'Select your city';
  static const citySheetTitle = 'Select your city';
  static const citySearchHint = 'Search cities';
  static const cityNoResults = 'No cities found';
  static const sectorsLabel = 'Which sectors are you interested in?';
  static const sectorsHint = 'Select all that apply';
  static const otherSector = 'Other';
  static const otherSectorHint = 'Type a sector';
  static const bioLabel = 'Bio';
  static const bioHint = 'Tell others a little about yourself';
  static const optionalSuffix = '(optional)';
  static String sectorsSelected(int count) => '$count selected';

  // Validation
  static const fullNameRequired = 'Please enter your full name.';
  static const emailRequired = 'Please enter your email address.';
  static const emailInvalid = 'Enter a valid email address, like name@example.com.';
  static const passwordRequired = 'Please enter a password.';
  static const passwordTooShort = 'Password must be at least 8 characters.';
  static const passwordNeedsUppercase =
      'Password must include an uppercase letter.';
  static const passwordNeedsLowercase =
      'Password must include a lowercase letter.';
  static const passwordNeedsNumber = 'Password must include a number.';
  static const passwordNeedsSpecial =
      'Password must include a special character.';
  static const fullNameTooShort = 'Your name must be at least 2 characters.';
  static const fullNameLettersOnly =
      'Use letters only, without numbers or symbols.';
  static const phoneRequired = 'Please enter your phone number.';
  static const phoneInvalid =
      'Enter a 9-digit Saudi mobile number starting with 5.';
  static const cityRequired = 'Please select your city.';
  static const sectorsRequired = 'Select at least one sector.';

  // Live rule checklists shown under a field while the user types.
  static const ruleNameLength = 'At least 2 characters';
  static const ruleNameLetters = 'Letters only (no numbers or symbols)';
  static const ruleEmailAt = 'Contains @ with a name before it';
  static const ruleEmailDomain = 'A domain like example.com';
  static const rulePhoneDigits = '9 digits';
  static const rulePhoneStart = 'Starts with 5';
  static const rulePasswordLength = 'At least 8 characters';
  static const rulePasswordUpper = 'One uppercase letter';
  static const rulePasswordLower = 'One lowercase letter';
  static const rulePasswordNumber = 'One number';
  static const rulePasswordSpecial = 'One special character (! @ # \$)';
  static const ruleConfirmMatches = 'Matches your password';
  static const loginEmailInvalid = 'Enter a valid email address';
  static const loginPasswordRequired = 'Enter your password';
  static const confirmPasswordRequired = 'Please confirm your password.';
  static const passwordsDontMatch = "Passwords don't match.";

  // Sign up
  static const signupTitle = 'Set up your account';
  static const signupButton = 'Create account';
  static const signupHaveAccount = 'Already have an account?';
  static const emailInUse = 'An account with this email already exists.';
  static const weakPassword = 'Choose a stronger password.';
  static const profileSaveFailed =
      "We couldn't finish creating your account. Please try again.";

  // "Verify your email" pop-up on the Log in screen
  static const verifyEmailTitle = 'Verify your email';
  static const verifyEmailBodyBefore = 'We sent a verification link to ';
  static const verifyEmailBodyAfter =
      '. Open the link to activate your account, then log in.';
  // Same pop-up, shown again when the user tries to log in before verifying.
  static const verifyEmailReminderTitle = 'Email not verified';
  static const verifyEmailReminderBodyBefore =
      "Your email isn't verified yet. Please open the verification link we sent to ";
  static const verifyEmailReminderBodyAfter =
      ', then try logging in again.';
  static const verifyEmailSpamHint =
      "Can't find it? Check your spam or junk folder.";
  static const verifyEmailOk = 'OK';
  static const checkEmailSendFailed =
      "We couldn't send the verification email. Tap “Resend verification email” to try again.";
  static const resendVerification = 'Resend verification email';
  static const verificationSent = 'Verification email sent. Check your inbox.';
  static const alreadyVerified = 'Your email is already verified. You can log in.';

  // Log in
  static const loginTitle = 'Welcome back';
  static const loginButton = 'Log in';
  static const loginNoAccount = "Don't have an account?";
  static const signupLink = 'Sign up';
  static const forgotPasswordLink = 'Forgot password?';
  static const incorrectCredentials = 'Incorrect email or password.';
  static const profileMissing =
      "We couldn't find your account details. Please contact support.";

  // Forgot password
  static const forgotTitle = 'Forgot password?';
  static const forgotSubtitle =
      "Enter the email address linked to your account and we'll send you a link to reset your password.";
  static const forgotButton = 'Send reset link';
  static const forgotEmailHint = 'name@example.com';
  static const resetLinkMessage =
      'If an account exists for this email, a reset link has been sent.';

  static const sectors = [
    'HealthTech',
    'Fintech',
    'EdTech',
    'E-commerce',
    'Logistics',
    'AgriTech',
    'PropTech',
    'CleanTech',
  ];
  static const stages = ['Idea', 'Pre-seed', 'Seed', 'Series A'];
  static const cities = ['Riyadh', 'Jeddah', 'Dammam', 'Khobar', 'Other'];

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
    'Taif',
    'Unaizah',
    'Yanbu',
  ];

  // Home placeholders
  static String welcomeUser(String name) => 'Welcome, $name';
  static const founderHomeTitle = 'Founder home';
  static const investorHomeTitle = 'Investor home';
  static const comingSoon = 'This screen is coming soon.';
  static const logOut = 'Log out';
}
