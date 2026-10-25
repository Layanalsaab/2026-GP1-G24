import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/app_constants/firestore_collections.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/funding_round_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/firebase_services/auth_service.dart';
import 'package:startsa/models/funding_round.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';

import '../support/fakes.dart';

/// Firestore kept in a map: collection path -> document id -> data. A batch
/// applies its writes one after the other; [commits] counts the batches.
class _MemoryFirestore extends FirestoreService {
  final Map<String, Map<String, Map<String, Object?>>> store = {};
  int commits = 0;
  int _ids = 0;

  @override
  Object serverTimestamp() => 'now';

  @override
  String newDocumentId(String collection) => 'doc${++_ids}';

  @override
  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async => (store[collection] ??= {})[id] = {...data};

  @override
  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async => (store[collection] ??= {})[id] = {
    ...?store[collection]?[id],
    ...data,
  };

  @override
  Future<void> deleteDocument(String collection, String id) async =>
      store[collection]?.remove(id);

  @override
  Future<void> commit(List<FirestoreWrite> writes) async {
    commits++;
    for (final w in writes) {
      switch (w.kind) {
        case FirestoreWriteKind.set:
          await setDocument(w.collection, w.id, w.data);
        case FirestoreWriteKind.update:
          await updateDocument(w.collection, w.id, w.data);
        case FirestoreWriteKind.delete:
          await deleteDocument(w.collection, w.id);
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String id,
  ) async {
    final data = store[collection]?[id];
    return data == null ? null : Map<String, dynamic>.from(data);
  }

  @override
  Future<List<FirestoreDocument>> listCollection(
    String collection, {
    int limit = 100,
  }) async => [
    for (final e in (store[collection] ?? {}).entries)
      (id: e.key, data: Map<String, dynamic>.from(e.value)),
  ];
}

/// A stored round document like the imported dataset's.
Map<String, Object?> _doc({
  required int number,
  required String stage,
  required int? amount,
  required DateTime start,
  DateTime? end,
  int raised = 0,
  List<Map<String, Object?>> investors = const [],
}) => {
  'startupId': 's1',
  'number': number,
  'status': end == null ? 'active' : 'completed',
  'stage': stage,
  'stageOther': null,
  'amount': amount,
  'raised': raised,
  'startDate': start,
  'endDate': end,
  'investors': investors,
  'wantsLeadInvestor': null,
  'isDataset': true,
};

void main() {
  const path = 'startups/s1/fundingRounds';
  final now = DateTime(2026, 10, 25);
  late _MemoryFirestore db;
  late FundingRoundRepository repo;

  /// Rafeeq raising SAR 500,000 (Pre-seed), saved as startup s1.
  Startup raising() => PrototypeSeed.rafeeq.copyWith(id: 's1');

  setUp(() {
    db = _MemoryFirestore();
    repo = FundingRoundRepository(firestore: db);
  });

  group('FundingRound document', () {
    test('reads a dataset round: open, the lead first, profile links', () {
      final r = FundingRound.fromMap(
        'r1',
        _doc(
          number: 1,
          stage: 'seed',
          amount: 2925000,
          raised: 2194000,
          start: DateTime(2023, 11, 25),
          investors: [
            {'name': 'Angel One', 'investorId': null, 'isLead': false},
            {'name': 'Fund Two', 'investorId': 'inv-2', 'isLead': true},
          ],
        ),
      )!;
      expect(r.isOpen, isTrue);
      expect(r.type, StartupStage.seed);
      expect(r.amount, 2925000);
      expect(r.investors.first.name, 'Fund Two');
      expect(r.investors.first.isLead, isTrue);
      expect(r.investors.first.hasProfile, isTrue);
      expect(r.investors.last.hasProfile, isFalse);
    });

    test('an undisclosed amount is not shown', () {
      expect(
        FundingRound.fromMap(
          'r1',
          _doc(
            number: 1,
            stage: 'seed',
            amount: null,
            start: DateTime(2020),
            end: DateTime(2020, 3),
          ),
        ),
        isNull,
      );
    });

    test('an Other round shows its written type', () {
      final r = FundingRound.fromMap('r1', {
        ..._doc(
          number: 1,
          stage: 'other',
          amount: 1000000,
          start: DateTime(2021),
          end: DateTime(2021, 5),
        ),
        'stageOther': 'Private Equity',
      })!;
      expect(r.typeLabel, 'Private Equity');
    });

    test('saved fields: status, dates and the linked investor ids', () {
      final map = FundingRound(
        number: 2,
        type: StartupStage.seed,
        amount: 3000000,
        raised: 500000,
        start: now,
        investors: const [
          RoundInvestor(name: 'Fund Two', investorId: 'inv-2', isLead: true),
          RoundInvestor(name: 'Angel One'),
        ],
        wantsLeadInvestor: true,
      ).toMap('s1');
      expect(map['startupId'], 's1');
      expect(map['status'], 'active');
      expect(map['stage'], 'seed');
      expect(map['startDate'], now);
      expect(map['endDate'], isNull);
      expect(map['investorIds'], ['inv-2']);
      expect(map['investorCount'], 2);
      expect(map['isDataset'], isFalse);
    });

    test('a closed round keeps what it raised', () {
      final open = FundingRound(
        number: 1,
        type: StartupStage.seed,
        amount: 3000000,
        raised: 1000000,
        start: DateTime(2026, 2, 1),
      );
      expect(open.closed(now).raised, 1000000);
      expect(open.closed(now).end, now);
      expect(open.closed(now).isOpen, isFalse);
    });

    test('a round that started and ended in the same month', () {
      final r = FundingRound(
        number: 1,
        type: StartupStage.seed,
        amount: 1,
        start: DateTime(2022, 2, 3),
        end: DateTime(2022, 2, 20),
      );
      expect(r.dateLabel, 'Feb 2022');
    });
  });

  group('FundingRoundRepository', () {
    test('shows the rounds in date order, without the undisclosed ones', () async {
      db.store[path] = {
        'a': _doc(
          number: 1,
          stage: 'pre_seed',
          amount: null,
          start: DateTime(2019),
          end: DateTime(2019, 6),
        ),
        'b': _doc(
          number: 3,
          stage: 'seed',
          amount: 4000000,
          start: DateTime(2023),
        ),
        'c': _doc(
          number: 2,
          stage: 'pre_seed',
          amount: 1500000,
          start: DateTime(2021),
          end: DateTime(2021, 9),
        ),
      };
      final rounds = await repo.roundsOf('s1');
      expect([for (final r in rounds) r.id], ['c', 'b']);
      // Numbered again without the hidden round.
      expect([for (final r in rounds) r.number], [1, 2]);
      expect(rounds.last.isOpen, isTrue);
    });

    test('Funding ticked, no round yet: Round 1 opens', () async {
      final writes = await repo.writesFor(
        's1',
        raising().copyWith(raisedInRound: 100000, wantsLeadInvestor: true),
        isNew: true,
        now: now,
      );
      expect(writes, hasLength(1));
      final w = writes.single;
      expect(w.kind, FirestoreWriteKind.set);
      expect(w.collection, path);
      expect(w.data['number'], 1);
      expect(w.data['status'], 'active');
      expect(w.data['stage'], 'pre_seed');
      expect(w.data['amount'], 500000);
      expect(w.data['raised'], 100000);
      expect(w.data['wantsLeadInvestor'], isTrue);
      expect(w.data['startDate'], now);
    });

    test('Funding ticked with an open round: only what changed', () async {
      db.store[path] = {
        'open': {
          ..._doc(
            number: 1,
            stage: 'pre_seed',
            amount: 500000,
            start: DateTime(2026, 8),
          ),
          // Rafeeq wants a lead investor.
          'wantsLeadInvestor': true,
        },
      };
      expect(await repo.writesFor('s1', raising(), now: now), isEmpty);

      final writes = await repo.writesFor(
        's1',
        raising().copyWith(
          fundingRequirement: 1800000,
          raisedInRound: 300000,
          stage: StartupStage.seed,
        ),
        now: now,
      );
      final w = writes.single;
      expect(w.kind, FirestoreWriteKind.update);
      expect(w.id, 'open');
      expect(w.data['amount'], 1800000);
      expect(w.data['raised'], 300000);
      expect(w.data['stage'], 'seed');
      expect(w.data.containsKey('status'), isFalse);
    });

    test('Funding unticked: the open round closes, raised kept', () async {
      db.store[path] = {
        'open': _doc(
          number: 1,
          stage: 'pre_seed',
          amount: 500000,
          raised: 200000,
          start: DateTime(2026, 8),
        ),
      };
      final closed = raising().copyWith(
        lookingFor: {LookingFor.talent},
        clearFunding: true,
      );
      final w = (await repo.writesFor('s1', closed, now: now)).single;
      expect(w.id, 'open');
      expect(w.data['status'], 'completed');
      expect(w.data['endDate'], now);
      expect(w.data.containsKey('raised'), isFalse);
    });

    test('not raising and no open round: nothing to write', () async {
      final notRaising = raising().copyWith(
        lookingFor: {LookingFor.talent},
        clearFunding: true,
      );
      expect(await repo.writesFor('s1', notRaising, now: now), isEmpty);
    });
  });

  group('StartupRepository saves the rounds with the startup', () {
    late StartupRepository startups;

    setUp(() {
      startups = StartupRepository(
        auth: FakeAuthService()
          ..signedIn = const AuthAccount(
            uid: 'uid1',
            email: 'a@b.co',
            emailVerified: true,
          ),
        firestore: db,
        rounds: repo,
      );
    });

    test('create with Funding: the startup and Round 1 in one batch', () async {
      final saved = await startups.create(PrototypeSeed.rafeeq);
      expect(db.commits, 1);
      expect(db.store[FirestoreCollections.startups]![saved.id], isNotNull);
      final rounds = db.store[FundingRoundFields.collectionOf(saved.id)]!;
      expect(rounds.values.single['amount'], 500000);
      expect(rounds.values.single['status'], 'active');
    });

    test('create without Funding: no round', () async {
      final saved = await startups.create(
        PrototypeSeed.rafeeq.copyWith(
          lookingFor: {LookingFor.talent},
          clearFunding: true,
        ),
      );
      expect(db.commits, 0);
      expect(db.store[FundingRoundFields.collectionOf(saved.id)], isNull);
    });

    test('unticking Funding closes the round; delete removes the rounds', () async {
      final saved = await startups.create(PrototypeSeed.rafeeq);
      final roundsPath = FundingRoundFields.collectionOf(saved.id);
      await startups.update(
        saved.copyWith(lookingFor: {LookingFor.talent}, clearFunding: true),
      );
      expect(db.store[roundsPath]!.values.single['status'], 'completed');
      final doc = db.store[FirestoreCollections.startups]![saved.id]!;
      expect(doc['fundingRequirement'], isNull);
      expect(doc['lookingFor'], ['talent']);

      await startups.delete(saved);
      expect(db.store[roundsPath], isEmpty);
      expect(db.store[FirestoreCollections.startups]![saved.id], isNull);
    });
  });
}
