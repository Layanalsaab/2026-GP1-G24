class ProfileStrings {
  ProfileStrings._();

  static const previewBar = 'Preview · This is how others see your startup';
  static const previewBarPrivate =
      'Preview · Private, only your team can see it';
  static const about = 'About';
  static const team = 'Team';
  static const noTeamDetails = 'This startup hasn’t added team details yet.';
  static const associatedInvestors = 'Associated investors';
  static const raising = 'Raising';
  static const kvRaising = 'Raising';
  static const kvValuation = 'Valuation';
  static const kvCapital = 'Current capital';
  static const kvModel = 'Commerce model';
  static const sendRequest = 'Send investment request';
  static const requestSent = 'Request sent';
  static const expressInterest = 'Express interest';
  static const interestSent = 'Interest sent';

  static const interestedIn = 'Interested in';
  static const investmentSize = 'Investment Size';
  static const perFundingRound = 'Per funding round';
  static const offerTitle = 'What I can offer startups';
  static const lookingForTitle = 'What I’m looking for in startups';
  static const background = 'Investment Background';
  static const yearsOfInvesting = 'Years of investing';
  static const startupsInvested = 'Startups Invested';
  static const no = 'No';
  static const interests = 'Investment Interests';
  static const sectors = 'Sectors';

  // Investment tickets on a profile
  static const tickets = 'Investment Tickets';
  static const ticketStatus = 'Status';
  static const sendTicketRequest = 'Send request';
  static const chooseStartup = 'Choose your startup';
  static const requestAmount = 'Amount';
  static const noRaisingStartup =
      'You need a startup that is raising to send a request.';
  static const requestAlreadySent =
      'You already sent a request on this ticket with every startup that is raising.';
  static const sendRequestFailed = 'Couldn’t send the request. Try again.';
  static const ticketMinimum = 'Minimum';
  static const ticketMaximum = 'Maximum';
  static const ticketCreated = 'Created';
  static const done = 'Done';
  static const stages = 'Stages';
  static const commerceModels = 'Commerce Models';
  static const privateTag = 'Private';
  static const notAdded = 'Not added';
  static const associations = 'Investment Associations';
  static const linkedin = 'LinkedIn';
  static String associationCount(int n) =>
      n == 1 ? '1 Association' : '$n Associations';

  static const focusSectors = 'Focus sectors';
  static const details = 'Details';
  static const duration = 'Duration';
  static const runningSince = 'Running since';
  static const visitWebsite = 'Visit website';

  static const editProfile = 'Edit profile';
  static const myStartups = 'Startups';
  static const addStartup = '+ Add';
  static const noStartups = 'No startups yet.';

  static const founderInterests = 'Interests';
  static const contact = 'Contact Information';
  static const contactIntro =
      'Only the details marked Public are shown to others.';
  static const contactShown = 'Shown on your profile';

  /// "Private.
  static String contactPrivateNote(String noun) =>
      'Private. Only you can see your $noun';

  static String detailPrivate(String label) => '$label is private';
  static const email = 'Email';
  static const phone = 'Phone Number';
  static const contactPublic = 'Public';
  static const contactOnlyYou = 'Only you';

  static const save = 'Save';
  static const changePhoto = 'Change photo';
  static const bio = 'Bio';
  static const city = 'City';
  static const linkedinLabel = 'LinkedIn profile';
  static const selectCityTitle = 'Select your city';
  static const searchCities = 'Search cities';
  static const noCities = 'No cities found';

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

  static const shareTitle = 'Share';
  static const copyLink = 'Copy link';
  static const shareEmail = 'Email';
  static const shareMore = 'More';
  static const shareCantOpen = 'Couldn’t open that app.';
  static String shareMessage(String name, {String? kind}) => switch (kind) {
    'startup' =>
      'Look, I found $name on Start.sa. A startup I think you will like.',
    'investor' =>
      'Look, I found $name on Start.sa. An investor I think you should meet.',
    'program' =>
      'Look, I found $name on Start.sa. A support channel that might help you.',
    _ => 'Look, I found $name on Start.sa.',
  };
  static const shareMessagePlain = 'Look what I found on Start.sa.';

  /// The line before the link.
  static const shareTakeALook = 'Take a look:';

  /// The Email subject, and the greeting at the start of its body.
  static String shareEmailSubject(String? name) => (name ?? '').trim().isEmpty
      ? 'Look what I found on Start.sa'
      : 'Look what I found on Start.sa: ${name!.trim()}';
  static const shareEmailGreeting = 'Hi,';

  /// THE message a startup is shared with.
  static const startupShareTemplate =
      'Check out {name} on Start.sa, a {sector} startup from {city}! {link}';

  /// THE message an investor profile is shared with.
  static const investorShareTemplate =
      'Check out {name} on Start.sa, an investor from {city}! {link}';

  /// investorShareTemplate filled in.
  static String investorShare({
    required String name,
    required String city,
    required String link,
  }) {
    final c = city.trim();
    return investorShareTemplate
        .replaceAll(' from {city}', c.isEmpty ? '' : ' from $c')
        .replaceAll('{name}', name.trim())
        .replaceAll('{link}', link);
  }

  /// startupShareTemplate filled in.
  static String startupShare({
    required String name,
    required String sector,
    required String city,
    required String link,
  }) => startupShareTemplate
      .replaceAll('{name}', name.trim())
      .replaceAll('{sector}', sector.trim())
      .replaceAll('{city}', city.trim())
      .replaceAll('{link}', link);

  static const linkCopied = 'Link copied';
  static const profileSaved = 'Profile saved';
  static const changesSaved = 'Changes saved';
  static const fixFields = 'Please fix the highlighted fields';
  static const darkOn = 'Dark mode on';
  static const darkOff = 'Dark mode off';
  static String requestSentTo(String name) => 'Request sent to $name';

  static const changePasswordTitle = 'Change password';
  static const currentPassword = 'Current password';
  static const currentPasswordHint = 'Enter your current password';
  static const newPassword = 'New password';
  static const newPasswordHint = 'Enter a new password';
  static const confirmPassword = 'Confirm new password';
  static const confirmPasswordHint = 'Re-enter the new password';
  static const updatePassword = 'Update password';
  static const passwordUpdated = 'Your password has been updated.';

  static const deleteTitle = 'Delete your account?';
  static const deleteConfirm = 'Yes, delete my account';
  static const cancel = 'Cancel';
}
