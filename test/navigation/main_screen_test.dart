import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/account_strings.dart';
import 'package:startsa/app_constants/navigation_strings.dart';
import 'package:startsa/app_constants/startup_strings.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/explore_startups/screens/explore_screen.dart';
import 'package:startsa/features/programs/screens/programs_screen.dart';
import 'package:startsa/features/search/screens/hub_screen.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/navigation/main_screen.dart';

import '../support/fakes.dart';

/// The main shell (Figma "V2 · 40 · Explore" and "V2 · 41 · Menu"): the top
/// bar with the avatar menu, the 3-tab bottom bar, and the side menu whose
/// unbuilt items are inert placeholders.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    AuthRepository.instance = FakeAuthRepository();
    UserRepository.instance = FakeUserRepository();
    StartupRepository.instance = FakeStartupRepository();
  });

  const founder = AppUser(
    uid: 'uid1',
    role: AccountRole.founder,
    fullName: 'Shahad Alabdulkarim',
    email: 'shahad@example.com',
    city: 'Riyadh',
  );
  const investor = AppUser(
    uid: 'uid2',
    role: AccountRole.investor,
    fullName: 'Layan Alsaab',
    email: 'layan@example.com',
    city: 'Riyadh',
  );

  /// Opens the main screen. It starts on the Hub, so by default the Explore
  /// tab is tapped (most tests here are about Explore).
  Future<void> pumpMain(
    WidgetTester tester, {
    AppUser user = founder,
    bool openExplore = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: MainScreen(user: user)));
    await tester.pumpAndSettle();
    if (openExplore) {
      await tester.tap(find.text(NavigationStrings.explore));
      await tester.pumpAndSettle();
    }
  }

  Future<void> openMenu(WidgetTester tester) async {
    await tester.tap(find.bySemanticsLabel(NavigationStrings.openMenu));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the Hub, with the three tabs in the bar', (
    tester,
  ) async {
    await pumpMain(tester, openExplore: false);

    expect(find.byType(HubScreen), findsOneWidget);
    expect(find.byType(ExploreScreen), findsNothing);
    for (final label in [
      NavigationStrings.supportSystems,
      NavigationStrings.hub,
      NavigationStrings.explore,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    // The old Programs, Services and Account tabs are gone.
    expect(find.text('Programs'), findsNothing);
    expect(find.text('Services'), findsNothing);
    // The avatar shows the user's initials.
    expect(find.text('SA'), findsOneWidget);
  });

  testWidgets('every tab opens its own screen', (tester) async {
    await pumpMain(tester, openExplore: false);

    await tester.tap(find.text(NavigationStrings.hub));
    await tester.pumpAndSettle();
    expect(find.byType(HubScreen), findsOneWidget);

    await tester.tap(find.text(NavigationStrings.supportSystems));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramsScreen), findsOneWidget);

    await tester.tap(find.text(NavigationStrings.explore));
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
  });

  testWidgets('screen readers hear which tab is open', (tester) async {
    await pumpMain(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel(NavigationStrings.explore)),
      isSemantics(
        label: NavigationStrings.explore,
        isButton: true,
        isEnabled: true,
        isSelected: true,
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel(NavigationStrings.hub)),
      isSemantics(
        label: NavigationStrings.hub,
        isButton: true,
        isEnabled: true,
      ),
    );
  });

  group('side menu', () {
    testWidgets("a founder's menu lists the Figma items", (tester) async {
      await pumpMain(tester);
      await openMenu(tester);

      expect(find.text('Shahad Alabdulkarim'), findsOneWidget);
      expect(find.text('Founder · Riyadh'), findsOneWidget);
      for (final item in [
        NavigationStrings.menuProfile,
        NavigationStrings.menuMyStartups,
        NavigationStrings.menuMyRequests,
        NavigationStrings.menuAskGemini,
        NavigationStrings.menuExpressionsOfInterest,
        NavigationStrings.menuBookmarks,
        NavigationStrings.menuNotifications,
        NavigationStrings.menuSettings,
        NavigationStrings.menuLogOut,
      ]) {
        expect(find.text(item), findsOneWidget, reason: item);
      }
      // These belong to the investor menu.
      expect(find.text(NavigationStrings.menuInvestmentWallet), findsNothing);
      expect(find.text(NavigationStrings.menuAssociations), findsNothing);
    });

    testWidgets("an investor's menu has the Investment Wallet", (tester) async {
      await pumpMain(tester, user: investor);
      await openMenu(tester);

      expect(find.text('Investor · Riyadh'), findsOneWidget);
      for (final item in [
        NavigationStrings.menuProfile,
        NavigationStrings.menuInvestmentWallet,
        NavigationStrings.menuAssociations,
        NavigationStrings.menuMyRequests,
        NavigationStrings.menuBookmarks,
        NavigationStrings.menuNotifications,
        NavigationStrings.menuSettings,
        NavigationStrings.menuLogOut,
      ]) {
        expect(find.text(item), findsOneWidget, reason: item);
      }
      expect(find.text(NavigationStrings.menuMyStartups), findsNothing);
      expect(find.text(NavigationStrings.menuAskGemini), findsNothing);
    });

    testWidgets('Profile opens the account page over the bar', (tester) async {
      await pumpMain(tester);
      await openMenu(tester);

      await tester.tap(find.text(NavigationStrings.menuProfile));
      await tester.pumpAndSettle();
      expect(find.text(AccountStrings.editAccount), findsOneWidget);
      expect(find.text(NavigationStrings.supportSystems), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ExploreScreen), findsOneWidget);
    });

    testWidgets('My Startups opens the startups page', (tester) async {
      await pumpMain(tester);
      await openMenu(tester);

      await tester.tap(find.text(NavigationStrings.menuMyStartups));
      await tester.pumpAndSettle();
      expect(find.text(StartupStrings.emptyButton), findsOneWidget);
    });

    testWidgets(
      'every unbuilt item is inert: the menu stays and nothing opens',
      (tester) async {
        final items = [
          NavigationStrings.menuMyRequests,
          NavigationStrings.menuAskGemini,
          NavigationStrings.menuExpressionsOfInterest,
          NavigationStrings.menuBookmarks,
          NavigationStrings.menuNotifications,
        ];
        await pumpMain(tester);
        await openMenu(tester);

        for (final item in items) {
          await tester.tap(find.text(item));
          await tester.pumpAndSettle();
          // Still on the open menu: no page, no snack bar.
          expect(find.text(NavigationStrings.menuLogOut), findsOneWidget);
          expect(find.byType(SnackBar), findsNothing);
          expect(find.byTooltip('Back'), findsNothing, reason: item);
        }
      },
    );

    testWidgets("an investor's Wallet and Associations are inert", (
      tester,
    ) async {
      await pumpMain(tester, user: investor);
      await openMenu(tester);

      for (final item in [
        NavigationStrings.menuInvestmentWallet,
        NavigationStrings.menuAssociations,
      ]) {
        await tester.tap(find.text(item));
        await tester.pumpAndSettle();
        expect(find.text(NavigationStrings.menuLogOut), findsOneWidget);
        expect(find.byTooltip('Back'), findsNothing);
      }
    });
  });

  testWidgets('the bell and a card bookmark are inert', (tester) async {
    await pumpMain(tester);

    await tester.tap(
      find.bySemanticsLabel(NavigationStrings.notificationsLabel),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byTooltip('Back'), findsNothing);

    await tester.tap(
      find.byIcon(Icons.bookmark_border_rounded).first,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byTooltip('Back'), findsNothing);
  });
}
