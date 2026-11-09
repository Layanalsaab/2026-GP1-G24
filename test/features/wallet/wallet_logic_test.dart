import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/matching_repository.dart';
import 'package:startsa/data_access/repositories/ticket_repository.dart';
import 'package:startsa/features/wallet/view_models/wallet_view_model.dart';
import 'package:startsa/helpers/ticket_rules.dart';
import 'package:startsa/models/connection_request.dart';
import 'package:startsa/models/investment_ticket.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/recommender/content_ranker.dart' show MatchResult;

/// Firestore kept in a map: collection -> document id -> data.
class MemoryFirestore extends FirestoreService {
  MemoryFirestore();

  final Map<String, Map<String, Map<String, Object?>>> store = {};
  bool failWrites = false;
  int _next = 0;

  @override
  Object serverTimestamp() => DateTime(2026, 11, 7, 12);

  @override
  String newDocumentId(String collection) => 'doc${_next++}';

  @override
  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data, {
    bool merge = false,
  }) async {
    if (failWrites) throw Exception('offline');
    (store[collection] ??= {})[id] = {...data};
  }

  @override
  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async {
    if (failWrites) throw Exception('offline');
    (store[collection] ??= {})[id] = {...?store[collection]?[id], ...data};
  }

  @override
  Future<void> deleteDocument(String collection, String id) async {
    if (failWrites) throw Exception('offline');
    store[collection]?.remove(id);
  }

  @override
  Future<void> commit(List<FirestoreWrite> writes) async {
    for (final w in writes) {
      store[w.collection]?.remove(w.id);
    }
  }

  @override
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async => [
    for (final e in (store[collection] ?? {}).entries)
      if (e.value[field] == value)
        (id: e.key, data: Map<String, dynamic>.from(e.value)),
  ];
}

InvestmentTicket ticket({
  String id = 'inv1-T1',
  String name = 'Ticket 1',
  List<String> sectors = const ['HealthTech'],
  List<String> stages = const ['Pre-seed'],
  int min = 100000,
  int max = 300000,
  TicketStatus status = TicketStatus.open,
}) => InvestmentTicket(
  id: id,
  investorId: 'inv1',
  name: name,
  sectors: sectors,
  stages: stages,
  amountMin: min,
  amountMax: max,
  status: status,
);

Map<String, Object?> ticketDoc(InvestmentTicket t, {DateTime? created}) => {
  TicketFields.investorId: t.investorId,
  ...t.editableFields(),
  TicketFields.status: t.status.value,
  TicketFields.startupId: t.startupId,
  TicketFields.createdAt: created ?? DateTime(2026, 11, 1),
};

