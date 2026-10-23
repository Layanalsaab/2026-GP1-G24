/// User-facing copy of the founder tools (My Startups, the 4-step startup form,
/// Manage startup, Valuation calculator), word for word from
/// docs/05_screens.md section D, docs/06 section 8 and 9, and docs/07 section 5.
/// Curly quotes (’ “ ”) are part of the copy.
class FounderToolsStrings {
  FounderToolsStrings._();

  static const sar = 'SAR';

  // ---- My Startups ----
  static const myStartupsTitle = 'My Startups';
  static const addAction = 'Add';
  static String startupCount(int n) => n == 1 ? '1 startup' : '$n startups';
  static const manage = 'Manage';
  static const view = 'View';
  static const roleFounder = 'Founder';
  static const roleMember = 'Team member';
  static const allStartups = 'All startups';
  static const filterStartupsTitle = 'Filter startups';
  static const sortStartupsTitle = 'Sort startups';
  static const visibilityGroup = 'VISIBILITY';
  static const roleGroup = 'MY ROLE';
  static const optionAll = 'All';
  static const optionPublic = 'Public';
  static const optionPrivate = 'Private';
  static const done = 'Done';
  static String filtersCount(int n) => '$n filters';
  static const noMatchTitle = 'No startups match these filters.';
  static const showAllStartups = 'Show all startups';
  static const emptyTitle = 'Add your first startup';
  static const emptyMessage =
      'Create a profile so investors and seekers can find you. It takes about 5 minutes.';
  static const emptyButton = 'Add startup';
  static const publicPill = 'Public';
  static const privatePill = 'Private';
  static String raising(String amount) => 'Raising $amount';
  static String lookingForLine(String what) =>
      'Looking for ${what.toLowerCase()}';
  static const loadFailed = 'We couldn’t load your startups.';
  static const retry = 'Retry';

  // ---- Steps ----
  static const stepTitles = [
    'Overview',
    'Startup Description',
    'Target Market',
    'Funding & goals',
    'Startup Team',
  ];
  static const onboardingFirstTitle = 'Overview';
  static const next = 'Next';
  static const create = 'Create startup';
  static const saveChanges = 'Save changes';
  static String added(String name) => '$name was added';
  static const changesSaved = 'Changes saved';
  static String deleted(String name) => '$name was deleted';
  static const fillRequired = 'Please fix the highlighted fields';
  static const saveMemberFirst = 'Save or cancel the team member first';
  static const saveFailed = 'We couldn’t save your startup. Please try again.';
  static const logoTooLarge = 'That image is too large. Choose one under 2 MB.';
  static const logoFailed = 'We couldn’t use that image. Try another one.';

  // Step 1
  static const logoLabel = 'Startup logo';
  static const uploadLogo = 'Upload logo';
  static const changeLogo = 'Change logo';
  static const nameLabel = 'Startup name';
  static const nameHint = 'e.g. Rafeeq Health';
  static const descriptionLabel = 'Brief description';
  static const descriptionHint = 'Describe your startup';
  static const sectorLabel = 'Sector';
  static const sectorHint = 'Select a sector';
  static const sectorTitle = 'Select sector';
  static const sectorSearch = 'Search sectors';
  static const sectorNoResults = 'No sectors found';
  static const sectorNoun = 'sector';
  static const stageLabel = 'Stage';
  static const stageHint = 'Select a stage';
  static const stageTitle = 'Select stage';
  static const stageNoun = 'stage';
  static const modelLabel = 'Commerce model';
  static const modelHint = 'Select a commerce model';
  static const modelTitle = 'Select commerce model';
  static const modelNoun = 'commerce model';
  static const cityLabel = 'Headquarters';
  static const cityHint = 'Select a city';
  static const cityTitle = 'Select headquarters';
  static const citySearch = 'Search cities';
  static const cityNoResults = 'No cities found';
  static const foundedLabel = 'Founded year';
  static const foundedHint = 'e.g. 2024';
  static const websiteLabel = 'Website';
  static const websiteHint = 'e.g. example.com';

