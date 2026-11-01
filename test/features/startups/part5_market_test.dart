import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/startup_step_body.dart';
import 'package:startsa/shared_ui/widgets/forms/app_field.dart';

const _sam =
    'Your SAM (serviceable available market): the total amount the customers '
    'you can realistically reach spend per year on products like yours. Enter '
    'it in SAR.';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<StartupStepsViewModel> open(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(412, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final vm = StartupStepsViewModel()..step = 2;
    addTearDown(vm.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: StartupStepBody(vm: vm, step: 2)),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    return vm;
  }

  testWidgets('Target market size: the "i" explains SAM', (t) async {
    await open(t);
    expect(find.text(_sam), findsNothing);
    await t.tap(find.byType(InfoButton));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text(_sam), findsOneWidget);
    // The old explanation is gone.
    expect(
      find.textContaining(
        'The total amount customers in your target market spend',
      ),
      findsNothing,
    );
  });

  testWidgets('errors: format live, required after leaving or on Next', (
    t,
  ) async {
    final vm = await open(t);
    expect(vm.errorOf(StartupField.customers), isNull);
    expect(vm.errorOf(StartupField.marketSize), isNull);

    // Market size: a zero says so from the first keystroke.
    vm.tam.text = '0';
    expect(
      vm.errorOf(StartupField.marketSize),
      'Target market size must be more than 0.',
    );
    vm.tam.text = '5,000,000';
    expect(vm.errorOf(StartupField.marketSize), isNull);

    // Typed, emptied and left: required.
    final boxes = find.byType(TextField);
    await t.enterText(boxes.at(0), 'x');
    await t.enterText(boxes.at(0), '');
    expect(vm.errorOf(StartupField.customers), isNull, reason: 'still inside');
    await t.tap(boxes.at(1));
    await t.pump();
    expect(
      vm.errorOf(StartupField.customers),
      'Please describe your target customers.',
    );

    vm.tam.clear();
    await t.enterText(boxes.at(1), '5');
    await t.enterText(boxes.at(1), '');
    await t.tap(boxes.at(0));
    await t.pump();
    expect(
      vm.errorOf(StartupField.marketSize),
      'Please enter your target market size.',
    );
  });
}
