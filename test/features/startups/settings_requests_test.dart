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
import 'package:startsa/features/startups/screens/my_startups_screen.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/connection_request.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/headers/tabbed_header.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import '../../support/fakes.dart';

Future<void> _open(
  WidgetTester t, {
  StartupRole role = StartupRole.founder,
  VoidCallback? onLeave,
  String tab = 'Settings',
  Startup? startup,
}) async {
  t.view.physicalSize = const Size(1236, 2676);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      navigatorKey: AppToast.navigatorKey,
      home: ManageStartupScreen(
        startup: startup ?? PrototypeSeed.rafeeq,
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

/// Leave startup sits at the bottom of the Details tab: bring it into view.
Future<void> _toLeave(WidgetTester t) async {
  await t.ensureVisible(find.text('Leave startup'));
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
    FundingRoundRepository.instance = FundingRoundRepository.sample();
    AppSession.instance = AppSession();
  });

  group('Settings tab', () {
    testWidgets('owner: Public startup and Close, no Leave, no Delete', (
      t,
    ) async {
      await _open(t);
      expect(find.text('Public startup'), findsOneWidget);
      expect(find.text('Close startup'), findsOneWidget);
      expect(
        find.text(
          'Permanently closes the startup so it can no longer be edited, while your team keeps access.',
        ),
        findsOneWidget,
      );
      // Leave startup is in Details, not here.
      expect(find.text('Leave startup'), findsNothing);
      expect(find.text('Delete startup'), findsNothing);
      expect(find.text('Transfer ownership'), findsNothing);
    });

    testWidgets('the visibility title follows the switch', (t) async {
      await _open(t);
      const publicText =
          'Anyone on Start.sa can find this startup in the Hub and Explore.';
      const privateText =
          'Only your team can see this startup. It won’t appear in the Hub or Explore.';
      expect(find.text('Public startup'), findsOneWidget);
      expect(find.text(publicText), findsOneWidget);
      expect(find.text('Private startup'), findsNothing);
      await t.tap(find.text('Public startup'));
      await t.pumpAndSettle();
      expect(find.text('Private startup'), findsOneWidget);
      expect(find.text(privateText), findsOneWidget);
      expect(find.text('Public startup'), findsNothing);
      expect(find.text('Public profile'), findsNothing);
      expect(find.text('Private profile'), findsNothing);
      await t.tap(find.text('Private startup'));
      await t.pumpAndSettle();
      expect(find.text('Public startup'), findsOneWidget);
      expect(find.text(publicText), findsOneWidget);
    });

    testWidgets('co-founder: Public startup, no Close, no Leave here', (
      t,
    ) async {
      await _open(t, role: StartupRole.coFounder);
      expect(find.text('Public startup'), findsOneWidget);
      expect(find.text('Close startup'), findsNothing);
      expect(find.text('Leave startup'), findsNothing);
    });

    testWidgets('team member: nothing to change in Settings', (t) async {
      await _open(t, role: StartupRole.member);
      expect(find.text('Public startup'), findsNothing);
      expect(find.text('Close startup'), findsNothing);
      expect(find.text('Leave startup'), findsNothing);
      expect(find.text('There is nothing to change here.'), findsOneWidget);
    });

    testWidgets('Details: Leave startup under the sections', (t) async {
      await _open(t, tab: 'Startup Team');
      await _toLeave(t);
      expect(find.text('Leave startup'), findsOneWidget);
      expect(
        find.text('Choose who will take over as owner before you leave.'),
        findsOneWidget,
      );
    });

    testWidgets('Details: co-founder and team member can leave', (t) async {
      await _open(t, role: StartupRole.coFounder, tab: 'Startup Team');
      await _toLeave(t);
      expect(
        find.text('You will no longer be a co-founder of this startup'),
        findsOneWidget,
      );
    });

    testWidgets('Details: a team member sees Leave too', (t) async {
      await _open(t, role: StartupRole.member, tab: 'Startup Team');
      await _toLeave(t);
      expect(
        find.text('You will no longer be on this startup’s team'),
        findsOneWidget,
      );
    });

    testWidgets('a closed startup: its owner only has the visibility switch', (
      t,
    ) async {
      await _open(
        t,
        startup: PrototypeSeed.rafeeq.copyWith(
          isClosed: true,
          isPublic: true,
          memberRoles: const {'sample-faisal': 'member'},
        ),
      );
      expect(find.text('Public startup'), findsOneWidget);
      expect(
        find.text('Shown in the Hub as a closed startup.'),
        findsOneWidget,
      );
      expect(find.text('Close startup'), findsNothing);
      expect(find.text('Leave startup'), findsNothing);
      expect(
        find.text(
          'You closed this startup. It cannot be edited or reopened, but you can still choose whether it appears in the Hub.',
        ),
        findsOneWidget,
      );
      await t.tap(find.text('Public startup'));
      await t.pumpAndSettle();
      expect(find.text('Private startup'), findsOneWidget);
      expect(find.text('Visible only to its team.'), findsOneWidget);
      final repo = StartupRepository.instance as FakeStartupRepository;
      expect(repo.closedVisibility, [('mock-rafeeq', false)]);
      await t.pump(const Duration(seconds: 4));
    });

    testWidgets('a closed startup: a team member can change nothing', (
      t,
    ) async {
      await _open(
        t,
        role: StartupRole.member,
        startup: PrototypeSeed.rafeeq.copyWith(isClosed: true),
      );
      expect(find.text('Leave startup'), findsNothing);
      expect(find.text('Public startup'), findsNothing);
      expect(
        find.text(
          'This startup is closed, so there is nothing to change here.',
        ),
        findsOneWidget,
      );
      expect(find.text('This startup has been closed.'), findsOneWidget);
    });

    testWidgets('Leave asks, then removes the user and goes back', (t) async {
      var left = false;
      await _open(
        t,
        role: StartupRole.coFounder,
        onLeave: () => left = true,
        tab: 'Startup Team',
      );
      await _toLeave(t);
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

    testWidgets('the owner alone is asked to invite the next owner', (t) async {
      await _open(t, tab: 'Startup Team');
      await _toLeave(t);
      await t.tap(find.text('Leave startup'));
      await t.pumpAndSettle();
      // One sheet: what happens next and the e-mail.
      expect(find.text('Invite a new owner'), findsOneWidget);
      expect(
        find.textContaining('There is no one else on Rafeeq Health’s team.'),
        findsOneWidget,
      );
      expect(find.text('Send invitation'), findsOneWidget);
      await t.tap(find.text('Cancel').last);
      await t.pumpAndSettle();
      expect(find.text('Invite a new owner'), findsNothing);
    });

    testWidgets('the owner names a joined member the next owner', (t) async {
      await _open(
        t,
        startup: PrototypeSeed.rafeeq.copyWith(
          memberRoles: const {'sample-faisal': 'member'},
        ),
        tab: 'Startup Team',
      );
      await _toLeave(t);
      await t.tap(find.text('Leave startup'));
      await t.pumpAndSettle();
      // A card for every joined person, then "Invite someone new".
      expect(find.text('Choose the next owner'), findsOneWidget);
      expect(
        find.text('Select who will manage Rafeeq Health after you leave.'),
        findsOneWidget,
      );
      expect(find.text('Invite someone new'), findsOneWidget);
      await t.tap(find.text('Faisal Alkhaldi'));
      await t.pumpAndSettle();
      expect(
        find.text('Make Faisal Alkhaldi the owner of Rafeeq Health?'),
        findsOneWidget,
      );
      await t.tap(find.text('Make Faisal Alkhaldi the owner'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      final repo = StartupRepository.instance as FakeStartupRepository;
      expect(repo.transfers, [('mock-rafeeq', 'sample-faisal')]);
      await t.pump(const Duration(seconds: 4));
    });

    testWidgets('Close asks, then closes it and declines waiting requests', (
      t,
    ) async {
      final requests = RequestRepository.instance;
      await _open(t);
      await t.tap(find.text('Close startup'));
      await t.pumpAndSettle();
      expect(find.text('Close Rafeeq Health?'), findsOneWidget);
      await t.tap(find.text('Close startup').last);
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      final repo = StartupRepository.instance as FakeStartupRepository;
      expect(repo.startups.single.isClosed, isTrue);
      expect(
        requests
            .inboxFor('mock-rafeeq')
            .where((r) => r.status == RequestStatus.pending),
        isEmpty,
      );
      await t.pump(const Duration(seconds: 4));
    });
  });

  group('Interest (Requests moved into the round)', () {
    testWidgets('there is no Requests tab in Manage startup', (t) async {
      await _open(t);
      final tabs = find.byType(ScrollableHeaderTabBar);
      for (final label in [
        'Dashboard',
        'Startup Overview',
        'Startup Ask',
        'EOI',
        'Settings',
      ]) {
        expect(
          find.descendant(of: tabs, matching: find.text(label)),
          findsOneWidget,
          reason: label,
        );
      }
      expect(
        find.descendant(of: tabs, matching: find.text('Requests')),
        findsNothing,
      );
    });

    testWidgets('a team member sees interest without the reply button', (
      t,
    ) async {
      await _open(t, role: StartupRole.member, tab: 'EOI');
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
    final details = find.descendant(
      of: find.byType(ScrollableHeaderTabBar),
      matching: find.text('Startup Team'),
    );
    await t.ensureVisible(details);
    await t.pumpAndSettle();
    await t.tap(details);
    await t.pumpAndSettle();
    await _toLeave(t);
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
