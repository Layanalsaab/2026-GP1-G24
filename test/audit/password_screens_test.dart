import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/account_strings.dart';
import 'package:startsa/app_constants/auth_strings.dart';
import 'package:startsa/app_constants/profile_strings.dart';
import 'package:startsa/app_constants/validation_strings.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/features/login_and_signup/screens/forgot_password_screen.dart';
import 'package:startsa/features/profiles/screens/change_password_screen.dart';
import 'package:startsa/features/profiles/screens/delete_account_dialog.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';

import '../support/fakes.dart';

Future<void> _pump(WidgetTester t, Widget screen) async {
  await t.binding.setSurfaceSize(const Size(412, 1400));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(MaterialApp(theme: AppTheme.light, home: screen));
  await t.pump(const Duration(milliseconds: 800));
}

/// Pumps past the toast timers so none is left running.
Future<void> _settle(WidgetTester t) => t.pump(const Duration(seconds: 4));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  late FakeAuthRepository auth;
  setUp(() {
    auth = FakeAuthRepository();
    AuthRepository.instance = auth;
  });

  group('Change password screen', () {
    Finder fields() => find.byType(TextField);

    testWidgets('empty form: each required field says so, nothing is sent',
        (t) async {
      await _pump(t, const ChangePasswordScreen());
      await t.tap(find.text(ProfileStrings.updatePassword));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text(AccountStrings.currentPasswordRequired), findsOneWidget);
      expect(auth.changePasswordCalls, 0);
      await _settle(t);
    });

    testWidgets('a space can not be typed in the new or confirm password',
        (t) async {
      await _pump(t, const ChangePasswordScreen());
      await t.enterText(fields().at(1), 'Ab cd 1!');
      await t.enterText(fields().at(2), 'Ab cd 1!');
      await t.pump();
      expect(t.widget<TextField>(fields().at(1)).controller!.text, 'Abcd1!');
      expect(t.widget<TextField>(fields().at(2)).controller!.text, 'Abcd1!');
    });

    testWidgets('a mismatching confirmation is shown under its field',
        (t) async {
      await _pump(t, const ChangePasswordScreen());
      await t.enterText(fields().at(0), 'Oldpass1!');
      await t.enterText(fields().at(1), 'Newpass1!x');
      await t.enterText(fields().at(2), 'Newpass1!y');
      await t.tap(find.text(ProfileStrings.updatePassword));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text(ValidationStrings.confirmMismatch), findsOneWidget);
      expect(auth.changePasswordCalls, 0);
      await _settle(t);
    });

    testWidgets('a wrong current password is reported on that field',
        (t) async {
      auth.changePasswordFails = AuthFailure.invalidCredentials;
      await _pump(t, const ChangePasswordScreen());
      await t.enterText(fields().at(0), 'Wrongpass1!');
      await t.enterText(fields().at(1), 'Newpass1!x');
      await t.enterText(fields().at(2), 'Newpass1!x');
      await t.tap(find.text(ProfileStrings.updatePassword));
      await t.pump(const Duration(milliseconds: 300));
      expect(auth.changePasswordCalls, 1);
      expect(find.text(AccountStrings.currentPasswordIncorrect), findsOneWidget);
      await _settle(t);
    });

    testWidgets('a valid change is sent once', (t) async {
      await _pump(t, const ChangePasswordScreen());
      await t.enterText(fields().at(0), 'Oldpass1!');
      await t.enterText(fields().at(1), 'Newpass1!x');
      await t.enterText(fields().at(2), 'Newpass1!x');
      await t.tap(find.text(ProfileStrings.updatePassword));
      await t.pump(const Duration(milliseconds: 300));
      expect(auth.changePasswordCalls, 1);
      await _settle(t);
    });
  });

  group('Delete account dialog', () {
    Widget host(AccountRole role) => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showDeleteAccountDialog(context, role: role),
            child: const Text('open'),
          ),
        ),
      ),
    );

    Future<void> open(WidgetTester t, AccountRole role) async {
      await _pump(t, host(role));
      await t.tap(find.text('open'));
      await t.pump(const Duration(milliseconds: 600));
    }

    testWidgets('founder and investor each see their own warning', (t) async {
      await open(t, AccountRole.founder);
      expect(find.text(AccountStrings.deleteWarningFounder), findsOneWidget);
      await t.tap(find.text(ProfileStrings.cancel));
      await t.pump(const Duration(milliseconds: 600));
      await t.tap(find.text('open'));
      await t.pump(const Duration(milliseconds: 600));
      expect(auth.deleteAccountCalls, 0);
    });

    testWidgets('investor warning', (t) async {
      await open(t, AccountRole.investor);
      expect(find.text(AccountStrings.deleteWarningInvestor), findsOneWidget);
    });

    testWidgets('no password: asks for it and deletes nothing', (t) async {
      await open(t, AccountRole.founder);
      await t.tap(find.text(ProfileStrings.deleteAccount).last);
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text(AccountStrings.passwordRequired), findsOneWidget);
      expect(auth.deleteAccountCalls, 0);
    });

    testWidgets('wrong password: says so and keeps the account', (t) async {
      auth.deleteAccountFails = AuthFailure.invalidCredentials;
      await open(t, AccountRole.founder);
      await t.enterText(find.byType(TextField), 'Wrongpass1!');
      await t.tap(find.text(ProfileStrings.deleteAccount).last);
      await t.pump(const Duration(milliseconds: 300));
      expect(auth.deleteAccountCalls, 1);
      expect(find.text(AccountStrings.passwordIncorrect), findsOneWidget);
    });

    testWidgets('correct password: the account is deleted', (t) async {
      await open(t, AccountRole.founder);
      await t.enterText(find.byType(TextField), 'Rightpass1!');
      await t.tap(find.text(ProfileStrings.deleteAccount).last);
      await t.pump(const Duration(milliseconds: 600));
      expect(auth.deleteAccountCalls, 1);
      expect(find.text(AccountStrings.cannotBeUndone), findsNothing);
    });
  });

  group('Forgot password screen', () {
    testWidgets('a malformed email is refused, nothing is sent', (t) async {
      await _pump(t, const ForgotPasswordScreen());
      await t.enterText(find.byType(TextField), 'not-an-email');
      await t.pump();
      expect(find.text(ValidationStrings.emailInvalid), findsOneWidget);
      await t.tap(find.text(AuthStrings.sendResetLink));
      await t.pump(const Duration(milliseconds: 300));
      expect(auth.resetCalls, 0);
      await _settle(t);
    });

    testWidgets('an empty email is refused after pressing Send', (t) async {
      await _pump(t, const ForgotPasswordScreen());
      await t.tap(find.text(AuthStrings.sendResetLink));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text(ValidationStrings.emailInvalid), findsOneWidget);
      expect(auth.resetCalls, 0);
      await _settle(t);
    });

    testWidgets('a valid email sends one reset link', (t) async {
      await _pump(t, const ForgotPasswordScreen(email: 'layan@gmail.com'));
      await t.tap(find.text(AuthStrings.sendResetLink));
      await t.pump(const Duration(milliseconds: 300));
      expect(auth.resetCalls, 1);
      await _settle(t);
    });

    testWidgets('a failure is reported and can be retried', (t) async {
      auth.resetFails = AuthFailure.network;
      await _pump(t, const ForgotPasswordScreen(email: 'layan@gmail.com'));
      await t.tap(find.text(AuthStrings.sendResetLink));
      await t.pump(const Duration(milliseconds: 300));
      expect(auth.resetCalls, 1);
      auth.resetFails = null;
      await _settle(t);
      await t.tap(find.text(AuthStrings.sendResetLink));
      await t.pump(const Duration(milliseconds: 300));
      expect(auth.resetCalls, 2);
      await _settle(t);
    });
  });
}
