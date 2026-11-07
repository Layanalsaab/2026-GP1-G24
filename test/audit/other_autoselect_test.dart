// An "Other" write-in that names a listed option picks that option by itself,
// silently, once the typing pauses (0.5 s): no message, "Other" is dropped.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/login_and_signup/view_models/investor_onboarding_view_model.dart';
import 'package:startsa/helpers/other_check.dart';
import 'package:startsa/shared_ui/widgets/overlays/multi_picker_sheet.dart';
import 'package:startsa/shared_ui/widgets/overlays/picker_sheet.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test(
    'OtherCheck.match finds the option, ignoring case, spaces and plural',
    () {
      const options = ['FinTech', 'HealthTech', 'Other'];
      expect(OtherCheck.match('fintechs', options), 'FinTech');
      expect(OtherCheck.match(' Health Tech ', options), 'HealthTech');
      expect(OtherCheck.match('Beekeeping', options), isNull);
      expect(OtherCheck.match('', options), isNull);
      expect(OtherCheck.match(null, options), isNull);
    },
  );

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

  const pause = Duration(milliseconds: 600);

  Future<void> pumpMulti(
    WidgetTester t,
    List<String> toggled, {
    Set<String> selected = const {'Other'},
    List<String> options = const ['Retail', 'Fintech', 'Other'],
    List<String>? others,
    Map<String, String> alsoCountsAs = const {},
  }) async {
    await t.binding.setSurfaceSize(const Size(412, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiPickerSheet(
            title: 'Sectors',
            options: options,
            selected: selected,
            onToggle: toggled.add,
            onOtherChanged: (others ?? <String>[]).add,
            otherNoun: 'sector',
            alsoCountsAs: alsoCountsAs,
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
  }

  testWidgets('multi: a listed option typed in Other is ticked after a pause', (
    t,
  ) async {
    final toggled = <String>[];
    final others = <String>[];
    await pumpMulti(t, toggled, others: others);
    await t.enterText(find.byType(EditableText).last, 'fin tech');
    await t.pump(const Duration(milliseconds: 300));
    expect(toggled, isEmpty, reason: 'still waiting for the typing to pause');
    await t.pump(pause);
    // The option is ticked, Other is unticked, its text is cleared.
    expect(toggled, ['Fintech', 'Other']);
    expect(others.last, '');
    expect(find.byType(EditableText), findsNothing);
    expect(find.textContaining('already in the list'), findsNothing);
  });

  testWidgets('multi: a longer phrase is not cut off by the shorter option', (
    t,
  ) async {
    final toggled = <String>[];
    await pumpMulti(t, toggled);
    final box = find.byType(EditableText).last;
    await t.enterText(box, 'Retail');
    await t.pump(const Duration(milliseconds: 300));
    await t.enterText(box, 'Retail stores');
    await t.pump(pause);
    expect(toggled, isEmpty);
    expect(find.byType(EditableText), findsOneWidget);
  });

  testWidgets('multi: the alias b2b ticks the commerce model', (t) async {
    final toggled = <String>[];
    await pumpMulti(
      t,
      toggled,
      options: InvestorOnboardingViewModel.modelOptions,
      alsoCountsAs: InvestorOnboardingViewModel.modelAlsoCountsAs,
    );
    await t.enterText(find.byType(EditableText).last, 'b2b');
    await t.pump(pause);
    final b2b = InvestorOnboardingViewModel.modelOptions.firstWhere(
      (o) => o.contains('B2B'),
    );
    expect(toggled, [b2b, 'Other']);
  });

  testWidgets('multi: an option already ticked stays ticked, Other goes', (
    t,
  ) async {
    final toggled = <String>[];
    await pumpMulti(t, toggled, selected: const {'Other', 'Retail'});
    await t.enterText(find.byType(EditableText).last, 'retail');
    await t.pump(pause);
    expect(toggled, ['Other'], reason: 'Retail is not toggled off');
  });

  testWidgets('multi: closing before the pause still counts the match', (
    t,
  ) async {
    final toggled = <String>[];
    await t.binding.setSurfaceSize(const Size(412, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showMultiPickerSheet(
                context,
                title: 'Sectors',
                options: const ['Retail', 'Fintech', 'Other'],
                selected: const {'Other'},
                onToggle: toggled.add,
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
    await t.enterText(find.byType(EditableText).last, 'fintech');
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    expect(toggled, ['Fintech', 'Other']);
  });

  testWidgets('multi: a new write-in ticks nothing', (t) async {
    final toggled = <String>[];
    await pumpMulti(t, toggled);
    await t.enterText(find.byType(EditableText).last, 'Subscription boxes');
    await t.pump(pause);
    expect(toggled, isEmpty);
    expect(find.byType(EditableText), findsOneWidget);
  });

  testWidgets('single: the typed option is picked after a pause, no message', (
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
                title: 'Model',
                options: const ['Pre-seed', 'Seed', 'Series A'],
                selected: 'Other',
                otherNoun: 'model',
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
    await t.pump(const Duration(milliseconds: 300));
    expect(result, isNull);
    await t.pump(pause);
    await t.pumpAndSettle();
    expect(find.textContaining('already in the list'), findsNothing);
    expect(result?.value, 'Series A');
    expect(result?.otherText, isNull);
  });
}
