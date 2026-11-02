// An "Other" write-in that repeats a listed option still shows the error, and
// now also selects that option for the person.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/login_and_signup/view_models/investor_onboarding_view_model.dart';
import 'package:startsa/helpers/other_check.dart';
import 'package:startsa/shared_ui/widgets/overlays/multi_picker_sheet.dart';
import 'package:startsa/shared_ui/widgets/overlays/picker_sheet.dart';

const _msg = 'This option is already in the list. Select it instead.';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('OtherCheck.match finds the option, ignoring case, spaces and plural', () {
    const options = ['FinTech', 'HealthTech', 'Other'];
    expect(OtherCheck.match('fintechs', options), 'FinTech');
    expect(OtherCheck.match(' Health Tech ', options), 'HealthTech');
    expect(OtherCheck.match('Beekeeping', options), isNull);
    expect(OtherCheck.match('', options), isNull);
    expect(OtherCheck.match(null, options), isNull);
  });

  test('OtherCheck.match maps an alias to its option', () {
    final m = InvestorOnboardingViewModel.modelAlsoCountsAs;
    final options = InvestorOnboardingViewModel.modelOptions;
    final b2b = options.firstWhere((o) => o.contains('B2B'));
    expect(OtherCheck.match('b2b', options, alsoCountsAs: m), b2b);
    expect(
      OtherCheck.match('business to business', options, alsoCountsAs: m),
      b2b,
    );
  });

  Future<void> pumpMulti(
    WidgetTester t,
    List<String> toggled, {
    Set<String> selected = const {'Other'},
  }) async {
    await t.binding.setSurfaceSize(const Size(412, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiPickerSheet(
            title: 'Commerce models',
            options: InvestorOnboardingViewModel.modelOptions,
            selected: selected,
            onToggle: toggled.add,
            otherNoun: 'commerce model',
            alsoCountsAs: InvestorOnboardingViewModel.modelAlsoCountsAs,
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('multi: typing a listed option shows the error and ticks it', (
    t,
  ) async {
    final toggled = <String>[];
    await pumpMulti(t, toggled);
    final box = find.byType(EditableText).last;
    await t.enterText(box, 'b2b');
    await t.pump();
    expect(find.text(_msg), findsOneWidget);
    final b2b = InvestorOnboardingViewModel.modelOptions.firstWhere(
      (o) => o.contains('B2B'),
    );
    expect(toggled, [b2b]);
    // Typing more of the same option does not tick it twice.
    await t.enterText(box, 'B2B ');
    await t.pump();
    expect(toggled, [b2b]);
  });

  testWidgets('multi: a new write-in ticks nothing', (t) async {
    final toggled = <String>[];
    await pumpMulti(t, toggled);
    await t.enterText(find.byType(EditableText).last, 'Subscription boxes');
    await t.pump();
    expect(find.text(_msg), findsNothing);
    expect(toggled, isEmpty);
  });

  testWidgets('single: the repeated option is selected and Done picks it', (
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
                title: 'Stage',
                options: const ['Pre-seed', 'Seed', 'Series A'],
                selected: 'Other',
                otherNoun: 'stage',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(EditableText).last, 'series a');
    await t.pumpAndSettle();
    expect(find.text(_msg), findsOneWidget);
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(result?.value, 'Series A');
    expect(result?.otherText, isNull);
  });
}
