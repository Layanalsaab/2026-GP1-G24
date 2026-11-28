import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/activity_repository.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/funding_round_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/startups/screens/manage_startup_screen.dart';
import 'package:startsa/features/startups/screens/my_startups_screen.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/auth_failure.dart';
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
    ActivityRepository.instance = ActivityRepository(sample: true);
    DiscoveryRepository.instance = DiscoveryRepository.sample();
    FundingRoundRepository.instance = FundingRoundRepository.sample();
    AppSession.instance = AppSession();
  });

  group('Settings tab', () {
    testWidgets('founder: Public startup, Close and Delete, no Leave', (
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
      expect(find.text('Delete startup'), findsOneWidget);
      // Leave startup is in the Startup Team tab, not here.
      expect(find.text('Leave startup'), findsNothing);
      expect(find.text('Transfer ownership'), findsNothing);
    });

    testWidgets('Delete asks, then asks for the password, then deletes', (
      t,
    ) async {
      final auth = FakeAuthRepository();
      AuthRepository.instance = auth;
      await _open(t);
      await t.tap(find.text('Delete startup'));
      await t.pumpAndSettle();
      expect(find.text('Delete Rafeeq Health?'), findsOneWidget);
      await t.tap(find.text('Delete startup').last);
      await t.pumpAndSettle();
      // Only the password step now.
      expect(
        find.text('Enter your password to delete this startup.'),
        findsOneWidget,
      );
      // No password: asked for, nothing deleted.
      await t.tap(find.text('Delete startup').last);
      await t.pump();
      expect(find.text('Please enter your password.'), findsOneWidget);
      final repo = StartupRepository.instance as FakeStartupRepository;
      expect(repo.startups, hasLength(1));
      // A wrong password: says so, still nothing deleted.
      auth.verifyPasswordFails = AuthFailure.invalidCredentials;
      await t.enterText(find.byType(TextField).last, 'Wrong1!');
      await t.tap(find.text('Delete startup').last);
      await t.pump();
      await t.pump();
      expect(find.text('The password is incorrect.'), findsOneWidget);
      expect(repo.startups, hasLength(1));
      // The right one: deleted.
      auth.verifyPasswordFails = null;
      await t.tap(find.text('Delete startup').last);
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(repo.startups, isEmpty);
      await t.pump(const Duration(seconds: 4));
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

    testWidgets('co-founder: like a team member, nothing to change', (t) async {
      await _open(t, role: StartupRole.coFounder);
      expect(find.text('Public startup'), findsNothing);
      expect(find.text('Close startup'), findsNothing);
      expect(find.text('Delete startup'), findsNothing);
      expect(find.text('Leave startup'), findsNothing);
      expect(find.text('There is nothing to change here.'), findsOneWidget);
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
        find.text('Choose the next founder before you leave.'),
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

    testWidgets('a closed startup: its founder has visibility and Delete', (
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
      expect(find.text('Delete startup'), findsOneWidget);
      expect(find.text('Leave startup'), findsNothing);
      expect(
        find.text(
          'This startup was closed and can no longer be edited or reopened. You can choose from Settings whether it appears in the Hub.',
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

    testWidgets('the founder alone chooses his role, then invites', (t) async {
      await _open(t, tab: 'Startup Team');
      await _toLeave(t);
      await t.tap(find.text('Leave startup'));
      await t.pumpAndSettle();
      // His role after the handover first.
      expect(find.text('Your role after the handover'), findsOneWidget);
      await t.tap(find.text('Stay as a co-founder'));
      await t.pumpAndSettle();
      // One sheet: what happens next and the e-mail.
      expect(find.text('Invite a new founder'), findsOneWidget);
      expect(
        find.textContaining('There is no one else on Rafeeq Health’s team.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('you will stay on the team as a co-founder'),
        findsOneWidget,
      );
      expect(find.text('Send invitation'), findsOneWidget);
      await t.tap(find.text('Cancel').last);
      await t.pumpAndSettle();
      expect(find.text('Invite a new founder'), findsNothing);
    });

    testWidgets('the founder names a joined member, then leaves for good', (
      t,
    ) async {
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
      expect(find.text('Choose the next founder'), findsOneWidget);
      expect(
        find.text('They will have full control of Rafeeq Health.'),
        findsOneWidget,
      );
      expect(find.text('Invite someone new'), findsOneWidget);
      // His card in the sheet (his team card is behind it).
      await t.tap(find.text('Faisal Alkhaldi').last);
      await t.pumpAndSettle();
      expect(find.text('Your role after the handover'), findsOneWidget);
      expect(find.text('Stay as a team member'), findsOneWidget);
      await t.tap(find.text('Leave for good'));
      await t.pumpAndSettle();
      expect(
        find.text('Make Faisal Alkhaldi the founder of Rafeeq Health?'),
        findsOneWidget,
      );
      expect(
        find.textContaining('you will leave Rafeeq Health'),
        findsOneWidget,
      );
      await t.tap(find.text('Make Faisal Alkhaldi the founder'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      final repo = StartupRepository.instance as FakeStartupRepository;
      expect(repo.transfers, [('mock-rafeeq', 'sample-faisal')]);
      expect(repo.transferStays, [null]);
      await t.pump(const Duration(seconds: 4));
    });

    testWidgets('the founder hands over and stays as a team member', (t) async {
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
      // His card in the sheet (his team card is behind it).
      await t.tap(find.text('Faisal Alkhaldi').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Stay as a team member'));
      await t.pumpAndSettle();
      expect(
        find.textContaining('you will stay on the team as a team member'),
        findsOneWidget,
      );
      await t.tap(find.text('Make Faisal Alkhaldi the founder'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      final repo = StartupRepository.instance as FakeStartupRepository;
      expect(repo.transferStays, ['member']);
      await t.pump(const Duration(seconds: 4));
    });

    testWidgets('Close asks, then closes it', (t) async {
      await _open(t);
      await t.tap(find.text('Close startup'));
      await t.pumpAndSettle();
      expect(find.text('Close Rafeeq Health?'), findsOneWidget);
      await t.tap(find.text('Close startup').last);
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      final repo = StartupRepository.instance as FakeStartupRepository;
      expect(repo.startups.single.isClosed, isTrue);
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

    testWidgets('EOI shows only the empty message', (t) async {
      await _open(t, tab: 'EOI');
      expect(find.text('No new expressions of interest.'), findsOneWidget);
      expect(find.text('New · 0'), findsOneWidget);
      expect(find.text('All · 0'), findsOneWidget);
      await t.tap(find.text('All · 0'));
      await t.pump();
      expect(find.text('No new expressions of interest.'), findsOneWidget);
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
