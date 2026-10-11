import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/account_strings.dart';
import 'package:startsa/app_constants/app_strings.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/profiles/screens/account_screen.dart';
import 'package:startsa/features/profiles/screens/settings_screen.dart';
import 'package:startsa/shared_ui/theme/theme_controller.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/startup.dart';
import 'package:startsa/models/auth_failure.dart';

import '../../support/fakes.dart';

/// Only counted, never read.
class _AnyStartup extends Fake implements Startup {}

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

  final investor = AppUser(
    uid: 'uid2',
    role: AccountRole.investor,
    fullName: 'Khalid Al-Mansour',
    email: 'khalid@example.com',
    city: 'Riyadh',
    bio: 'Angel investor.',
    phone: '509876543',
    sectorsOfInterest: ['Fintech'],
    createdAt: DateTime(2026, 10, 3),
  );

  Future<void> pumpAccount(
    WidgetTester tester, {
    AppUser? user,
    AccountRole? role,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    var shown = user ?? investor;
    if (role != null) {
      shown = AppUser(
        uid: shown.uid,
        role: role,
        fullName: shown.fullName,
        email: shown.email,
      );
    }
    await tester.pumpWidget(MaterialApp(home: AccountScreen(user: shown)));
    await tester.pumpAndSettle();
  }

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: SettingsScreen(user: investor)));
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    // Scroll it into view first: the investor's criteria card can push the
    // menu below the bottom of the test screen.
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the saved details', (tester) async {
    await pumpAccount(tester);

    expect(find.text('Khalid Al-Mansour'), findsOneWidget);
    expect(find.text('KA'), findsOneWidget);
    expect(find.text('Investor'), findsOneWidget);
    expect(find.text('Riyadh'), findsOneWidget);
    expect(find.text('khalid@example.com'), findsOneWidget);
    expect(find.text('+966 50 987 6543'), findsOneWidget);
    expect(find.text('Joined October 2026'), findsOneWidget);
    expect(find.text('Angel investor.'), findsOneWidget);
    expect(find.text('0 Associations', findRichText: true), findsOneWidget);
    expect(find.text(AccountStrings.editAccount), findsOneWidget);
  });

  testWidgets('a founder sees how many startups they have', (tester) async {
    final startups = FakeStartupRepository();
    StartupRepository.instance = startups;
    startups.startups.addAll([_AnyStartup(), _AnyStartup()]);
    await pumpAccount(
      tester,
      user: investor.copyWith(),
      role: AccountRole.founder,
    );

    expect(find.text('2 Startups', findRichText: true), findsOneWidget);
  });

  testWidgets('edit profile saves and shows the new name', (tester) async {
    await pumpAccount(tester);
    await tapText(tester, AccountStrings.editAccount);
    expect(find.text('Edit profile'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Khalid Mansour');
    await tapText(tester, AccountStrings.save);

    expect(users.savedProfile?['fullName'], 'Khalid Mansour');
    expect(users.savedProfile?['phone'], '509876543');
    expect(find.text('Khalid Mansour'), findsOneWidget);
    expect(find.text(AccountStrings.changesSaved), findsOneWidget);
  });

  testWidgets('edit profile uses the same limits as sign-up', (tester) async {
    await pumpAccount(tester);
    await tapText(tester, AccountStrings.editAccount);

    final fields = find.byType(TextField);
    // Name 50, bio 160, email 100 (read-only), phone 9.
    await tester.enterText(fields.at(0), 'A' * 80);
    await tester.enterText(fields.at(1), 'b' * 200);
    await tester.pumpAndSettle();

    expect(AccountStrings.bioMaxLength, 160);
    expect(find.text('50/50'), findsOneWidget);
    expect(find.text('160/160'), findsOneWidget);
    expect(find.text('18/100'), findsOneWidget);
    expect(find.text('9/9'), findsOneWidget);
  });

  testWidgets('edit profile rejects a phone that does not start with 5', (
    tester,
  ) async {
    await pumpAccount(tester);
    await tapText(tester, AccountStrings.editAccount);

    await tester.enterText(find.byType(TextField).last, '412345678');
    await tapText(tester, AccountStrings.save);

    expect(users.profileUpdates, 0);
    expect(find.text(AppStrings.rulePhoneStart), findsOneWidget);
    expect(find.text(AccountStrings.save), findsOneWidget); // still editing
  });

  testWidgets('Settings shows the Figma rows', (tester) async {
    await pumpSettings(tester);

    for (final text in [
      AccountStrings.settings,
      AccountStrings.sectionDisplay,
      AccountStrings.darkMode,
      AccountStrings.darkModeHint,
      AccountStrings.sectionNotifications,
      AccountStrings.notificationSettings,
      AccountStrings.notificationSettingsHint,
      AccountStrings.sectionAccount,
      AccountStrings.changePassword,
      AccountStrings.deleteAccount,
      AccountStrings.deleteAccountHint,
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('Notification settings opens the placeholder', (tester) async {
    await pumpSettings(tester);
    await tapText(tester, AccountStrings.notificationSettings);

    expect(find.text('Notifications'), findsWidgets);
  });

  testWidgets('Dark mode switch toggles and is remembered', (tester) async {
    final settings = FakeAppSettingsRepository();
    final theme = ThemeController(settings: settings);
    ThemeController.instance = theme;
    await pumpSettings(tester);

    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    expect(theme.value, ThemeMode.dark);
    expect(settings.darkMode, isTrue);

    // A fresh controller (next app start) picks the saved choice up.
    final next = ThemeController(settings: settings);
    await next.load();
    expect(next.value, ThemeMode.dark);
  });

  testWidgets('change password: wrong current password, then success', (
    tester,
  ) async {
    await pumpSettings(tester);
    await tapText(tester, AccountStrings.changePassword);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Wrong123');
    await tester.enterText(fields.at(1), 'NewPass1!');
    await tester.enterText(fields.at(2), 'NewPass1!');

    repo.changePasswordFails = AuthFailure.invalidCredentials;
    await tapText(tester, AccountStrings.updatePassword);
    expect(find.text(AccountStrings.currentPasswordIncorrect), findsOneWidget);

    repo.changePasswordFails = null;
    await tester.enterText(fields.at(0), 'OldPass1!');
    await tapText(tester, AccountStrings.updatePassword);

    expect(repo.changePasswordCalls, 2);
    expect(find.text(AccountStrings.passwordUpdated), findsOneWidget);
    expect(find.text(AccountStrings.updatePassword), findsNothing); // closed
  });

  testWidgets('Back is blocked while the new password is being saved', (
    tester,
  ) async {
    final saving = Completer<void>();
    repo.gate = saving.future;
    await pumpSettings(tester);
    await tapText(tester, AccountStrings.changePassword);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'OldPass1!');
    await tester.enterText(fields.at(1), 'NewPass1!');
    await tester.enterText(fields.at(2), 'NewPass1!');
    await tester.tap(find.text(AccountStrings.updatePassword));
    await tester.pump(); // saving (spinner), so no pumpAndSettle here

    await tester.binding.handlePopRoute(); // the phone's back button
    await tester.pump();
    expect(
      find.text(AccountStrings.currentPasswordLabel),
      findsOneWidget,
    ); // still here

    saving.complete();
    await tester.pumpAndSettle();
    expect(find.text(AccountStrings.passwordUpdated), findsOneWidget);
    expect(
      find.text(AccountStrings.currentPasswordLabel),
      findsNothing,
    ); // closed
  });

  testWidgets('delete account: wrong password, then deleted', (tester) async {
    await pumpSettings(tester);
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
