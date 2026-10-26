/// Firestore collection and field names, written once.
class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
  static const startups = 'startups';
  static const requests = 'requests';
  static const interests = 'interests';
  static const publicProfiles = 'publicProfiles';

  /// Investors (imported dataset and, later, public investor profiles).
  /// Same field names as an investor's `users/{uid}` document.
  static const investors = 'investors';

  /// Team invitations (id = `startupId~email`): see [InvitationFields].
  static const invitations = 'invitations';

  /// Names of the startups that invited an e-mail with no account yet.
  static const inviteEmails = 'inviteEmails';

  /// Finds an account by e-mail (id = the e-mail, lower-case).
  static const emailIndex = 'emailIndex';

  /// `users/{uid}/bookmarks/{itemKey}`
  static const bookmarks = 'bookmarks';
}

class UserFields {
  UserFields._();

  static const role = 'role';
  static const fullName = 'fullName';
  static const email = 'email';
  static const createdAt = 'createdAt';

  // Added when a founder finishes onboarding.
  static const onboardingCompleted = 'onboardingCompleted';
  static const sector = 'sector';
  static const stage = 'stage';
  static const city = 'city';

  // Added when a user edits their account.
  static const bio = 'bio';
  static const phone = 'phone';

  /// Whether the profile shows the email / phone (private when missing).
  static const emailPublic = 'emailPublic';
  static const phonePublic = 'phonePublic';
  static const sectorsOfInterest = 'sectorsOfInterest';

  // Profile photo: download URL of `users/{uid}/profile.jpg` in Storage.
  static const photoUrl = 'photoUrl';

  // Added when an investor finishes onboarding (their investment criteria).
  static const preferredSectors = 'preferredSectors';
  static const preferredStages = 'preferredStages';
  static const ticketSize = 'ticketSize';

  // Added by the redesigned sign-up (docs/07).
  static const linkedin = 'linkedinUrl';

  /// Investor: "What I hope to gain from startups".
  static const gain = 'gain';

  /// Investor: "What I can bring to startups" (also the sign-up step 4
  /// "Besides funding, what can you offer startups?").
  static const valueOffered = 'offer';
  static const sectorsOther = 'sectorsOther';

  /// Older documents kept the investor questions in one map; new documents
  /// store them as the flat fields below (see InvestorCriteria).
  static const investorCriteria = 'investorCriteria';

  // Investor questions from sign-up steps 3 and 4, stored flat on the user
  // (same names as the `investors` collection).
  static const investmentsCount = 'investmentsCount';
  static const hasLedRound = 'hasLedRound';
  static const roundsLed = 'roundsLed';
  static const coInvest = 'coInvest';
  static const ticketSizeOther = 'ticketSizeOther';
  static const roundSizeMin = 'roundSizeMin';
  static const roundSizeMax = 'roundSizeMax';
  static const preferredStagesOther = 'preferredStagesOther';
  static const preferredCommerceModels = 'preferredCommerceModels';
  static const preferredCommerceModelsOther = 'preferredCommerceModelsOther';

  /// How long they have been investing (one of the years options).
  static const yearsInvesting = 'yearsInvesting';

  /// "What do you look for in a startup?" (a string).
  static const lookingFor = 'lookingFor';

  /// Investor headline, e.g. "Angel Investor" (set by the dataset).
  static const title = 'title';
}

/// Fields of a `startups/{startupId}` document. firestore.rules uses the same
/// names, so change both together.
class StartupFields {
  StartupFields._();

  static const founderId = 'founderId';
  static const name = 'name';
  static const tagline = 'oneLinePitch';
  static const description = 'description';
  static const sector = 'sector';
  static const sectorOther = 'sectorOther';
  static const stage = 'stage';
  static const stageOther = 'stageOther';
  static const businessModel = 'businessModel';
  static const businessModelOther = 'businessModelOther';
  static const lookingForOther = 'lookingForOther';
  static const location = 'location';
  static const foundedYear = 'foundedYear';
  static const websiteUrl = 'websiteUrl';
  static const lookingFor = 'lookingFor';
  static const fundingRequirement = 'fundingRequirement';
  static const isPublic = 'isPublic';
  static const logoUrl = 'logoUrl';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';

