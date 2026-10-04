import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/account_strings.dart';
import 'package:startsa/app_constants/navigation_strings.dart';
import 'package:startsa/app_constants/startup_strings.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/services/screens/services_screen.dart';
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
    StartupRepository.instance = FakeStartupRepository();
  });

  const founder = AppUser(
    uid: 'uid1',
    role: AccountRole.founder,
    fullName: 'Shahad Alabdulkarim',
    email: 'shahad@example.com',
    city: 'Riyadh',
  );

  // Hub, Programs and Explore are built (with sample data) for everyone.
  const builtTabs = [
    NavigationStrings.hub,
    NavigationStrings.programs,
    NavigationStrings.explore,
  ];

  Future<void> pumpMain(WidgetTester tester, {AppUser user = founder}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: MainScreen(user: user)));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the Account tab, with all five tabs in the bar', (
    tester,
  ) async {
    await pumpMain(tester);

    for (final label in [
      ...builtTabs,
      NavigationStrings.services,
      NavigationStrings.account,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Shahad Alabdulkarim'), findsOneWidget);
    expect(find.text('Founder · Riyadh'), findsOneWidget);
    expect(find.text(AccountStrings.editAccount), findsOneWidget);
    // A main tab has nothing to go back to.
    expect(find.bySemanticsLabel('Back'), findsNothing);
  });

  testWidgets('every tab opens its own screen', (tester) async {
    await pumpMain(tester);

    for (final label in [...builtTabs, NavigationStrings.services]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('Shahad Alabdulkarim'), findsNothing); // left Account
    }
    await tester.tap(find.text(NavigationStrings.account));
    await tester.pumpAndSettle();
    expect(find.text('Shahad Alabdulkarim'), findsOneWidget);
  });

  testWidgets(
    'screen readers hear which tab is open, and that every tab is available',
    (tester) async {
      const investor = AppUser(
        uid: 'uid2',
        role: AccountRole.investor,
        fullName: 'Sara Investor',
        email: 'sara@example.com',
      );
      await pumpMain(tester, user: investor);

      expect(
        tester.getSemantics(find.bySemanticsLabel(NavigationStrings.account)),
        isSemantics(
          label: NavigationStrings.account,
          isButton: true,
          isEnabled: true,
          isSelected: true,
        ),
      );
      for (final label in [...builtTabs, NavigationStrings.services]) {
        expect(
          tester.getSemantics(find.bySemanticsLabel(label)),
          isSemantics(label: label, isButton: true, isEnabled: true),
        );
      }
    },
  );

  testWidgets('Edit account opens over the bar and Back returns to the tab', (
    tester,
  ) async {
    await pumpMain(tester);

    await tester.tap(find.text(AccountStrings.editAccount));
    await tester.pumpAndSettle();
    expect(find.text(AccountStrings.saveChanges), findsOneWidget);
    expect(
      find.text(NavigationStrings.account),
      findsNothing,
    ); // bar is covered

    await tester.binding.handlePopRoute(); // the phone's back button
    await tester.pumpAndSettle();
    expect(find.text(NavigationStrings.account), findsOneWidget);
    expect(find.text('Shahad Alabdulkarim'), findsOneWidget);
  });

  testWidgets(
    'no Back arrow on the Account tab, even if it refreshed while Settings was open',
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
      expect(
        find.text(AccountStrings.settings),
        findsOneWidget,
      ); // on the Account tab
      expect(find.bySemanticsLabel('Back'), findsNothing);
    },
  );

  testWidgets(
    'a founder\'s Services tab is the Services grid (Figma V2 · 35)',
    (tester) async {
      await pumpMain(tester);

      await tester.tap(find.text(NavigationStrings.services));
      await tester.pumpAndSettle();
      expect(find.byType(ServicesScreen), findsOneWidget);
      for (final tile in [
        StartupStrings.tileMyStartups,
        StartupStrings.tileAssociations,
        StartupStrings.tileCalculator,
        StartupStrings.tileAskGemini,
        StartupStrings.tileDashboard,
      ]) {
        expect(find.text(tile), findsOneWidget);
      }

      // My Startups opens over the tab, with a back arrow.
      await tester.tap(find.text(StartupStrings.tileMyStartups));
      await tester.pumpAndSettle();
      expect(find.text(StartupStrings.emptyButton), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(ServicesScreen), findsOneWidget);

      // Tiles that aren't built yet do nothing: no page, no message.
      for (final tile in [
        StartupStrings.tileAssociations,
        StartupStrings.tileCalculator,
        StartupStrings.tileAskGemini,
        StartupStrings.tileDashboard,
      ]) {
        await tester.tap(find.text(tile));
        await tester.pumpAndSettle();
        expect(find.byType(ServicesScreen), findsOneWidget, reason: tile);
        expect(find.text(StartupStrings.comingSoon), findsNothing, reason: tile);
        expect(find.byType(SnackBar), findsNothing, reason: tile);
      }
    },
  );

  testWidgets(
    'an investor\'s Services tab shows Associations and Calculator, and does nothing',
    (tester) async {
      const investor = AppUser(
        uid: 'uid2',
        role: AccountRole.investor,
        fullName: 'Sara Investor',
        email: 'sara@example.com',
      );
      await pumpMain(tester, user: investor);

      await tester.tap(find.text(NavigationStrings.services));
      await tester.pumpAndSettle();
      expect(find.byType(ServicesScreen), findsOneWidget);
      expect(find.text(StartupStrings.tileAssociations), findsOneWidget);
      expect(find.text(StartupStrings.tileCalculator), findsOneWidget);
      // An investor has no startups, Gemini or dashboard here.
      expect(find.text(StartupStrings.tileMyStartups), findsNothing);
      expect(find.text(StartupStrings.tileAskGemini), findsNothing);
      expect(find.text(StartupStrings.tileDashboard), findsNothing);

      // Both tiles are design only: tapping them changes nothing.
      for (final tile in [
        StartupStrings.tileAssociations,
        StartupStrings.tileCalculator,
      ]) {
        await tester.tap(find.text(tile));
        await tester.pumpAndSettle();
        expect(find.byType(ServicesScreen), findsOneWidget, reason: tile);
      }
    },
  );
}
