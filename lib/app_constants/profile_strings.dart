/// Copy of the profile screens (startup profile, investor profile, program
/// details, own profile, Edit profile, Settings), word for word from
/// docs/05_screens.md section C and docs/06 section 7.
class ProfileStrings {
  ProfileStrings._();

  // ---- Startup profile ----
  static const tabOverview = 'Overview';
  static const tabBusiness = 'Business';
  static const tabTeam = 'Team';
  static const tabFinancials = 'Financials';
  static const previewBar = 'Preview · This is how others see your startup';
  static const closePreview = 'Close preview';
  static const about = 'About';
  static const lookingFor = 'Looking for';
  static const theProblem = 'The problem';
  static const ourSolution = 'Our solution';
  static const targetCustomers = 'Target customers';
  static const different = 'What makes us different';
  static const marketSize = 'Market size';
  static const yearlyRevenue = 'Yearly revenue';
  static const expectedGrowth = 'Expected growth';
  static const noBusinessDetails =
      'This startup hasn’t added business details yet.';
  static const team = 'Team';
  static const foundedBy = 'Founded by';
  static const noTeamDetails = 'This startup hasn’t added team details yet.';
  static const associatedInvestors = 'Associated investors';
  static const fundingAndFinancials = 'Funding and financials';
  static const expectedRevenue = 'Expected revenue';
  static const sarPerYear = 'SAR per year';
  static const raising = 'Raising';
  static const kvRaising = 'Raising';
  static const kvLead = 'Lead investor';
  static const kvLeadYes = 'Looking for one';
  static const kvLeadNo = 'Not needed';
  static const kvValuation = 'Valuation';
  static const kvCapital = 'Current capital';
  static const kvFounded = 'Founded';
  static const kvModel = 'Commerce model';
  static const kvCity = 'City';
  static const sendRequest = 'Send investment request';
  static const requestSent = 'Request sent';
  static const expressInterest = 'Express interest';
  static const interestSent = 'Interest sent';

  // ---- Investor profile ----
  static const investsIn = 'Invests in';
  static const interestedIn = 'Interested in';
  static const canBring = 'What I can bring to startups';
  static const hopeToGain = 'What I hope to gain';
  static const investmentFocus = 'Investment focus';
  static const stages = 'Stages';
  static const ticketSize = 'Ticket size';
  static const associations = 'Investment associations';
  static const linkedin = 'LinkedIn';
  static String associationCount(int n) =>
      n == 1 ? '1 Association' : '$n Associations';

  // ---- Program details ----
  static const focusSectors = 'Focus sectors';
  static const details = 'Details';
  static const duration = 'Duration';
  static const runningSince = 'Running since';
  static const visitWebsite = 'Visit website';

  // ---- Own profile ----
  static const editProfile = 'Edit profile';
  static const myStartups = 'My startups';
  static const addStartup = '+ Add';
  static const noStartups = 'No startups yet.';
  static const contact = 'Contact';
  static const email = 'Email';
  static const phone = 'Phone';

  // ---- Edit profile ----
  static const save = 'Save';
  static const changePhoto = 'Change photo';
  static const fullName = 'Full name';
  static const bio = 'Bio';
  static const city = 'City';
  static const cityPlaceholder = 'Select your city';
  static const sectorsOfInterest = 'Sectors of interest';
  static const valueLabel = 'What value can you bring to startups?';
  static const valueTip =
      'For example: connections with venture capital firms, experience in real estate, mentoring founders, industry partnerships.';
  static const gainLabel = 'What do you hope to gain from startups?';
  static const gainHint =
      'For example: financial returns, early access to new technology, or a long-term role with founders';
  static const gainTip =
      'For example: strong returns, early access to new tech, growing your portfolio in a sector, long-term partnerships with founders.';
  static const emailLabel = 'Email address';
  static const phoneLabel = 'Phone number';
  static const linkedinLabel = 'LinkedIn profile';
  static const linkedinHint = 'linkedin.com/in/your-name';
  static const otherSectorHint = 'Type your sector, e.g. SportsTech';
  static const selectCityTitle = 'Select your city';
  static const searchCities = 'Search cities';
  static const noCities = 'No cities found';

  // ---- Settings ----
  static const settings = 'Settings';
  static const display = 'DISPLAY';
  static const notifications = 'NOTIFICATIONS';
  static const account = 'ACCOUNT';
  static const darkMode = 'Dark mode';
  static const darkModeHint = 'Use a dark theme across the app';
  static const notificationSettings = 'Notification settings';
  static const notificationSettingsHint =
      'Choose which notifications you receive';
  static const changePassword = 'Change password';
  static const deleteAccount = 'Delete account';
  static const deleteAccountHint = 'Permanently remove your account and data';

  // ---- Toasts ----
  static const linkCopied = 'Link copied';
  static const addedToBookmarks = 'Added to bookmarks';
  static const removedFromBookmarks = 'Removed from bookmarks';
  static const profileSaved = 'Profile saved';
  static const fixFields = 'Please fix the highlighted fields';
  static const darkOn = 'Dark mode on';
  static const darkOff = 'Dark mode off';
  static String requestSentTo(String name) => 'Request sent to $name';
  static String interestSentTo(String name) => 'Interest sent to $name';
  static String withdrawnFrom(String name) => 'Withdrawn from $name';

  // ---- Change password (not designed; the existing flow, restyled) ----
  static const changePasswordTitle = 'Change password';
  static const currentPassword = 'Current password';
  static const currentPasswordHint = 'Enter your current password';
  static const newPassword = 'New password';
  static const newPasswordHint = 'Enter a new password';
  static const confirmPassword = 'Confirm new password';
  static const confirmPasswordHint = 'Re-enter the new password';
  static const updatePassword = 'Update password';
  static const passwordUpdated = 'Your password has been updated.';

  // ---- Delete account ----
  static const deleteTitle = 'Delete your account?';
  static const deleteConfirm = 'Yes, delete my account';
  static const deletePasswordLabel = 'Enter your password to confirm';
  static const deletePasswordHint = 'Password';
  static const cancel = 'Cancel';
}
