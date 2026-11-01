import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/founder_tools_strings.dart';
import 'package:startsa/data_access/mock_data/prototype_seed.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/startup_ask.dart';
import 'package:startsa/features/startups/widgets/startup_step_body.dart';
import 'package:startsa/models/startup_enums.dart';

const _msg = 'This option is already in the list. Select it instead.';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('the new partner and support lists, in this order', () {
    expect(FounderToolsStrings.partnerOptions, [
      'Co-founder',
      'Distributor',
      'Technology development',
      'Supplier',
      'Marketing specialist',
      'Legal and accounting',
      'Other',
    ]);
    expect(FounderToolsStrings.supportOptions, [
      'Mentorship',
      'Hiring',
      'Incubator',
      'Accelerator',
      'Support Studios',
      'Other',
    ]);
  });

  testWidgets('no lead-investor question on the Startup Ask', (t) async {
    await t.binding.setSurfaceSize(const Size(412, 2400));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final vm = StartupStepsViewModel()..toggleLookingFor('Funding');
    addTearDown(vm.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StartupStepBody(vm: vm, step: StartupStepsViewModel.askStep),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 500));
    // Funding keeps exactly its two questions.
    expect(find.textContaining('How much are you raising?'), findsOneWidget);
    expect(find.textContaining('already raised'), findsOneWidget);
    expect(find.textContaining('lead investor'), findsNothing);
    expect(find.text('Yes'), findsNothing);
  });

  group('Other cannot repeat a listed partner or support type', () {
    test('partner: shown as it is typed, blocks Next', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      vm.toggleLookingFor('Partnership');
      vm.togglePartner('Other');
      vm.partnerOther.text = 'distributors';
      expect(vm.errorOf(StartupField.partnerTypes), _msg);
      expect(vm.stepComplete(StartupStepsViewModel.askStep), isFalse);
      vm.partnerOther.text = 'Technology Development';
      expect(vm.errorOf(StartupField.partnerTypes), _msg);
      vm.partnerOther.text = 'Banks';
      expect(vm.errorOf(StartupField.partnerTypes), isNull);
    });

    test('support: shown as it is typed', () {
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      vm.toggleLookingFor('Support');
      vm.toggleSupport('Other');
      vm.supportOther.text = 'support studio';
      expect(vm.errorOf(StartupField.supportTypes), _msg);
      vm.supportOther.text = 'accelerators';
      expect(vm.errorOf(StartupField.supportTypes), _msg);
      vm.supportOther.text = 'Grants';
      expect(vm.errorOf(StartupField.supportTypes), isNull);
    });
  });

  group('startups that saved the old options', () {
    test('their saved data is not touched; the form shows the old ones', () {
      final old = PrototypeSeed.rafeeq.copyWith(
        lookingFor: {LookingFor.partnership, LookingFor.support},
        partnerTypes: ['Marketing', 'Corporate'],
        supportTypes: ['Hiring', 'Tech development', 'Co-founder'],
      );
      // Details and the startup page read the saved text as it is.
      expect(StartupAsk.partners(old), ['Marketing', 'Corporate']);
      expect(StartupAsk.support(old), [
        'Hiring',
        'Tech development',
        'Co-founder',
      ]);
      // The form: "Hiring" is still a listed option; the removed ones show
      // together under Other (none is dropped).
      final vm = StartupStepsViewModel(initial: old);
      addTearDown(vm.dispose);
      expect(vm.supportSel, {'Hiring', 'Other'});
      expect(vm.supportOther.text, 'Tech development, Co-founder');
      expect(vm.partnerSel, {'Other'});
      expect(vm.partnerOther.text, 'Marketing, Corporate');
    });

    test('an old lead-investor answer stays as it was saved', () {
      final old = PrototypeSeed.rafeeq.copyWith(wantsLeadInvestor: true);
      final vm = StartupStepsViewModel(initial: old);
      addTearDown(vm.dispose);
      expect(vm.errorOf(StartupField.funding), isNull);
    });
  });
}
