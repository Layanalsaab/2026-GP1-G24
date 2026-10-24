import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/bookmarks/screens/bookmarks_screen.dart';
import 'package:startsa/features/startups/screens/my_startups_screen.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/headers/list_screen_header.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import '../../support/fakes.dart';

Future<void> _pump(WidgetTester t, Widget home) async {
  await t.binding.setSurfaceSize(const Size(412, 892));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      navigatorKey: AppToast.navigatorKey,
      home: home,
    ),
  );
  await t.pump(const Duration(milliseconds: 800));
}

/// A few saved items for the screen (the screen itself has no sample list).
final _saved = [
  SavedBookmark(
    item: HomeItem.fromStartup(PrototypeSeed.rafeeq),
    savedAt: DateTime(2026, 10, 20),
  ),
  SavedBookmark(
    item: HomeItem.fromInvestor(PrototypeSeed.sara),
    savedAt: DateTime(2026, 10, 18),
  ),
  SavedBookmark(
    item: HomeItem.fromProgram(PrototypeSeed.programs.first),
    savedAt: DateTime(2026, 10, 15),
  ),
];

/// Opens a bottom sheet from a pill and lets it finish sliding in.
Future<void> _tapPill(WidgetTester t, String label) async {
  await t.tap(find.text(label));
  await t.pump(const Duration(milliseconds: 100));
  await t.pump(const Duration(milliseconds: 600));
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => StartupRepository.instance = FakeStartupRepository());

  group('Bookmarks', () {
    testWidgets('shows the saved cards, the pills and no count line', (
      t,
    ) async {
      await _pump(t, BookmarksScreen(items: _saved));
      expect(find.text('Bookmarks'), findsOneWidget);
      expect(find.text('All types'), findsOneWidget);
      expect(find.text('Newest first'), findsOneWidget);
      expect(find.textContaining('saved'), findsNothing);
      expect(find.text('Rafeeq Health'), findsOneWidget);
    });

    testWidgets('the type filter narrows the list and goes gold', (t) async {
      await _pump(t, BookmarksScreen(items: _saved));
      await _tapPill(t, 'All types');
      expect(find.text('Filter by type'), findsOneWidget);
      for (final o in [
        'All types',
        'Startups',
        'Investors',
        'Support Channels',
      ]) {
        expect(find.text(o), findsWidgets);
      }
      await t.tap(find.text('Investors').last);
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Rafeeq Health'), findsNothing);
      expect(find.text(PrototypeSeed.sara.name), findsOneWidget);
    });

    testWidgets('removing the last card of a type shows the small card', (
      t,
    ) async {
      await _pump(
        t,
        BookmarksScreen(items: [_saved.first]),
      );
      // Only a startup is saved: filter to investors.
      await _tapPill(t, 'All types');
      await t.tap(find.text('Investors').last);
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('No saved investors yet.'), findsOneWidget);
      await t.tap(find.text('Show all bookmarks'));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Rafeeq Health'), findsOneWidget);
    });

    testWidgets('nothing saved shows the empty card and no pills', (t) async {
      var explored = false;
      await _pump(
        t,
        BookmarksScreen(items: const [], onExplore: () => explored = true),
      );
      expect(find.text('No bookmarks yet'), findsOneWidget);
      expect(find.text('All types'), findsNothing);
      await t.tap(find.text('Explore'));
      expect(explored, isTrue);
    });
  });

  group('My Startups', () {
    testWidgets('team-member startups show a tag and View', (t) async {
      await _pump(t, const MyStartupsScreen());
      expect(find.text('My Startups'), findsOneWidget);
      expect(find.text('All startups'), findsOneWidget);
      expect(find.text('Newest first'), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'^\d+ startups?$')),
        findsNothing,
        reason: 'no count line under the title',
      );
      expect(find.text('Team member'), findsWidgets);
      expect(find.text('View'), findsWidgets);
    });

    testWidgets('the filter sheet applies at once and stays open', (t) async {
      await _pump(t, const MyStartupsScreen());
      await _tapPill(t, 'All startups');
      expect(find.text('Filter startups'), findsOneWidget);
      expect(find.text('VISIBILITY'), findsOneWidget);
      expect(find.text('MY ROLE'), findsOneWidget);
      // Founder: no sample founder startup, so nothing matches.
      await t.tap(find.text('Founder').last);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Filter startups'), findsOneWidget);
      await t.tap(find.text('Done'));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('No startups match these filters.'), findsOneWidget);
      // The pill shows the single active option.
      expect(find.text('Founder'), findsOneWidget);
      await t.tap(find.text('Show all startups'));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('All startups'), findsOneWidget);
      expect(find.text('Team member'), findsWidgets);
    });

    testWidgets('both banners have exactly the same height', (t) async {
      await _pump(t, BookmarksScreen(items: _saved));
      final bookmarks = t.getSize(find.byType(ListScreenHeader)).height;
      await _pump(t, const MyStartupsScreen());
      final mine = t.getSize(find.byType(ListScreenHeader)).height;
      expect(mine, bookmarks);
    });
  });
}
