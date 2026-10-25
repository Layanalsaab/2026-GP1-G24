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
import 'package:startsa/features/startups/screens/my_startups_screen.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/headers/tabbed_header.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import '../../support/fakes.dart';

Future<void> _open(
  WidgetTester t, {
  StartupRole role = StartupRole.founder,
  VoidCallback? onLeave,
  String tab = 'Settings',
}) async {
  t.view.physicalSize = const Size(1236, 2676);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      navigatorKey: AppToast.navigatorKey,
      home: ManageStartupScreen(
        startup: PrototypeSeed.rafeeq,
        role: role,
        onLeave: onLeave,
      ),
    ),
  );
  await t.pumpAndSettle();
  final target = find.descendant(
    of: find.byType(ScrollableHeaderTabBar),
    matching: find.text(tab),
  );
  await t.ensureVisible(target);
  await t.pumpAndSettle();
  await t.tap(target);
  await t.pumpAndSettle();
}

/// Test-only memberships (they used to be built-in sample data): Naql as
/// co-founder, Mizan Learn as team member.
final _teamStartups = [
  MyStartupEntry(
    startup: PrototypeSeed.naql,
    role: StartupRole.coFounder,
    addedAt: DateTime(2026, 10, 14),
  ),
  MyStartupEntry(
    startup: PrototypeSeed.mizan,
    role: StartupRole.member,
    addedAt: DateTime(2026, 9, 2),
  ),
];

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

  group('Settings tab', () {
    testWidgets('founder: Public profile and Delete, no Leave', (t) async {
      await _open(t);
      expect(find.text('Public profile'), findsOneWidget);
      expect(find.text('Delete startup'), findsOneWidget);
      expect(find.text('Leave startup'), findsNothing);
      expect(
        find.text('Removes the startup and all its requests'),
        findsOneWidget,
      );
    });

    testWidgets('co-founder: Public profile and Leave, no Delete', (t) async {
      await _open(t, role: StartupRole.coFounder);
      expect(find.text('Public profile'), findsOneWidget);
      expect(find.text('Delete startup'), findsNothing);
      expect(find.text('Leave startup'), findsOneWidget);
      expect(
        find.text('You’ll stop being a co-founder of this startup'),
        findsOneWidget,
      );
    });

    testWidgets('team member: only Leave', (t) async {
      await _open(t, role: StartupRole.member);
      expect(find.text('Public profile'), findsNothing);
      expect(find.text('Delete startup'), findsNothing);
      expect(find.text('Leave startup'), findsOneWidget);
      expect(
        find.text('You’ll be removed from this startup’s team'),
        findsOneWidget,
      );
    });

    testWidgets('Leave asks, then removes the user and goes back', (t) async {
      var left = false;
      await _open(t, role: StartupRole.coFounder, onLeave: () => left = true);
      await t.tap(find.text('Leave startup'));
      await t.pumpAndSettle();
      expect(find.text('Leave Rafeeq Health?'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(left, isFalse);
      await t.tap(find.text('Leave startup'));
      await t.pumpAndSettle();
      await t.tap(find.text('Leave startup').last);
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(left, isTrue);
      expect(find.text('You left Rafeeq Health'), findsOneWidget);
      await t.pump(const Duration(seconds: 4));
    });

    testWidgets('Delete removes the startup, its requests and its interest', (
      t,
    ) async {
      final requests = RequestRepository.instance;
      final interests = InterestRepository.instance;
      expect(requests.inboxFor('mock-rafeeq'), isNotEmpty);
      expect(interests.inboxFor('mock-rafeeq'), isNotEmpty);
      await _open(t);
      await t.tap(find.text('Delete startup'));
      await t.pumpAndSettle();
      expect(find.text('Delete Rafeeq Health?'), findsOneWidget);
      await t.tap(find.text('Delete startup').last);
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(requests.inboxFor('mock-rafeeq'), isEmpty);
      expect(interests.inboxFor('mock-rafeeq'), isEmpty);
      final repo = StartupRepository.instance as FakeStartupRepository;
      expect(repo.startups, isEmpty);
      await t.pump(const Duration(seconds: 4));
    });
  });

  group('Requests and Interest', () {
    testWidgets('a founder sees Accept and Decline', (t) async {
      await _open(t, tab: 'Requests');
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('a team member sees the requests without the buttons', (
      t,
    ) async {
      await _open(t, role: StartupRole.member, tab: 'Requests');
      expect(find.text('Pending · 1'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Decline'), findsNothing);
    });

    testWidgets('a team member sees interest without the reply button', (
      t,
    ) async {
      await _open(t, role: StartupRole.member, tab: 'Interest');
      expect(find.text('Noura Alharbi'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Reply')), findsNothing);
    });
  });

  testWidgets('leaving from Manage removes it from My Startups', (t) async {
    t.view.physicalSize = const Size(1236, 2676);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        navigatorKey: AppToast.navigatorKey,
        home: MyStartupsScreen(teamStartups: _teamStartups),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Naql'), findsOneWidget); // the co-founder sample
    await t.tap(find.text('Naql'));
    await t.pumpAndSettle();
    final settings = find.descendant(
      of: find.byType(ScrollableHeaderTabBar),
      matching: find.text('Settings'),
    );
    await t.ensureVisible(settings);
    await t.pumpAndSettle();
    await t.tap(settings);
    await t.pumpAndSettle();
    await t.tap(find.text('Leave startup'));
    await t.pumpAndSettle();
    await t.tap(find.text('Leave startup').last);
    await t.pump();
    await t.pump(const Duration(milliseconds: 600));
    await t.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('Naql'), findsNothing);
    expect(find.text('Mizan Learn'), findsOneWidget);
  });
}
