/// User-facing text for the Services hub, startup management (My Startups,
/// Create/Edit, Profile), in one place.
/// Wording follows Figma "V2 · 24 / 25 / 25b / 35" where it exists.
class StartupStrings {
  StartupStrings._();

  // Services (Figma "V2 · 35 · Services")
  static const servicesTitle = 'Services';
  static const tileMyStartups = 'My Startups';
  static const tileAssociations = 'Associations';
  static const tileCalculator = 'Calculator';
  static const tileAskGemini = 'Ask Gemini';
  static const tileDashboard = 'Dashboard';

  // My Startups (Figma "V2 · 44 / 44b · My Startups")
  static const myStartupsTitle = 'My Startups';
  static const addAction = 'Add';
  static String startupCount(int count) =>
      count == 1 ? '1 startup' : '$count startups';
  static const manage = 'Manage';
  static const moreOptions = 'More options';
  static String lookingForTag(String what) => 'Looking for: $what';
  static const emptyTitle = 'No startups yet';
  static const emptyButton = 'Add startup';
  static const loadFailed = "We couldn't load your startups.";
  static const retry = 'Retry';
  static const publicBadge = 'Public';
  static const privateBadge = 'Private';

  // Manage startup (Figma "V2 · 44c · Startup — Manage")
  static const editStartup = 'Edit startup';
  static const preview = 'Preview';
  static const activityTitle = 'Activity';
  static const activityPeriod = 'Last 7 days';
  static const activityViews = 'Views';
  static const activityBookmarks = 'Bookmarks';
  static const activityRequests = 'Requests';
  static const associationsTitle = 'Investment associations';
  static const associationApproved = 'Approved · Public';
  static const associationApprovedPrivate = 'Approved · Private';
  static const noAssociations = 'No investment associations yet';
  static const associationWaiting = 'Waiting for approval';
  static const addInvestor = 'Add investor';
  static const calculatorTitle = 'Fundraising calculator';
  static const calculatorSubtitle = 'Estimate valuation and equity';

  // Create / Edit (Figma "V2 · 25 · Create Startup", "V2 · 25b · Edit Startup")
  static const addTitle = 'Add startup';
  static const editTitle = 'Edit startup';
  static const saveNew = 'Create startup';
  static const saveChanges = 'Save';
  static const previewAsPublic = 'Preview as public';
  static String added(String name) => '$name was added';
  static const saved = 'Changes saved.';
  static const saveFailed = "We couldn't save your startup.";
  static const fixErrors = 'Please fix the highlighted fields.';
  static const requiredMark = ' *';
  static const optional = 'Optional';
  static const editPrivateBanner =
      'This startup is Private — only you can see it.';
  static const editPublicBanner =
      'This startup is Public — investors and startup seekers can find it.';

  // Field groups (small headings between fields)
  static const sectionVisibility = 'Visibility';

  // Choosing from a list
  static const selectSector = 'Select a sector';
  static const selectStage = 'Select a stage';
  static const selectBusinessModel = 'Select a commerce model';
  static const selectLocation = 'Select a city';
  static const done = 'Done';
  static const otherRequiredShort = 'Please type your choice.';
  static const otherSymbols = 'Use letters and numbers only, without symbols.';

  // "Other" in Sector, Stage and Commerce model: a text box appears
  static const sectorOtherLabel = 'Please specify your sector';
  static const sectorOtherHint = 'e.g. Biotech';
  static const stageOtherLabel = 'Please specify your stage';
  static const stageOtherHint = 'e.g. Bridge round';
  static const businessModelOtherLabel = 'Please specify your commerce model';
  static const lookingForOtherLabel = 'Please specify what you are looking for';
  static const lookingForOtherHint = 'e.g. Legal advice';
  static const lookingForOtherRequired =
      'Please specify what you are looking for.';
  static const businessModelOtherHint = 'e.g. Subscription box';

  // Logo
  static const logoLabel = 'Startup logo';
  static const logoHint = 'Square image, up to 2 MB.';
  static const logoUpload = 'Upload logo';
  static const logoChange = 'Change logo';
  static const logoRemove = 'Remove';
  static const cropLogoTitle = 'Crop logo';
  static const logoTooLarge = 'This logo is too large. Try another one.';
  static const logoPickFailed = "We couldn't open that image. Try another one.";

