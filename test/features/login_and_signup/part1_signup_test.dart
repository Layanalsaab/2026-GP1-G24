import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/login_and_signup/view_models/signup_view_model.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/shared_ui/widgets/forms/visibility_picker.dart';

Widget _picker({
  bool isPublic = false,
  String field = 'email',
  ValueChanged<bool>? onChanged,
}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: VisibilityPicker(
        isPublic: isPublic,
        onChanged: onChanged ?? (_) {},
        fieldName: field,
      ),
    ),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('Visibility picker', () {
    testWidgets('Only you is the private look; Public is the other', (t) async {
      await t.pumpWidget(_picker());
      expect(find.text('Only you'), findsOneWidget);
      expect(find.text('Public'), findsNothing);
      await t.pumpWidget(_picker(isPublic: true));
      expect(find.text('Public'), findsOneWidget);
      expect(find.text('Only you'), findsNothing);
    });

    testWidgets('the button is at least 32 px tall', (t) async {
      await t.pumpWidget(_picker());
      final box = find.ancestor(
        of: find.text('Only you'),
        matching: find.byType(Container),
      );
      expect(t.getSize(box.first).height, greaterThanOrEqualTo(32));
    });

    testWidgets('a tap opens the sheet; picking Public closes it', (t) async {
      bool? got;
      await t.pumpWidget(_picker(onChanged: (v) => got = v));
      await t.tap(find.text('Only you'));
      await t.pumpAndSettle();
      expect(find.text('Who can see your email?'), findsOneWidget);
      expect(
        find.text('Anyone on Start.sa can see your email on your profile.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'Your email stays private and is never shown on your profile.',
        ),
        findsOneWidget,
      );
      await t.tap(find.text('Public'));
      await t.pumpAndSettle();
      expect(got, isTrue);
      expect(find.text('Who can see your email?'), findsNothing);
    });

    testWidgets('picking the current choice changes nothing', (t) async {
      var calls = 0;
      await t.pumpWidget(_picker(onChanged: (_) => calls++));
      await t.tap(find.text('Only you'));
      await t.pumpAndSettle();
      await t.tap(find.text('Only you').last);
      await t.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('Who can see your email?'), findsNothing);
    });

    testWidgets('the phone number says phone number', (t) async {
      await t.pumpWidget(_picker(field: 'phone'));
      await t.tap(find.text('Only you'));
      await t.pumpAndSettle();
      expect(find.text('Who can see your phone number?'), findsOneWidget);
      expect(
        find.text(
          'Anyone on Start.sa can see your phone number on your profile.',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Your phone number stays private and is never shown on your profile.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the screen-reader label says who can see it', (t) async {
      await t.pumpWidget(_picker());
      expect(
        find.bySemanticsLabel(
          'Who can see your email: only you. Tap to change.',
        ),
        findsOneWidget,
      );
      await t.pumpWidget(_picker(isPublic: true, field: 'phone'));
      expect(
        find.bySemanticsLabel(
          'Who can see your phone number: everyone. Tap to change.',
        ),
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
