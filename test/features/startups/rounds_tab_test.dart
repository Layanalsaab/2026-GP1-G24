import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/activity_repository.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/firebase_services/firestore_service.dart';
import 'package:startsa/data_access/repositories/funding_round_repository.dart';
import 'package:startsa/data_access/repositories/matching_repository.dart';
import 'package:startsa/features/profiles/screens/investor_profile_screen.dart';
import 'package:startsa/features/startups/widgets/manage_rounds_tab.dart';
import 'package:startsa/data_access/repositories/interest_repository.dart';
import 'package:startsa/data_access/repositories/request_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/startups/screens/manage_startup_screen.dart';
import 'package:startsa/features/startups/view_models/rounds_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/funding_round.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/shared_ui/icons/app_icons.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/headers/tabbed_header.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';
import 'package:startsa/shared_ui/widgets/overlays/picker_sheet.dart';

import '../../support/fakes.dart';

/// Serves fixed documents instead of Firestore (the matching pools).
class _FakeFirestore extends FirestoreService {
  _FakeFirestore(this.collections);

  final Map<String, List<FirestoreDocument>> collections;

  @override
  Future<List<FirestoreDocument>> queryWhereEqual(
    String collection,
    String field,
    Object value, {
    int? limit,
  }) async => [
    for (final d in collections[collection] ?? const <FirestoreDocument>[])
      if (d.data[field] == value) d,
  ];
}

