/// User-facing text for the Services hub, startup management (My Startups,
/// Create/Edit, Profile) and the "coming soon" placeholders, in one place.
/// Wording follows Figma "V2 · 24 / 25 / 25b / 35" where it exists.
class StartupStrings {
  StartupStrings._();

  // Placeholders
  static const comingSoon = 'Coming in a later sprint';
  static const comingSoonBody =
      "We're still building this. Check back after the next update.";

  // Services (Figma "V2 · 35 · Services")
  static const servicesTitle = 'Services';
  static const tileMyStartups = 'My Startups';
  static const tileAssociations = 'Associations';
  static const tileCalculator = 'Calculator';
  static const tileAskGemini = 'Ask Gemini';
  static const tileDashboard = 'Dashboard';

  // My Startups (Figma "V2 · 24 · My Startups")
  static const myStartupsTitle = 'My Startups';
  static const filterAll = 'All';
  static const createNewStartup = 'Create new startup';
  static const emptyTitle = 'No startups yet';
  static const emptyBody =
      'Create a profile for your startup to start connecting with investors.';
  static const emptyButton = 'Add your first startup';
  static const noPublic = 'None of your startups are public yet.';
  static const noPrivate = 'None of your startups are private.';
  static const loadFailed = "We couldn't load your startups.";
  static const retry = 'Retry';
  static const publicBadge = 'Public';
  static const privateBadge = 'Private';

  // Create / Edit (Figma "V2 · 25 · Create Startup", "V2 · 25b · Edit Startup")
  static const addTitle = 'Create Startup';
  static const editTitle = 'Edit Startup';
  static const saveNew = 'Create startup';
  static const saveChanges = 'Save changes';
  static const saveDisabledHint = 'Fill in all required fields to continue.';
  static const noChangesHint = 'Make a change to save.';
  static const previewAsPublic = 'Preview as public';
  static const created = 'Startup created.';
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
  static const sectionBasics = 'BASICS';
  static const sectionDetails = 'DETAILS';
  static const sectionLookingFor = "WHAT YOU'RE LOOKING FOR";
  static const sectionVisibility = 'VISIBILITY';

  // Choosing from a list
  static String choose(String label) => 'Choose ${label.toLowerCase()}';
  static const done = 'Done';

  // Logo
  static const logoLabel = 'Logo';
  static const logoHint = 'Square image, up to 2 MB.';
  static const logoUpload = 'Upload logo';
  static const logoChange = 'Change logo';
  static const logoRemove = 'Remove';
  static const cropLogoTitle = 'Crop logo';
  static const logoTooLarge =
      'This image is larger than 2 MB after compression. Choose a smaller one.';
  static const logoPickFailed = "We couldn't open that image. Try another one.";

  // Fields
  static const nameLabel = 'Startup name';
  static const nameHint = 'e.g. Rafeeq Health';
  static const taglineLabel = 'One-liner description';
  static const taglineHint = 'One line that sums up what you do';
  static const descriptionLabel = 'Description';
  static const descriptionHint =
      'What problem do you solve, for whom, and how?';
  static const sectorLabel = 'Sector';
  static const stageLabel = 'Stage';
  static const businessModelLabel = 'Business model';
  static const locationLabel = 'City';
  static const foundedYearLabel = 'Founded year';
  static const foundedYearHint = 'e.g. 2023';
  static const websiteLabel = 'Website';
  static const websiteHint = 'e.g. rafeeqhealth.sa';
  static const lookingForLabel = 'Looking for';
  static const fundingLabel = 'Funding requirement (SAR)';
  static const fundingHint = 'e.g. 500000';
  static const fundingHelper = 'How much you are raising in this round.';
  static const sar = 'SAR';
  static String charCount(int count, int max) => '$count / $max';
  static String minChars(int min) => 'At least $min characters';

  // Validation
  static const nameRequired = 'Please enter your startup name.';
  static String nameLength(int min, int max) =>
      'Name must be $min to $max characters.';
  static String taglineTooLong(int max) =>
      'One-liner must be $max characters or fewer.';
  static const taglineOneLine = 'One-liner must fit on one line.';
  static const descriptionRequired = 'Please describe your startup.';
  static String descriptionTooShort(int min, int count) =>
      'Description needs at least $min characters ($count so far).';
  static String descriptionTooLong(int max) =>
      'Description must be $max characters or fewer.';
  static const sectorRequired = 'Choose a sector.';
  static const stageRequired = 'Choose a stage.';
  static const businessModelRequired = 'Choose a business model.';
  static const locationRequired = 'Choose a location.';
  static String foundedYearRange(int min, int max) =>
      'Enter a year between $min and $max.';
  static const websiteInvalid = 'Enter a valid web address, like example.com.';
  static const lookingForRequired = 'Choose at least one option.';
  static const fundingRequired = 'Enter the amount you are raising.';
  static const fundingInvalid = 'Enter an amount greater than zero.';

  // Visibility
  static const visibilitySwitch = 'Make this startup public';
  static const visibilityOn =
      'Your startup appears in the Startup Hub and can be found by investors '
      'and startup seekers.';
  static const visibilityOff =
      'Only you can see this startup. It will not appear anywhere in the app.';
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
  static String deleteBody(String name) =>
      '$name and its logo will be permanently deleted. This cannot be undone.';
  static const deleteConfirm = 'Delete';
  static String deleted(String name) => '$name was deleted.';
  static const deleteFailed = "We couldn't delete this startup.";
  static const dangerZone = 'DANGER ZONE';

  // Profile (preview)
  static const previewBanner = 'Preview: this is how others see your startup.';
  static const previewPrivateBanner =
      'This startup is private. Others will see this page once you make it '
      'public.';
  static const previewUnsavedBanner =
      'You have unsaved changes. This preview shows the last saved version.';
  static const aboutTitle = 'About';
  static const detailsTitle = 'At a glance';
  static const lookingForTitle = 'Looking for';
  static const fundingTitle = 'Raising';
  static const visitWebsite = 'Visit website';
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
