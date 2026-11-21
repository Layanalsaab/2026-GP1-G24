import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/remote/for_you_api.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/for_you_cache.dart';
import 'package:startsa/data_access/repositories/not_interested_repository.dart';
import 'package:startsa/features/search/view_models/home_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/home_item.dart';

/// The For You server, answering from a queue: a list, null (no answer) or a
/// future (for example a Completer's, to answer later or never).
class FakeForYou implements ForYouSource {
  FakeForYou([List<Object?> answers = const []]) : _answers = [...answers];

  final List<Object?> _answers;

  /// What every call after the queue is empty answers.
  Object? then;

  int calls = 0;

  @override
  bool enabled = true;

  /// Adds the answer of a later call.
  void answer(Object? value) => _answers.add(value);

  @override
  Future<List<ForYouPick>?> forYou() {
    calls++;
    final next = _answers.isEmpty ? then : _answers.removeAt(0);
    if (next is Future<List<ForYouPick>?>) return next;
    return Future.value(next as List<ForYouPick>?);
  }

  @override
  Future<bool> profileText(HomeItemKind kind, String id) async => true;
}

/// Firestore kept in a map: collection path -> document id -> data.
class _MemoryFirestore extends FirestoreService {
  final Map<String, Map<String, Map<String, Object?>>> store = {};

  @override
  Object serverTimestamp() => 'now';

  @override
  Future<void> setDocument(
    String collection,
    String id,
    Map<String, Object?> data, {
    bool merge = false,
  }) async {
    (store[collection] ??= {})[id] = data;
  }

