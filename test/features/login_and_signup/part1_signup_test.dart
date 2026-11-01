import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_view_model.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/shared_ui/widgets/forms/visibility_switch.dart';

Widget _switch({required bool isPublic, ValueChanged<bool>? onChanged}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: VisibilitySwitch(
            isPublic: isPublic,
            onChanged: onChanged ?? (_) {},
            fieldName: 'email',
          ),
        ),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Visibility switch', () {
    testWidgets('Private: the word, a 40 x 24 grey track, a 18 x 18 knob', (
      t,
    ) async {
      await t.pumpWidget(_switch(isPublic: false));
      expect(find.text('Private'), findsOneWidget);
      expect(
        t.getSize(find.byKey(const ValueKey('visibility-track'))),
        const Size(40, 24),
      );
      expect(
        t.getSize(find.byKey(const ValueKey('visibility-knob'))),
        const Size(18, 18),
      );
      final track = t.widget<AnimatedContainer>(
        find.byKey(const ValueKey('visibility-track')),
      );
      expect(
        (track.decoration! as BoxDecoration).color,
        const Color(0xFFD6D3CC),
      );
    });

    testWidgets('Public: moss track and the knob 16 px to the right', (
      t,
    ) async {
      await t.pumpWidget(_switch(isPublic: false));
      double knobInTrack() =>
          t.getTopLeft(find.byKey(const ValueKey('visibility-knob'))).dx -
          t.getTopLeft(find.byKey(const ValueKey('visibility-track'))).dx;
      final off = knobInTrack();
      await t.pumpWidget(_switch(isPublic: true));
      await t.pumpAndSettle();
      expect(find.text('Public'), findsOneWidget);
      expect(knobInTrack() - off, 16);
      final track = t.widget<AnimatedContainer>(
        find.byKey(const ValueKey('visibility-track')),
      );
      expect(
        (track.decoration! as BoxDecoration).color,
        const Color(0xFF2F5D3A),
      );
    });

    testWidgets('a tap flips it', (t) async {
      bool? got;
      await t.pumpWidget(_switch(isPublic: false, onChanged: (v) => got = v));
      await t.tap(find.byKey(const ValueKey('visibility-knob')));
      expect(got, isTrue);
    });

    testWidgets('the screen-reader label says what a tap does', (t) async {
      await t.pumpWidget(_switch(isPublic: false));
      expect(
        find.bySemanticsLabel('Your email is private. Tap to make it public.'),
        findsOneWidget,
      );
      await t.pumpWidget(_switch(isPublic: true));
      expect(
        find.bySemanticsLabel('Your email is public. Tap to make it private.'),
        findsOneWidget,
      );
    });
  });

  group('Create your account: errors while typing', () {
    late SignupViewModel vm;
    setUp(() => vm = SignupViewModel(role: AccountRole.founder));
    tearDown(() => vm.dispose());

    test('an untouched empty form shows no error at all', () {
      expect(vm.nameError, isNull);
      expect(vm.emailError, isNull);
      expect(vm.phoneError, isNull);
      expect(vm.bioError, isNull);
      expect(vm.confirmError, isNull);
    });

    test(
      'format errors show from the first keystroke and clear when valid',
      () {
        vm.name.text = 'S';
        expect(vm.nameError, isNotNull);
        vm.name.text = 'Sara Alswailem';
        expect(vm.nameError, isNull);
        vm.name.text = 'Sara 2';
        expect(vm.nameError, isNotNull);

        vm.email.text = 's';
        expect(vm.emailError, isNotNull);
        vm.email.text = 'sara@gmail.com';
        expect(vm.emailError, isNull);

        vm.phone.text = '5';
        expect(vm.phoneError, isNotNull);
        vm.phone.text = '512345678';
        expect(vm.phoneError, isNull);

        vm.linkedin.text = 'x';
        expect(vm.linkedinError, isNotNull);
        vm.linkedin.text = 'linkedin.com/in/sara';
        expect(vm.linkedinError, isNull);

        vm.password.text = 'Abcdef1!';
        vm.confirm.text = 'Abc';
        expect(vm.confirmError, isNotNull);
        vm.confirm.text = 'Abcdef1!';
        expect(vm.confirmError, isNull);
      },
    );

    test('a required message appears after Continue is pressed', () {
      vm.attempted = true;
      expect(vm.nameError, isNotNull);
      expect(vm.emailError, isNotNull);
      expect(vm.phoneError, isNotNull);
      expect(vm.bioError, isNotNull);
    });
  });

  group('Required errors after leaving a field (with a widget tree)', () {
    testWidgets('typed then left empty -> required; never typed -> none', (
      t,
    ) async {
      final vm = SignupViewModel(role: AccountRole.founder);
      addTearDown(vm.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(controller: vm.name, focusNode: vm.nameFocus),
                TextField(controller: vm.email, focusNode: vm.emailFocus),
                TextField(controller: vm.bio, focusNode: vm.bioFocus),
              ],
            ),
          ),
        ),
      );
      // Tab through a field that was never typed in: no error.
      vm.nameFocus.requestFocus();
      await t.pump();
      vm.emailFocus.requestFocus();
      await t.pump();
      expect(vm.nameError, isNull);

      // Type in the e-mail, empty it, leave: now it is required.
      await t.enterText(find.byType(TextField).at(1), 'a');
      await t.enterText(find.byType(TextField).at(1), '');
      expect(vm.emailError, isNull, reason: 'still in the field');
      vm.bioFocus.requestFocus();
      await t.pump();
      expect(vm.emailError, isNotNull);
      expect(vm.bioError, isNull, reason: 'the bio was never typed in');
    });
  });
}
