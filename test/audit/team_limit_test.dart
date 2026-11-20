import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/startups/view_models/startup_steps_view_model.dart';
import 'package:startsa/features/startups/widgets/startup_step_body.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/team_member.dart';

const _founder = AppUser(
  uid: 'u1',
  role: AccountRole.founder,
  fullName: 'Shahad Alabdulkarim',
  email: 'shahad@gmail.com',
);

List<TeamMember> _people(int n) => [
  for (var i = 0; i < n; i++)
    TeamMember(
      name: i == 0 ? 'Shahad Alabdulkarim' : 'Person $i',
      role: 'Role',
      contribution: 'Helps',
      isFounder: i == 0,
    ),
];

/// A team has no size limit: the founder can always add another person.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => AppSession.instance = AppSession()..signIn(_founder));

  test('a team of 20 can still get a 21st person', () {
    final vm = StartupStepsViewModel()..team = _people(20);
    addTearDown(vm.dispose);
    vm.openMemberEditor();
    expect(vm.editorOpen, isTrue);
  });

  test('a big team (60) can still get another person', () {
    final vm = StartupStepsViewModel()..team = _people(60);
    addTearDown(vm.dispose);
    vm.openMemberEditor();
    expect(vm.editorOpen, isTrue);
  });

  test('a big team can still edit one of its people', () {
    final vm = StartupStepsViewModel()..team = _people(60);
    addTearDown(vm.dispose);
    vm.openMemberEditor(3);
    expect(vm.editorOpen, isTrue);
    expect(vm.editingIndex, 3);
  });

  Future<void> show(WidgetTester t, StartupStepsViewModel vm) async {
    await t.binding.setSurfaceSize(const Size(412, 20000));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StartupStepBody(
              vm: vm,
              step: StartupStepsViewModel.teamStep,
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
  }

  for (final n in [19, 20, 21, 40]) {
    testWidgets('with $n people the Add button still shows', (t) async {
      final vm = StartupStepsViewModel()..team = _people(n);
      addTearDown(vm.dispose);
      await show(t, vm);
      expect(find.text('Add team member'), findsOneWidget);
      expect(find.textContaining('up to 20'), findsNothing);
    });
  }
}
