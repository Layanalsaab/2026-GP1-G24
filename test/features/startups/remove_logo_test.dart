import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/startup_step_body.dart';

const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<StartupStepsViewModel> open(WidgetTester t) async {
    await t.binding.setSurfaceSize(const Size(412, 1800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final vm = StartupStepsViewModel(
      initial: PrototypeSeed.rafeeq.copyWith(id: 'x1', logoData: _png),
    );
    addTearDown(vm.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: StartupStepBody(vm: vm, step: 0)),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    return vm;
  }

  testWidgets('a saved logo can be removed', (t) async {
    final vm = await open(t);
    await t.tap(find.text('Change logo'));
    await t.pumpAndSettle();
    expect(find.text('Remove logo'), findsOneWidget);
    await t.tap(find.text('Remove logo'));
    await t.pumpAndSettle();
    expect(vm.hasLogo, isFalse);
    expect(vm.removeLogo, isTrue);
    expect(vm.isDirty, isTrue);
    expect(find.text('Upload logo'), findsOneWidget);
  });

  testWidgets('closing the sheet keeps the logo', (t) async {
    final vm = await open(t);
    await t.tap(find.text('Change logo'));
    await t.pumpAndSettle();
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    expect(vm.hasLogo, isTrue);
    expect(vm.removeLogo, isFalse);
  });
}
