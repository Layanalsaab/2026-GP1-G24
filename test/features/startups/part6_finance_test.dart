import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/startup_step_body.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<StartupStepsViewModel> open(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(412, 3000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final vm = StartupStepsViewModel()..step = 3;
    addTearDown(vm.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: StartupStepBody(vm: vm, step: 3)),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    return vm;
  }

  testWidgets('Finance and Growth says "revenue model", never "business"', (
    t,
  ) async {
    await open(t);
    expect(
      find.textContaining('Explain your revenue model', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('business model'), findsNothing);
    expect(find.textContaining('Business model'), findsNothing);
  });

  testWidgets('the revenue model is required after Next or after leaving', (
    t,
  ) async {
    final vm = await open(t);
    expect(vm.errorOf(StartupField.modelText), isNull);
    vm.next();
    expect(
      vm.errorOf(StartupField.modelText),
      'Please explain your revenue model.',
    );
  });

  testWidgets('money boxes: required after typing, clearing and leaving', (
    t,
  ) async {
    final vm = await open(t);
    final boxes = find.byType(TextField);
    // revenue this year is the first amount box
    await t.tap(boxes.at(0));
    await t.pump();
    await t.tap(boxes.at(1));
    await t.pump();
    expect(vm.errorOf(StartupField.revenueNow), isNull, reason: 'never typed');
    await t.enterText(boxes.at(1), '5');
    await t.enterText(boxes.at(1), '');
    await t.tap(boxes.at(0));
    await t.pump();
    expect(vm.errorOf(StartupField.capital), isNotNull);
  });
}
