import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/account_strings.dart';
import 'package:startsa/app_constants/navigation_strings.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/navigation/main_screen.dart';

import '../support/fakes.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  late FakeUserRepository users;

  setUp(() {
    AuthRepository.instance = FakeAuthRepository();
    users = FakeUserRepository();
    UserRepository.instance = users;
  });

  const founder = AppUser(
    uid: 'uid1',
    role: AccountRole.founder,
    fullName: 'Shahad Alabdulkarim',
    email: 'shahad@example.com',
    city: 'Riyadh',
  );

  const notBuiltYet = [
    NavigationStrings.hub,
    NavigationStrings.programs,
    NavigationStrings.explore,
    NavigationStrings.services,
  ];

  Future<void> pumpMain(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MainScreen(user: founder)));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the Account tab, with all five tabs in the bar', (tester) async {
    await pumpMain(tester);

    for (final label in [...notBuiltYet, NavigationStrings.account]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Shahad Alabdulkarim'), findsOneWidget);
    expect(find.text('Founder · Riyadh'), findsOneWidget);
    expect(find.text(AccountStrings.editAccount), findsOneWidget);
    // A main tab has nothing to go back to.
    expect(find.bySemanticsLabel('Back'), findsNothing);
  });

  testWidgets('tabs that are not built yet do nothing when tapped', (tester) async {
    await pumpMain(tester);

    for (final label in notBuiltYet) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('Shahad Alabdulkarim'), findsOneWidget); // still on Account
    }
  });

  testWidgets('screen readers hear which tab is open and which are unavailable', (tester) async {
    await pumpMain(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel(NavigationStrings.account)),
      isSemantics(
        label: NavigationStrings.account,
        isButton: true,
        isEnabled: true,
        isSelected: true,
      ),
    );
    for (final label in notBuiltYet) {
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(label: label, isButton: true, isEnabled: false),
      );
    }
  });

  testWidgets('Edit account opens over the bar and Back returns to the tab', (tester) async {
    await pumpMain(tester);

    await tester.tap(find.text(AccountStrings.editAccount));
    await tester.pumpAndSettle();
    expect(find.text(AccountStrings.saveChanges), findsOneWidget);
    expect(find.text(NavigationStrings.account), findsNothing); // bar is covered

    await tester.binding.handlePopRoute(); // the phone's back button
    await tester.pumpAndSettle();
    expect(find.text(NavigationStrings.account), findsOneWidget);
    expect(find.text('Shahad Alabdulkarim'), findsOneWidget);
  });

  testWidgets('no Back arrow on the Account tab, even if it refreshed while Settings was open',
      (tester) async {
    final reload = Completer<void>();
    users.getProfileGate = reload.future;
    users.profiles[founder.uid] = founder;
    await pumpMain(tester);

    await tester.tap(find.text(AccountStrings.settings));
    await tester.pumpAndSettle();
    reload.complete(); // the Account tab refreshes behind Settings
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute(); // back to the tab
    await tester.pumpAndSettle();
    expect(find.text(AccountStrings.settings), findsOneWidget); // on the Account tab
    expect(find.bySemanticsLabel('Back'), findsNothing);
  });
}
