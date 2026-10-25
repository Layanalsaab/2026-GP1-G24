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
import 'package:startsa/features/startups/view_models/rounds_view_model.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/funding_round.dart';
import 'package:startsa/models/list_entries.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/headers/tabbed_header.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';
import 'package:startsa/shared_ui/widgets/overlays/picker_sheet.dart';

import '../../support/fakes.dart';

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

    test('Add round needs an amount and a lead-investor answer', () {
      final vm = RoundsViewModel(now: DateTime(2026, 10, 25));
      addTearDown(vm.dispose);
      vm.closeOpenRound();
      vm.openForm();
      expect(vm.formValid, isFalse);
      expect(vm.addRound(), isFalse);
      expect(vm.amountError, 'Please enter the round amount.');
      expect(vm.leadError, 'Please choose one.');
      vm.amount.text = '1,000,000';
      vm.setLead(true);
      expect(vm.addRound(), isTrue);
      expect(vm.openRound!.number, 3);
      expect(vm.openRound!.type, StartupStage.seriesA);
      expect(vm.openRound!.amount, 1000000);
    });
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
      expect(find.text('Ahmad Hassan'), findsOneWidget);
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
      await t.tap(find.text('Add round').last);
      await t.pumpAndSettle();
      expect(find.text('Please enter the round amount.'), findsOneWidget);
      expect(find.text('Please choose one.'), findsOneWidget);
      await t.pump(const Duration(seconds: 4));
      await t.enterText(find.byType(TextField).last, '1200000');
      await t.pump();
      expect(find.text('1,200,000'), findsOneWidget);
      await t.tap(find.text('Yes'));
      await t.pump();
      await t.tap(find.text('Add round').last);
      await t.pumpAndSettle();
      expect(find.text('Round 3'), findsOneWidget);
      expect(find.text('1.2M'), findsOneWidget);
      expect(find.text('Close round'), findsOneWidget);
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

    testWidgets('a team member only reads the rounds', (t) async {
      await _openRounds(t, role: StartupRole.member);
      expect(find.text('Close round'), findsNothing);
      expect(find.text('Add round'), findsNothing);
      expect(find.text('Round 2'), findsOneWidget);
    });
  });
}
