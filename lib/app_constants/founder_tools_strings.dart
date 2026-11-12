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
    'Startup Overview',
    'Startup Description',
    'Target Market',
    'Finance and Growth',
    'Startup Team',
    'Startup Ask',
  ];
  static const onboardingFirstTitle = 'Startup Overview';
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
  static const logoTooLarge = 'This logo is too large. Try another one.';
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
  static const sectorHint = 'Select sectors';
  static const sectorTitle = 'Select sectors';
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
  static const advantageHint =
      'What you do better or differently than your competitors';

  // Step 3
  static const marketLabel = 'Target market size';
  static const marketInfo =
      'Your SAM (serviceable available market): the total amount the customers you can realistically reach spend per year on products like yours. Enter it in SAR.';
  static const teamLabel = 'Team members';
  static const teamSub = 'Including you as a founder';
  static const teamInfo =
      'Co-founders can edit this startup. Other members can only view it. Everyone you add by email gets linked to their Start.sa profile, or receives an invitation.';
  static const addMember = 'Add team member';
  static const teamFull = 'A team can have up to 20 people.';
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
      'How much more money you spend than you earn each month: your monthly costs minus your monthly revenue. Enter 0 if you earn more than you spend.';
  static const revenueLabel = 'Expected revenue, next 3 years (SAR)';
  static const valuationLabel = 'Current company valuation';
  static const valuationInfo =
      'What your whole company is worth today. If you’ve raised money before, use the valuation from that round.';
  static const modelTextLabel = 'Explain your revenue model';

  /// The title of the answer in Manage -> Details and on the startup page.
  static const revenueModelTitle = 'Revenue model';
  static const modelTextHint = 'Describe how your startup makes money';
  static const modelTextInfo =
      'Who pays you, how much they pay, and how often.';
  static const modelTextMax = 250;
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
    'Co-founder',
    'Distributor',
    'Technology developer',
    'Supplier',
    'Marketing specialist',
    'Legal and accounting',
    'Other',
  ];
  static const supportOptions = [
    'Mentorship',
    'Hiring',
    'Incubator',
    'Accelerator',
    'Support Studios',
    'Other',
  ];
  static const visibilityLabel = 'Visibility';
  static const visibilityPublicTitle = 'Public startup';
  static const visibilityPublicText =
      'Anyone on Start.sa can find this startup in the Hub and Explore.';
  static const visibilityPrivateTitle = 'Private startup';
  static const visibilityPrivateText =
      'Only your team can see this startup. It won’t appear in the Hub or Explore.';
  static const yes = 'Yes';
  static const no = 'No';
  static const required = 'Required';

  // ---- Manage startup ----
  static const tabDashboard = 'Dashboard';
  static const tabDetails = 'Details';
  static const tabRounds = 'Rounds';
  static const tabOverview = 'Overview';
  static const tabRequests = 'Requests';
  static const tabInterest = 'EOI';
  static const interestTitle = 'Expressions of interest';
  static const interestSubtitle = 'Guests who are interested in your startup';
  static const tabSettings = 'Settings';
  static const editStartup = 'Edit startup';
  static const preview = 'Preview';
  static const activity = 'Activity';
  static const activityEmpty =
      'Views, bookmarks and requests will show here once people discover your startup.';
  static const views = 'Views';
  static const bookmarks = 'Bookmarks';
  static const requests = 'Requests';
  static const associatedTitle = 'Associated Investors';
  static const raisingLabel = 'Raising';
  static const valuationTile = 'Valuation';
  static const notRaisingValue = 'Not raising';
  static const noOpenRound = 'No open round';
  static const valuationCurrent = 'Current';
  static const associatedEmptyMember = 'No associated investors yet.';
  static const associatedEmpty =
      'Investors whose requests you accept appear here and on your profile.';
  static const shownOnProfile = 'Shown on profile';
  static const calcCardTitle = 'Valuation Calculator';
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
  // Manage -> Settings shows the same two texts as the Startup Overview step.
  static const publicProfileOn = visibilityPublicText;
  static const publicProfileOff = visibilityPrivateText;
  static const nowPublic = 'Startup is now public';
  static const nowPrivate = 'Startup is now private';
  static const leaveStartup = 'Leave startup';
  static const leaveCoFounderText =
      'You’ll stop being a co-founder of this startup';
  static const leaveMemberText = 'You’ll be removed from this startup’s team';

  /// The owner: she names the next owner first.
  static const leaveOwnerText =
      'Choose who will take over as owner before you leave.';
  static String leaveTitle(String name) => 'Leave $name?';
  static const leaveMessageCoFounder =
      'You won’t be able to edit this startup anymore. The owner or a co-founder can add you again.';
  static const leaveMessageMember =
      'You’ll be removed from this startup’s team. The owner or a co-founder can add you again.';
  static const noPermissionAnymore =
      'You don’t have permission to edit this startup anymore.';
  static String leftToast(String name) => 'You left $name';
  static const leaveFailed =
      'We couldn’t remove you from the startup. Please try again.';

  static const previewLabel = 'Preview';

  // ---- Closing a startup (docs: Closing a Startup, Leaving and Deleting
  // an Account) ----
  static const roleOwner = 'Owner';
  static const closedPill = 'Closed';
  static const closeStartup = 'Close startup';
  static const closeStartupText =
      'Permanently closes the startup so it can no longer be edited, while your team keeps access.';
  static String closeTitle(String name) => 'Close $name?';

  /// The confirmation. [teamCount]: the people who joined (not the owner).
  static String closeMessage(String name, int teamCount) {
    final where = teamCount <= 0
        ? '$name will remain in your account as a closed startup.'
        : '$name will remain in your account and your team’s as a closed '
              'startup, and your team will be notified.';
    return 'This cannot be undone. $where It can no longer be edited or '
        'receive requests, and its open funding round will end. You can '
        'still choose whether it appears in the Hub.';
  }

  /// People invited who haven't joined: their invitations are cancelled.
  static String invitationsCancelled(List<String> names) {
    if (names.length == 1) {
      return 'The pending invitation to ${names.first} will be cancelled.';
    }
    final who =
        '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
    return 'The pending invitations to $who will be cancelled.';
  }

  static String closedToast(String name) => '$name is now closed.';
  static const closeFailed = 'We couldn’t close the startup. Please try again.';
  static const closedBannerTitle = 'Closed';
  static String closedBannerOwner(String? date) => date == null
      ? 'You closed this startup. It cannot be edited or reopened, but you can still choose whether it appears in the Hub.'
      : 'You closed this startup on $date. It cannot be edited or reopened, but you can still choose whether it appears in the Hub.';
  static String closedBannerTeam(String? date) => date == null
      ? 'This startup has been closed.'
      : 'This startup was closed on $date.';
  static const closedBannerPublic =
      'This startup has been closed and is no longer accepting requests.';

  /// The Public / Private switch of a closed startup (its owner only).
  static const closedPublicText = 'Shown in the Hub as a closed startup.';
  static const closedPrivateText = 'Visible only to its team.';
  static const noSettings = 'There is nothing to change here.';
  static const closedNoSettings =
      'This startup is closed, so there is nothing to change here.';

  // ---- The owner leaving: naming the next owner ----
  static const nextOwnerTitle = 'Choose the next owner';
  static String nextOwnerText(String name) =>
      'Select who will manage $name after you leave.';
  static String nextOwnerAlone(String name) =>
      'There is no one else on $name’s team.';
  static const inviteSomeoneNew = 'Invite someone new';
  static const inviteSomeoneNewText = 'Send an invitation by email';
  static String makeOwnerTitle(String person, String name) =>
      'Make $person the owner of $name?';
  static String makeOwnerMessage(String person, String name) =>
      '$person will become the owner of $name and will have full control of it, including its team, its visibility in the Hub and closing it. You will leave $name and will no longer be able to view or manage it. This cannot be undone.';
  static String makeOwnerConfirm(String person) => 'Make $person the owner';
  static String onlyStartupTitle(String name) => '$name is your only startup';
  static const onlyStartupText =
      'After leaving, you will need to add a new startup to continue using your founder account.';
  static String newOwnerToast(String person, String name) =>
      '$person is now the owner of $name.';
  static const handoverFailed =
      'We couldn’t hand over the startup. Please try again.';
  static const ownerEmailTitle = 'Invite a new owner';
  static const ownerEmailLabel = 'Email address';
  static const ownerEmailHint = 'name@example.com';
  static String inviteOwnerMessage(String name) =>
      'You will remain in control until the invitation is accepted. The new owner will then have full control of $name, and you will leave it.';
  static const sendInvitation = 'Send invitation';
  static String ownerInviteSent(String email) => 'Invitation sent to $email.';
  static const ownerInviteFailed =
      'We couldn’t send the invitation. Please try again.';
  static const ownerEmailInvalid = 'Enter a valid email address.';
  static const ownerEmailInvestor =
      'This email belongs to an investor account and cannot be the owner.';
  static const ownerEmailOnTeam =
      'This person is already on the team. Choose them from the list instead.';
  static const ownerEmailYou = 'This is your own email address.';
  static String ownerWaiting(String email, String name) =>
      'Waiting for $email to accept becoming the owner of $name.';
  static const cancelInvitation = 'Cancel invitation';

  // Resend, expiry and what happened to the email
  static const resendEmail = 'Resend email';
  static String ownerExpires(int? days) => switch (days) {
    null => 'The invitation expires after 30 days.',
    <= 0 => 'The invitation expires today.',
    1 => 'The invitation expires tomorrow.',
    final d => 'The invitation expires in $d days.',
  };
  static String ownerResendText(int? days) =>
      'Send the email again. ${ownerExpires(days)}';
  static const ownerInviteExpiredTitle = 'Invitation expired';
  static String ownerInviteExpiredText(String email) =>
      '$email didn’t answer within 30 days, so the invitation ended. You are still the owner. Choose "Leave startup" in Details to invite someone again.';
  static const ownerInviteSavedNoEmail =
      'The invitation is saved, but the email couldn’t be sent. The person will see it in the app when they log in. You can resend the email from Settings.';
  static String ownerEmailResent(String email) => 'Email sent again to $email.';
  static const ownerEmailTooSoon =
      'An email was sent less than an hour ago. Try again later.';
  static const ownerEmailResendFailed =
      'We couldn’t send the email. The invitation is still waiting in the app.';

  // The invitation page, when someone else is signed in
  static String inviteSignedInAs(String mine, String invited) =>
      'You’re signed in as $mine, but this invitation is for $invited.';
  static const inviteLogOutContinue = 'Log out and continue';
  static const inviteStayHere = 'Stay signed in';
  static const inviteInvestorAccount =
      'This email belongs to an investor account. An investor account can’t be part of a startup’s team.';
  static const inviteExpired = 'This invitation has expired.';
  static const cancelOwnerInviteTitle = 'Cancel the invitation?';
  static String cancelOwnerInviteMessage(String email, String name) =>
      '$email will no longer be able to take over $name. You will remain the owner.';
  static const keepInvitation = 'Keep invitation';
  static const ownerInviteCancelled = 'The invitation was cancelled.';
  static const ownerInviteCancelFailed =
      'We couldn’t cancel the invitation. Please try again.';

  // ---- One-time pop-ups (shown the next time the app opens) ----
  static String noticeClosedTitle(String name) => '$name has been closed';
  static const noticeClosedMessage =
      'It remains in your startups as a closed startup and can still be viewed.';
  static String noticeNewOwnerTitle(String name) =>
      'You are now the owner of $name';
  static const noticeNewOwnerMessage =
      'You can now manage its team, visibility and settings.';
  static String noticeOwnershipTitle(String name) =>
      'Ownership of $name has changed';
  static String noticeOwnershipMessage(String person, String name) =>
      '$person is now the owner of $name.';
  static const noticeDeclinedTitle = 'Invitation declined';
  static String noticeDeclinedMessage(String email, String name) =>
      '$email declined to become the owner of $name. You remain in control.';
  static String viewStartup(String name) => 'View $name';
  static const noticeOk = 'OK';

  static const lostStartupTitle = 'You no longer have a startup';
  static const lostStartupMessage = 'Add a new startup to continue.';

  // ---- Valuation calculator ----
  static const calcTitle = 'Valuation Calculator';
  static const thisRound = 'THIS ROUND';
  static const fundingToRaise = 'Funding to raise';
  static const equityToGive = 'Equity to give up';
  static const currentOwnership = 'Your current ownership';
  static const postMoney = 'Post-money valuation';
  static const preMoney = 'Pre-money valuation';
  static const valueOfShare = 'Value of your share';
  static const fillAbove = 'Fill in the fields above';
  static const ownershipAfter = 'Ownership after this round';
  static const youFounder = 'You (founder)';
  static const otherOwners = 'Other existing owners';
  static const newInvestors = 'New investors';
  static const equityGivenUp = 'Equity given up';
  static const yourDilution = 'Your dilution';
  // shown under the funding box
  static String calcRoundHint(int number, String type, String raised) =>
      'Round $number · $type · $raised raised so far';
  static const calcOwnershipHint =
      'You had earlier rounds or have co-founders, so you probably own less than 100%. Enter your share.';
  // under the green card when the terms don't match the startup's valuation
  static String calcValuationNote({
    required bool lower,
    required String valuation,
    required String funding,
    required String own,
    required String shown,
  }) =>
      '${lower ? 'Lower' : 'Higher'} than your valuation ($valuation). '
      'At your valuation, $funding would cost $own of your company, '
      'not $shown, so you\'d ${lower ? 'give away more' : 'keep more'}.';

  static const calcNote =
      'This is the valuation your chosen terms imply, not a market valuation of your startup.';

  /// Info sheet copy by key (docs/07 section 5): key -> (title, text).
  static const calcInfo = <String, (String, String)>{
    'f': (
      'Funding to raise',
      'The total money you want investors to put into your startup in this round. It starts at your open round’s amount; change it to test another amount or an investor’s offer.',
    ),
    'e': (
      'Equity to give up',
      'The share of your company the new investors will own in return for their money. It starts at what your round costs at your current company valuation and follows the funding you type; type an investor’s offer here to test it.',
    ),
    'o': (
      'Your current ownership',
      'How much of the company you own today, before this round. It starts at 100% when you have no co-founders and no earlier rounds. Investors in this round are not counted here: they are the new investors.',
    ),
    'post': (
      'Post-money valuation',
      'What your whole company is worth right after the investment, including the new money. Funding ÷ equity.',
    ),
    'pre': (
      'Pre-money valuation',
      'What your company is worth just before the investment. Post-money valuation − funding. If it’s different from your current valuation, a note under the result shows what the same money would cost at your own valuation.',
    ),
    'val': (
      'Value of your share',
      'What your share of the company is worth at this valuation.',
    ),
    'change': ('Your dilution', 'How much your ownership drops in this round.'),
    'own': (
      'Ownership after this round',
      'The new investors get the share you give up. Everyone who already owns part of the company keeps the same slice of the rest, so each of their shares gets a little smaller.',
    ),
  };

  // ---- Confirm before saving ----
  static const saveConfirmTitle = 'Save changes?';
  static const saveConfirmButton = 'Save changes';
  static const saveProfileMessage =
      'Your changes will be saved to your profile.';
  static const saveStartupMessage =
      'Your changes will be saved to this startup.';
  static const saveRoundMessage = 'Your changes will be saved to this round.';
  static const addRoundTitle = 'Add round?';
  static const addRoundMessage = 'This round will be added to your startup.';
  static const addRoundButton = 'Add round';
  static const roundUpdated = 'Round updated';

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