  // Step 2
  static const problemLabel = 'What problem does your startup solve?';
  static const problemHint = 'Describe the problem your customers face';
  static const solutionLabel = 'What is your solution?';
  static const solutionHint = 'Explain how your product solves it';
  static const customersLabel = 'Who are your target customers?';
  static const customersHint =
      'e.g. families caring for elderly parents in Riyadh';
  static const advantageLabel = 'What makes your startup unique?';
  static const advantageHint = 'What you do better or differently than others';

  // Step 3
  static const marketLabel = 'Target market size';
  static const marketInfo =
      'The total amount customers in your target market spend per year on products like yours. Enter it in SAR.';
  static const teamLabel = 'Team members';
  static const teamInfo =
      'Show that your team has the experience to run this project: relevant skills, past roles and results, and why you are the best team to build it.';
  static const addMember = 'Add team member';
  static const newMember = 'New team member';
  static const editMember = 'Edit team member';
  static const memberName = 'Full name';
  static const memberNameHint = 'e.g. Faisal Alkhaldi';
  static const memberRole = 'Role';
  static const memberRoleHint = 'e.g. CTO';
  static const memberSpec = 'Specialization';
  static const memberSpecHint = 'e.g. Mobile and cloud';
  static const memberYears = 'Years of experience';
  static const memberYearsHint = 'e.g. 10';
  static const memberBio = 'Short bio';
  static const memberBioHint = 'Relevant experience and past results';
  static const cancel = 'Cancel';
  static const addMemberButton = 'Add member';
  static const saveMemberButton = 'Save member';
  static const removeMember = 'Remove this member';
  static const editMemberLabel = 'Edit team member';

  // Step 4
  static const growthLabel = 'Expected growth';
  static const growthHint = 'How big can the company grow, and how fast?';
  static const capitalLabel = 'Current available capital';
  static const revenueLabel = 'Expected revenue, next 3 years';
  static const revenueHint = 'Amounts in SAR';
  static const valuationLabel = 'Current company valuation';
  static const leadLabel = 'Are you looking for a lead investor?';
  static const leadInfo =
      'A lead investor sets the terms of your round and brings other investors in.';
  static const fundingLabel = 'Funding amount';
  static const lookingForLabel = 'What are you looking for?';
  static const lookingForOtherHint = 'What else are you looking for?';
  static const visibilityLabel = 'Visibility';
  static const visibilityPublicTitle = 'Public';
  static const visibilityPublicText =
      'Anyone can find this startup in the Hub, Explore, Trending, and Matches, and can send you requests.';
  static const visibilityPrivateTitle = 'Private';
  static const visibilityPrivateText =
      'Only you can see this startup. It won’t appear in the Hub, Explore, Trending, or Matches.';
  static const yes = 'Yes';
  static const no = 'No';
  static const required = 'Required';

