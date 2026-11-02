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

/// firestore.rules refuses a startup with more than 20 team cards, so the
/// app must stop at 20 instead of failing on save.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => AppSession.instance = AppSession()..signIn(_founder));

  test('the limit is the one the security rules use', () {
    expect(TeamMember.teamMax, 20);
  });

  test('a team of 19 can still get a 20th person', () {
    final vm = StartupStepsViewModel()..team = _people(19);
    addTearDown(vm.dispose);
    vm.openMemberEditor();
    expect(vm.editorOpen, isTrue);
  });

  test('a full team (20) does not open the editor for a new person', () {
    final vm = StartupStepsViewModel()..team = _people(20);
    addTearDown(vm.dispose);
    vm.openMemberEditor();
    expect(vm.editorOpen, isFalse);
  });

  test('a full team can still edit one of its people', () {
    final vm = StartupStepsViewModel()..team = _people(20);
    addTearDown(vm.dispose);
    vm.openMemberEditor(3);
    expect(vm.editorOpen, isTrue);
    expect(vm.editingIndex, 3);
  });

  Future<void> show(WidgetTester t, StartupStepsViewModel vm) async {
    await t.binding.setSurfaceSize(const Size(412, 6000));
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

  testWidgets('with 19 people the Add button shows', (t) async {
    final vm = StartupStepsViewModel()..team = _people(19);
    addTearDown(vm.dispose);
    await show(t, vm);
    expect(find.text('Add team member'), findsOneWidget);
    expect(find.text('A team can have up to 20 people.'), findsNothing);
  });

  testWidgets('with 20 people the Add button is replaced by a note', (t) async {
    final vm = StartupStepsViewModel()..team = _people(20);
    addTearDown(vm.dispose);
    await show(t, vm);
    expect(find.text('Add team member'), findsNothing);
    expect(find.text('A team can have up to 20 people.'), findsOneWidget);
  });
}
