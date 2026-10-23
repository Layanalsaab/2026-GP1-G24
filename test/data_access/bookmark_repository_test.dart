import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';

/// Firestore kept in a map: collection path -> document id -> data.
class _MemoryFirestore extends FirestoreService {
  final Map<String, Map<String, Map<String, Object?>>> store = {};

  @override
  Object serverTimestamp() => 'now';

  @override
  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data,
  ) async => (store[collection] ??= {})[id] = data;

  @override
  Future<void> deleteDocument(String collection, String id) async =>
      store[collection]?.remove(id);

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
  const path = 'users/u1/bookmarks';

  late _MemoryFirestore db;
  late BookmarkRepository repo;

  setUp(() {
    db = _MemoryFirestore();
    repo = BookmarkRepository(firestore: db);
    AppSession.instance.reset();
  });

  tearDown(() => AppSession.instance.reset());

  test('signed out: toggles stay in memory, nothing is saved', () async {
    expect(repo.toggle('s-barq'), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(repo.isBookmarked('s-barq'), isTrue);
    expect(db.store, isEmpty);
  });

  test('signed in: toggle saves and removes the document', () async {
    AppSession.instance.signIn(user);

    repo.toggle('i-ANG-1');
    await Future<void>.delayed(Duration.zero);
    expect(db.store[path]!['i-ANG-1'], {
      'type': 'investor',
      'targetId': 'ANG-1',
      'createdAt': 'now',
    });

    repo.toggle('i-ANG-1');
    await Future<void>.delayed(Duration.zero);
    expect(db.store[path], isEmpty);
  });

  test('bookmarks survive log out and come back with load', () async {
    AppSession.instance.signIn(user);
    repo.toggle('s-barq');
    repo.toggle('p-taqadam');
    await Future<void>.delayed(Duration.zero);

    repo.clear(); // log out
    expect(repo.count, 0);

    await repo.load('u1'); // log in again
    expect(repo.keys.value, {'s-barq', 'p-taqadam'});
  });

  test('deleteAll removes every saved bookmark', () async {
    AppSession.instance.signIn(user);
    repo.toggle('s-barq');
    repo.toggle('i-ANG-1');
    await Future<void>.delayed(Duration.zero);

    await repo.deleteAll('u1');
    expect(db.store[path], isEmpty);
    expect(repo.count, 0);
  });

  test('newest first, with a type filter', () async {
    db.store[path] = {
      's-old': {'createdAt': DateTime(2026, 1, 1)},
      'i-mid': {'createdAt': DateTime(2026, 5, 1)},
      'p-new': {'createdAt': DateTime(2026, 9, 1)},
    };
    await repo.load('u1');
    expect(repo.newestFirst(), ['p-new', 'i-mid', 's-old']);

    repo.toggle('s-today'); // saved now, so it comes first
    expect(repo.newestFirst().first, 's-today');
    expect(repo.newestFirst(type: 'startup'), ['s-today', 's-old']);
  });

  test('key helpers', () {
    expect(BookmarkRepository.typeOf('s-barq-d6bc'), 'startup');
    expect(BookmarkRepository.targetIdOf('s-barq-d6bc'), 'barq-d6bc');
    expect(BookmarkRepository.typeOf('p-taqadam'), 'program');
  });
}
