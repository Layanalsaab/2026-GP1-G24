import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/repositories/not_interested_repository.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';

/// Firestore kept in a map: collection path -> document id -> data.
class _MemoryFirestore extends FirestoreService {
  final Map<String, Map<String, Map<String, Object?>>> store = {};

  @override
  Object serverTimestamp() => 'now';

  /// When true, every setDocument fails.
  bool failWrites = false;

  @override
  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data, {
    bool merge = false,
  }) async {
    if (failWrites) throw Exception('offline');
    (store[collection] ??= {})[id] = data;
  }

  @override
  Future<void> deleteDocument(String collection, String id) async =>
      store[collection]?.remove(id);

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

void main() {
  const user = AppUser(
    uid: 'u1',
    role: AccountRole.founder,
    fullName: 'Sara Test',
    email: 's@x.co',
  );
  const path = 'users/u1/notInterested';

  late _MemoryFirestore db;
  late NotInterestedRepository repo;

  setUp(() {
    db = _MemoryFirestore();
    repo = NotInterestedRepository(firestore: db);
    AppSession.instance.reset();
    AppSession.instance.signIn(user);
  });

  tearDown(() => AppSession.instance.reset());

  test('add saves the key with type, target and time', () async {
    await repo.add('s-x');
    expect(db.store[path]!['s-x'], {
      'type': 'startup',
      'targetId': 'x',
      'createdAt': 'now',
    });
    expect(repo.keys.value, {'s-x'});
    expect(repo.contains('s-x'), isTrue);
  });

  test('add changes keys at once, before the write lands', () async {
    final future = repo.add('s-x');
    expect(repo.keys.value, {'s-x'});
    await future;
  });

  test('remove deletes it (Undo)', () async {
    await repo.add('s-x');
    await repo.remove('s-x');
    expect(db.store[path], isEmpty);
    expect(repo.keys.value, isEmpty);
  });

  test('a failed write puts the key back', () async {
    db.failWrites = true;
    await repo.add('s-x');
    expect(repo.keys.value, isEmpty);
  });

  test('load reads saved keys and clear forgets them', () async {
    db.store[path] = {
      's-a': {'createdAt': DateTime(2026, 1, 1)},
      'i-b': {'createdAt': DateTime(2026, 2, 1)},
    };
    await repo.load('u1');
    expect(repo.keys.value, {'s-a', 'i-b'});
    repo.clear();
    expect(repo.keys.value, isEmpty);
  });

  test('deleteAll removes every saved key', () async {
    await repo.add('s-a');
    await repo.add('i-b');
    await repo.deleteAll('u1');
    expect(db.store[path], isEmpty);
    expect(repo.keys.value, isEmpty);
  });
}
