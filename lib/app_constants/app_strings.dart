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
  static const confirmPasswordLabel = 'Confirm password';

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
  static const confirmPasswordRequired = 'Please confirm your password.';
  static const passwordsDontMatch = "Passwords don't match.";

  // Sign up
  static const signupTitle = 'Set up your account';
  static String signupSubtitle(String role) =>
      'You selected $role. Enter your details below.';
  static const signupButton = 'Create account';
  static const signupHaveAccount = 'Already have an account? Log in';
  static const emailInUse = 'An account with this email already exists.';
  static const weakPassword = 'Choose a stronger password.';
  static const profileSaveFailed =
      "We couldn't finish creating your account. Please try again.";

  // Check your email
  static const checkEmailTitle = 'Check your email';
  static String checkEmailBody(String email) =>
      'We sent a verification link to $email. Open it to activate your account, then log in.';
  static const checkEmailSendFailed =
      "We couldn't send the verification email. Tap “Resend verification email” to try again.";
  static const resendVerification = 'Resend verification email';
  static const verificationSent = 'Verification email sent. Check your inbox.';
  static const alreadyVerified = 'Your email is already verified. You can log in.';
  static const backToLogin = 'Back to log in';

  // Log in
  static const loginTitle = 'Welcome back';
  static const loginSubtitle = 'Log in to continue where you left off.';
  static const loginButton = 'Log in';
  static const loginNoAccount = "Don't have an account? Sign up";
  static const forgotPasswordLink = 'Forgot password?';
  static const incorrectCredentials = 'Incorrect email or password.';
  static const verifyEmailFirst = 'Please verify your email before logging in.';
  static const profileMissing =
      "We couldn't find your account details. Please contact support.";

  // Forgot password
  static const forgotTitle = 'Forgot your password?';
  static const forgotSubtitle =
      "Enter your email address and we'll send you a link to reset your password.";
  static const forgotButton = 'Send reset link';
  static const resetLinkMessage =
      'If an account exists for this email, a reset link has been sent.';

  // Founder onboarding
  static const onboardingSectorTitle = 'What sector is your startup in?';
  static const onboardingSectorHint =
      'This helps us match you with the right investors.';
  static const onboardingStageTitle = 'What stage are you at?';
  static const onboardingCityTitle = 'Where are you based?';
  static const onboardingContinue = 'Continue';
  static const onboardingIncomplete =
      'Please choose a sector, a stage, and a city.';
  static const onboardingSaveFailed =
      "We couldn't save your answers. Please try again.";
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

  // Home placeholders
  static String welcomeUser(String name) => 'Welcome, $name';
  static const founderHomeTitle = 'Founder home';
  static const investorHomeTitle = 'Investor home';
  static const comingSoon = 'This screen is coming soon.';
  static const logOut = 'Log out';
}
