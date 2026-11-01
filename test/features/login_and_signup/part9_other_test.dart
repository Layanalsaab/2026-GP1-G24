import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/login_and_signup/view_models/investor_onboarding_view_model.dart';
import 'package:startsa/models/app_user.dart';
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

  testWidgets('the multi sheet refuses "b2b" as you type (commerce models)', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(412, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiPickerSheet(
            title: 'Commerce models',
            options: InvestorOnboardingViewModel.modelOptions,
            selected: const {'Other'},
            onToggle: (_) {},
            otherNoun: 'commerce model',
            alsoCountsAs: InvestorOnboardingViewModel.modelAlsoCountsAs,
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    final box = find.byType(EditableText).last;
    await t.enterText(box, 'b');
    await t.pump();
    expect(find.text(_msg), findsNothing);
    await t.enterText(box, 'b2b');
    await t.pump();
    expect(find.text(_msg), findsOneWidget);
    await t.enterText(box, 'Subscription boxes');
    await t.pump();
    expect(find.text(_msg), findsNothing);
  });
}