void main() {
  group('TicketErrors', () {
    test('name, sectors, stages', () {
      expect(TicketErrors.name('  '), 'Enter a name for this ticket.');
      expect(TicketErrors.name('Seed bets'), isNull);
      expect(TicketErrors.sectors({}), 'Select at least one sector.');
      expect(TicketErrors.stages({}), 'Select at least one stage.');
      expect(TicketErrors.stages({'Seed'}), isNull);
    });

    test('minimum: SAR 1,000, and nothing above (any ticket size is fine)', () {
      expect(TicketErrors.minAmount, 1000);
      expect(TicketErrors.minimum(null), 'Enter the minimum amount.');
      expect(TicketErrors.minimum(0), 'Enter the minimum amount.');
      expect(
        TicketErrors.minimum(999),
        'The minimum must be at least SAR 1,000.',
      );
      expect(TicketErrors.minimum(1000), isNull);
      expect(TicketErrors.minimum(1001), isNull);
      expect(TicketErrors.minimum(50000000), isNull);
    });

    test('maximum: required, at least SAR 1,000, more than the minimum', () {
      expect(TicketErrors.maximum(null, 100000), 'Enter the maximum amount.');
      expect(TicketErrors.maximum(0, 100000), 'Enter the maximum amount.');
      expect(
        TicketErrors.maximum(999, null),
        'The maximum must be at least SAR 1,000.',
      );
      // Strictly more than the minimum.
      expect(
        TicketErrors.maximum(100000, 100000),
        'The maximum must be more than the minimum.',
      );
      expect(
        TicketErrors.maximum(99999, 100000),
        'The maximum must be more than the minimum.',
      );
      expect(TicketErrors.maximum(100001, 100000), isNull);
      expect(TicketErrors.maximum(1001, 1000), isNull);
      // A very large ticket is fine.
      expect(TicketErrors.maximum(900000000, 250000000), isNull);
      // Nothing to compare with yet.
      expect(TicketErrors.maximum(5000, null), isNull);
    });

    test('Other needs its text, like every other picker', () {
      expect(
        TicketErrors.sectors({'Other'}),
        'Please type your sector — it can’t be blank.',
      );
      expect(TicketErrors.sectors({'Other'}, other: '  '), isNotNull);
      expect(TicketErrors.sectors({'Other'}, other: 'SportsTech'), isNull);
      expect(TicketErrors.sectors({'Fintech', 'Other'}, other: 'x'), isNull);
    });
  });

  group('ticket matches (lib/recommender)', () {
    // Rafeeq Health: HealthTech, Pre-seed, B2C, raising SAR 500,000.
    final rafeeq = PrototypeSeed.rafeeq;

    List<TicketMatch> matches(
      InvestmentTicket t,
      List<Startup> startups, {
      List<String> models = const [],
    }) {
      final byId = {for (final s in startups) s.id: s};
      return [
        for (final r in MatchingRepository.matchesForTicket(t, models, startups))
          TicketMatch(startup: byId[r.id]!, result: r),
      ];
    }

    test('what a round still needs is funding minus raised', () {
      expect(remainingOf(rafeeq), 500000);
      expect(remainingOf(rafeeq.copyWith(raisedInRound: 200000)), 300000);
      expect(remainingOf(rafeeq.copyWith(raisedInRound: 900000)), 0);
    });

    test('same sector and stage, minimum within what is left', () {
      final m = matches(ticket(), [rafeeq]).single;
      expect(m.remaining, 500000);
      // No commerce models; the ticket's 300K covers 60% of the 500K left:
      // (0.41 + 0.29 + 0.12 * 0.6) / 0.82.
      expect(m.percent, 94);
      expect(m.close, isFalse);
    });

    test('the profile commerce models count 20%', () {
      final m = matches(
        ticket(),
        [rafeeq],
        models: const ['Business-to-Business (B2B)'],
      ).single;
      expect(m.percent, 77); // Rafeeq is B2C: 0.41 + 0.29 + 0.12 * 0.6
    });

    test('close: only the sector or only the stage differs', () {
      expect(matches(ticket(sectors: ['Fintech']), [rafeeq]).single.close, isTrue);
      expect(matches(ticket(stages: ['Seed']), [rafeeq]).single.close, isTrue);
      expect(
        matches(ticket(sectors: ['Fintech'], stages: ['Seed']), [rafeeq]),
        isEmpty,
      );
    });

    test('no match: minimum too high, or the ticket is closed or used', () {
      expect(matches(ticket(min: 600000, max: 700000), [rafeeq]), isEmpty);
      expect(matches(ticket(status: TicketStatus.closed), [rafeeq]), isEmpty);
      expect(matches(ticket(status: TicketStatus.used), [rafeeq]), isEmpty);
    });

    test('a startup that is not raising, closed or private never matches', () {
      expect(
        matches(ticket(), [rafeeq.copyWith(raisedInRound: 500000)]),
        isEmpty,
      );
      expect(matches(ticket(), [rafeeq.copyWith(isClosed: true)]), isEmpty);
      expect(matches(ticket(), [rafeeq.copyWith(isPublic: false)]), isEmpty);
    });

    test('a typed sector matches by the Other rule (case, spaces, one s)', () {
      final sports = rafeeq.copyWith(
        sector: Sector.other,
        sectorOther: 'Sports Tech',
      );
      bool exact(List<String> sectors) {
        final m = matches(ticket(sectors: sectors), [sports]);
        return m.isNotEmpty && !m.single.close;
      }

      expect(exact(['SportsTech']), isTrue);
      expect(exact(['sportstechs']), isTrue);
      expect(exact(['Fashion']), isFalse);
      // A ticket with the plain "Other" matches any Other sector.
      expect(exact(['Other']), isTrue);
      expect(matches(ticket(sectors: ['Other']), [rafeeq]).single.close, isTrue);
    });

    test('best first: exact before close, then by name', () {
      final alpha = rafeeq.copyWith(id: 'alpha', name: 'Alpha');
      final seed = rafeeq.copyWith(
        id: 'seed',
        name: 'Aardvark',
        stage: StartupStage.seed,
      );
      expect(
        [for (final m in matches(ticket(), [seed, rafeeq, alpha])) m.startup.name],
        ['Alpha', 'Rafeeq Health', 'Aardvark'],
      );
    });
  });

  group('helpers', () {
    test('shortList shows two items then +N', () {
      expect(shortList(['A']), 'A');
      expect(shortList(['A', 'B']), 'A, B');
      expect(shortList(['A', 'B', 'C', 'D']), 'A, B +2');
    });

    test('timeAgo', () {
      final now = DateTime(2026, 11, 7, 12);
      expect(timeAgo(now, now: now), 'just now');
      expect(
        timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
        '5m ago',
      );
      expect(
        timeAgo(now.subtract(const Duration(hours: 3)), now: now),
        '3h ago',
      );
      expect(
        timeAgo(now.subtract(const Duration(days: 2)), now: now),
        '2d ago',
      );
      expect(
        timeAgo(now.subtract(const Duration(days: 14)), now: now),
        '2w ago',
      );
      expect(timeAgo(null, now: now), 'just now');
    });

    test('a ticket number comes from its id', () {
      expect(InvestmentTicket.numberOf('abc-T12'), 12);
      expect(InvestmentTicket.numberOf('abc'), 0);
    });
  });

  group('WalletViewModel', () {
    late MemoryFirestore db;
    late WalletViewModel vm;

    Future<void> seed(List<InvestmentTicket> tickets) async {
      for (final t in tickets) {
        (db.store[FirestoreCollections.tickets] ??= {})[t.id] = ticketDoc(t);
      }
    }

    Future<WalletViewModel> make() async {
      final v = WalletViewModel(
        investorId: 'inv1',
        tickets: TicketRepository(firestore: db),
        matching: MatchingRepository(
          firestore: _StartupsFirestore([PrototypeSeed.rafeeq]),
          live: false,
        ),
        now: () => DateTime(2026, 11, 7, 14),
      );
      v.setOptionOrder(
        sectors: const ['HealthTech', 'Fintech', 'Logistics'],
        stages: const ['Pre-seed', 'Seed'],
      );
      await v.load();
      return v;
    }

    setUp(() => db = MemoryFirestore());

    test('loads the tickets newest first and counts matches', () async {
      await seed([
        ticket(id: 'inv1-T1'),
        ticket(
          id: 'inv1-T2',
          name: 'Ticket 2',
          sectors: ['Fintech'],
          stages: ['Series A'],
        ),
        ticket(id: 'inv1-T3', name: 'Ticket 3', status: TicketStatus.closed),
      ]);
      vm = await make();
      expect(
        [for (final t in vm.tickets) t.id],
        ['inv1-T3', 'inv1-T2', 'inv1-T1'],
      );
      expect(vm.matchesOf(vm.ticketById('inv1-T1')!).length, 1);
      expect(vm.matchesOf(vm.ticketById('inv1-T2')!), isEmpty);
      // A closed ticket has no matches.
      expect(vm.matchesOf(vm.ticketById('inv1-T3')!), isEmpty);
    });

    test('a failed load says so', () async {
      db = _FailingFirestore();
      vm = await make();
      expect(vm.loadFailed, isTrue);
      expect(vm.isLoading, isFalse);
    });

    test('the default name is the highest number plus 1', () async {
      await seed([ticket(id: 'inv1-T1'), ticket(id: 'inv1-T4', name: 'x')]);
      vm = await make();
      vm.openForm();
      expect(vm.name.text, 'Ticket 5');
    });

    test('the default name alone is not a change', () async {
      vm = await make();
      vm.openForm();
      expect(vm.name.text, 'Ticket 1');
      expect(vm.formDirty, isFalse);
      vm.name.text = 'Seed bets';
      expect(vm.formDirty, isTrue);
      vm.name.text = 'Ticket 1';
      expect(vm.formDirty, isFalse);
      vm.toggleSector('HealthTech');
      expect(vm.formDirty, isTrue);
    });

    test(
      'errors: empty boxes wait for the first try, wrong values show',
      () async {
        vm = await make();
        vm.openForm();
        expect(vm.sectorsError, isNull);
        expect(vm.minError, isNull);
        // At least SAR 1,000, and no limit from what the investor usually
        // invests.
        vm.min.text = '999';
        expect(vm.minError, 'The minimum must be at least SAR 1,000.');
        vm.min.text = '50,000';
        expect(vm.minError, isNull);
        vm.min.text = '80,000,000';
        expect(vm.minError, isNull);
        vm.min.text = '100,000';
        vm.max.text = '100,000';
        expect(vm.maxError, 'The maximum must be more than the minimum.');
        expect(vm.formValid, isFalse);
        expect(await vm.submit(), isFalse);
        expect(vm.sectorsError, 'Select at least one sector.');
        expect(vm.stagesError, 'Select at least one stage.');
      },
    );

    test('adding saves an open ticket with the next id', () async {
      await seed([ticket(id: 'inv1-T1')]);
      vm = await make();
      vm.openForm();
      vm.name.text = 'Health bets';
      vm.toggleSector('Logistics');
      vm.toggleSector('HealthTech');
      vm.toggleStage('Seed');
      vm.min.text = '100,000';
      vm.max.text = '300,000';
      expect(vm.formValid, isTrue);
      expect(await vm.submit(), isTrue);
      expect(vm.formOpen, isFalse);
      expect(vm.tickets.first.id, 'inv1-T2');
      final saved = db.store[FirestoreCollections.tickets]!['inv1-T2']!;
      expect(saved[TicketFields.status], 'open');
      expect(saved[TicketFields.startupId], isNull);
      expect(saved[TicketFields.investorId], 'inv1');
      // In the order of the lists.
      expect(saved[TicketFields.sectors], ['HealthTech', 'Logistics']);
      expect(saved[TicketFields.amountMin], 100000);
      expect(saved[TicketFields.amountMax], 300000);
    });

    test('editing saves the new values', () async {
      await seed([ticket(id: 'inv1-T1')]);
      vm = await make();
      vm.openEdit(vm.tickets.first);
      expect(vm.name.text, 'Ticket 1');
      expect(vm.min.text, '100,000');
      expect(vm.formDirty, isFalse);
      vm.max.text = '400,000';
      expect(vm.formDirty, isTrue);
      expect(await vm.submit(), isTrue);
      expect(vm.editing, isNull);
      expect(vm.tickets.first.amountMax, 400000);
      expect(
        db.store[FirestoreCollections.tickets]!['inv1-T1']![TicketFields
            .amountMax],
        400000,
      );
    });

    test('only an open ticket can be edited or closed', () async {
      await seed([
        ticket(id: 'inv1-T1', status: TicketStatus.closed),
        ticket(id: 'inv1-T2', name: 'Used', status: TicketStatus.used),
      ]);
      vm = await make();
      vm.openEdit(vm.ticketById('inv1-T1')!);
      expect(vm.editing, isNull);
      expect(await vm.closeTicket(vm.ticketById('inv1-T2')!), isFalse);
    });

    test('closing an open ticket', () async {
      await seed([ticket(id: 'inv1-T1')]);
      vm = await make();
      expect(await vm.closeTicket(vm.tickets.first), isTrue);
      expect(vm.tickets.first.status, TicketStatus.closed);
      expect(
        db.store[FirestoreCollections.tickets]!['inv1-T1']![TicketFields
            .status],
        'closed',
      );
    });

    test(
      'a failed save keeps the form and says so without a technical word',
      () async {
        vm = await make();
        vm.openForm();
        vm.toggleSector('HealthTech');
        vm.toggleStage('Seed');
        vm.min.text = '100,000';
        vm.max.text = '300,000';
        db.failWrites = true;
        expect(await vm.submit(), isFalse);
        expect(vm.formOpen, isTrue);
        expect(vm.error, 'Couldn’t save the ticket. Try again.');
        expect(vm.error!.toLowerCase().contains('firebase'), isFalse);
      },
    );

    test(
      'send request: the amount is checked against the ticket and the round',
      () async {
        await seed([ticket(id: 'inv1-T1', min: 100000, max: 300000)]);
        vm = await make();
        final t = vm.tickets.first;
        final m = vm.matchesOf(t).single;
        vm.startSend(t, m.startup.id);
        expect(vm.sendError(t, m.remaining), isNull);
        vm.sendAmount.text = '';
        vm.trySend(t, m.remaining);
        expect(vm.sendError(t, m.remaining), 'Enter an amount.');
        vm.sendAmount.text = '50,000';
        expect(
          vm.sendError(t, m.remaining),
          'The minimum for this ticket is SAR 100,000.',
        );
        vm.sendAmount.text = '400,000';
        // The ticket's maximum is smaller than what the round needs.
        expect(
          vm.sendError(t, m.remaining),
          'The most you can send is SAR 300,000.',
        );
        vm.sendAmount.text = '200,000';
        expect(vm.sendError(t, m.remaining), isNull);
        expect(
          TicketSend.range(t, m.remaining),
          'Between SAR 100,000 and SAR 300,000',
        );
      },
    );

    test('send request: the most is what the round still needs', () async {
      await seed([ticket(id: 'inv1-T1', min: 100000, max: 900000)]);
      vm = await make();
      final t = vm.tickets.first;
      expect(TicketSend.most(t, 500000), 500000);
    });

    test(
      'sending stores a pending request with the ticket and amount',
      () async {
        await seed([ticket(id: 'inv1-T1')]);
        vm = await make();
        final t = vm.tickets.first;
        final m = vm.matchesOf(t).single;
        vm.startSend(t, m.startup.id);
        vm.sendAmount.text = '200,000';
        expect(vm.trySend(t, m.remaining), isTrue);
        expect(await vm.sendRequest(t, m), isTrue);
        expect(vm.sendingTo, isNull);
        expect(vm.requestSent(t, m.startup.id), isTrue);
        expect(vm.pendingCount, 1);
        final doc = db.store[FirestoreCollections.requests]!.values.single;
        expect(doc['ticketId'], 'inv1-T1');
        expect(doc['amount'], 200000);
        expect(doc['status'], 'pending');
        expect(doc['startupId'], m.startup.id);
        expect(doc['investorId'], 'inv1');
      },
    );

    test('a closed or used ticket cannot send a request', () async {
      await seed([ticket(id: 'inv1-T1', status: TicketStatus.closed)]);
      vm = await make();
      final t = vm.tickets.first;
      vm.startSend(t, 'mock-rafeeq');
      expect(vm.sendingTo, isNull);
      vm.sendAmount.text = '200,000';
      final fake = TicketMatch(
        startup: PrototypeSeed.rafeeq,
        result: const MatchResult(
          id: 'mock-rafeeq',
          name: 'Rafeeq Health',
          score: 1,
          percent: 100,
          rows: [],
          remaining: 500000,
        ),
      );
      expect(await vm.sendRequest(t, fake), isFalse);
      expect(db.store[FirestoreCollections.requests], isNull);
    });

    test('requests: filters, pending count and withdraw', () async {
      await seed([ticket(id: 'inv1-T1')]);
      (db.store[FirestoreCollections.requests] ??= {}).addAll({
        'r1': _requestDoc('r1', 'pending', 100000),
        'r2': _requestDoc('r2', 'accepted', 150000),
        'r3': _requestDoc('r3', 'declined', 120000),
      });
      vm = await make();
      expect(vm.requests.length, 3);
      expect(vm.pendingCount, 1);
      vm.setFilter(RequestFilter.accepted);
      expect([for (final r in vm.visibleRequests) r.id], ['r2']);
      vm.setFilter(RequestFilter.all);
      expect(vm.visibleRequests.length, 3);
      // Only a pending request is withdrawn.
      final accepted = vm.requests.firstWhere((r) => r.id == 'r2');
      expect(await vm.withdraw(accepted), isFalse);
      final pending = vm.requests.firstWhere((r) => r.id == 'r1');
      expect(await vm.withdraw(pending), isTrue);
      expect(vm.pendingCount, 0);
      expect(
        db.store[FirestoreCollections.requests]!.containsKey('r1'),
        isFalse,
      );
    });

    test('a request is shown with the ticket it was sent with', () async {
      await seed([ticket(id: 'inv1-T1', name: 'Health bets')]);
      (db.store[FirestoreCollections.requests] ??= {})['r1'] = _requestDoc(
        'r1',
        'pending',
        100000,
      );
      vm = await make();
      expect(vm.ticketName('inv1-T1'), 'Health bets');
      expect(
        vm.requestsOfTicket(vm.tickets.first).single.startupName,
        'Rafeeq Health',
      );
    });

    test(
      'Other in the sectors: the typed text is the ticket\'s sector',
      () async {
        vm = await make();
        vm.openForm();
        vm.toggleSector('Other');
        expect(vm.sectorsError, isNull); // not tried yet
        vm.toggleStage('Seed');
        vm.min.text = '100,000';
        vm.max.text = '300,000';
        // Other with nothing typed is not valid.
        expect(vm.formValid, isFalse);
        await vm.submit();
        expect(vm.sectorsError, 'Please type your sector — it can’t be blank.');
        vm.setSectorOther('SportsTech');
        vm.toggleSector('HealthTech');
        expect(vm.formValid, isTrue);
        expect(vm.sectorsToSave, ['HealthTech', 'SportsTech']);
        expect(await vm.submit(), isTrue);
        final saved = db.store[FirestoreCollections.tickets]!.values.single;
        expect(saved[TicketFields.sectors], ['HealthTech', 'SportsTech']);
      },
    );

    test('unticking Other forgets the text', () async {
      vm = await make();
      vm.openForm();
      vm.toggleSector('Other');
      vm.setSectorOther('SportsTech');
      vm.toggleSector('Other');
      expect(vm.sectorOther, '');
      expect(vm.sectors, isEmpty);
      vm.toggleSector('Other');
      vm.undoSectorOther();
      expect(vm.sectors, isEmpty);
    });

    test('editing a ticket with a typed sector shows it under Other', () async {
      await seed([
        ticket(id: 'inv1-T1', sectors: ['HealthTech', 'SportsTech']),
      ]);
      vm = await make();
      vm.openEdit(vm.tickets.first);
      expect(vm.sectors, {'HealthTech', 'Other'});
      expect(vm.sectorOther, 'SportsTech');
      expect(vm.formDirty, isFalse);
      expect(vm.sectorsToSave, ['HealthTech', 'SportsTech']);
      vm.setSectorOther('Esports');
      expect(vm.formDirty, isTrue);
    });

    test(
      'an investor account deleted removes its tickets and requests',
      () async {
        await seed([ticket(id: 'inv1-T1')]);
        (db.store[FirestoreCollections.requests] ??= {})['r1'] = _requestDoc(
          'r1',
          'pending',
          100000,
        );
        await TicketRepository(firestore: db).removeAllFor('inv1');
        expect(db.store[FirestoreCollections.tickets], isEmpty);
        expect(db.store[FirestoreCollections.requests], isEmpty);
      },
    );

    test('a deleted startup removes the requests sent to it', () async {
      (db.store[FirestoreCollections.requests] ??= {})['r1'] = _requestDoc(
        'r1',
        'pending',
        100000,
      );
      await TicketRepository(firestore: db)
          .removeRequestsForStartup('mock-rafeeq');
      expect(db.store[FirestoreCollections.requests], isEmpty);
    });

    test('a request status is read from the stored value', () {
      final r = TicketRequest.fromMap('r', _requestDoc('r', 'accepted', 1));
      expect(r!.status, RequestStatus.accepted);
      expect(r.statusLabel, 'Accepted');
      // A request that was not sent through a ticket is not a wallet request.
      expect(
        TicketRequest.fromMap('x', {'startupId': 's', 'amount': 1}),
        isNull,
      );
    });
  });
}

Map<String, Object?> _requestDoc(String id, String status, int amount) => {
  'startupId': 'mock-rafeeq',
  'founderId': 'mock-founder-1',
  'investorId': 'inv1',
  'message': '',
  'amount': amount,
  'status': status,
  'createdAt': DateTime(2026, 11, 6),
  TicketFields.ticketId: 'inv1-T1',
  TicketFields.startupName: 'Rafeeq Health',
};

/// The public startups for the matches.
class _StartupsFirestore extends FirestoreService {
  _StartupsFirestore(this.startups);

  final List<dynamic> startups;

  @override
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async => [
    for (final s in startups)
      (id: s.id as String, data: Map<String, dynamic>.from(s.toMap() as Map)),
  ];
}

class _FailingFirestore extends MemoryFirestore {
  @override
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async => throw Exception('offline');
}