  // Added by the redesigned Add / Edit startup (docs/07).
  static const problem = 'problem';
  static const solution = 'solution';
  static const customers = 'targetCustomers';
  static const advantage = 'differentiation';
  static const tam = 'marketSizeTam';
  static const sam = 'marketSizeSam';
  static const som = 'marketSizeSom';
  static const team = 'teamMembers';
  static const growth = 'expectedGrowth';
  static const capital = 'currentAvailableCapital';
  static const revenueYear1 = 'expectedRevenueYear1';
  static const revenueYear2 = 'expectedRevenueYear2';
  static const revenueYear3 = 'expectedRevenueYear3';
  static const valuation = 'valuation';
  static const wantsLeadInvestor = 'wantsLeadInvestor';

  // Finance and Growth / Startup Ask answers.
  static const revenueThisYear = 'revenueThisYear';
  static const monthlyBurn = 'monthlyBurnRate';
  static const businessModelText = 'businessModelExplanation';
  static const raisedInRound = 'raisedInRound';
  static const partnerTypes = 'partnerTypes';
  static const supportTypes = 'supportTypes';

  /// The people of the startup other than the founder. Kept INSIDE the
  /// startup document: `memberIds` (for queries) and `memberRoles` (uid ->
  /// 'coFounder' or 'member'). Deleting the startup deletes every membership
  /// with it, and "Leave startup" removes only the user's own entry.
  static const memberIds = 'memberIds';
  static const memberRoles = 'memberRoles';
}

/// Fields of a `startups/{startupId}/fundingRounds/{roundId}` document (the
/// same names as the imported dataset and firestore.rules).
class FundingRoundFields {
  FundingRoundFields._();

  /// The subcollection of a startup that holds its rounds.
  static String collectionOf(String startupId) =>
      '${FirestoreCollections.startups}/$startupId/fundingRounds';

  static const startupId = 'startupId';
  static const number = 'number';
  static const status = 'status';
  static const stage = 'stage';
  static const stageOther = 'stageOther';
  static const amount = 'amount';
  static const raised = 'raised';
  static const startDate = 'startDate';
  static const endDate = 'endDate';
  static const investors = 'investors';
  static const investorIds = 'investorIds';
  static const investorCount = 'investorCount';
  static const wantsLeadInvestor = 'wantsLeadInvestor';
  static const isDataset = 'isDataset';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';

  /// [status] values.
  static const active = 'active';
  static const completed = 'completed';
}

/// Fields of a `requests/{id}` document (investor -> startup).
class RequestFields {
  RequestFields._();

  static const startupId = 'startupId';
  static const founderId = 'founderId';
  static const investorId = 'investorId';
  static const message = 'message';
  static const amount = 'amount';
  static const equity = 'equity';
  static const status = 'status';
  static const createdAt = 'createdAt';
}

/// Fields of an `interests/{id}` document (guest -> startup).
class InterestFields {
  InterestFields._();

  static const startupId = 'startupId';
  static const name = 'name';
  static const roleLine = 'roleLine';
  static const message = 'message';
  static const createdAt = 'createdAt';
  static const seenByFounder = 'seenByFounder';
}

/// Firebase Storage folders. storage.rules uses the same paths.
class StoragePaths {
  StoragePaths._();

  /// `startup_logos/{founderId}/{startupId}/{fileName}`
  static String startupLogo(
    String founderId,
    String startupId,
    String fileName,
  ) => 'startup_logos/$founderId/$startupId/$fileName';

  /// `users/{uid}/profile.jpg`
  static String userProfilePhoto(String uid) => 'users/$uid/profile.jpg';
}
