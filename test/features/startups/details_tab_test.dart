import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/activity_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/interest_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/startups/screens/manage_startup_screen.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/headers/tabbed_header.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import '../../support/fakes.dart';

const _sections = [
  'Overview',
  'Startup Description',
  'Target Market',
  'Finance and Growth',
  'Startup Ask',
  'Startup Team',
];

Future<void> _openDetails(
  WidgetTester t, {
  StartupRole role = StartupRole.founder,
}) async {
  t.view.physicalSize = const Size(1236, 2676);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      navigatorKey: AppToast.navigatorKey,
      home: ManageStartupScreen(startup: PrototypeSeed.rafeeq, role: role),
    ),
  );
  await t.pumpAndSettle();
  final tab = find.descendant(
    of: find.byType(ScrollableHeaderTabBar),
    matching: find.text('Details'),
  );
  await t.tap(tab);
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    StartupRepository.instance = FakeStartupRepository()
      ..startups.add(PrototypeSeed.rafeeq);
    UserRepository.instance = FakeUserRepository();
    RequestRepository.instance = RequestRepository(sample: true);
    InterestRepository.instance = InterestRepository(sample: true);
    ActivityRepository.instance = ActivityRepository(sample: true);
    DiscoveryRepository.instance = DiscoveryRepository.sample();
    AppSession.instance = AppSession();
  });

  testWidgets('six sections in order, closed, no Edit pill yet', (t) async {
    await _openDetails(t);
    var lastY = -1.0;
    for (final title in _sections) {
      final y = t.getTopLeft(find.text(title)).dy;
      expect(y, greaterThan(lastY), reason: title);
      lastY = y;
    }
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('only one section is open at a time and shows its answers', (
    t,
  ) async {
    await _openDetails(t);
    await t.tap(find.text('Startup Description'));
    await t.pumpAndSettle();
    expect(find.text('What problem does your startup solve?'), findsOneWidget);
    expect(find.text('What is your solution?'), findsOneWidget);
    expect(find.text('What makes your startup unique?'), findsOneWidget);
    await t.ensureVisible(find.text('Target Market'));
    await t.pumpAndSettle();
    await t.tap(find.text('Target Market'));
    await t.pumpAndSettle();
    expect(find.text('What problem does your startup solve?'), findsNothing);
    expect(find.text('Who are your target customers?'), findsOneWidget);
  });

  testWidgets('the Edit pill opens only that section, filled in', (t) async {
    await _openDetails(t);
    await t.tap(find.text('Startup Description'));
    await t.pumpAndSettle();
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    expect(find.text('EDIT STARTUP'), findsOneWidget);
    expect(find.text('Startup Description'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.textContaining('STEP'), findsNothing);
    // Pre-filled with the saved problem.
    expect(
      find.widgetWithText(TextField, PrototypeSeed.rafeeq.problem),
      findsOneWidget,
    );
  });

  testWidgets('Back with no change leaves without asking', (t) async {
    await _openDetails(t);
    await t.tap(find.text('Startup Description'));
    await t.pumpAndSettle();
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    await t.tap(find.bySemanticsLabel('Back').first);
    await t.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('EDIT STARTUP'), findsNothing);
  });

  testWidgets('Back after a change asks, then Discard or Keep editing', (
    t,
  ) async {
    await _openDetails(t);
    await t.tap(find.text('Startup Description'));
    await t.pumpAndSettle();
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    await t.enterText(
      find.widgetWithText(TextField, PrototypeSeed.rafeeq.problem),
      'A different problem',
    );
    await t.pump();
    await t.tap(find.bySemanticsLabel('Back').first);
    await t.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await t.tap(find.text('Keep editing'));
    await t.pumpAndSettle();
    expect(find.text('EDIT STARTUP'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('Back').first);
    await t.pumpAndSettle();
    await t.tap(find.text('Discard'));
    await t.pumpAndSettle();
    expect(find.text('EDIT STARTUP'), findsNothing);
    expect(find.text('A different problem'), findsNothing);
  });

  testWidgets('Save writes the change and Details shows it', (t) async {
    await _openDetails(t);
    await t.tap(find.text('Startup Description'));
    await t.pumpAndSettle();
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    await t.enterText(
      find.widgetWithText(TextField, PrototypeSeed.rafeeq.problem),
      'Nurses are hard to book',
    );
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('EDIT STARTUP'), findsNothing);
    expect(find.text('Nurses are hard to book'), findsWidgets);
    final repo = StartupRepository.instance as FakeStartupRepository;
    expect(repo.startups.single.problem, 'Nurses are hard to book');
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('a team member sees the sections but no Edit pill', (t) async {
    await _openDetails(t, role: StartupRole.member);
    expect(find.text('Edit'), findsNothing);
    await t.tap(find.text('Overview'));
    await t.pumpAndSettle();
    expect(find.text('Sector'), findsOneWidget);
  });

  testWidgets('the two Finance boxes are the same height, label on top', (
    t,
  ) async {
    // A narrow phone makes "Current company valuation" wrap to two lines.
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        navigatorKey: AppToast.navigatorKey,
        home: ManageStartupScreen(startup: PrototypeSeed.rafeeq),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(ScrollableHeaderTabBar),
        matching: find.text('Details'),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('Finance and Growth'));
    await t.pumpAndSettle();
    Size box(String label) => t.getSize(
      find
          .ancestor(of: find.text(label), matching: find.byType(Container))
          .first,
    );
    // Revenue and capital are in the same row: same height, labels on top.
    final revenue = box('Current financial year revenue');
    final capital = box('Current available capital');
    expect(revenue.height, capital.height);
    expect(
      t.getTopLeft(find.text('Current financial year revenue')).dy,
      t.getTopLeft(find.text('Current available capital')).dy,
    );
    // Every box of Finance and Growth is there.
    for (final label in [
      'Monthly burn rate',
      'Runway',
      'Current company valuation',
      'Explain your business model',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('Finance and Growth edits only its half, Startup Ask the other', (
    t,
  ) async {
    await _openDetails(t);
    await t.tap(find.text('Finance and Growth'));
    await t.pumpAndSettle();
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    expect(find.text('EDIT STARTUP'), findsOneWidget);
    expect(find.text('Finance and Growth'), findsOneWidget);
    expect(
      find.textContaining('Current available capital', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('lead investor', findRichText: true),
      findsNothing,
    );
    await t.tap(find.bySemanticsLabel('Back').first);
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Startup Ask'));
    await t.pumpAndSettle();
    await t.tap(find.text('Startup Ask'));
    await t.pumpAndSettle();
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    expect(find.text('Startup Ask'), findsOneWidget);
    expect(
      find.textContaining('lead investor', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Current available capital', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('saving a section says "Changes saved"', (t) async {
    await _openDetails(t);
    await t.tap(find.text('Startup Description'));
    await t.pumpAndSettle();
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    await t.enterText(
      find.widgetWithText(TextField, PrototypeSeed.rafeeq.problem),
      'Another problem',
    );
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Changes saved'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
  });
}