  // Fields
  static const nameLabel = 'Startup name';
  static const nameHint = 'e.g. Rafeeq Health';
  static const descriptionLabel = 'Description';
  static const descriptionHint = 'Describe your startup';
  static const sectorLabel = 'Sector';
  static const stageLabel = 'Stage';
  static const businessModelLabel = 'Commerce model';
  static const locationLabel = 'City';
  static const foundedYearLabel = 'Founded';
  static const foundedYearHint = 'e.g. 2024';
  static const websiteLabel = 'Website';
  static const websiteHint = 'e.g. rafeeqhealth.sa';
  static const lookingForLabel = 'What are you looking for?';
  static const fundingLabel = 'Funding amount';
  static const fundingHint = '0';
  static const sar = 'SAR';

  // Validation
  static const nameRequired = 'Please enter your startup name.';
  static String nameTooShort(int min) =>
      'Startup name must be at least $min characters.';
  static String nameTooLong(int max) =>
      'Startup name must be $max characters or fewer.';
  static const descriptionRequired = 'Please describe your startup.';
  static String descriptionTooShort(int min) =>
      'Description must be at least $min characters.';
  static String descriptionTooLong(int max) =>
      'Description must be $max characters or fewer.';
  static const sectorRequired = 'Please select a sector.';
  static const stageRequired = 'Please select a stage.';
  static const businessModelRequired = 'Please select a commerce model.';
  static const sectorOtherRequired = 'Please specify your sector.';
  static const stageOtherRequired = 'Please specify your stage.';
  static const businessModelOtherRequired =
      'Please specify your commerce model.';
  static String otherTooLong(int max) =>
      'This must be $max characters or fewer.';
  static const locationRequired = 'Please select a city.';
  static String foundedYearRange(int min, int max) =>
      'Enter a year between $min and $max.';
  static const websiteInvalid = 'Enter a valid web address, like example.com.';
  static const lookingForRequired = 'Select at least one option.';
  static const fundingRequired = 'Please enter the funding amount.';
  static const fundingInvalid = 'Enter an amount greater than zero.';

  // Visibility
  static const visibilitySwitch = 'Public';
  static const visibilityPrivateLabel = 'Private';
  static const visibilityOn =
      'Anyone can find this startup in the Hub, Explore, Trending, and '
      'Matches, and can send you requests.';
  static const visibilityOff =
      "Only you can see this startup. It won't appear in the Hub, Explore, "
      'Trending, or Matches, and no one can send you requests.';
  static const makePrivateTitle = 'Make this startup private?';
  static const makePrivateBody =
      'This will remove your startup from the Startup Hub. Investors will no '
      'longer be able to find it.';
  static const makePrivateConfirm = 'Make private';
  static const cancel = 'Cancel';

  // Unsaved changes
  static const discardTitle = 'Discard changes?';
  static const discardBody =
      "You have changes that haven't been saved. If you leave now, they will "
      'be lost.';
  static const discard = 'Discard';
  static const keepEditing = 'Keep editing';

  // Delete
  static const deleteButton = 'Delete startup';
  static const deleteHint =
      'Permanently removes this startup and its logo. This cannot be undone.';
  static String deleteTitle(String name) => 'Delete $name?';
  static const deleteBody =
      "This permanently removes the startup and its requests, associations, "
      "and expressions of interest. This can't be undone.";
  static const deleteConfirm = 'Delete startup';
  static String deleted(String name) => '$name was deleted.';
  static const deleteFailed = "We couldn't delete this startup.";
  static const dangerZone = 'DANGER ZONE';

  // Profile (Figma "V2 · 45 / 45b / 45c · Startup Profile")
  static const previewBanner = 'Preview — this is how others see your startup';
  static const previewPrivateBanner =
      'This startup is private. Others will see this page once you make it '
      'public.';
  static const previewUnsavedBanner =
      'You have unsaved changes. This preview shows the last saved version.';
  static const foundedBy = 'Founded by';
  static const aboutTitle = 'About';
  static const detailsTitle = 'Details';
  static const lookingForTitle = 'Looking for';
  static const raisingThisRound = 'raising this round';
  static const sendRequest = 'Send request';
  static const expressInterest = 'Express interest';
  static const share = 'Share';
  static const bookmark = 'Bookmark';
  static const close = 'Close';
  static const websiteOpenFailed = "We couldn't open the website.";
  static const notProvided = 'Not provided';

  // Errors
  static const networkError =
      'No internet connection. Check your connection and try again.';
  static const permissionError =
      "You don't have permission to do this. Try logging in again.";
  static const notFoundError =
      'This startup no longer exists. It may have been deleted.';
  static const genericError = 'Something went wrong. Please try again.';
}
