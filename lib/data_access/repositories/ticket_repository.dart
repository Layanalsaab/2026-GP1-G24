import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../models/investment_ticket.dart';
import '../firebase_services/firestore_service.dart';

class TicketRepository {
  TicketRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  /// The app-wide instance.
  static TicketRepository instance = TicketRepository();

  final FirestoreService _firestore;

  /// Counts tickets saved by this app (created, edited or closed); For You
  /// listens so a ticket shapes it as soon as it is saved.
  ValueListenable<int> get saved => _saved;
  final ValueNotifier<int> _saved = ValueNotifier<int>(0);

  /// The ticket saved last, as it is now.
  InvestmentTicket? get lastSaved => _lastSaved;
  InvestmentTicket? _lastSaved;

  void _report(InvestmentTicket ticket) {
    _lastSaved = ticket;
    _saved.value++;
  }

  /// More tickets than any investor has.
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
    final created = InvestmentTicket(
      id: id,
      investorId: investorId,
      name: draft.name,
      sectors: draft.sectors,
      stages: draft.stages,
      amountMin: draft.amountMin,
      amountMax: draft.amountMax,
      createdAt: DateTime.now(),
    );
    _report(created);
    return created;
  }

  /// Saves the edited name, sectors, stages and amounts of an open ticket.
  Future<void> update(InvestmentTicket ticket) async {
    await _firestore.updateDocument(
      FirestoreCollections.tickets,
      ticket.id,
      ticket.editableFields(),
    );
    _report(ticket);
  }

  /// Closes the ticket: it matches nothing and can't be used anymore.
  Future<void> close(InvestmentTicket ticket) async {
    await _firestore.updateDocument(FirestoreCollections.tickets, ticket.id, {
      TicketFields.status: TicketFields.closed,
    });
    _report(ticket.copyWith(status: TicketStatus.closed));
  }

  Future<void> removeAllFor(String investorId) async {
    final tickets = await _firestore.queryWhereEqual(
      FirestoreCollections.tickets,
      TicketFields.investorId,
      investorId,
      limit: _limit,
    );
    if (tickets.isEmpty) return;
    await _firestore.commit([
      for (final d in tickets)
        FirestoreWrite.delete(FirestoreCollections.tickets, d.id),
    ]);
  }
}
