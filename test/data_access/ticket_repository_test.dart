import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/repositories/ticket_repository.dart';
import 'package:startsa/models/investment_ticket.dart';

import '../support/recording_firestore.dart';

void main() {
  const draft = InvestmentTicket(
    id: '',
    investorId: 'u1',
    name: 'Logistics seed',
    sectors: ['Logistics'],
    stages: ['Seed'],
    amountMin: 100000,
    amountMax: 2000000,
  );

  // For You listens to these, so a ticket shapes it as soon as it is saved.
  test('every saved ticket is reported, with its new state', () async {
    final repo = TicketRepository(firestore: RecordingFirestore());
    expect(repo.saved.value, 0);
    expect(repo.lastSaved, isNull);

    final created = await repo.create('u1', draft, const []);
    expect(repo.saved.value, 1);
    expect(repo.lastSaved!.id, created.id);
    expect(repo.lastSaved!.isOpen, isTrue);

    final edited = created.copyWith(amountMax: 3000000);
    await repo.update(edited);
    expect(repo.saved.value, 2);
    expect(repo.lastSaved!.amountMax, 3000000);

    await repo.close(edited);
    expect(repo.saved.value, 3);
    expect(repo.lastSaved!.id, created.id);
    expect(repo.lastSaved!.isOpen, isFalse);
  });
}
