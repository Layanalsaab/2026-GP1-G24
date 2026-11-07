/// Every word of the Investment Wallet (investor only).
///
/// Buttons, field labels and confirm titles are sentence case; screen titles
/// and menu names are Title Case.
class WalletStrings {
  WalletStrings._();

  // Screen and tabs
  static const title = 'Investment Wallet';
  static const tabTickets = 'Tickets';
  static const tabRequests = 'Requests';

  // Tickets tab
  static const ticketsHeading = 'Investment tickets';
  static const allAmounts = 'All amounts in SAR';
  static const addTicket = 'Add ticket';
  static const tapHint = 'Tap a ticket to see its details.';
  static const noTickets =
      'No tickets yet. Add one to see startups that fit what you want to invest in.';
  static const colTicket = 'Ticket';
  static const colAmount = 'Amount';
  static const colMatches = 'Matches';
  static const loading = 'Loading tickets…';
  static const loadFailed = 'Couldn’t load your tickets. Check your connection.';
  static const tryAgain = 'Try again';

  // Form
  static const newTicket = 'New ticket';
  static const editTicket = 'Edit ticket';
  static const nameLabel = 'Ticket name';
  static const sectorsLabel = 'Sectors';
  static const sectorsPlaceholder = 'Select sectors';
  static const stagesLabel = 'Stages';
  static const stagesPlaceholder = 'Select stages';
  static const minLabel = 'Minimum amount';
  static const maxLabel = 'Maximum amount';
  static const cancel = 'Cancel';
  static const saveChanges = 'Save changes';

  // Confirms
  static const addTitle = 'Add ticket?';
  static const addMessage = 'This ticket will be added to your wallet.';
  static const saveTitle = 'Save changes?';
  static const saveMessage = 'Your changes will be saved to this ticket.';
  static const discardTitle = 'Discard changes?';
  static const discardMessage = 'If you go back now, your changes will be lost.';
  static const discard = 'Discard';
  static const keepEditing = 'Keep editing';
  static const closeTicket = 'Close ticket';
  static String closeTitle(String name) => 'Close $name?';
  static const closeMessage =
      'This ticket won’t match any round anymore. You can’t use it after closing it.';
  static const sendTitle = 'Send request?';
  static String sendMessage(String startup, String amount) =>
      '$startup will see your request for $amount.';
  static const sendRequest = 'Send request';
  static const withdrawTitle = 'Withdraw request?';
  static String withdrawMessage(String startup) =>
      '$startup will no longer see this request.';
  static const withdraw = 'Withdraw';

  // Toasts
  static const ticketAdded = 'Ticket added';
  static const ticketSaved = 'Ticket saved';
  static const ticketClosed = 'Ticket closed';
  static const requestWithdrawn = 'Request withdrawn';
  static String requestSent(String startup) => 'Request sent to $startup';

  // Errors (never a technical message)
  static const saveFailed = 'Couldn’t save the ticket. Try again.';
  static const sendFailed = 'Couldn’t send the request. Try again.';
  static const withdrawFailed = 'Couldn’t withdraw the request. Try again.';

  // Ticket page
  static const allTickets = 'All tickets';
  static const minimum = 'Minimum';
  static const maximum = 'Maximum';
  static const usedFor = 'Used for';
  static const requestsHeading = 'Requests';
  static const requestsSub = 'Sent with this ticket';
  static const noTicketRequests = 'No requests sent with this ticket yet.';
  static const matchesHeading = 'Matches';
  static const matchesSub = 'Open rounds that fit this ticket';
  static const noMatches = 'No matching rounds right now.';
  static const matchesFailed =
      'Couldn’t load the matches. Check your connection.';
  static const findingMatches = 'Finding matches…';
  static const requestSentPill = 'Request sent';

  // Requests tab
  static const noRequests = 'No requests yet. Send one from a matching ticket.';
  static String noRequestsOf(String filter) =>
      'No ${filter.toLowerCase()} requests.';
}
