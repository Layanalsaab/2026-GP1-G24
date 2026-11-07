import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_view_model.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/helpers/other_check.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/shared_ui/widgets/overlays/multi_picker_sheet.dart';
import 'package:startsa/shared_ui/widgets/overlays/picker_sheet.dart';

const _msg = 'This option is already in the list. Select it instead.';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('OtherCheck', () {
    const options = ['Fintech', 'HealthTech', 'AI', 'E-commerce', 'Other'];

    test('ignores capital letters, spaces and one trailing s', () {
      for (final t in [
        'fintech',
        'FINTECH',
        ' Fintech ',
        'Fin tech',
        'fintechs',
        'Health Tech',
        'healthtechs',
        'ai',
        'AIs',
        'e-commerce',
        'E-Commerces',
        'e commerce',
        'ecommerce',
      ]) {
        expect(OtherCheck.repeats(t, options), isTrue, reason: t);
      }
    });

    test('a different word is fine; blank never repeats', () {
      for (final t in ['Beekeeping', 'Fintechx', 'Health', 'Aid', '', '   ']) {
        expect(OtherCheck.repeats(t, options), isFalse, reason: t);
      }
      expect(OtherCheck.repeats(null, options), isFalse);
    });
  });

  group('Create your account sectors', () {
    test('Other repeating a listed sector is an error and blocks Continue', () {
      final vm = SignupViewModel(role: AccountRole.founder);
      addTearDown(vm.dispose);
      vm.toggleSector('Other');
      vm.sectorsOther.text = 'fintechs';
      expect(vm.sectorsOtherError, _msg);
      expect(vm.isValid, isFalse);
      vm.sectorsOther.text = 'Beekeeping';
      expect(vm.sectorsOtherError, isNull);
    });
  });

  Widget host(Widget sheet) => MaterialApp(home: Scaffold(body: sheet));

  group('Picker sheets', () {
    testWidgets('single-select: Other naming an option picks it, no error', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(412, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      PickerResult? result;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showPickerSheet(
                  context,
                  title: 'Sector',
                  options: const ['Fintech', 'HealthTech', 'Other'],
                  selected: 'Other',
                  otherNoun: 'sector',
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(EditableText).last, 'Beekeeping');
      await t.pump(const Duration(milliseconds: 600));
      expect(result, isNull);
      await t.enterText(find.byType(EditableText).last, 'fintechs');
      await t.pump(const Duration(milliseconds: 600));
      await t.pumpAndSettle();
      expect(find.text(_msg), findsNothing);
      expect(result?.value, 'Fintech');
      expect(result?.otherText, isNull);
    });

    testWidgets('commerce model: "b2b" is picked for you after a pause', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(412, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      PickerResult? result;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => result = await showPickerSheet(
                  context,
                  title: 'Commerce model',
                  options: const [
                    'Business-to-Business (B2B)',
                    'Business-to-Consumer (B2C)',
                    'Business-to-Government (B2G)',
                    'Other',
                  ],
                  selected: 'Other',
                  otherNoun: 'commerce model',
                  alsoCountsAs: StartupStepsViewModel.modelAlsoCountsAs,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      final box = find.byType(EditableText).last;
      await t.enterText(box, 'B');
      await t.pump(const Duration(milliseconds: 600));
      expect(result, isNull);
      await t.enterText(box, 'b2b');
      await t.pump(const Duration(milliseconds: 600));
      await t.pumpAndSettle();
      expect(find.text(_msg), findsNothing);
      expect(result?.value, 'Business-to-Business (B2B)');
      expect(result?.otherText, isNull);
    });

    testWidgets('multi-select: Other naming an option ticks it, no error', (
      t,
    ) async {
      final toggled = <String>[];
      await t.binding.setSurfaceSize(const Size(412, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        host(
          MultiPickerSheet(
            title: 'Sectors',
            options: const ['Fintech', 'HealthTech', 'Other'],
            selected: const {'Other'},
            onToggle: toggled.add,
            otherNoun: 'sector',
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 400));
      await t.enterText(find.byType(EditableText).last, 'Health Tech');
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text(_msg), findsNothing);
      expect(toggled, ['HealthTech', 'Other']);
    });
  });
}
