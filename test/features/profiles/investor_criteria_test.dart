import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/account_strings.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/app_constants/investor_strings.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/profiles/screens/account_screen.dart';
import 'package:startsa/features/profiles/view_models/edit_criteria_view_model.dart';
import 'package:startsa/features/profiles/view_models/investor_onboarding_view_model.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';

import '../../support/fakes.dart';

void main() {
  late FakeUserRepository users;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    users = FakeUserRepository();
    UserRepository.instance = users;
    AuthRepository.instance = FakeAuthRepository();
  });

  const investor = AppUser(
    uid: 'uid3',
    role: AccountRole.investor,
    fullName: 'Layan Alsaab',
    email: 'layan@example.com',
    city: 'Riyadh',
    onboardingCompleted: true,
    preferredSectors: ['HealthTech', 'Fintech'],
    preferredStages: ['Pre-seed', 'Seed'],
    ticketSize: 'SAR 100K–500K',
  );

  group('InvestorOnboardingViewModel', () {
    InvestorOnboardingViewModel viewModel() =>
        InvestorOnboardingViewModel(userId: 'uid3', userRepository: users);

    void answerAll(InvestorOnboardingViewModel vm) {
      vm.toggleSector('Fintech');
      vm.toggleSector('HealthTech');
      vm.toggleStage('Seed');
      vm.selectTicketSize('> SAR 2M');
      vm.selectCity('Jeddah');
    }

    test('missing answers show a message and save nothing', () async {
      final vm = viewModel()
        ..toggleSector('Fintech')
        ..selectTicketSize('> SAR 2M')
        ..selectCity('Jeddah'); // no stage

      expect(await vm.submit(), isFalse);
      expect(vm.error, InvestorStrings.onboardingIncomplete);
      expect(users.investorOnboardingSaves, 0);
    });

    test('tapping a chosen sector again removes it', () {
      final vm = viewModel()
        ..toggleSector('Fintech')
        ..toggleSector('Fintech');
      expect(vm.sectors, isEmpty);
    });

    test('saves the answers in list order and marks onboarding done', () async {
      final vm = viewModel();
      answerAll(vm);

      expect(await vm.submit(), isTrue);
      expect(users.savedInvestorOnboarding, {
        'sectors': ['HealthTech', 'Fintech'],
        'stages': ['Seed'],
        'ticketSize': '> SAR 2M',
        'city': 'Jeddah',
      });

      const before = AppUser(
        uid: 'uid3',
        role: AccountRole.investor,
        fullName: 'Layan',
        email: 'l@b.co',
      );
      final after = vm.savedUser(before);
      expect(after.onboardingCompleted, isTrue);
      expect(after.city, 'Jeddah');
      expect(after.preferredSectors, ['HealthTech', 'Fintech']);
      expect(after.ticketSize, '> SAR 2M');
    });

    test('a network problem is explained and nothing is marked done', () async {
      users.onboardingFails = AuthFailure.network;
      final vm = viewModel();
      answerAll(vm);

      expect(await vm.submit(), isFalse);
      expect(vm.error, AppStrings.networkError);
      expect(vm.isLoading, isFalse);
      expect(users.savedInvestorOnboarding, isNull);
    });
  });

  test('onboarding starts with a city the investor already saved', () {
    final vm = InvestorOnboardingViewModel(
      userId: 'uid3',
      city: 'Dammam',
      userRepository: users,
    );
    expect(vm.city, 'Dammam');
  });

  group('EditCriteriaViewModel', () {
    test('an old value that is no longer an option does not count', () async {
      const old = AppUser(
        uid: 'uid4',
        role: AccountRole.investor,
        fullName: 'Old',
        email: 'o@b.co',
        preferredSectors: ['Gaming'],
        preferredStages: ['Seed'],
        ticketSize: '> SAR 2M',
      );
      final vm = EditCriteriaViewModel(user: old, userRepository: users);

      expect(await vm.submit(), isNull);
      expect(vm.error, InvestorStrings.criteriaIncomplete);
      expect(users.criteriaUpdates, 0);
    });

    test('starts from the saved criteria', () {
      final vm = EditCriteriaViewModel(user: investor, userRepository: users);
      expect(vm.sectors, {'HealthTech', 'Fintech'});
      expect(vm.stages, {'Pre-seed', 'Seed'});
      expect(vm.ticketSize, 'SAR 100K–500K');
    });

    test('removing every sector shows a message and saves nothing', () async {
      final vm = EditCriteriaViewModel(user: investor, userRepository: users)
        ..toggleSector('HealthTech')
        ..toggleSector('Fintech');

      expect(await vm.submit(), isNull);
      expect(vm.error, InvestorStrings.criteriaIncomplete);
      expect(users.criteriaUpdates, 0);
    });

    test('saves the changes and returns the updated user', () async {
      final vm = EditCriteriaViewModel(user: investor, userRepository: users)
        ..toggleSector('EdTech')
        ..toggleStage('Pre-seed')
        ..selectTicketSize('SAR 500K–2M');

      final updated = await vm.submit();
      expect(users.savedCriteria, {
        'sectors': ['HealthTech', 'Fintech', 'EdTech'],
        'stages': ['Seed'],
        'ticketSize': 'SAR 500K–2M',
      });
      expect(updated?.preferredStages, ['Seed']);
      expect(updated?.fullName, 'Layan Alsaab'); // the rest is unchanged
    });

    test('a failed save keeps the old criteria and explains why', () async {
      users.updateFails = AuthFailure.unknown;
      final vm = EditCriteriaViewModel(user: investor, userRepository: users)
        ..toggleSector('EdTech');

      expect(await vm.submit(), isNull);
      expect(vm.error, AccountStrings.saveFailed);
    });
  });

  group('Account tab criteria card', () {
    Future<void> pumpAccount(WidgetTester tester, AppUser user) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: AccountScreen(user: user)));
      await tester.pumpAndSettle();
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    testWidgets("shows the investor's saved criteria", (tester) async {
      await pumpAccount(tester, investor);

      expect(find.text(InvestorStrings.criteriaTitle), findsOneWidget);
      for (final value in [
        'HealthTech',
        'Fintech',
        'Pre-seed',
        'Seed',
        'SAR 100K–500K',
      ]) {
        expect(find.text(value), findsOneWidget);
      }
    });

    testWidgets('founders have no criteria card', (tester) async {
      await pumpAccount(
        tester,
        const AppUser(
          uid: 'uid1',
          role: AccountRole.founder,
          fullName: 'Shahad',
          email: 's@b.co',
        ),
      );
      expect(find.text(InvestorStrings.criteriaTitle), findsNothing);
    });

    testWidgets('Edit criteria saves and the card shows the change', (tester) async {
      await pumpAccount(tester, investor);

      await tapText(tester, InvestorStrings.edit);
      expect(find.text(InvestorStrings.saveCriteria), findsOneWidget);

      await tapText(tester, 'Fintech'); // remove
      await tapText(tester, 'EdTech'); // add
      await tapText(tester, InvestorStrings.saveCriteria);

      expect(users.savedCriteria?['sectors'], ['HealthTech', 'EdTech']);
      expect(find.text(InvestorStrings.saveCriteria), findsNothing); // closed
      expect(find.text(InvestorStrings.criteriaSaved), findsOneWidget);
      expect(find.text('EdTech'), findsOneWidget);
      expect(find.text('Fintech'), findsNothing);
    });
  });
}
