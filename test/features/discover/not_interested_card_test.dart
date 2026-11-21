import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/remote/for_you_api.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/for_you_cache.dart';
import 'package:startsa/data_access/repositories/not_interested_repository.dart';
import 'package:startsa/features/explore_startups/screens/explore_screen.dart';
import 'package:startsa/features/search/view_models/home_view_model.dart';
import 'package:startsa/features/search/widgets/home_layout.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';

class _FakeForYou implements ForYouSource {
  _FakeForYou(this.picks);

  final List<ForYouPick> picks;

  @override
  bool enabled = true;

  @override
  Future<List<ForYouPick>?> forYou() async => picks;

  @override
  Future<bool> profileText(HomeItemKind kind, String id) async => true;
}

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

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late _MemoryFirestore db;

  setUp(() {
    DiscoveryRepository.instance = DiscoveryRepository.sample(
      startups: [
        for (final (n, id) in const ['a', 'b', 'c'].indexed)
          PrototypeSeed.startups[n].copyWith(
            id: id,
            name: 'Startup $id',
            isPublic: true,
          ),
      ],
    );
    db = _MemoryFirestore();
    BookmarkRepository.instance = BookmarkRepository(firestore: db);
    AppSession.instance.reset();
    final user = AppUser(
      uid: 'u1',
      role: AccountRole.investor,
      fullName: 'Layan Test',
      email: 'u1@x.co',
    );
    AppSession.instance.signIn(user);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() => AppSession.instance.reset());

  Future<HomeViewModel> pumpForYou(WidgetTester t, List<String> order) async {
    t.view.physicalSize = const Size(1236, 2676);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final vm = HomeViewModel(
      role: SessionRole.investor,
      user: AppSession.instance.user,
      forYou: _FakeForYou([
        for (final id in order) ForYouPick(id, HomeItemKind.startup, 0.5),
      ]),
      forYouCache: ForYouCache(),
      notInterested: NotInterestedRepository(firestore: db),
      forYouQuietTime: Duration.zero,
    );
    addTearDown(vm.dispose);
    await t.pumpAndSettle();
    vm
      ..selectTab(HomeTab.explore)
      ..selectExploreTab(2);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: vm,
            builder: (context, _) => SingleChildScrollView(
              child: ExploreScreen(viewModel: vm, onSignUp: () {}),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    return vm;
  }

  List<String> ids(HomeViewModel vm) => [for (final i in vm.recommended) i.id];

  testWidgets('For You cards have a Not interested button; other lists '
      'don\'t', (t) async {
    final items = DiscoveryRepository.instance
        .recommendedStartups(investorId: 'u1', bookmarks: const {})
        .take(2)
        .toList();
    expect(items, hasLength(2));

    Future<void> pumpSlot(void Function(HomeItem)? onNotInterested) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeColumn(
                slots: [cardsSlot(items, onNotInterested: onNotInterested)],
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    await pumpSlot((_) {});
    expect(find.bySemanticsLabel('Not interested'), findsNWidgets(2));
    await pumpSlot(null);
    expect(find.bySemanticsLabel('Not interested'), findsNothing);
  });

  testWidgets('tapping it hides the card and Undo brings it back', (t) async {
    final vm = await pumpForYou(t, ['a', 'b', 'c']);
    expect(ids(vm), ['a', 'b', 'c']);

    await t.tap(find.bySemanticsLabel('Not interested').at(1));
    await t.pumpAndSettle();
    expect(find.text('Startup b'), findsNothing);
    expect(find.text('Hidden from For You'), findsOneWidget);
    expect(ids(vm), ['a', 'c']);
    expect(db.store['users/u1/notInterested'], contains('s-b'));

    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(ids(vm), ['a', 'b', 'c']);
    expect(
      t.getTopLeft(find.text('Startup b')).dy,
      greaterThan(t.getTopLeft(find.text('Startup a')).dy),
    );
    expect(
      t.getTopLeft(find.text('Startup b')).dy,
      lessThan(t.getTopLeft(find.text('Startup c')).dy),
    );
    expect(db.store['users/u1/notInterested'] ?? {}, isNot(contains('s-b')));
  });

  testWidgets('a second hide replaces the message; Undo restores only the '
      'latest', (t) async {
    final vm = await pumpForYou(t, ['a', 'b', 'c']);
    await t.tap(find.bySemanticsLabel('Not interested').at(0));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Not interested').at(0));
    await t.pumpAndSettle();
    expect(ids(vm), ['c']);
    expect(find.text('Hidden from For You'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(ids(vm), ['b', 'c']);
  });
}
