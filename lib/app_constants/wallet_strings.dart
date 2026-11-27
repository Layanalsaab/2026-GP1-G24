/// Every word of the Investment Wallet (investor only).
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
  static const loading = 'Loading tickets…';
  static const loadFailed =
      'Couldn’t load your tickets. Check your connection.';
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

  static const discardTitle = 'Discard changes?';
  static const discardMessage =
      'If you go back now, your changes will be lost.';
  static const discard = 'Discard';
  static const keepEditing = 'Keep editing';
  static const closeTicket = 'Close ticket';
  static String closeTitle(String name) => 'Close $name?';
  static const closeMessage =
      'This ticket won’t match any round anymore. You can’t use it after closing it.';
  static const sendRequest = 'Send request';

  // Toasts
  static const ticketAdded = 'Ticket added';
  static const ticketSaved = 'Ticket saved';
  static const ticketClosed = 'Ticket closed';

  // Errors (never a technical message)
  static const saveFailed = 'Couldn’t save the ticket. Try again.';

  // Ticket page
  static const allTickets = 'All tickets';
  static const minimum = 'Minimum';
  static const maximum = 'Maximum';
  static const usedFor = 'Used for';
  // Requests that startups send to a ticket
  static const receivedHeading = 'Requests Received';
  static const receivedSub = 'Startups that sent you a request for this ticket';
  static const noReceived = 'No requests received for this ticket yet.';
  static const requestsHeading = 'Investment Requests';
  static const requestsSub = 'Sent with this ticket';
  static const noTicketRequests = 'No requests sent with this ticket yet.';
  static const matchesHeading = 'Suggested Startups';
  static const matchesSub =
      'Startups with an open round that matches this ticket';
  static const noMatches = 'No startups with a matching open round right now.';
  static const matchesFailed =
      'Couldn’t load the suggested startups. Check your connection.';

  // Requests tab
  static const noRequests = 'No requests yet. Send one from a matching ticket.';
}
