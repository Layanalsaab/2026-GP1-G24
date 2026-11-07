import '../../app_constants/firestore_collections.dart';
import '../../models/connection_request.dart';
import '../../models/investment_ticket.dart';
import '../firebase_services/firestore_service.dart';

/// An investor's investment tickets (`tickets/{investorId}-T{n}`) and the
/// requests they send through a ticket (`requests` with a `ticketId`).
///
/// Every method throws AuthException on failure (network, permission, ...),
/// like the other repositories.
class TicketRepository {
  TicketRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  /// The app-wide instance. Tests replace it with a fake.
  static TicketRepository instance = TicketRepository();

  final FirestoreService _firestore;

  /// More tickets or requests than any investor has.
  static const _limit = 200;

  /// The investor's tickets, newest first.
  Future<List<InvestmentTicket>> ticketsOf(String investorId) async {
    final docs = await _firestore.queryWhereEqual(
      FirestoreCollections.tickets,
      TicketFields.investorId,
      investorId,
      limit: _limit,
    );
    final tickets = [
      for (final d in docs) ?InvestmentTicket.fromMap(d.id, d.data),
    ];
    tickets.sort((a, b) => b.number.compareTo(a.number));
    return tickets;
  }

  /// The id of the next ticket: the highest number plus 1.
  static String nextId(String investorId, List<InvestmentTicket> existing) {
    var highest = 0;
    for (final t in existing) {
      if (t.number > highest) highest = t.number;
    }
    return '$investorId-T${highest + 1}';
  }

  /// Saves a new open ticket and returns it.
  Future<InvestmentTicket> create(
    String investorId,
    InvestmentTicket draft,
    List<InvestmentTicket> existing,
  ) async {
    final id = nextId(investorId, existing);
    await _firestore.setDocument(FirestoreCollections.tickets, id, {
      TicketFields.investorId: investorId,
      ...draft.editableFields(),
      TicketFields.status: TicketFields.open,
      TicketFields.startupId: null,
      TicketFields.createdAt: _firestore.serverTimestamp(),
    });
    return InvestmentTicket(
      id: id,
      investorId: investorId,
      name: draft.name,
      sectors: draft.sectors,
      stages: draft.stages,
      amountMin: draft.amountMin,
      amountMax: draft.amountMax,
      createdAt: DateTime.now(),
    );
  }

  /// Saves the edited name, sectors, stages and amounts of an open ticket.
  Future<void> update(InvestmentTicket ticket) => _firestore.updateDocument(
    FirestoreCollections.tickets,
    ticket.id,
    ticket.editableFields(),
  );

  /// Closes the ticket: it matches nothing and can't be used anymore.
  Future<void> close(InvestmentTicket ticket) => _firestore.updateDocument(
    FirestoreCollections.tickets,
    ticket.id,
    {TicketFields.status: TicketFields.closed},
  );

  /// The requests the investor sent through a ticket, newest first.
  Future<List<TicketRequest>> requestsOf(String investorId) async {
    final docs = await _firestore.queryWhereEqual(
      FirestoreCollections.requests,
      TicketFields.investorId,
      investorId,
      limit: _limit,
    );
    final requests = [
      for (final d in docs) ?TicketRequest.fromMap(d.id, d.data),
    ];
    requests.sort((a, b) {
      final x = a.createdAt, y = b.createdAt;
      if (x == null || y == null) return 0;
      return y.compareTo(x);
    });
    return requests;
  }

  /// Sends a request for [amount] to a startup with [ticket]. The founder's
  /// accept / decline is not built yet: the request only waits as Pending.
  Future<TicketRequest> sendRequest({
    required InvestmentTicket ticket,
    required String startupId,
    required String startupName,
    required String? founderId,
    required int amount,
  }) async {
    final id = _firestore.newDocumentId(FirestoreCollections.requests);
    await _firestore.setDocument(FirestoreCollections.requests, id, {
      'startupId': startupId,
      'founderId': founderId,
      'investorId': ticket.investorId,
      'message': '',
      'amount': amount,
      'status': RequestStatus.pending.value,
      'createdAt': _firestore.serverTimestamp(),
      TicketFields.ticketId: ticket.id,
      TicketFields.startupName: startupName,
    });
    return TicketRequest(
      id: id,
      ticketId: ticket.id,
      startupId: startupId,
      startupName: startupName,
      amount: amount,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  /// The investor takes a request back.
  Future<void> withdraw(String requestId) =>
      _firestore.deleteDocument(FirestoreCollections.requests, requestId);

  /// An investor's account is deleted: their tickets and every request they
  /// sent go too.
  Future<void> removeAllFor(String investorId) async {
    final tickets = await _firestore.queryWhereEqual(
      FirestoreCollections.tickets,
      TicketFields.investorId,
      investorId,
      limit: _limit,
    );
    final requests = await _firestore.queryWhereEqual(
      FirestoreCollections.requests,
      TicketFields.investorId,
      investorId,
      limit: _limit,
    );
    await _commitDeletes(FirestoreCollections.tickets, tickets);
    await _commitDeletes(FirestoreCollections.requests, requests);
  }

  /// A startup is deleted: the requests sent to it go too (call this before
  /// the startup document is deleted; the rules read the startup).
  Future<void> removeRequestsForStartup(String startupId) async {
    final requests = await _firestore.queryWhereEqual(
      FirestoreCollections.requests,
      'startupId',
      startupId,
      limit: _limit,
    );
    await _commitDeletes(FirestoreCollections.requests, requests);
  }

  Future<void> _commitDeletes(
    String collection,
    List<FirestoreDocument> docs,
  ) async {
    if (docs.isEmpty) return;
    await _firestore.commit([
      for (final d in docs) FirestoreWrite.delete(collection, d.id),
    ]);
  }
}
