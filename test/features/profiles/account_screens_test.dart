import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/account_strings.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/profiles/screens/account_screen.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/auth_failure.dart';

import '../../support/fakes.dart';

void main() {
  late FakeAuthRepository repo;
  late FakeUserRepository users;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    repo = FakeAuthRepository();
    users = FakeUserRepository();
    AuthRepository.instance = repo;
    UserRepository.instance = users;
  });

  const investor = AppUser(
    uid: 'uid2',
    role: AccountRole.investor,
    fullName: 'Khalid Al-Mansour',
    email: 'khalid@example.com',
    city: 'Riyadh',
  );

  Future<void> pumpAccount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: AccountScreen(user: investor)));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the saved details', (tester) async {
    await pumpAccount(tester);

    expect(find.text('Khalid Al-Mansour'), findsOneWidget);
    expect(find.text('KA'), findsOneWidget);
    expect(find.text('Investor · Riyadh'), findsOneWidget);
    expect(find.text('khalid@example.com'), findsOneWidget);
    expect(find.text(AccountStrings.notAddedYet), findsOneWidget); // no bio yet
  });

  testWidgets('edit account saves and shows the new name', (tester) async {
    await pumpAccount(tester);
    await tapText(tester, AccountStrings.editAccount);

    await tester.enterText(find.byType(TextField).first, 'Khalid Mansour');
    await tapText(tester, AccountStrings.saveChanges);

    expect(users.savedProfile?['fullName'], 'Khalid Mansour');
    expect(find.text('Khalid Mansour'), findsOneWidget);
    expect(find.text(AccountStrings.changesSaved), findsOneWidget);
  });

  testWidgets('log out asks first; Cancel keeps the user signed in', (tester) async {
    await pumpAccount(tester);

    await tapText(tester, AppStrings.logOut);
    expect(find.text(AccountStrings.logOutTitle), findsOneWidget);

    await tapText(tester, AccountStrings.cancel);
    expect(repo.signOutCalls, 0);
    expect(find.text(AccountStrings.logOutTitle), findsNothing);

    await tapText(tester, AppStrings.logOut); // the menu row
    await tapText(tester, AppStrings.logOut); // the dialog button
    expect(repo.signOutCalls, 1);
    expect(find.text('Create account'), findsOneWidget); // the Start screen
  });

  testWidgets('change password: wrong current password, then success', (tester) async {
    await pumpAccount(tester);
    await tapText(tester, AccountStrings.settings);
    await tapText(tester, AccountStrings.changePassword);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Wrong123');
    await tester.enterText(fields.at(1), 'NewPass1');
    await tester.enterText(fields.at(2), 'NewPass1');

    repo.changePasswordFails = AuthFailure.invalidCredentials;
    await tapText(tester, AccountStrings.updatePassword);
    expect(find.text(AccountStrings.currentPasswordIncorrect), findsOneWidget);

    repo.changePasswordFails = null;
    await tester.enterText(fields.at(0), 'OldPass1');
    await tapText(tester, AccountStrings.updatePassword);

    expect(repo.changePasswordCalls, 2);
    expect(find.text(AccountStrings.passwordUpdated), findsOneWidget);
    expect(find.text(AccountStrings.updatePassword), findsNothing); // closed
  });

  testWidgets('Back is blocked while the new password is being saved', (tester) async {
    final saving = Completer<void>();
    repo.gate = saving.future;
    await pumpAccount(tester);
    await tapText(tester, AccountStrings.settings);
    await tapText(tester, AccountStrings.changePassword);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'OldPass1');
    await tester.enterText(fields.at(1), 'NewPass1');
    await tester.enterText(fields.at(2), 'NewPass1');
    await tester.tap(find.text(AccountStrings.updatePassword));
    await tester.pump(); // saving (spinner), so no pumpAndSettle here

    await tester.binding.handlePopRoute(); // the phone's back button
    await tester.pump();
    expect(find.text(AccountStrings.currentPasswordLabel), findsOneWidget); // still here

    saving.complete();
    await tester.pumpAndSettle();
    expect(find.text(AccountStrings.passwordUpdated), findsOneWidget);
    expect(find.text(AccountStrings.currentPasswordLabel), findsNothing); // closed
  });

  testWidgets('delete account: wrong password, then deleted', (tester) async {
    await pumpAccount(tester);
    await tapText(tester, AccountStrings.settings);
    await tapText(tester, AccountStrings.deleteAccount); // the Settings row

    expect(find.text(AccountStrings.deleteTitle), findsOneWidget);
    expect(find.text(AccountStrings.deleteWarningInvestor), findsOneWidget);

    repo.deleteAccountFails = AuthFailure.invalidCredentials;
    await tester.enterText(find.byType(TextField).last, 'Wrong123');
    await tapText(tester, AccountStrings.deleteAccount); // the dialog button
    expect(find.text(AccountStrings.passwordIncorrect), findsOneWidget);

    repo.deleteAccountFails = null;
    await tapText(tester, AccountStrings.deleteAccount);

    expect(repo.deleteAccountCalls, 2);
    expect(find.text('Create account'), findsOneWidget); // the Start screen
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse); // Back can't return into the app
  });
}
