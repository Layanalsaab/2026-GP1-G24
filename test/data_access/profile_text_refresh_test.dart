import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/firebase_services/auth_service.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/remote/for_you_api.dart';
import 'package:startsa/data_access/repositories/funding_round_repository.dart';
import 'package:startsa/data_access/repositories/public_profile_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/investor_criteria.dart';

import '../support/fakes.dart';

class _MemoryFirestore extends FirestoreService {
  final Map<String, Map<String, Map<String, Object?>>> store = {};
  int _ids = 0;

  @override
  Object serverTimestamp() => 'now';

  @override
  String newDocumentId(String collection) => 'doc${++_ids}';

  @override
  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data, {
    bool merge = false,
  }) async => (store[collection] ??= {})[id] = {...data};

  @override
  Future<void> updateDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async =>
      (store[collection] ??= {})[id] = {...?store[collection]?[id], ...data};

  @override
  Future<void> commit(List<FirestoreWrite> writes) async {
    for (final w in writes) {
      switch (w.kind) {
        case FirestoreWriteKind.set:
          await setDocument(w.collection, w.id, w.data);
        case FirestoreWriteKind.update:
          await updateDocument(w.collection, w.id, w.data);
        case FirestoreWriteKind.delete:
          store[w.collection]?.remove(w.id);
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

enum _Mode { ok, returnsFalse, throwsAsync, throwsSync }

class _FakeForYou implements ForYouSource {
  @override
  bool enabled = true;
  _Mode mode = _Mode.ok;
  final calls = <(HomeItemKind, String)>[];

  @override
  Future<List<ForYouPick>?> forYou() async => null;

  @override
  Future<bool> profileText(HomeItemKind kind, String id) {
    calls.add((kind, id));
    switch (mode) {
      case _Mode.ok:
        return Future.value(true);
      case _Mode.returnsFalse:
        return Future.value(false);
      case _Mode.throwsAsync:
        return Future.error(StateError('boom'));
      case _Mode.throwsSync:
        throw StateError('boom');
    }
  }

  @override
  final ValueListenable<int> profileTextDone = ValueNotifier<int>(0);
}

void main() {
  late _MemoryFirestore db;
  late _FakeForYou forYou;
  late StartupRepository startups;
  late UserRepository users;

  setUp(() {
    db = _MemoryFirestore();
    forYou = _FakeForYou();
    PublicProfileRepository.instance = PublicProfileRepository(firestore: db);
    startups = StartupRepository(
      auth: FakeAuthService()
        ..signedIn = const AuthAccount(
          uid: 'uid1',
          email: 'a@b.co',
          emailVerified: true,
        ),
      firestore: db,
      rounds: FundingRoundRepository(firestore: db),
      forYou: forYou,
    );
    users = UserRepository(firestore: db, forYou: forYou);
    db.store['users'] = {
      'u1': {'role': 'investor', 'fullName': 'Inv'},
      'u2': {'role': 'founder', 'fullName': 'Fou'},
    };
  });

  test(
    'creating and updating a startup asks the server to re-encode it',
    () async {
      final created = await startups.create(PrototypeSeed.rafeeq);
      expect(forYou.calls, [(HomeItemKind.startup, created.id)]);

      await startups.update(created);
      expect(forYou.calls, [
        (HomeItemKind.startup, created.id),
        (HomeItemKind.startup, created.id),
      ]);
    },
  );

  test(
    'saving investor answers asks the server to re-encode the investor',
    () async {
      await users.saveInvestorOnboarding(
        uid: 'u1',
        criteria: const InvestorCriteria(lookFor: 'x'),
      );
      expect(forYou.calls, [(HomeItemKind.investor, 'u1')]);
    },
  );

  test("a founder's profile edit sends nothing", () async {
    await users.updateProfile(
      uid: 'u2',
      fullName: 'Fou',
      bio: 'b',
      phone: '1',
      sectorsOfInterest: const [],
    );
    expect(forYou.calls, isEmpty);
  });

  for (final mode in [
    _Mode.returnsFalse,
    _Mode.throwsAsync,
    _Mode.throwsSync,
  ]) {
    test('a server failure never breaks the save ($mode)', () async {
      forYou.mode = mode;
      final created = await startups.create(PrototypeSeed.rafeeq);
      expect(db.store['startups']![created.id], isNotNull);
      await startups.update(created);
      await users.saveInvestorOnboarding(
        uid: 'u1',
        criteria: const InvestorCriteria(lookFor: 'x'),
      );
      expect(db.store['investors']!['u1'], isNotNull);
      await Future<void>.delayed(Duration.zero);
    });
  }

  test('with the server off nothing is sent', () async {
    forYou.enabled = false;
    final created = await startups.create(PrototypeSeed.rafeeq);
    await startups.update(created);
    await users.saveInvestorOnboarding(
      uid: 'u1',
      criteria: const InvestorCriteria(lookFor: 'x'),
    );
    expect(forYou.calls, isEmpty);
  });
}