  // ---- Manage startup ----
  static const tabOverview = 'Overview';
  static const tabRequests = 'Requests';
  static const tabInterest = 'Interest';
  static const tabSettings = 'Settings';
  static const editStartup = 'Edit startup';
  static const preview = 'Preview';
  static const activity = 'Activity';
  static const activityEmpty =
      'Views, bookmarks and requests will show here once people discover your startup.';
  static const views = 'Views';
  static const bookmarks = 'Bookmarks';
  static const requests = 'Requests';
  static const associatedTitle = 'Associated investors';
  static const associatedEmpty =
      'Investors whose requests you accept appear here and on your profile.';
  static const shownOnProfile = 'Shown on profile';
  static const calcCardTitle = 'Valuation calculator';
  static const calcCardText =
      'See what your funding ask says your startup is worth';
  static const pending = 'Pending';
  static const accepted = 'Accepted';
  static const declined = 'Declined';
  static const offer = 'Offer';
  static const checkInCalculator = 'Check in calculator';
  static const decline = 'Decline';
  static const accept = 'Accept';
  static const acceptedPill = 'Accepted · now an associated investor';
  static const declinedPill = 'Declined';
  static String filterLabel(String label, int n) => '$label · $n';
  static String requestsEmpty(String status) => 'No $status requests.';
  static String acceptedToast(String name) =>
      '$name is now an associated investor';
  static const declinedToast = 'Request declined';
  static const interestNew = 'New';
  static const interestAll = 'All';
  static const interestEmpty = 'No new expressions of interest.';
  static const interestAllEmpty = 'No expressions of interest yet.';
  static const replyLabel = 'Reply';
  static const publicProfile = 'Public profile';
  static const publicProfileOn = 'Visible in Hub, Explore and Matches';
  static const publicProfileOff = 'Only you can see this startup';
  static const nowPublic = 'Startup is now public';
  static const nowPrivate = 'Startup is now private';
  static const deleteStartup = 'Delete startup';
  static const deleteStartupText = 'Removes the startup and all its requests';
  static String deleteTitle(String name) => 'Delete $name?';
  static const deleteMessage =
      'This permanently removes the startup and its requests, associations, and expressions of interest. This can’t be undone.';
  static const deleteFailed =
      'We couldn’t delete the startup. Please try again.';
  static const previewLabel = 'Preview';

  // ---- Valuation calculator ----
  static const calcTitle = 'Valuation calculator';
  static const thisRaise = 'THIS RAISE';
  static const fundingToRaise = 'Funding to raise';
  static const equityToGive = 'Equity to give up';
  static const currentOwnership = 'Your current ownership';
  static const postMoney = 'Post-money valuation';
  static const preMoney = 'Pre-money valuation';
  static const valueOfShare = 'Value of your share';
  static const fillAbove = 'Fill in the fields above';
  static const ownershipAfter = 'Ownership after this raise';
  static const youFounder = 'You (founder)';
  static const otherOwners = 'Other existing owners';
  static const newInvestors = 'New investors';
  static const equityGivenUp = 'Equity given up';
  static const calcNote =
      'This is the valuation your chosen terms imply, not a market valuation of your startup.';

  /// Info sheet copy by key (docs/07 section 5): key -> (title, text).
  static const calcInfo = <String, (String, String)>{
    'f': (
      'Funding to raise',
      'The total money you want investors to put into your startup in this raise.',
    ),
    'e': (
      'Equity to give up',
      'The share of your company the new investors will own in return for their money.',
    ),
    'o': (
      'Your current ownership',
      'How much of the company you own today, before this raise. If nobody else owns part of your startup yet, leave it at 100%.',
    ),
    'post': (
      'Post-money valuation',
      'What your whole company is worth right after the investment, including the new money. Funding ÷ equity.',
    ),
    'pre': (
      'Pre-money valuation',
      'What your company is worth just before the investment. Post-money valuation − funding.',
    ),
    'val': (
      'Value of your share',
      'What your share of the company is worth at this valuation.',
    ),
    'own': (
      'Ownership after this raise',
      'The new investors get the share you give up. Everyone who already owns part of the company keeps the same slice of the rest, so each of their shares gets a little smaller.',
    ),
  };

  // ---- Leaving the form / drafts ----
  static const discard = 'Discard';
  static const keepEditing = 'Keep editing';
  static const discardStartupTitle = 'Discard this startup?';
  static const discardStartupMessage =
      'If you go back now, the details you entered will be deleted.';
  static const discardEditTitle = 'Discard changes?';
  static const discardEditMessage =
      'If you go back now, your changes will be lost.';
  static const draftBadge = 'Draft';
  static const draftContinue = 'Continue editing';
  static const untitledStartup = 'Untitled startup';
  static const discardDraftTitle = 'Discard this draft?';
  static const discardDraftMessage =
      'The details you entered for this draft will be deleted.';
  static const draftDiscarded = 'Draft discarded';
}
