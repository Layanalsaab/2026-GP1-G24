import 'connection_request.dart';

/// A startup's request to an investor, sent from one of the investor's open
/// tickets (`ticketRequests/{startupId}~{ticketId}`). The investor sees it as
/// "Request received" and accepts or declines it.
class ReceivedRequest {
  const ReceivedRequest({
    required this.id,
    required this.ticketId,
    required this.startupId,
    required this.startupName,
    required this.founderId,
    required this.investorId,
    required this.amount,
    required this.status,
    this.message = '',
    this.createdAt,
  });

  final String id;
  final String ticketId;
  final String startupId;
  final String startupName;
  final String founderId;
  final String investorId;

  /// In SAR.
  final int amount;
  final RequestStatus status;
  final String message;
  final DateTime? createdAt;

  bool get isPending => status == RequestStatus.pending;

  ReceivedRequest withStatus(RequestStatus value) => ReceivedRequest(
    id: id,
    ticketId: ticketId,
    startupId: startupId,
    startupName: startupName,
    founderId: founderId,
    investorId: investorId,
    amount: amount,
    status: value,
    message: message,
    createdAt: createdAt,
  );

  /// Null for a document that is not a valid request.
  static ReceivedRequest? fromMap(String id, Map<String, dynamic>? data) {
    if (data == null) return null;
    final ticket = data['ticketId'];
    final startup = data['startupId'];
    final amount = data['amount'];
    if (ticket is! String || ticket.isEmpty) return null;
    if (startup is! String || startup.isEmpty) return null;
    if (amount is! num) return null;
    final created = data['createdAt'];
    return ReceivedRequest(
      id: id,
      ticketId: ticket,
      startupId: startup,
      startupName: (data['startupName'] as String?) ?? '',
      founderId: (data['founderId'] as String?) ?? '',
      investorId: (data['investorId'] as String?) ?? '',
      amount: amount.round(),
      status: RequestStatus.fromValue(data['status']),
      message: (data['message'] as String?) ?? '',
      // A Firestore Timestamp is read by the service as a DateTime.
      createdAt: created is DateTime ? created : null,
    );
  }
}
