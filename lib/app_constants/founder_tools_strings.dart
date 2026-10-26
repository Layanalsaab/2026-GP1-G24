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
  static const roleCoFounder = 'Co-founder';
  static const roleMember = 'Team member';
  static const notRaising = 'Not raising right now';
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
    'Finance and Growth',
    'Startup Ask',
    'Startup Team',
  ];
  static const onboardingFirstTitle = 'Overview';
  static const next = 'Next';
  static const create = 'Create startup';
  static const saveChanges = 'Save changes';
  static const save = 'Save';
  static const editSectionLabel = 'Edit startup';
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
  static const teamSub = 'Including you as a founder';
  static const teamInfo =
      'Co-founders can edit this startup. Other members can only view it. Everyone you add by email gets linked to their Start.sa profile, or receives an invitation.';
  static const addMember = 'Add team member';
  static const newMember = 'New team member';
  static const editMember = 'Edit team member';
  static const memberName = 'Full name';
  static const memberNameHint = 'e.g. Faisal Alkhaldi';
  static const memberEmail = 'Email';
  static const memberEmailHint = 'e.g. name@example.com';
  static const memberRole = 'Role';
  static const memberRoleHint = 'e.g. CTO';
  static const memberContribution = 'Contribution';
  static const memberContributionInfo =
      'What does this person bring to the startup? For example, their experience, skills or connections.';
  static const coFounderTitle = 'Co-founder';
  static const coFounderText =
      'Co-founders can edit this startup. Other members can only view it.';
  static const tagMember = 'Member';
  static const addYourRole = 'Add your role';
  static const titleYourDetails = 'Your details';
  static const titleEditFounder = 'Edit founder';
  static const memberContributionHint =
      'Experience, skills or connections they bring';
  static String editMemberOf(String name) => 'Edit $name';
  static const inviteTitle = 'This person isn’t on Start.sa yet';
  static String inviteMessage(String email) =>
      'We’ll email $email an invitation to join and see this startup. Do you want to continue?';
  static const sendInvite = 'Send invite';
  static const invitationSent = 'Invitation sent';
  static const invitationQueued = 'Invitation will be sent when you save';
  static String invitationsSent(int n) =>
      n == 1 ? 'Invitation sent' : '$n invitations sent';
  static String invitesFailed(int n) => n == 1
      ? 'Saved, but the invitation email wasn’t sent. Save again to try again.'
      : 'Saved, but $n invitation emails weren’t sent. Save again to try again.';
  static const invitesOffline =
      'No internet connection. Save again when you’re back online to send the invitation.';
  static const invitesLimit =
      'We’ve reached today’s invitation limit. Save again tomorrow to send it.';
  static const inviteJoinFailed =
      'We couldn’t join the team. Please try again.';
  static const tagDeclined = 'Declined';
  static const cancel = 'Cancel';
  static const addMemberButton = 'Add member';
  static const saveMemberButton = 'Save';
  static const removeMember = 'Remove this member';
  static const editMemberLabel = 'Edit team member';

  // Step 4
  static const growthLabel = 'Expected growth';
  static const revenueNowLabel = 'Current financial year revenue';
  static const revenueNowInfo =
      'The money your startup has earned so far this financial year. Enter 0 if you haven’t made any sales yet.';
  static const capitalLabel = 'Current available capital';
  static const burnLabel = 'Monthly burn rate';
  static const burnInfo =
      'How much money you lose each month: your monthly costs minus your monthly revenue. Enter 0 if you earn more than you spend.';
  static const revenueLabel = 'Expected revenue, next 3 years (SAR)';
  static const valuationLabel = 'Current company valuation';
  static const valuationInfo =
      'What your whole company is worth today. If you’ve raised money before, use the valuation from that round.';
  static const modelTextLabel = 'Explain your business model';
  static const modelTextHint = 'Describe how your startup makes money';
  static const modelTextInfo =
      'How your startup makes money. For example: who pays you, what you charge, and how often.';
  static const modelTextMax = 250;
  static const leadLabel = 'Are you looking for a lead investor?';
  static const leadInfo =
      'A lead investor sets the terms of your round and brings other investors in.';
  static const fundingLabel = 'How much are you raising?';
  static const fundingInfo =
      'The total amount you want to raise in this funding round.';
  static const raisedLabel = 'How much have you already raised in this round?';
  static const raisedInfo =
      'The amount investors have already committed to this round. Enter 0 if you haven’t raised anything yet.';
  static const lookingForLabel = 'What are you looking for?';
  static const lookingForOtherHint = 'What else are you looking for?';
  static const partnerLabel = 'What type of partner do you need?';
  static const supportLabel = 'What type of support do you need?';
  static const partnerPlaceholder = 'Select partner types';
  static const supportPlaceholder = 'Select support types';
  static const partnerTitle = 'Select partner types';
  static const supportTitle = 'Select support types';
  static const partnerOptions = [
    'Distribution',
    'Technology',
    'Supplier',
    'Marketing',
    'Government',
    'Corporate',
    'Other',
  ];
  static const supportOptions = [
    'Mentorship',
    'Advisors',
    'Co-founder',
    'Hiring',
    'Marketing',
    'Tech development',
    'Legal and accounting',
    'Other',
  ];
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
  static const tabDashboard = 'Dashboard';
  static const tabDetails = 'Details';
  static const tabRounds = 'Rounds';
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
  static const raisingLabel = 'Raising';
  static const valuationTile = 'Valuation';
  static const notRaisingValue = 'Not raising';
  static const noOpenRound = 'No open round';
  static const valuationCurrent = 'Current';
  static const associatedEmptyMember = 'No associated investors yet.';
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
  static const publicProfileOff = 'Only your team can see this startup';
  static const nowPublic = 'Startup is now public';
  static const nowPrivate = 'Startup is now private';
  static const deleteStartup = 'Delete startup';
  static const leaveStartup = 'Leave startup';
  static const leaveCoFounderText =
      'You’ll stop being a co-founder of this startup';
  static const leaveMemberText = 'You’ll be removed from this startup’s team';
  static String leaveTitle(String name) => 'Leave $name?';
  static const leaveMessage =
      'You won’t be able to see or manage this startup any more. The founder can add you again.';
  static const leaveMessageCoFounder =
      'You won’t be able to edit this startup anymore. A founder or co-founder can add you again.';
  static const leaveMessageMember =
      'You’ll be removed from this startup’s team. A founder or co-founder can add you again.';
  static const noPermissionAnymore =
      'You don’t have permission to edit this startup anymore.';
  static String leftToast(String name) => 'You left $name';
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
