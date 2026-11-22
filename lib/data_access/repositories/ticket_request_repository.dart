import '../../app_constants/firestore_collections.dart';
import '../../models/connection_request.dart';
import '../../models/investment_ticket.dart';
import '../../models/received_request.dart';
import '../../models/startup.dart';
import '../firebase_services/firestore_service.dart';

class TicketRequestRepository {
  TicketRequestRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  /// The app-wide instance.
  static TicketRequestRepository instance = TicketRequestRepository();

  final FirestoreService _firestore;

  static const _limit = 200;

  /// One request per startup per ticket: the id says so.
  static String idOf(String startupId, String ticketId) =>
      '$startupId~$ticketId';

  List<ReceivedRequest> _sorted(Iterable<ReceivedRequest> all) {
    final list = all.toList();
    list.sort((a, b) {
      final x = a.createdAt, y = b.createdAt;
      if (x == null || y == null) return 0;
      return y.compareTo(x);
    });
    return list;
  }

  /// What the investor received, newest first.
  Future<List<ReceivedRequest>> receivedBy(String investorId) async {
    final docs = await _firestore.queryWhereEqual(
      FirestoreCollections.ticketRequests,
      'investorId',
      investorId,
      limit: _limit,
    );
    return _sorted([
      for (final d in docs) ?ReceivedRequest.fromMap(d.id, d.data),
    ]);
  }

  /// The ids (startup~ticket) of what the founder already sent.
  Future<Set<String>> sentBy(String founderId) async {
    final docs = await _firestore.queryWhereEqual(
      FirestoreCollections.ticketRequests,
      'founderId',
      founderId,
      limit: _limit,
    );
    return {for (final d in docs) d.id};
  }

  /// The founder of startup asks the owner of ticket to invest amount.
  Future<ReceivedRequest> send({
    required InvestmentTicket ticket,
    required Startup startup,
    required int amount,
    String message = '',
  }) async {
    final id = idOf(startup.id, ticket.id);
    await _firestore.setDocument(FirestoreCollections.ticketRequests, id, {
      'startupId': startup.id,
      'founderId': startup.founderId,
      'investorId': ticket.investorId,
      'ticketId': ticket.id,
      'startupName': startup.name,
      'amount': amount,
      'message': message,
      'status': RequestStatus.pending.value,
      'createdAt': _firestore.serverTimestamp(),
    });
    return ReceivedRequest(
      id: id,
      ticketId: ticket.id,
      startupId: startup.id,
      startupName: startup.name,
      founderId: startup.founderId,
      investorId: ticket.investorId,
      amount: amount,
      status: RequestStatus.pending,
      message: message,
      createdAt: DateTime.now(),
    );
  }

  /// Deletes every request sent to investorId's tickets.
  Future<void> removeAllFor(String investorId) async {
    final docs = await _firestore.queryWhereEqual(
      FirestoreCollections.ticketRequests,
      'investorId',
      investorId,
      limit: _limit,
    );
    if (docs.isEmpty) return;
    await _firestore.commit([
      for (final d in docs)
        FirestoreWrite.delete(FirestoreCollections.ticketRequests, d.id),
    ]);
  }

  /// The investor accepts or declines a pending request (once).
  Future<void> answer(String id, {required bool accept}) =>
      _firestore.updateDocument(FirestoreCollections.ticketRequests, id, {
        'status':
            (accept ? RequestStatus.accepted : RequestStatus.declined).value,
        'respondedAt': _firestore.serverTimestamp(),
      });
}
