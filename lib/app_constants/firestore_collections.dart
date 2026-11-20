/// Firestore collection and field names, written once.
class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
  static const startups = 'startups';
  static const requests = 'requests';

  static const ticketRequests = 'ticketRequests';

  /// An investor's investment tickets (id = investorId-T1, ...).
  static const tickets = 'tickets';
  static const interests = 'interests';
  static const publicProfiles = 'publicProfiles';

  /// Investors (imported dataset and, later, public investor profiles).
  static const investors = 'investors';

  /// Team invitations (id = startupId~email): see InvitationFields.
  static const invitations = 'invitations';

  /// Names of the startups that invited an e-mail with no account yet.
  static const inviteEmails = 'inviteEmails';

  /// Finds an account by e-mail (id = the e-mail, lower-case).
  static const emailIndex = 'emailIndex';

  /// users/{uid}/bookmarks/{itemKey}
  static const bookmarks = 'bookmarks';

  static const notices = 'notices';
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

  static const isArchived = 'isArchived';
  static const sectorsOfInterest = 'sectorsOfInterest';

  static const preferredSectors = 'preferredSectors';
  static const preferredStages = 'preferredStages';
  static const ticketSize = 'ticketSize';

  // Added by the redesigned sign-up (docs/07).
  static const linkedin = 'linkedinUrl';

  static const valueOffered = 'offer';
  static const sectorsOther = 'sectorsOther';

  static const investorCriteria = 'investorCriteria';

  static const investmentsCount = 'investmentsCount';
  static const roundSizeMin = 'roundSizeMin';
  static const roundSizeMax = 'roundSizeMax';
  static const preferredCommerceModels = 'preferredCommerceModels';
  static const preferredCommerceModelsOther = 'preferredCommerceModelsOther';

  /// How long they have been investing (one of the years options).
  static const yearsInvesting = 'yearsInvesting';

  /// "What do you look for in a startup?" (a string).
  static const lookingFor = 'lookingFor';

  /// Investor headline, e.g.
  static const title = 'title';
}

/// Fields of a startups/{startupId} document.
class StartupFields {
  StartupFields._();

  static const founderId = 'founderId';
  static const name = 'name';
  static const description = 'description';
  static const sector = 'sector';
  static const sectorOther = 'sectorOther';

  static const otherSectors = 'otherSectors';
  static const stage = 'stage';
  static const commerceModel = 'commerceModel';
  static const commerceModelOther = 'commerceModelOther';
  static const location = 'location';
  static const foundedYear = 'foundedYear';
  static const websiteUrl = 'websiteUrl';
  static const lookingFor = 'lookingFor';
  static const fundingRequirement = 'fundingRequirement';
  static const isPublic = 'isPublic';

  static const logoData = 'logoData';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';

  // Added by the redesigned Add / Edit startup (docs/07).
  static const problem = 'problem';
  static const solution = 'solution';
  static const customers = 'targetCustomers';
  static const advantage = 'differentiation';
  static const marketSize = 'marketSize';
  static const team = 'teamMembers';
  static const capital = 'currentAvailableCapital';
  static const revenueYear1 = 'expectedRevenueYear1';
  static const revenueYear2 = 'expectedRevenueYear2';
  static const revenueYear3 = 'expectedRevenueYear3';
  static const valuation = 'valuation';

  // Finance and Growth / Startup Ask answers.
  static const revenueThisYear = 'revenueThisYear';
  static const monthlyBurn = 'monthlyBurnRate';
  static const revenueModel = 'revenueModel';
  static const raisedInRound = 'raisedInRound';
  static const partnerTypes = 'partnerTypes';
  static const supportTypes = 'supportTypes';

  /// The people of the startup other than the founder.
  static const memberIds = 'memberIds';
  static const memberRoles = 'memberRoles';

  static const coFounderIds = 'coFounderIds';

  /// active or closed.
  static const status = 'status';
  static const statusActive = 'active';
  static const statusClosed = 'closed';

  /// When the startup was closed (a timestamp).
  static const closedAt = 'closedAt';

  /// True only on the startups imported from the dataset (Crunchbase).
  static const isArchived = 'isArchived';
}

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

  /// True only on rounds imported from the dataset (Crunchbase).
  static const isArchived = 'isArchived';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';

  /// status values.
  static const active = 'active';
  static const completed = 'completed';
}

/// Fields of a requests/{id} document (investor -> startup).
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

/// Fields of an interests/{id} document (guest -> startup).
class InterestFields {
  InterestFields._();

  static const startupId = 'startupId';
  static const name = 'name';
  static const roleLine = 'roleLine';
  static const message = 'message';
  static const createdAt = 'createdAt';
  static const seenByFounder = 'seenByFounder';
}

/// Firebase Storage folders.
class StoragePaths {
  StoragePaths._();
}

class TicketFields {
  TicketFields._();

  static const investorId = 'investorId';
  static const name = 'name';
  static const sectors = 'sectors';
  static const stages = 'stages';
  static const amountMin = 'amountMin';
  static const amountMax = 'amountMax';

  /// open, closed or used.
  static const status = 'status';

  /// The startup the ticket was used for; null until then.
  static const startupId = 'startupId';
  static const createdAt = 'createdAt';

  static const open = 'open';
  static const closed = 'closed';
  static const used = 'used';

  /// Extra fields of a requests document sent through a ticket.
  static const ticketId = 'ticketId';
  static const startupName = 'startupName';
}