Future<void> _openRounds(
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
  await t.tap(
    find.descendant(
      of: find.byType(ScrollableHeaderTabBar),
      matching: find.text('Rounds'),
    ),
  );
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
    MatchingRepository.instance = MatchingRepository(
      firestore: _FakeFirestore(const {}),
      live: false,
    );
    AppSession.instance = AppSession();
  });

  group('RoundsViewModel', () {
    test('round types: the same stage as the last round and later ones', () {
      final vm = RoundsViewModel();
      addTearDown(vm.dispose);
      // The sample's newest round is Round 2 (Seed).
      expect(vm.allowedTypes, [
        StartupStage.seed,
        StartupStage.seriesA,
        StartupStage.seriesB,
        StartupStage.seriesC,
      ]);
      expect(vm.defaultType, StartupStage.seriesA);
    });

    test('with no rounds every stage is offered, starting at Pre-seed', () {
      final vm = RoundsViewModel(rounds: const []);
      addTearDown(vm.dispose);
      expect(vm.allowedTypes, StartupStage.picks);
      expect(vm.defaultType, StartupStage.preSeed);
      expect(vm.nextNumber, 1);
    });

    test('the bar stops at 100 % but the percentage can go past it', () {
      final r = FundingRound(
        number: 1,
        type: StartupStage.seed,
        amount: 100000,
        raised: 110000,
        start: DateTime(2026, 1, 1),
      );
      expect(r.percent, 110);
    });

    test(
      'Add round needs the round type, the amount and what is raised',
      () async {
        final vm = RoundsViewModel(now: DateTime(2026, 10, 25));
        addTearDown(vm.dispose);
        await vm.closeOpenRound();
        vm.openForm();
        expect(vm.formValid, isFalse);
        expect(await vm.addRound(), isFalse);
        expect(vm.amountError, 'Please enter the amount you’re raising.');
        expect(
          vm.raisedError,
          'Please enter an amount. Enter 0 if you haven’t raised anything yet.',
        );
        // At least SAR 1,000, whatever the round type; no maximum.
        vm.amount.text = '999';
        expect(vm.amountError, 'The amount must be at least SAR 1,000.');
        expect(vm.formValid, isFalse);
        vm.amount.text = '1,000';
        expect(vm.amountError, isNull);
        vm.amount.text = '1,000,000';
        expect(vm.amountError, isNull, reason: 'no Series A range any more');
        vm.amount.text = '10,000,000';
        vm.raised.text = '12,000,000';
        expect(
          vm.raisedError,
          'This can’t be more than the amount you’re raising.',
        );
        vm.raised.text = '2,000,000';
        expect(await vm.addRound(), isTrue);
        expect(vm.openRound!.number, 3);
        expect(vm.openRound!.type, StartupStage.seriesA);
        expect(vm.openRound!.amount, 10000000);
        // The new open round starts at what is already raised.
        expect(vm.openRound!.raised, 2000000);
      },
    );
  });

  group('Rounds tab', () {
    testWidgets('the table: newest first, amounts, bars and investors', (
      t,
    ) async {
      await _openRounds(t);
      expect(find.text('Funding rounds'), findsOneWidget);
      expect(find.text('All amounts in SAR'), findsOneWidget);
      expect(find.text('Close round'), findsOneWidget);
      expect(find.text('Add round'), findsNothing);
      for (final h in ['ROUND', 'AMOUNT', 'RAISED', 'INVESTORS']) {
        expect(find.text(h), findsOneWidget, reason: h);
      }
      expect(
        t.getTopLeft(find.text('Round 2')).dy,
        lessThan(t.getTopLeft(find.text('Round 1')).dy),
      );
      expect(find.text('500K'), findsOneWidget);
      expect(find.text('250K'), findsNWidgets(2)); // amount and raised
      expect(find.text('200K'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Seed'), findsOneWidget);
      expect(find.text('Aug 2026 – now'), findsOneWidget);
      expect(find.text('Jan – Jun 2026'), findsOneWidget);
      // The lead investor of the round says so.
      expect(find.text('Ahmad Hassan · Lead'), findsOneWidget);
      expect(find.text('Layan Alsaab'), findsOneWidget);
    });

    testWidgets('Close round asks, then moves the round to closed', (t) async {
      await _openRounds(t);
      await t.tap(find.text('Close round'));
      await t.pumpAndSettle();
      expect(find.text('Close Round 2?'), findsOneWidget);
      expect(
        find.textContaining('Investors won’t be able to send requests'),
        findsOneWidget,
      );
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.text('Close round'), findsOneWidget);
      await t.tap(find.text('Close round'));
      await t.pumpAndSettle();
      // The dialog's red button has the same label.
      await t.tap(find.text('Close round').last);
      await t.pumpAndSettle();
      expect(find.text('Close round'), findsNothing);
      expect(find.text('Add round'), findsOneWidget);
      expect(find.text('Aug 2026 – now'), findsNothing);
    });

    testWidgets('Add round: types, errors, then the new round is open', (
      t,
    ) async {
      // A tall screen: the form is longer now (two amounts).
      t.view.physicalSize = const Size(800, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await _openRounds(t);
      await t.tap(find.text('Close round'));
      await t.pumpAndSettle();
      await t.tap(find.text('Close round').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Add round'));
      await t.pumpAndSettle();
      expect(find.text('New round · Round 3'), findsOneWidget);
      // Default type: the stage after the last round (Seed -> Series A).
      expect(find.text('Series A'), findsOneWidget);
      await t.tap(find.text('Series A'));
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Round type'), findsWidgets);
      // An earlier stage is not offered in the sheet.
      expect(
        find.descendant(
          of: find.byType(PickerSheet),
          matching: find.text('Pre-seed'),
        ),
        findsNothing,
      );
      for (final o in ['Seed', 'Series B', 'Series C']) {
        expect(find.text(o), findsWidgets, reason: o);
      }
      await t.tap(find.text('Series B').last);
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 600));
      // Empty: both errors show.
      await t.ensureVisible(find.text('Add round').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Add round').last);
      await t.pumpAndSettle();
      expect(
        find.text('Please enter the amount you’re raising.'),
        findsOneWidget,
      );
      // No lead-investor question any more.
      expect(find.text('Please choose one.'), findsNothing);
      await t.pump(const Duration(seconds: 4));
      final fields = find.byType(TextField);
      await t.enterText(fields.at(fields.evaluate().length - 2), '1200000');
      await t.pump();
      expect(find.text('1,200,000'), findsOneWidget);
      // No range per round type: SAR 1,200,000 is fine for Series B.
      expect(find.textContaining('range'), findsNothing);
      expect(find.textContaining('at least SAR 1,000'), findsNothing);
      await t.enterText(fields.at(fields.evaluate().length - 2), '60000000');
      await t.enterText(fields.last, '0');
      await t.pump();
      await t.pumpAndSettle();
      // (There is no lead-investor Yes / No to answer any more.)
      expect(find.text('Yes'), findsNothing);
      await t.ensureVisible(find.text('Add round').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Add round').last);
      await t.pumpAndSettle();
      // The confirm comes first; Cancel keeps the form, nothing is added.
      expect(find.text('Add round?'), findsOneWidget);
      expect(
        find.text('This round will be added to your startup.'),
        findsOneWidget,
      );
      await t.tap(find.text('Cancel').last);
      await t.pumpAndSettle();
      expect(find.text('Add round?'), findsNothing);
      expect(find.text('New round · Round 3'), findsOneWidget);
      await t.tap(find.text('Add round').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Add round').last);
      await t.pumpAndSettle();
      expect(find.text('Round 3'), findsOneWidget);
      expect(find.text('60M'), findsOneWidget);
      expect(find.text('Close round'), findsOneWidget);
    });

    testWidgets('Cancel asks "Discard changes?" only after a change', (
      t,
    ) async {
      t.view.physicalSize = const Size(800, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await _openRounds(t);
      await t.tap(find.text('Close round'));
      await t.pumpAndSettle();
      await t.tap(find.text('Close round').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Add round'));
      await t.pumpAndSettle();
      // Nothing changed: Cancel closes the form at once.
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('New round · Round 3'), findsNothing);
      // Typed an amount: Cancel asks; "Keep editing" keeps it.
      await t.tap(find.text('Add round'));
      await t.pumpAndSettle();
      final fields = find.byType(TextField);
      await t.enterText(fields.at(fields.evaluate().length - 2), '1200000');
      await t.pump();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      expect(
        find.text('If you go back now, your changes will be lost.'),
        findsOneWidget,
      );
      await t.tap(find.text('Keep editing'));
      await t.pumpAndSettle();
      expect(find.text('New round · Round 3'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      await t.tap(find.text('Discard'));
      await t.pumpAndSettle();
      expect(find.text('New round · Round 3'), findsNothing);
    });

    testWidgets('the dashboard Raising tile follows the open round', (t) async {
      await _openRounds(t);
      final dashboard = find.descendant(
        of: find.byType(ScrollableHeaderTabBar),
        matching: find.text('Dashboard'),
      );
      await t.ensureVisible(dashboard);
      await t.pumpAndSettle();
      await t.tap(dashboard);
      await t.pumpAndSettle();
      expect(find.text('SAR 500K'), findsOneWidget);
      expect(find.text('Round 2 · Open'), findsOneWidget);
    });

    testWidgets('rows show Open / Closed, a hint, and the plain table stays', (
      t,
    ) async {
      await _openRounds(t);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('Tap a round to see its details.'), findsOneWidget);
      // Nothing is open yet: no page.
      expect(find.text('All rounds'), findsNothing);
    });

    testWidgets('an open round page: card, investors and matches', (t) async {
      await _openRounds(t);
      await t.tap(find.text('Round 2'));
      await t.pumpAndSettle();
      expect(find.text('All rounds'), findsOneWidget);
      expect(find.text('Round 2'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Seed · Aug 2026 – now'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('SAR 500,000'), findsOneWidget);
      expect(find.text('SAR 200,000'), findsOneWidget);
      expect(find.text('40% of the target raised'), findsOneWidget);
      expect(find.text('Investors'), findsOneWidget);
      expect(find.text('Who invested in this round'), findsOneWidget);
      expect(find.text('Ahmad Hassan'), findsOneWidget);
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Investors that fit this round'), findsOneWidget);
      expect(find.text('Edit round'), findsOneWidget);
      // The list is gone; the back link returns to it.
      expect(find.text('Funding rounds'), findsNothing);
      await t.tap(find.text('All rounds'));
      await t.pumpAndSettle();
      expect(find.text('Funding rounds'), findsOneWidget);
      expect(find.text('All rounds'), findsNothing);
    });

    testWidgets('a closed round page: no Matches, no Edit round', (t) async {
      await _openRounds(t);
      await t.tap(find.text('Round 1'));
      await t.pumpAndSettle();
      expect(find.text('Closed'), findsOneWidget);
      expect(find.text('SAR 250,000'), findsNWidgets(2));
      expect(find.text('100% of the target raised'), findsOneWidget);
      expect(find.text('Layan Alsaab'), findsOneWidget);
      expect(find.text('Matches'), findsNothing);
      expect(find.text('Edit round'), findsNothing);
      // The investor opens their profile.
      await t.tap(find.text('Layan Alsaab'));
      await t.pumpAndSettle();
      expect(find.byType(InvestorProfileScreen), findsOneWidget);
    });

    testWidgets('a round with no investors says so (open and closed)', (
      t,
    ) async {
      FundingRoundRepository.instance = FundingRoundRepository.sample();
      final vm = RoundsViewModel(
        rounds: [
          FundingRound(
            number: 2,
            type: StartupStage.seed,
            amount: 100000,
            start: DateTime(2026, 8, 1),
          ),
          FundingRound(
            number: 1,
            type: StartupStage.preSeed,
            amount: 50000,
            start: DateTime(2026, 1, 1),
            end: DateTime(2026, 2, 1),
          ),
        ],
      );
      addTearDown(vm.dispose);
      t.view.physicalSize = const Size(1236, 2676);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          navigatorKey: AppToast.navigatorKey,
          home: Scaffold(
            body: SingleChildScrollView(child: ManageRoundsTab(vm: vm)),
          ),
        ),
      );
      await t.tap(find.text('Round 2'));
      await t.pumpAndSettle();
      expect(find.text('No investors yet'), findsOneWidget);
      await t.tap(find.text('All rounds'));
      await t.pumpAndSettle();
      await t.tap(find.text('Round 1'));
      await t.pumpAndSettle();
      expect(find.text('No investors recorded'), findsOneWidget);
    });

    testWidgets('Matches: the top five investors with the percent only', (
      t,
    ) async {
      Map<String, dynamic> investor(int n) => {
        'role': 'investor',
        'fullName': 'Matched Investor $n',
        'title': 'Angel Investor',
        'city': 'Riyadh',
        'preferredSectors': ['HealthTech'],
        'preferredStages': ['Seed'],
        'preferredCommerceModels': <String>[],
        'ticketSize': 'SAR 100K – 500K',
      };
      MatchingRepository.instance = MatchingRepository(
        firestore: _FakeFirestore({
          'investors': [
            for (var n = 1; n <= 7; n++) (id: 'ANG-$n', data: investor(n)),
          ],
        }),
        live: false,
      );
      await _openRounds(t);
      await t.tap(find.text('Round 2'));
      await t.pumpAndSettle();
      // Seven fit; only five are shown.
      expect(find.textContaining('Matched Investor'), findsNWidgets(5));
      expect(find.text('100% match'), findsNWidgets(5));
      // Why they matched is on the investor's profile, not on the card.
      expect(find.text('Same sector & stage'), findsNothing);
      // "Angel Investor · [pin] Riyadh" on every match card.
      expect(find.text('Angel Investor'), findsAtLeastNWidgets(5));
      expect(find.text('Riyadh'), findsAtLeastNWidgets(5));
      expect(
        find.byWidgetPredicate((w) => w is AppIcon && w.path == AppIcons.pin),
        findsAtLeastNWidgets(5),
      );
      // Tapping one opens that investor.
      await t.ensureVisible(find.text('Matched Investor 1'));
      await t.pumpAndSettle();
      await t.tap(find.text('Matched Investor 1'));
      await t.pumpAndSettle();
      expect(find.byType(InvestorProfileScreen), findsOneWidget);
      // The profile starts with the match and why.
      expect(
        find.text(
          '100% match with your startup Rafeeq Health',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('Sector · HealthTech', findRichText: true), findsOneWidget);
      expect(find.text('Stage · Seed', findRichText: true), findsOneWidget);
    });

    testWidgets('Edit round: pre-filled, confirm, then the round is updated', (
      t,
    ) async {
      await _openRounds(t);
      await t.tap(find.text('Round 2'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Edit round'));
      await t.pumpAndSettle();
      await t.tap(find.text('Edit round'));
      await t.pumpAndSettle();
      expect(find.text('Edit round · Round 2'), findsOneWidget);
      // Pre-filled with the current values; the button is hidden meanwhile.
      expect(find.text('500,000'), findsOneWidget);
      expect(find.text('200,000'), findsOneWidget);
      expect(find.text('Edit round'), findsNothing);
      final fields = find.byType(TextField);
      // (No range per round type any more: the sample's SAR 500,000 Seed is
      // fine.)
      expect(find.textContaining('range'), findsNothing);
      expect(find.textContaining('at least SAR 1,000'), findsNothing);
      await t.enterText(fields.at(fields.evaluate().length - 2), '3000000');
      await t.enterText(fields.last, '300000');
      await t.pump();
      await t.ensureVisible(find.text('Save changes'));
      await t.pumpAndSettle();
      await t.tap(find.text('Save changes'));
      await t.pumpAndSettle();
      expect(find.text('Save changes?'), findsOneWidget);
      expect(
        find.text('Your changes will be saved to this round.'),
        findsOneWidget,
      );
      await t.tap(find.text('Save changes').last);
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Round updated'), findsOneWidget);
      await t.pumpAndSettle(const Duration(seconds: 5));
      expect(find.text('Edit round · Round 2'), findsNothing);
      expect(find.text('SAR 3,000,000'), findsOneWidget);
      expect(find.text('SAR 300,000'), findsOneWidget);
      expect(find.text('10% of the target raised'), findsOneWidget);
      final repo = StartupRepository.instance as FakeStartupRepository;
      expect(repo.startups.single.raisedInRound, 300000);
      expect(repo.startups.single.fundingRequirement, 3000000);
    });

    testWidgets('Edit round: Cancel asks only after a change', (t) async {
      await _openRounds(t);
      await t.tap(find.text('Round 2'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('Edit round'));
      await t.pumpAndSettle();
      await t.tap(find.text('Edit round'));
      await t.pumpAndSettle();
      // No change: Cancel closes the form at once.
      await t.ensureVisible(find.text('Cancel'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('Edit round · Round 2'), findsNothing);
      await t.ensureVisible(find.text('Edit round'));
      await t.pumpAndSettle();
      await t.tap(find.text('Edit round'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '250000');
      await t.pump();
      await t.ensureVisible(find.text('Cancel'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);
      await t.tap(find.text('Discard'));
      await t.pumpAndSettle();
      expect(find.text('Edit round · Round 2'), findsNothing);
      // The round is unchanged.
      expect(find.text('SAR 200,000'), findsOneWidget);
    });

    testWidgets('a view-only member opens the page but cannot edit', (t) async {
      await _openRounds(t, role: StartupRole.member);
      await t.tap(find.text('Round 2'));
      await t.pumpAndSettle();
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Edit round'), findsNothing);
    });

    testWidgets('switching Manage tabs comes back to the rounds list', (
      t,
    ) async {
      await _openRounds(t);
      await t.tap(find.text('Round 2'));
      await t.pumpAndSettle();
      expect(find.text('All rounds'), findsOneWidget);
      final tabs = find.byType(ScrollableHeaderTabBar);
      final dashboard = find.descendant(
        of: tabs,
        matching: find.text('Dashboard'),
      );
      await t.ensureVisible(dashboard);
      await t.pumpAndSettle();
      await t.tap(dashboard);
      await t.pumpAndSettle();
      expect(find.text('All rounds'), findsNothing);
      final rounds = find.descendant(of: tabs, matching: find.text('Rounds'));
      await t.ensureVisible(rounds);
      await t.pumpAndSettle();
      await t.tap(rounds);
      await t.pumpAndSettle();
      expect(find.text('All rounds'), findsNothing);
      expect(find.text('Funding rounds'), findsOneWidget);
    });

    testWidgets('Investment requests live on the open round page', (t) async {
      await _openRounds(t);
      // Not a tab of Manage startup any more.
      expect(
        find.descendant(
          of: find.byType(ScrollableHeaderTabBar),
          matching: find.text('Requests'),
        ),
        findsNothing,
      );
      await t.tap(find.text('Round 2'));
      await t.pumpAndSettle();
      expect(find.text('Investment Requests'), findsOneWidget);
      expect(find.text('Investors asking to join this round'), findsOneWidget);
      expect(find.text('Pending · 1'), findsOneWidget);
      expect(find.text('SAR 300,000 for 15%'), findsOneWidget);
      await t.ensureVisible(find.text('Accept'));
      await t.pumpAndSettle();
      await t.tap(find.text('Accept'));
      await t.pumpAndSettle();
      expect(find.text('No pending requests.'), findsOneWidget);
      await t.pump(const Duration(seconds: 4));
    });

    testWidgets('a closed round has no investment requests', (t) async {
      await _openRounds(t);
      await t.tap(find.text('Round 1'));
      await t.pumpAndSettle();
      expect(find.text('Investment Requests'), findsNothing);
    });

    testWidgets('a view-only member sees the requests without the buttons', (
      t,
    ) async {
      await _openRounds(t, role: StartupRole.member);
      await t.tap(find.text('Round 2'));
      await t.pumpAndSettle();
      expect(find.text('Investment Requests'), findsOneWidget);
      expect(find.text('Pending · 1'), findsOneWidget);
      expect(find.text('Accept'), findsNothing);
      expect(find.text('Decline'), findsNothing);
    });

    testWidgets('a team member only reads the rounds', (t) async {
      await _openRounds(t, role: StartupRole.member);
      expect(find.text('Close round'), findsNothing);
      expect(find.text('Add round'), findsNothing);
      expect(find.text('Round 2'), findsOneWidget);
    });
  });
}
