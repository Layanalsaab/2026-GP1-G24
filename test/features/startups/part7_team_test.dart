import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/startup_step_body.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';

const _founder = AppUser(
  uid: 'u1',
  role: AccountRole.founder,
  fullName: 'Shahad Alabdulkarim',
  email: 'shahad@gmail.com',
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => AppSession.instance = AppSession()..signIn(_founder));

  group('the team editor: no numbers in the name or the role', () {
    late StartupStepsViewModel vm;
    setUp(() {
      vm = StartupStepsViewModel()..step = StartupStepsViewModel.teamStep;
      vm.openMemberEditor();
    });
    tearDown(() => vm.dispose());

    test('Full name: the message shows from the first digit', () {
      vm.memberName.text = 'Sara 2';
      expect(vm.memberError(vm.memberName), "Names can't contain numbers.");
      vm.memberName.text = '7';
      expect(vm.memberError(vm.memberName), "Names can't contain numbers.");
      vm.memberName.text = 'Sara Alswailem';
      expect(vm.memberError(vm.memberName), isNull);
    });

    test('Role: the message shows from the first digit', () {
      vm.memberRole.text = 'CTO 2';
      expect(vm.memberError(vm.memberRole), "The role can't contain numbers.");
      vm.memberRole.text = '3';
      expect(vm.memberError(vm.memberRole), "The role can't contain numbers.");
      vm.memberRole.text = 'CTO';
      expect(vm.memberError(vm.memberRole), isNull);
    });

    test('a digit stops the member from being added', () async {
      vm.memberName.text = 'Sara Alswailem';
      vm.memberEmail.text = 'sara@gmail.com';
      vm.memberContribution.text = 'Operations';
      vm.memberRole.text = 'COO 1';
      expect(vm.memberComplete, isFalse);
      expect(await vm.saveMember(inviteConfirmed: true), MemberSave.invalid);
      vm.memberRole.text = 'COO';
      expect(vm.memberComplete, isTrue);
      vm.memberName.text = 'Sara 3 Alswailem';
      expect(vm.memberComplete, isFalse);
      expect(await vm.saveMember(inviteConfirmed: true), MemberSave.invalid);
    });

    test('the founder cannot put a number in their own role either', () {
      vm.cancelMemberEditor();
      final founderIndex = vm.team.indexWhere((m) => m.isFounder);
      vm.openMemberEditor(founderIndex);
      vm.memberRole.text = 'CEO 1';
      expect(vm.memberComplete, isFalse);
      vm.memberRole.text = 'CEO';
      vm.memberContribution.text = 'Leads';
      expect(vm.memberComplete, isTrue);
    });

    test('an untouched editor shows no red', () {
      expect(vm.memberError(vm.memberName), isNull);
      expect(vm.memberError(vm.memberEmail), isNull);
      expect(vm.memberError(vm.memberRole), isNull);
      expect(vm.memberError(vm.memberContribution), isNull);
    });
  });

  group('step order', () {
    test('Startup Team is step 5 of 6, the Startup Ask is the last', () {
      expect(StartupStepsViewModel.teamStep, 4);
      expect(StartupStepsViewModel.askStep, 5);
      final vm = StartupStepsViewModel()..step = StartupStepsViewModel.teamStep;
      addTearDown(vm.dispose);
      expect(vm.next(), isNot(StepAdvance.readyToSave));
    });

    testWidgets('each step shows its own content', (t) async {
      await t.binding.setSurfaceSize(const Size(412, 2200));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final vm = StartupStepsViewModel();
      addTearDown(vm.dispose);
      Future<void> show(int step) async {
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StartupStepBody(vm: vm, step: step),
              ),
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 300));
      }

      await show(StartupStepsViewModel.teamStep);
      expect(find.text('Add team member'), findsOneWidget);
      expect(find.text('Funding'), findsNothing);
      await show(StartupStepsViewModel.askStep);
      expect(find.text('Funding'), findsOneWidget);
      expect(find.text('Add team member'), findsNothing);
    });
  });
}
