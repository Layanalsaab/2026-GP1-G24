import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/data_access/repositories/funding_round_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/startups/view_models/rounds_view_model.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/manage_rounds_tab.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/funding_round.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/startup_enums.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';

import '../../support/fakes.dart';

/// Manage -> Rounds saves through the startup: Close round unticks Funding,
/// Add round ticks it with the new round's answers (and its Stage).
void main() {
  late FakeStartupRepository startups;
  final startup = PrototypeSeed.rafeeq;

  setUp(() {
    startups = FakeStartupRepository()..startups.add(startup);
    StartupRepository.instance = startups;
    FundingRoundRepository.instance = FundingRoundRepository.sample();
    AppSession.instance = AppSession();
  });

  Future<RoundsViewModel> loaded({List<Startup>? saved}) async {
    final vm = RoundsViewModel(
      startup: startup,
      onStartupSaved: saved?.add,
      now: DateTime(2026, 10, 25),
    );
    await Future<void>.delayed(Duration.zero);
    return vm;
  }

  test('the rounds are loaded for the startup', () async {
    final vm = await loaded();
    addTearDown(vm.dispose);
    expect(vm.ready, isTrue);
    expect(vm.rounds.map((r) => r.number), [2, 1]);
    expect(vm.openRound!.number, 2);
  });

  test(
    'Close round removes Funding and its answers from the startup',
    () async {
      final saved = <Startup>[];
      final vm = await loaded(saved: saved);
      addTearDown(vm.dispose);
      expect(await vm.closeOpenRound(), isTrue);
      expect(vm.openRound, isNull);
      // A closed round keeps what it raised (the sample: 200K of 500K).
      expect(vm.rounds.first.raised, 200000);
      expect(vm.rounds.first.isOpen, isFalse);
      final s = startups.startups.single;
      expect(s.seeksFunding, isFalse);
      expect(s.lookingFor, {LookingFor.talent});
      expect(s.fundingRequirement, isNull);
      expect(s.wantsLeadInvestor, isNull);
      expect(s.raisedInRound, isNull);
      expect(saved.single.seeksFunding, isFalse);
    },
  );

  test(
    'Add round ticks Funding and moves the Stage to the round type',
    () async {
      final vm = await loaded();
      addTearDown(vm.dispose);
      await vm.closeOpenRound();
      vm.openForm();
      // Never earlier than the last round (Seed).
      expect(vm.allowedTypes.first, StartupStage.seed);
      vm.setType(StartupStage.seriesA);
      vm.amount.text = '10,000,000';
      vm.raised.text = '0';
      vm.setLead(false);
      expect(await vm.addRound(), isTrue);
      expect(vm.openRound!.number, 3);
      final s = startups.startups.single;
      expect(s.seeksFunding, isTrue);
      expect(s.fundingRequirement, 10000000);
      expect(s.raisedInRound, 0);
      expect(s.wantsLeadInvestor, isFalse);
      expect(s.stage, StartupStage.seriesA);
    },
  );

  test('a failed save leaves the round as it was', () async {
    final vm = RoundsViewModel(
      startup: startup,
      startups: _FailingStartups(),
      now: DateTime(2026, 10, 25),
    );
    addTearDown(vm.dispose);
    await Future<void>.delayed(Duration.zero);
    expect(await vm.closeOpenRound(), isFalse);
    expect(vm.openRound, isNotNull);
    expect(vm.error, isNotNull);
  });

  testWidgets('long names wrap; more than 3 investors: "+N more"', (t) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final round = FundingRound(
      number: 1,
      type: StartupStage.seriesA,
      amount: 75000000,
      raised: 65625000,
      start: DateTime(2024, 5, 1),
      investors: [
        const RoundInvestor(name: 'Lead Fund', isLead: true),
        for (var i = 1; i <= 6; i++)
          RoundInvestor(name: 'A Very Long Investor Name Number $i'),
      ],
    );
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(child: RoundsTable(rounds: [round])),
        ),
      ),
    );
    expect(find.text('Lead Fund · Lead'), findsOneWidget);
    expect(find.text('A Very Long Investor Name Number 2'), findsOneWidget);
    expect(find.text('A Very Long Investor Name Number 3'), findsNothing);
    expect(find.text('+4 more'), findsOneWidget);
    await t.tap(find.text('+4 more'));
    await t.pump();
    expect(find.text('A Very Long Investor Name Number 6'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
    await t.tap(find.text('Show less'));
    await t.pump();
    expect(find.text('A Very Long Investor Name Number 6'), findsNothing);
  });

  group('the edit form may have no asks', () {
    test('a new startup must pick at least one', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      vm.step = 4;
      vm.next();
      expect(vm.errorOf(StartupField.lookingFor), 'Select at least one.');
    });

    test('an existing startup can save with none ticked', () {
      final vm = StartupStepsViewModel(
        initial: startup.copyWith(lookingFor: {}, clearFunding: true),
      );
      addTearDown(vm.dispose);
      vm.step = 4;
      vm.next();
      expect(vm.errorOf(StartupField.lookingFor), isNull);
      expect(vm.stepComplete(4), isTrue);
    });
  });
}

class _FailingStartups extends FakeStartupRepository {
  @override
  Future<Startup> update(
    Startup startup, {
    File? newLogo,
    bool removeLogo = false,
  }) async => throw Exception('offline');
}
