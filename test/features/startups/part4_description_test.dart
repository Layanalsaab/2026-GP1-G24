import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/startup_step_body.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Startup Description: the unique question has the new hint', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(412, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final vm = StartupStepsViewModel()..step = 1;
    addTearDown(vm.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: StartupStepBody(vm: vm, step: 1)),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    // The question is unchanged; only its placeholder changed.
    expect(
      find.textContaining(
        'What makes your startup unique?',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.text('What you do better or differently than your competitors'),
      findsOneWidget,
    );
    expect(
      find.text('What you do better or differently than others'),
      findsNothing,
    );
  });

  testWidgets('required messages: after leaving a typed field, or on Next', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(412, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final vm = StartupStepsViewModel()..step = 1;
    addTearDown(vm.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: StartupStepBody(vm: vm, step: 1)),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    // Nothing is red before anybody touches the step.
    expect(vm.errorOf(StartupField.problem), isNull);
    expect(vm.errorOf(StartupField.solution), isNull);
    expect(vm.errorOf(StartupField.advantage), isNull);

    final boxes = find.byType(TextField);
    // Tab into the problem field and out again without typing: still clean.
    await t.tap(boxes.at(0));
    await t.pump();
    await t.tap(boxes.at(1));
    await t.pump();
    expect(vm.errorOf(StartupField.problem), isNull);

    // Type in the solution, empty it and leave: now it is required.
    await t.enterText(boxes.at(1), 'x');
    await t.enterText(boxes.at(1), '');
    expect(vm.errorOf(StartupField.solution), isNull, reason: 'still inside');
    await t.tap(boxes.at(2));
    await t.pump();
    expect(vm.errorOf(StartupField.solution), 'Please describe your solution.');
    expect(vm.errorOf(StartupField.advantage), isNull);

    // Next shows all three.
    vm.next();
    expect(vm.errorOf(StartupField.problem), isNotNull);
    expect(vm.errorOf(StartupField.advantage), isNotNull);
  });
}
