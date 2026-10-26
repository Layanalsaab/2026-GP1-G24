import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/activity_repository.dart';
import 'package:startsa/data_access/repositories/bookmark_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/funding_round_repository.dart';
import 'package:startsa/data_access/repositories/interaction_repository.dart';
import 'package:startsa/data_access/repositories/interest_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/search/view_models/home_view_model.dart';
import 'package:startsa/features/startup_profile/screens/startup_profile_screen.dart';
import 'package:startsa/features/startups/screens/manage_startup_screen.dart';
import 'package:startsa/features/startups/view_models/rounds_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/headers/tabbed_header.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';

import '../../support/fakes.dart';

const _founder = AppUser(
  uid: 'founder-uid',
  role: AccountRole.founder,
  fullName: 'Shahad Alabdulkarim',
  email: 'shahad@gmail.com',
);
const _investor = AppUser(
  uid: 'inv-uid',
  role: AccountRole.investor,
  fullName: 'Layan Alsaab',
  email: 'layan@gmail.com',
);

Finder _tab(String label) => find.descendant(
  of: find.byType(ScrollableHeaderTabBar),
  matching: find.text(label),
);

Future<void> _pump(WidgetTester t, Widget home, {Size? size}) async {
  t.view.physicalSize = size ?? const Size(1236, 2676);
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  // A fresh tree each time (the screens read the session when they start).
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      navigatorKey: AppToast.navigatorKey,
      home: home,
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _goTo(WidgetTester t, String tab) async {
  await t.ensureVisible(_tab(tab));
  await t.pumpAndSettle();
  await t.tap(_tab(tab));
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
    BookmarkRepository.instance = BookmarkRepository();
    AppSession.instance = AppSession();
  });

  group('Part 6 · roles', () {
    test('the role is read from the startup itself', () {
      final s = PrototypeSeed.rafeeq.copyWith(
        founderId: 'f',
        memberRoles: const {'c': 'coFounder', 'm': 'member'},
      );
      expect(StartupRole.of(s, 'f'), StartupRole.founder);
      expect(StartupRole.of(s, 'c'), StartupRole.coFounder);
      expect(StartupRole.of(s, 'm'), StartupRole.member);
      expect(StartupRole.of(s, 'other'), isNull);
      expect(StartupRole.of(s, null), isNull);
    });

    test(
      'a team member cannot add or close rounds (checked in the action)',
      () async {
        final vm = RoundsViewModel(
          canManage: false,
          now: DateTime(2026, 10, 25),
        );
        addTearDown(vm.dispose);
        vm.openForm();
        expect(vm.formOpen, isFalse);
        expect(await vm.closeOpenRound(), isFalse);
        expect(vm.openRound, isNotNull);
        expect(await vm.addRound(), isFalse);
      },
    );

    testWidgets('Manage reads the role from the startup when none is given', (
      t,
    ) async {
      AppSession.instance.signIn(_founder);
      final s = PrototypeSeed.rafeeq.copyWith(
        founderId: 'someone-else',
        memberRoles: const {'founder-uid': 'coFounder'},
      );
      await _pump(t, ManageStartupScreen(startup: s));
      expect(find.text('CO-FOUNDER'), findsOneWidget);
      expect(find.text('View only'), findsNothing);
    });

    testWidgets('a team member gets the View only notice on every tab', (
      t,
    ) async {
      await _pump(
        t,
        ManageStartupScreen(
          startup: PrototypeSeed.mizan,
          role: StartupRole.member,
        ),
      );
      expect(find.text('TEAM MEMBER'), findsOneWidget);
      for (final tab in [
        'Dashboard',
        'Details',
        'Rounds',
        'Requests',
        'Settings',
      ]) {
        await _goTo(t, tab);
        expect(find.text('View only'), findsOneWidget, reason: tab);
        expect(
          find.text(
            'You’re a team member. Only the founder and co-founders can make changes.',
          ),
          findsOneWidget,
          reason: tab,
        );
      }
    });

    testWidgets('founders and co-founders never see the notice', (t) async {
      await _pump(
        t,
        ManageStartupScreen(
          startup: PrototypeSeed.rafeeq,
          role: StartupRole.coFounder,
        ),
      );
      expect(find.text('View only'), findsNothing);
    });

    testWidgets('a member with no associated investors reads the member text', (
      t,
    ) async {
      DiscoveryRepository.instance = DiscoveryRepository.sample();
      final lonely = PrototypeSeed.rafeeq.copyWith(id: 'no-investors');
      await _pump(
        t,
        ManageStartupScreen(startup: lonely, role: StartupRole.member),
      );
      expect(find.text('No associated investors yet.'), findsOneWidget);
    });

    testWidgets('the Valuation tile opens Details with Finance open (member)', (
      t,
    ) async {
      await _pump(
        t,
        ManageStartupScreen(
          startup: PrototypeSeed.rafeeq,
          role: StartupRole.member,
        ),
      );
      await t.tap(find.text('Valuation'));
      await t.pumpAndSettle();
      expect(find.text('Current available capital'), findsOneWidget);
    });
  });

  group('Part 7 · startup page', () {
    testWidgets('header: one sub-line, four equal tabs, no description', (
      t,
    ) async {
      AppSession.instance.signIn(_investor);
      await _pump(t, StartupProfileScreen(startup: PrototypeSeed.rafeeq));
      expect(find.text('Rafeeq Health'), findsWidgets);
      expect(find.text('HealthTech · Pre-seed · Riyadh'), findsOneWidget);
      for (final tab in ['Overview', 'Business', 'Team', 'Funding']) {
        expect(_tab(tab), findsOneWidget, reason: tab);
      }
      // Four equal cells.
      final widths = [
        for (final tab in ['Overview', 'Business', 'Team', 'Funding'])
          t
              .getSize(
                find
                    .ancestor(of: _tab(tab), matching: find.byType(Expanded))
                    .first,
              )
              .width,
      ];
      expect(widths.toSet().length, 1);
      // The brief description appears once: in About, not in the header.
      expect(find.text(PrototypeSeed.rafeeq.briefDescription), findsOneWidget);
    });

    testWidgets('Overview: tiles, About with facts, Looking for', (t) async {
      AppSession.instance.signIn(_investor);
      await _pump(t, StartupProfileScreen(startup: PrototypeSeed.rafeeq));
      // No Raising / Valuation tiles on Overview any more.
      expect(find.text('Round 2 · Open'), findsNothing);
      expect(find.text('Valuation'), findsNothing);
      expect(find.text('About'), findsOneWidget);
      for (final fact in [
        'Sector',
        'Stage',
        'Commerce model',
        'Headquarters',
        'Founded',
      ]) {
        expect(find.text(fact), findsOneWidget, reason: fact);
      }
      expect(find.text('Looking for'), findsOneWidget);
      // Funding shows only the amount; no "raised so far" or lead investor.
      expect(find.text('Raising SAR 500,000'), findsOneWidget);
      expect(find.textContaining('raised so far'), findsNothing);
      expect(find.textContaining('lead investor'), findsNothing);
      expect(find.text('Open to partnerships'), findsNothing);
    });

    testWidgets('Business, Team and Funding tabs show their cards', (t) async {
      AppSession.instance.signIn(_investor);
      await _pump(t, StartupProfileScreen(startup: PrototypeSeed.rafeeq));
      await _goTo(t, 'Business');
      expect(find.text('Startup description'), findsOneWidget);
      expect(find.text('The problem'), findsOneWidget);
      expect(find.text('Our solution'), findsOneWidget);
      expect(find.text('What makes us unique'), findsOneWidget);
      expect(find.text('Target market'), findsOneWidget);
      expect(find.text('Target customers'), findsOneWidget);
      expect(find.text('Target market size'), findsOneWidget);
      await _goTo(t, 'Team');
      expect(find.text('Team'), findsWidgets);
      expect(find.text('Founder'), findsOneWidget);
      expect(find.text('Associated investors'), findsOneWidget);
      await _goTo(t, 'Funding');
      expect(find.text('Current round'), findsOneWidget);
      expect(find.text('Funding goal'), findsOneWidget);
      expect(find.text('Key numbers'), findsOneWidget);
      for (final label in [
        'Valuation',
        'Available capital',
        'Revenue this year',
        'Monthly burn',
        'Runway',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('Traction'), findsNothing);
      expect(find.text('Funding rounds'), findsOneWidget);
      expect(find.text('All amounts in SAR'), findsOneWidget);
      expect(find.text('Round 1'), findsOneWidget);
      expect(find.text('Expected revenue'), findsOneWidget);
      expect(find.text('SAR per year'), findsOneWidget);
    });

    testWidgets('buttons: investor, guest and another founder', (t) async {
      AppSession.instance.signIn(_investor);
      await _pump(t, StartupProfileScreen(startup: PrototypeSeed.rafeeq));
      expect(find.text('Send investment request'), findsOneWidget);

      AppSession.instance = AppSession()..signInAsGuest();
      await _pump(t, StartupProfileScreen(startup: PrototypeSeed.rafeeq));
      expect(find.text('Express interest'), findsOneWidget);
      expect(find.bySemanticsLabel('Bookmark'), findsNothing);

      AppSession.instance = AppSession()..signIn(_founder);
      await _pump(t, StartupProfileScreen(startup: PrototypeSeed.rafeeq));
      expect(find.text('Send investment request'), findsNothing);
      expect(find.text('Express interest'), findsNothing);
      expect(find.text('Leave startup'), findsNothing);
    });

    testWidgets('preview: the bar, the close icon, no bookmark or button', (
      t,
    ) async {
      AppSession.instance.signIn(_founder);
      await _pump(
        t,
        StartupProfileScreen(startup: PrototypeSeed.rafeeq, preview: true),
      );
      expect(
        find.text('Preview · This is how others see your startup'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Share'), findsNothing);
      expect(find.text('Send investment request'), findsNothing);
    });

    testWidgets('preview of a private startup says only the team sees it', (
      t,
    ) async {
      AppSession.instance.signIn(_founder);
      await _pump(
        t,
        StartupProfileScreen(
          startup: PrototypeSeed.rafeeq.copyWith(isPublic: false),
          preview: true,
        ),
      );
      expect(
        find.text('Preview · Private, only your team can see it'),
        findsOneWidget,
      );
    });
  });

  group('Part 7 · who sees which startup', () {
    test('a private startup is never trending', () {
      final privateId = PrototypeSeed.daftar.id; // private in the sample
      final ids = InteractionRepository()
          .trendingStartups(TrendingRange.week)
          .map((i) => i.id);
      expect(ids, isNot(contains(privateId)));
    });

    test('the startups I belong to are in my Hub but not in For You', () {
      final naql = PrototypeSeed.naql.id;
      final m = HomeViewModel(role: SessionRole.founder, ownStartupIds: {naql})
        ..setHubSwitch(0);
      addTearDown(m.dispose);
      expect(m.hubCards.any((i) => i.id == naql), isTrue);
      m.setForYouSwitch(0);
      expect(m.newItems.any((i) => i.id == naql), isFalse);
      expect(m.recommended.any((i) => i.id == naql), isFalse);
    });

    test('they still appear in Trending', () {
      final naql = PrototypeSeed.naql.id;
      final m = HomeViewModel(role: SessionRole.founder, ownStartupIds: {naql})
        ..setTrendingSwitch(0);
      addTearDown(m.dispose);
      expect(m.trending.any((i) => i.id == naql), isTrue);
    });

    test('the session lists every startup the user belongs to', () {
      final s = AppSession()
        ..setOwnStartupIds(['a'])
        ..setMemberStartupIds(['b', 'c']);
      expect(s.belongingStartupIds, {'a', 'b', 'c'});
      expect(s.ownStartupIds, {'a'});
    });
  });
}
