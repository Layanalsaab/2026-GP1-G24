import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/login_and_signup/view_models/investor_onboarding_view_model.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_view_model.dart';
import 'package:startsa/features/profiles/view_models/edit_account_view_model.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/investor_criteria.dart';
import 'package:startsa/models/startup_enums.dart';

import '../../support/fakes.dart';

import 'package:startsa/shared_ui/widgets/overlays/multi_picker_sheet.dart';

const _investor = AppUser(
  uid: 'u1',
  role: AccountRole.investor,
  fullName: 'Layan Alsaab',
  email: 'layan@gmail.com',
);

const _msg = 'This option is already in the list. Select it instead.';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Investor: Other cannot repeat a listed sector or commerce model', () {
    late InvestorOnboardingViewModel vm;
    setUp(() => vm = InvestorOnboardingViewModel(user: _investor));
    tearDown(() => vm.dispose());

    test('sectors: shown as it is typed, blocks Next', () {
      vm.toggleSector('Fintech');
      vm.toggleSector('Other');
      vm.sectorsOther.text = 'fintechs';
      expect(vm.sectorsOtherError, _msg);
      expect(vm.step4Complete, isFalse);
      vm.sectorsOther.text = 'Fin Tech';
      expect(vm.sectorsOtherError, _msg);
      vm.sectorsOther.text = 'Beekeeping';
      expect(vm.sectorsOtherError, isNull);
    });

    test('commerce models: the short name and the long name both repeat', () {
      vm.toggleModel('Other');
      for (final t in [
        'b2b',
        'B2C',
        'Business to Business',
        'business-to-government',
      ]) {
        vm.modelsOther.text = t;
        expect(vm.modelsOtherError, _msg, reason: t);
      }
      vm.modelsOther.text = 'Subscription boxes';
      expect(vm.modelsOtherError, isNull);
    });

    test('an Other that is not ticked is never checked', () {
      vm.sectorsOther.text = 'fintech';
      expect(vm.sectorsOtherError, isNull);
    });
  });

  testWidgets('the multi sheet picks "b2b" for you (commerce models)', (
    t,
  ) async {
    final toggled = <String>[];
    await t.binding.setSurfaceSize(const Size(412, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiPickerSheet(
            title: 'Commerce models',
            options: InvestorOnboardingViewModel.modelOptions,
            selected: const {'Other'},
            onToggle: toggled.add,
            otherNoun: 'commerce model',
            alsoCountsAs: InvestorOnboardingViewModel.modelAlsoCountsAs,
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    final box = find.byType(EditableText).last;
    await t.enterText(box, 'b');
    await t.pump(const Duration(milliseconds: 600));
    expect(toggled, isEmpty);
    await t.enterText(box, 'b2b');
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text(_msg), findsNothing);
    expect(toggled, ['Business-to-Business (B2B)', 'Other']);
  });

  group('Investor and founder share one list and one "Other" rule', () {
    final all = [for (final s in Sector.values) s.label];

    test(
      'the sector list is the same for founders, investors and startups',
      () {
        expect(InvestorOnboardingViewModel.sectorOptions, all);
        expect(SignupViewModel.sectorOptions, all);
        expect(EditAccountViewModel.sectorOptions, all);
        expect(all.length, 25);
        expect(all.last, 'Other');
      },
    );

    test('every sector, in any capitals, is refused as an investor Other', () {
      final vm = InvestorOnboardingViewModel(user: _investor);
      addTearDown(vm.dispose);
      vm.toggleSector('Other');
      for (final s in all.where((s) => s != 'Other')) {
        for (final typed in [s, s.toUpperCase(), s.toLowerCase(), ' $s ']) {
          vm.sectorsOther.text = typed;
          expect(vm.sectorsOtherError, _msg, reason: typed);
        }
      }
      vm.sectorsOther.text = 'Beekeeping';
      expect(vm.sectorsOtherError, isNull);
    });

    test('the founder sign-up refuses the same texts', () {
      final vm = SignupViewModel(role: AccountRole.founder);
      addTearDown(vm.dispose);
      vm.toggleSector('Other');
      for (final s in all.where((s) => s != 'Other')) {
        for (final typed in [s, s.toUpperCase(), s.toLowerCase()]) {
          vm.sectorsOther.text = typed;
          expect(vm.sectorsOtherRepeats, isTrue, reason: typed);
        }
      }
    });

    test('Edit profile (investor) cannot be saved with a repeated Other', () {
      final vm = EditAccountViewModel(
        user: _investor.copyWith(
          bio: 'Angel investor.',
          phone: '512345678',
          city: 'Riyadh',
          gain: 'Good teams',
          valueOffered: 'Intros',
          investorCriteria: const InvestorCriteria(
            yearsInvesting: '1–3 years',
            dealsCount: '0',
            sectors: ['HealthTech'],
            stages: ['Seed'],
            commerceModels: ['Business-to-Business (B2B)'],
            lookFor: 'Good teams',
          ),
        ),
        userRepository: FakeUserRepository(),
      );
      addTearDown(vm.dispose);
      expect(vm.isValid, isTrue);
      vm.criteria!.toggleSector('Other');
      vm.criteria!.sectorsOther.text = 'FINTECH';
      expect(vm.criteria!.sectorsOtherError, _msg);
      expect(vm.isValid, isFalse);
      vm.criteria!.sectorsOther.text = 'Beekeeping';
      expect(vm.isValid, isTrue);
    });
  });

  testWidgets('the sectors sheet picks FINTECH / fin tech for you', (t) async {
    final toggled = <String>[];
    await t.binding.setSurfaceSize(const Size(412, 3000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiPickerSheet(
            title: 'Sectors',
            options: InvestorOnboardingViewModel.sectorOptions,
            selected: const {'Other'},
            onToggle: toggled.add,
            searchHint: 'Search sectors',
            otherNoun: 'sector',
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    // Narrow the long list to its last row, so the write-in box is built.
    await t.enterText(find.byType(EditableText).first, 'oth');
    await t.pump();
    await t.enterText(find.byType(EditableText).last, 'FINTECH');
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text(_msg), findsNothing);
    expect(toggled, ['Fintech', 'Other']);
  });
}
