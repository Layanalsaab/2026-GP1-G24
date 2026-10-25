/// Copy for the launch, intro, welcome, role, sign-up, verify, investor
/// onboarding, log-in and forgot-password screens, word for word from
/// docs/05_screens.md section A and docs/06 (curly quotes included).
class AuthStrings {
  AuthStrings._();

  // Brand
  static const appName = 'Start.sa';
  static const tagline = 'Connect. Invest. Grow.';

  // Intro
  static const skip = 'Skip';
  static const nextPage = 'Next';
  static const getStarted = 'Get started';
  static const intro1Headline = 'Where Saudi startups meet opportunity.';
  static const intro1Body =
      'One hub for founders, investors, and startup seekers.';
  static const intro2Kicker = 'SMART MATCHING';
  static const intro2Headline = 'Matched with the right partners.';
  static const intro2Body =
      'Discover startups and investors that fit your interests.';
  static const intro3Kicker = 'GROW FURTHER';
  static const intro3Headline = 'Programs, insights, and AI guidance.';
  static const intro3Body =
      'Accelerators and incubators directory, fundraising tools, and Ask Gemini for founders.';

  // Welcome
  static const welcomeLine1 = 'The Saudi startup and investment hub.';
  static const welcomeLine2 = 'Where founders, investors, and talent meet.';
  static const createAccount = 'Create account';
  static const logIn = 'Log in';
  static const continueAsGuest = 'Continue as guest';

  // Choose role
  static const chooseRoleTitle = 'Choose your role';
  static const founder = 'Founder';
  static const founderDescription =
      'Create and manage your startups, connect with investors, and access support programs.';
  static const investor = 'Investor';
  static const investorDescription =
      'Discover startups aligned with your investment interests and connect with founders.';
  static const continueLabel = 'Continue';
  static const haveAccount = 'Already have an account?';

  // Leaving sign-up step 1
  static const discardSignupTitle = 'Discard sign-up?';
  static const discardSignupMessage =
      'If you go back now, the details you entered will be deleted.';
  static const discard = 'Discard';

  // Step headers
  static const createAccountTitle = 'Create your account';
  static const verifyTitle = 'Verify your email';
  static const investmentsTitle = 'Investment Background';
  static const interestsTitle = 'Investment Interests';

  // Sign-up fields
  static const fullName = 'Full name';
  static const fullNamePlaceholder = 'e.g. Mohammed Ahmed';
  static const email = 'Email address';
  static const emailPlaceholder = 'e.g. example@gmail.com';
  static const phone = 'Phone number';
  static const phonePlaceholder = '5X XXX XXXX';
  static const phonePrefix = '+966';
  static const linkedin = 'LinkedIn profile';
  static const linkedinPlaceholder = 'linkedin.com/in/your-name';
  static const password = 'Password';
  static const passwordPlaceholder = 'e.g. Startup@123';
  static const confirmPassword = 'Confirm password';
  static const confirmPlaceholder = 'Re-enter your password';
  static const city = 'Which city are you in?';
  static const cityPlaceholder = 'Select your city';
  static const citySheetTitle = 'Select your city';
  static const citySearch = 'Search cities';
  static const citiesNone = 'No cities found';
  static const sectorsQuestion = 'Which sectors are you interested in?';
  static const sectorOtherHint = 'Type your sector, e.g. SportsTech';
  static const valueQuestion = 'What can you offer startups?';
  static const valuePlaceholder = 'Describe what you can offer';
  static const valueTip =
      'For example: funding, mentoring, industry connections, introductions to partners.';
  static const gainQuestion = 'What are you looking for in startups?';
  static const gainPlaceholder = 'Describe what you are looking for';
  static const gainTip =
      'For example: a strong team, early traction, a growing market, long-term partnerships.';
  static const bio = 'Bio';
  static const bioPlaceholder = 'Tell others a little about yourself';
  static const addPhoto = 'Add profile photo';
  static const profilePhoto = 'Profile photo';
  static const uploadPhoto = 'Upload photo';
  static const changePhoto = 'Change photo';
  static const sectorsPlaceholder = 'Select sectors';
  static const sectorsSheetTitle = 'Select sectors';
  static const sectorsSearch = 'Search sectors';
  static const sectorsNone = 'No sectors found';
  static const sectorsOtherEmpty =
      'Tell us your other sector — it can’t be blank.';
  static const bioRequiredLabel = 'Bio';
  static const photoAdded = 'Photo added';
  static const photoRemoved = 'Photo removed';

  // Verify
  static const verifyEmailSent = 'Verification email sent';
  static String verifyEmailSentTo(String email) =>
      'Verification email sent to $email';
  static const verifyDidntGet = 'Didn’t get the email?';
  static const resendEmail = 'Resend email';
  static const emailVerified = 'Email verified';
  static const alreadyVerifiedLogin =
      'Your email is already verified. You can log in.';
  static const alreadyVerified =
      'Your email is already verified. Tap Continue.';
  static const passwordPlaceholderLogin = 'Enter your password';

  // Investor step 3
  static const dealsQuestion = 'How many startups have you invested in so far?';
  static const dealsPlaceholder = 'Select a range';
  static const yearsQuestion = 'How many years have you been investing?';
  static const yearsSheetTitle = 'Years of investing';
  static const dealsSheetTitle = 'Startups invested in';
  static const roundSizeQuestion =
      'How much do you usually invest in one startup?';
  static const fillRequiredFields = 'Please fill in the required fields';
  static const ledQuestion = 'Have you ever led an investment round?';
  static const ledTip =
      'Leading means you set the terms and bring other investors in.';
  static const roundsLedQuestion = 'How many rounds have you led?';
  static const coInvestQuestion =
      'Are you open to investing alongside other investors?';
  static const ticketQuestion =
      'How much do you usually invest in one startup?';
  static const ticketOtherHint = 'Type an amount, e.g. SAR 50K';
  static const roundSizesQuestion = 'What round sizes do you like to join?';
  static const minimum = 'Minimum';
  static const maximum = 'Maximum';
  static const amountsInSar = 'Amounts in SAR';
  static const next = 'Next';
  static const finish = 'Finish';

  // Investor step 4
  static const investSectors = 'Which sectors are you interested in?';
  static const investStages = 'Which stages do you invest in?';
  static const stagesPlaceholder = 'Select stages';
  static const stagesSheetTitle = 'Select stages';
  static const modelsPlaceholder = 'Select commerce models';
  static const modelsSheetTitle = 'Select commerce models';
  static const stageOtherHint = 'Type your stage';
  static const investModels = 'Which commerce models do you invest in?';
  static const modelOtherHint = 'Type your commerce model';

  // Log in
  static const loginTitle = 'Welcome back';
  static const loginNoAccount = 'Don’t have an account?';
  static const signUp = 'Sign up';
  static const forgotLink = 'Forgot password?';
  static const incorrectCredentials = 'Incorrect email or password.';
  static String welcomeBack(String firstName) => 'Welcome back, $firstName';

  // Forgot password
  static const forgotTitle = 'Forgot password?';
  static const forgotIntro =
      'Enter the email address linked to your account and we’ll send you a link to reset your password.';
  static const forgotPlaceholder = 'name@example.com';
  static const sendResetLink = 'Send reset link';
  static String resetLinkSent(String email) => 'Reset link sent to $email';

  // Nouns for "Other" write-in errors
  static const nounSector = 'sector';
  static const nounStage = 'stage';
  static const nounModel = 'commerce model';
  static const nounAmount = 'amount';
}
