import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/interaction_repository.dart';
import 'package:startsa/features/explore_startups/screens/explore_screen.dart';
import 'package:startsa/features/search/view_models/home_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/cards/home_card.dart';

/// Startups served as documents for [DiscoveryRepository.refresh].
class _Docs extends FirestoreService {
  _Docs(this.startups);

  final Map<String, Map<String, Object?>> startups;

  @override
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async => [
    for (final e in startups.entries)
      (id: e.key, data: Map<String, dynamic>.from(e.value)),
  ];

  @override
  Future<List<FirestoreDocument>> listCollection(
    String collection, {
    int limit = 100,
  }) async => const [];
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<HomeViewModel> pump(
    WidgetTester t, {
    SessionRole role = SessionRole.investor,
    Map<String, DateTime> startups = const {},
    bool sample = false,
    int tab = 0,
  }) async {
    t.view.physicalSize = const Size(1236, 2676);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    if (sample) {
      DiscoveryRepository.instance = DiscoveryRepository.sample();
    } else {
      final repo = DiscoveryRepository(
        firestore: _Docs({
          for (final e in startups.entries)
            e.key: {
              ...PrototypeSeed.rafeeq.toMap(),
              'name': 'Startup ${e.key}',
              'isPublic': true,
              'createdAt': e.value,
            },
        }),
      );
      await repo.refresh();
      DiscoveryRepository.instance = repo;
    }
    InteractionRepository.instance = InteractionRepository();
    final vm = HomeViewModel(role: role)
      ..selectTab(HomeTab.explore)
      ..selectExploreTab(tab);
    addTearDown(vm.dispose);
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

  testWidgets('Latest: the newest startups with their "Joined" line', (t) async {
    final now = DateTime.now();
    await pump(
      t,
      startups: {
        'a': now.subtract(const Duration(days: 2)),
        'b': now,
        'c': now.subtract(const Duration(days: 40)),
      },
    );
    expect(find.text('Newest startups'), findsOneWidget);
    expect(find.text('Last week'), findsOneWidget);
    expect(find.byType(HomeCard), findsNWidgets(2));
    // Newest first.
    expect(
      t.getTopLeft(find.text('Startup b')).dy,
      lessThan(t.getTopLeft(find.text('Startup a')).dy),
    );
    expect(find.text('Joined today'), findsOneWidget);
    expect(find.text('Joined 2 days ago'), findsOneWidget);
    // No percentage on a Latest card.
    expect(find.textContaining('% match'), findsNothing);
  });

  testWidgets('Latest: the dropdown goes further back', (t) async {
    final now = DateTime.now();
    await pump(t, startups: {'c': now.subtract(const Duration(days: 40))});
    expect(find.text('No new startups'), findsOneWidget);
    expect(
      find.text('No startups joined in this time range. Try a longer one.'),
      findsOneWidget,
    );
    await t.tap(find.text('Last week'));
    await t.pumpAndSettle();
    for (final o in ['Last 3 months', 'Last 6 months', 'Last year']) {
      expect(find.text(o), findsOneWidget);
    }
    await t.tap(find.text('Last 3 months'));
    await t.pumpAndSettle();
    expect(find.text('Joined 1 month ago'), findsOneWidget);
    expect(find.text('No new startups'), findsNothing);
  });

  testWidgets('Trending: standard cards, rank and growth, the (i) button', (
    t,
  ) async {
    await pump(t, sample: true, tab: 1);
    expect(find.text('Top 30 trending'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.byType(HomeCard), findsWidgets);
    expect(find.text('#1 · +38%'), findsOneWidget);
    expect(find.text('more views than last week'), findsWidgets);
    final tip =
        'Based on profile views in the last 7 days. The more a profile’s '
        'views grew compared with the previous period, the higher it ranks.';
    expect(find.text(tip), findsNothing);
    await t.tap(find.bySemanticsLabel('About this list'));
    await t.pumpAndSettle();
    expect(find.text(tip), findsOneWidget);
    await t.tap(find.bySemanticsLabel('About this list'));
    await t.pumpAndSettle();
    expect(find.text(tip), findsNothing);
  });

  testWidgets('For You (investor): startups, no switch, no New section', (
    t,
  ) async {
    await pump(t, sample: true, tab: 2);
    expect(find.text('Recommended startups for you'), findsOneWidget);
    expect(find.text('New on Start.sa'), findsNothing);
    expect(find.text('Raising now'), findsNothing);
    expect(find.text('Investors backing'), findsNothing);
    // The Startups | Investors switch is gone.
    expect(find.text('Investors'), findsNothing);
    expect(find.byType(HomeCard), findsWidgets);
    await t.tap(find.bySemanticsLabel('About this list'));
    await t.pumpAndSettle();
    expect(
      find.text(
        'Based on your investment criteria: the sectors, stages and commerce '
        'models you want to invest in, and how much you usually invest.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('For You (founder): investors, with their own (i) text', (
    t,
  ) async {
    await pump(t, sample: true, role: SessionRole.founder, tab: 2);
    expect(find.text('Recommended investors for you'), findsOneWidget);
    expect(find.text('Startups'), findsNothing);
    await t.tap(find.bySemanticsLabel('About this list'));
    await t.pumpAndSettle();
    expect(
      find.textContaining('Based on your startup: its sector, stage'),
      findsOneWidget,
    );
  });

  testWidgets('searching turns any tab into the results view', (t) async {
    final vm = await pump(t, sample: true);
    vm.setQuery('a');
    await t.pumpAndSettle();
    expect(find.text('Newest startups'), findsNothing);
    expect(find.text('Results'), findsOneWidget);
  });
}
