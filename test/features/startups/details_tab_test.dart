import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/activity_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/funding_round_repository.dart';
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
  'Startup Overview',
  'Startup Description',
  'Target Market',
  'Finance and Growth',
  'Startup Team',
  'Startup Ask',
];

/// A tab of the Manage header (the bar scrolls sideways).
Finder _tab(String label) => find.descendant(
  of: find.byType(ScrollableHeaderTabBar),
  matching: find.text(label),
);

/// Opens Manage startup on Rafeeq Health, then the step tab [tab] (the six
/// steps of the form are tabs now; there is no Details tab any more).
Future<void> _openStep(
  WidgetTester t,
  String tab, {
  StartupRole role = StartupRole.founder,
  Size size = const Size(1236, 2676),
}) async {
  t.view.physicalSize = size;
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
  await _goTo(t, tab);
}

Future<void> _goTo(WidgetTester t, String tab) async {
  await t.ensureVisible(_tab(tab));
  await t.pumpAndSettle();
  await t.tap(_tab(tab));
  await t.pumpAndSettle();
}

/// The step's Edit link (at the right of the card's title).
Future<void> _edit(WidgetTester t) async {
  await t.ensureVisible(find.text('Edit'));
  await t.pumpAndSettle();
  await t.tap(find.text('Edit'));
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
    FundingRoundRepository.instance = FundingRoundRepository.sample();
    AppSession.instance = AppSession();
  });

  testWidgets('the six steps are tabs, in order, between EOI and Settings', (
    t,
  ) async {
    await _openStep(t, 'Dashboard');
    var lastX = t.getTopLeft(_tab('EOI')).dx;
    for (final title in _sections) {
      final x = t.getTopLeft(_tab(title)).dx;
      expect(x, greaterThan(lastX), reason: title);
      lastX = x;
    }
    expect(t.getTopLeft(_tab('Settings')).dx, greaterThan(lastX));
    // No Details tab any more.
    expect(_tab('Details'), findsNothing);
  });

  testWidgets('each step tab shows its answers with one Edit link', (t) async {
    await _openStep(t, 'Startup Description');
    expect(find.text('What problem does your startup solve?'), findsOneWidget);
    expect(find.text('What is your solution?'), findsOneWidget);
    expect(find.text('What makes your startup unique?'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    await _goTo(t, 'Target Market');
    expect(find.text('What problem does your startup solve?'), findsNothing);
    expect(find.text('Who are your target customers?'), findsOneWidget);
  });

  testWidgets('the Edit link opens only that section, filled in', (t) async {
    await _openStep(t, 'Startup Description');
    await _edit(t);
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
    await _openStep(t, 'Startup Description');
    await _edit(t);
    await t.tap(find.bySemanticsLabel('Back').first);
    await t.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('EDIT STARTUP'), findsNothing);
  });

  testWidgets('Back after a change asks, then Discard or Keep editing', (
    t,
  ) async {
    await _openStep(t, 'Startup Description');
    await _edit(t);
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

  testWidgets('Save writes the change and the step tab shows it', (t) async {
    await _openStep(t, 'Startup Description');
    await _edit(t);
    await t.enterText(
      find.widgetWithText(TextField, PrototypeSeed.rafeeq.problem),
      'Nurses are hard to book',
    );
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    expect(find.text('Save changes?'), findsOneWidget);
    await t.tap(find.text('Save changes'));
    await t.pumpAndSettle();
    expect(find.text('EDIT STARTUP'), findsNothing);
    expect(find.text('Nurses are hard to book'), findsWidgets);
    final repo = StartupRepository.instance as FakeStartupRepository;
    expect(repo.startups.single.problem, 'Nurses are hard to book');
    await t.pump(const Duration(seconds: 4));
  });

  testWidgets('a team member sees the steps but no Edit link', (t) async {
    await _openStep(t, 'Startup Overview', role: StartupRole.member);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Sector'), findsOneWidget);
  });

  testWidgets('the two Finance boxes are the same height, label on top', (
    t,
  ) async {
    // A narrow phone makes "Current company valuation" wrap to two lines.
    await _openStep(t, 'Finance and Growth', size: const Size(1080, 2400));
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
      'Revenue model',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('Finance and Growth edits only its half, Startup Ask the other', (
    t,
  ) async {
    await _openStep(t, 'Finance and Growth');
    await _edit(t);
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
    await _goTo(t, 'Startup Ask');
    await _edit(t);
    expect(find.text('Startup Ask'), findsOneWidget);
    expect(
      find.textContaining('lead investor', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining('Current available capital', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('saving a section says "Changes saved"', (t) async {
    await _openStep(t, 'Startup Description');
    await _edit(t);
    await t.enterText(
      find.widgetWithText(TextField, PrototypeSeed.rafeeq.problem),
      'Another problem',
    );
    await t.pump();
    await t.tap(find.text('Save'));
    await t.pumpAndSettle();
    await t.tap(find.text('Save changes'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('Changes saved'), findsOneWidget);
    await t.pump(const Duration(seconds: 4));
  });
}