  @override
  Future<void> deleteDocument(String collection, String id) async {
    store[collection]?.remove(id);
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

/// A saved-list store whose reads finish when the test says so.
class _HeldCache extends ForYouCache {
  final Map<String, Completer<List<String>>> reads = {};

  @override
  Future<List<String>> read(String uid) =>
      (reads[uid] = Completer<List<String>>()).future;

  @override
  Future<void> write(String uid, List<String> keys) async {}
}

ForYouPick s(String id) => ForYouPick(id, HomeItemKind.startup, 0.5);

AppUser investor(String uid) => AppUser(
  uid: uid,
  role: AccountRole.investor,
  fullName: 'Layan Test',
  email: '$uid@x.co',
);

void main() {
  late _MemoryFirestore db;
  late BookmarkRepository marks;
  late NotInterestedRepository hidden;

  setUp(() {
    DiscoveryRepository.instance = DiscoveryRepository.sample(
      startups: [
        for (final (n, id) in const ['a', 'b', 'c', 'saved', 'hidden'].indexed)
          PrototypeSeed.startups[n].copyWith(
            id: id,
            name: 'Startup $id',
            isPublic: true,
          ),
        PrototypeSeed.rafeeq.copyWith(
          id: 'closed',
          isPublic: true,
          isClosed: true,
        ),
        ...PrototypeSeed.startups.skip(5),
      ],
    );
    db = _MemoryFirestore();
    marks = BookmarkRepository(firestore: db);
    BookmarkRepository.instance = marks;
    hidden = NotInterestedRepository(firestore: db);
    AppSession.instance.reset();
    AppSession.instance.signIn(investor('u1'));
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => AppSession.instance.reset());

  HomeViewModel vm(
    FakeForYou server, {
    String? uid = 'u1',
    Duration quiet = Duration.zero,
    ForYouCache? cache,
  }) {
    final m = HomeViewModel(
      role: SessionRole.investor,
      user: uid == null ? null : investor(uid),
      forYou: server,
      forYouCache: cache ?? ForYouCache(),
      notInterested: hidden,
      forYouQuietTime: quiet,
    );
    addTearDown(m.dispose);
    return m;
  }

  List<String> ids(HomeViewModel m) => [for (final i in m.recommended) i.id];

  /// What the app ranks by itself (the fallback).
  List<String> dartList(String uid) => [
    for (final i in DiscoveryRepository.instance.recommendedStartups(
      investorId: uid,
      bookmarks: {
        for (final k in marks.keys.value) k: marks.savedAt(k) ?? DateTime.now(),
      },
    ))
      i.id,
  ];

  void openForYou(HomeViewModel m) => m
    ..selectTab(HomeTab.explore)
    ..selectExploreTab(2);

  test('the server list is shown in the server\'s order', () async {
    final m = vm(
      FakeForYou([
        [s('b'), s('a')],
      ]),
    );
    await pumpEventQueue();
    expect(ids(m), ['b', 'a']);
  });

  test('a server answer is saved for the user', () async {
    vm(
      FakeForYou([
        [s('b'), s('a')],
      ]),
    );
    await pumpEventQueue();
    expect(await ForYouCache().read('u1'), ['s-b', 's-a']);
  });

  test('the saved list shows before the server answers', () async {
    SharedPreferences.setMockInitialValues({
      'forYou.lastList.u1': ['s-a'],
    });
    final m = vm(FakeForYou([Completer<List<ForYouPick>?>().future]));
    await pumpEventQueue();
    expect(ids(m), ['a']);
  });

  test(
    'with no server answer and nothing saved, the Dart list is shown',
    () async {
      final m = vm(FakeForYou([null]));
      await pumpEventQueue();
      expect(ids(m), dartList('u1'));
      expect(ids(m), isNotEmpty);
    },
  );

  test('an empty server answer shows the Dart list', () async {
    final m = vm(FakeForYou([<ForYouPick>[]]));
    await pumpEventQueue();
    expect(ids(m), dartList('u1'));
    expect(ids(m), isNotEmpty);
  });

  test('a server list with nothing to show gives the Dart list', () async {
    marks.toggle('s-saved');
    final m = vm(
      FakeForYou([
        [s('saved'), s('ghost')],
      ]),
    );
    await pumpEventQueue();
    expect(ids(m), dartList('u1'));
    expect(ids(m), isNotEmpty);
  });

  test('a saved list with nothing to show gives the Dart list', () async {
    SharedPreferences.setMockInitialValues({
      'forYou.lastList.u1': ['s-ghost'],
    });
    final m = vm(FakeForYou([Completer<List<ForYouPick>?>().future]));
    await pumpEventQueue();
    expect(ids(m), dartList('u1'));
    expect(ids(m), isNotEmpty);
  });

  test(
    'hiding the last card leaves For You empty until it is redrawn',
    () async {
      final m = vm(
        FakeForYou([
          [s('a')],
        ])..then = null,
      );
      await pumpEventQueue();
      openForYou(m);
      expect(ids(m), ['a']);
      m.hideForYou(m.recommended.single);
      expect(ids(m), isEmpty);
      await pumpEventQueue();
      expect(ids(m), isEmpty);
      m.selectExploreTab(1);
      m.selectExploreTab(2);
      // The Dart list, without the hidden card.
      expect(ids(m), [
        for (final id in dartList('u1'))
          if (id != 'a') id,
      ]);
      expect(ids(m), isNotEmpty);
    },
  );

  test('bookmarked, Not interested and unknown ids are left out', () async {
    marks.toggle('s-saved');
    await hidden.add('s-hidden');
    final m = vm(
      FakeForYou([
        [s('a'), s('saved'), s('hidden'), s('ghost')],
      ]),
    );
    await pumpEventQueue();
    expect(ids(m), ['a']);
  });

  test('closed startups and the user\'s own are left out', () async {
    final m = HomeViewModel(
      role: SessionRole.investor,
      user: investor('u1'),
      ownStartupIds: {'b'},
      forYou: FakeForYou([
        [s('closed'), s('b'), s('a')],
      ]),
      forYouCache: ForYouCache(),
      notInterested: hidden,
      forYouQuietTime: Duration.zero,
    );
    addTearDown(m.dispose);
    await pumpEventQueue();
    expect(ids(m), ['a']);
  });

  test('Not interested items are left out of the Dart list too', () async {
    final first = dartList('u1').first;
    await hidden.add('s-$first');
    final m = vm(FakeForYou([null]));
    await pumpEventQueue();
    expect(ids(m), isNotEmpty);
    expect(ids(m), isNot(contains(first)));
  });

  test('another user\'s saved list is never used', () async {
    SharedPreferences.setMockInitialValues({
      'forYou.lastList.u2': ['s-a'],
    });
    final m = vm(FakeForYou([null]));
    await pumpEventQueue();
    expect(ids(m), dartList('u1'));
    expect(ids(m), isNot(['a']));
  });

  test('a saved list read before switching users is not shown', () async {
    final cache = _HeldCache();
    final m = vm(FakeForYou()..then = null, uid: 'u2', cache: cache);
    m.setUser(investor('u1'));
    // u1's read finishes first, then u2's late one.
    cache.reads['u1']!.complete(const []);
    await pumpEventQueue();
    cache.reads['u2']!.complete(const ['s-a']);
    await pumpEventQueue();
    expect(ids(m), dartList('u1'));
  });

  test('a late server answer for the previous user is dropped', () async {
    final old = Completer<List<ForYouPick>?>();
    final server = FakeForYou([old.future])..then = null;
    final m = vm(server, uid: 'u2');
    m.setUser(investor('u1'));
    old.complete([s('a')]);
    await pumpEventQueue();
    expect(ids(m), dartList('u1'));
    expect(await ForYouCache().read('u2'), isEmpty);
    expect(await ForYouCache().read('u1'), isEmpty);
  });

  test('no server address: no request, no saved list, the Dart list', () async {
    SharedPreferences.setMockInitialValues({
      'forYou.lastList.u1': ['s-a'],
    });
    final server = FakeForYou([
      [s('b')],
    ])..enabled = false;
    final m = vm(server);
    await pumpEventQueue();
    expect(server.calls, 0);
    expect(ids(m), dartList('u1'));
  });

  test('signed out: no request, the Dart list', () async {
    final server = FakeForYou([
      [s('b')],
    ]);
    final m = vm(server, uid: null);
    await pumpEventQueue();
    expect(server.calls, 0);
    expect(ids(m), isNot(['b']));
  });

  test('hide removes a card at once and undo puts it back in place', () async {
    final m = vm(
      FakeForYou([
        [s('a'), s('b'), s('c')],
      ])..then = null,
    );
    await pumpEventQueue();
    openForYou(m);
    expect(ids(m), ['a', 'b', 'c']);
    final b = m.recommended[1];
    var notified = 0;
    m.addListener(() => notified++);

    m.hideForYou(b);
    expect(ids(m), ['a', 'c']);
    expect(notified, 1);
    expect(hidden.contains('s-b'), isTrue);
    await pumpEventQueue();
    expect(db.store['users/u1/notInterested']!.keys, ['s-b']);
    expect(ids(m), ['a', 'c']);

    m.undoHideForYou(b);
    expect(ids(m), ['a', 'b', 'c']);
    expect(notified, 2);
    expect(hidden.contains('s-b'), isFalse);
    await pumpEventQueue();
    expect(db.store['users/u1/notInterested'], isEmpty);
    expect(ids(m), ['a', 'b', 'c']);
  });

  test('hide and undo work on the Dart list', () async {
    final m = vm(FakeForYou([null])..then = null);
    await pumpEventQueue();
    openForYou(m);
    final before = ids(m);
    expect(before.length, greaterThan(1));
    final second = m.recommended[1];
    m.hideForYou(second);
    expect(ids(m), [before.first, ...before.skip(2)]);
    m.undoHideForYou(second);
    expect(ids(m), before);
  });

  test('a new answer after a bookmark waits while For You is open', () async {
    final server = FakeForYou([
      [s('a'), s('b')],
      [s('c')],
    ]);
    final m = vm(server);
    await pumpEventQueue();
    openForYou(m);
    expect(ids(m), ['a', 'b']);
    marks.toggle('s-a');
    await pumpEventQueue();
    expect(server.calls, 2);
    expect(ids(m), ['a', 'b']);
    m.selectExploreTab(1);
    m.selectExploreTab(2);
    expect(ids(m), ['c']);
  });

  test(
    'a new answer after Not interested waits while For You is open',
    () async {
      final server = FakeForYou([
        [s('a'), s('b'), s('c')],
        [s('c'), s('a')],
      ]);
      final m = vm(server);
      await pumpEventQueue();
      openForYou(m);
      m.hideForYou(m.recommended[1]);
      await pumpEventQueue();
      expect(server.calls, 2);
      expect(ids(m), ['a', 'c']);
      m.selectExploreTab(1);
      m.selectExploreTab(2);
      expect(ids(m), ['c', 'a']);
    },
  );

  test(
    'reloading unchanged bookmarks and Not interested asks nothing',
    () async {
      marks.toggle('s-b');
      await hidden.add('s-c');
      await pumpEventQueue(); // The bookmark write lands.
      final server = FakeForYou()..then = [s('a')];
      final m = vm(server);
      await pumpEventQueue();
      openForYou(m);
      expect(ids(m), ['a']);
      final before = server.calls;
      // Both reloads find the same documents (a new but equal set).
      await marks.load('u1');
      await hidden.load('u1');
      await pumpEventQueue();
      expect(marks.keys.value, {'s-b'});
      expect(hidden.keys.value, {'s-c'});
      expect(server.calls, before);
    },
  );

  test('a bookmark on another tab redraws For You at once', () async {
    final server = FakeForYou([
      [s('a'), s('b')],
    ])..then = null;
    final m = vm(server);
    await pumpEventQueue();
    m.selectTab(HomeTab.explore); // Latest
    expect(ids(m), ['a', 'b']);
    marks.toggle('s-a');
    expect(ids(m), ['b']);
  });

  test('pulling to refresh shows the new answer at once', () async {
    final server = FakeForYou([
      [s('a'), s('b')],
      [s('c')],
    ]);
    final m = vm(server);
    await pumpEventQueue();
    openForYou(m);
    expect(ids(m), ['a', 'b']);
    var notified = 0;
    m.addListener(() => notified++);
    await m.refreshDirectory();
    await pumpEventQueue();
    expect(ids(m), ['c']);
    expect(notified, greaterThan(0));
  });

  test(
    'a bookmark change during a request asks again once, after it',
    () async {
      final first = Completer<List<ForYouPick>?>();
      final server = FakeForYou([first.future])..then = [s('c')];
      final m = vm(server);
      await pumpEventQueue();
      expect(server.calls, 1);
      marks.toggle('s-b');
      await pumpEventQueue();
      marks.toggle('s-b');
      await pumpEventQueue();
      expect(server.calls, 1);
      first.complete([s('a')]);
      await pumpEventQueue();
      expect(server.calls, 2);
      expect(ids(m), ['c']);
    },
  );

  test('pulling to refresh joins a request already running', () async {
    final first = Completer<List<ForYouPick>?>();
    final server = FakeForYou([first.future])..then = [s('c')];
    final m = vm(server);
    await pumpEventQueue();
    expect(server.calls, 1);
    await m.refreshDirectory();
    first.complete([s('a')]);
    await pumpEventQueue();
    expect(server.calls, 1);
    expect(ids(m), ['a']);
  });

  test('a profile change joins a request already running', () async {
    final first = Completer<List<ForYouPick>?>();
    final server = FakeForYou([first.future])..then = [s('c')];
    final m = vm(server);
    await pumpEventQueue();
    m.setUser(investor('u1')); // Same user, edited profile.
    first.complete([s('a')]);
    await pumpEventQueue();
    expect(server.calls, 1);
    expect(ids(m), ['a']);
  });

  test('a new user during a request is asked for once it is done', () async {
    final first = Completer<List<ForYouPick>?>();
    final server = FakeForYou([first.future])..then = [s('c')];
    final m = vm(server, uid: 'u2');
    await pumpEventQueue();
    m.setUser(investor('u1'));
    first.complete([s('a')]);
    await pumpEventQueue();
    expect(server.calls, 2);
    expect(ids(m), ['c']);
  });

  test('quick changes send one request', () {
    fakeAsync((async) {
      final server = FakeForYou()..then = [s('a')];
      final m = HomeViewModel(
        role: SessionRole.investor,
        user: investor('u1'),
        forYou: server,
        forYouCache: ForYouCache(),
        notInterested: hidden,
        forYouQuietTime: const Duration(milliseconds: 50),
      );
      async.flushMicrotasks();
      final before = server.calls;
      marks.toggle('s-b');
      async.elapse(const Duration(milliseconds: 10));
      marks.toggle('s-c');
      async.elapse(const Duration(milliseconds: 10));
      marks.toggle('s-b');
      async.elapse(const Duration(milliseconds: 100));
      expect(server.calls, before + 1);
      m.dispose();
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('closing the page cancels a waiting request', () {
    fakeAsync((async) {
      final server = FakeForYou()..then = [s('a')];
      final m = HomeViewModel(
        role: SessionRole.investor,
        user: investor('u1'),
        forYou: server,
        forYouCache: ForYouCache(),
        notInterested: hidden,
        forYouQuietTime: const Duration(milliseconds: 50),
      );
      async.flushMicrotasks();
      final before = server.calls;
      marks.toggle('s-b');
      m.dispose();
      expect(async.pendingTimers, isEmpty);
      async.elapse(const Duration(milliseconds: 100));
      expect(server.calls, before);
    });
  });
}
