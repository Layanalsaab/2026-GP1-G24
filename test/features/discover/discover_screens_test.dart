import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/explore_strings.dart';
import 'package:startsa/app_constants/navigation_strings.dart';
import 'package:startsa/app_constants/program_strings.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/explore_startups/screens/explore_screen.dart';
import 'package:startsa/features/profiles/screens/investor_profile_screen.dart';
import 'package:startsa/features/programs/screens/program_profile_screen.dart';
import 'package:startsa/features/startups/screens/startup_profile_screen.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/navigation/main_screen.dart';

import '../../support/fakes.dart';

/// The Explore, Hub and Programs tabs run on sample data (design phase), so
/// these tests check what is on screen and where each tap leads.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    AuthRepository.instance = FakeAuthRepository();
    UserRepository.instance = FakeUserRepository();
    StartupRepository.instance = FakeStartupRepository();
  });

  const founder = AppUser(
    uid: 'f1',
    role: AccountRole.founder,
    fullName: 'Shahad Founder',
    email: 'f@example.com',
  );
  const investor = AppUser(
    uid: 'i1',
    role: AccountRole.investor,
    fullName: 'Sara Investor',
    email: 'i@example.com',
  );

  Future<void> openTab(WidgetTester tester, AppUser user, String tab) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: MainScreen(user: user)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
  }

  group('Explore', () {
    testWidgets('a founder sees investors, with the Gemini button', (tester) async {
      await openTab(tester, founder, NavigationStrings.explore);

      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.text('Ahmad Hassan'), findsOneWidget);
      expect(find.text('Sara Al-Mohsen'), findsOneWidget);
      expect(find.text(ExploreStrings.askGemini), findsOneWidget);
      expect(find.text(ExploreStrings.invests('Pre-seed – Seed')), findsOneWidget);
    });

    testWidgets('an investor sees startups, without the Gemini button', (tester) async {
      await openTab(tester, investor, NavigationStrings.explore);

      expect(find.text('Rafeeq Health'), findsOneWidget);
      expect(find.text('Naql'), findsOneWidget);
      expect(find.text(ExploreStrings.askGemini), findsNothing);
    });

    testWidgets('the tabs switch between For You, Trending and Matches', (tester) async {
      await openTab(tester, investor, NavigationStrings.explore);

      await tester.tap(find.text(ExploreStrings.tabTrending));
      await tester.pumpAndSettle();
      expect(find.text('Mizan Learn'), findsOneWidget);
      expect(find.text('1'), findsOneWidget); // ranked 1, 2, 3
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text(ExploreStrings.tabMatches));
      await tester.pumpAndSettle();
      expect(find.text(ExploreStrings.matchPercent(82)), findsOneWidget);
      expect(find.text('Why: matches your investment preferences'), findsWidgets);
    });

    testWidgets("an investor's first startup opens the startup profile", (tester) async {
      await openTab(tester, investor, NavigationStrings.explore);

      await tester.tap(find.text(ExploreStrings.viewProfile).first);
      await tester.pumpAndSettle();

      expect(find.byType(StartupProfileScreen), findsOneWidget);
      expect(find.text('Rafeeq Health'), findsWidgets);
    });

    testWidgets("a founder's first investor opens the investor profile", (tester) async {
      await openTab(tester, founder, NavigationStrings.explore);

      await tester.tap(find.text(ExploreStrings.viewProfile).first);
      await tester.pumpAndSettle();

      expect(find.byType(InvestorProfileScreen), findsOneWidget);
      expect(find.text(ExploreStrings.investmentPreferences), findsOneWidget);
      expect(find.text('SAR 100K – 500K'), findsOneWidget);
    });

    testWidgets('only the first card leads anywhere', (tester) async {
      await openTab(tester, investor, NavigationStrings.explore);

      await tester.tap(find.text(ExploreStrings.viewProfile).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text(ExploreStrings.sendRequest).first);
      await tester.pumpAndSettle();

      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.byType(StartupProfileScreen), findsNothing);
    });
  });

  group('Hub', () {
    testWidgets('a founder browses investors', (tester) async {
      await openTab(tester, founder, NavigationStrings.hub);

      expect(find.text(ExploreStrings.searchHint), findsOneWidget);
      expect(find.text('Omar Khalid'), findsOneWidget);
    });

    testWidgets("an investor's first startup opens the startup profile", (tester) async {
      await openTab(tester, investor, NavigationStrings.hub);
      expect(find.text('Daftar'), findsOneWidget);

      await tester.tap(find.text(ExploreStrings.viewProfile).first);
      await tester.pumpAndSettle();

      expect(find.byType(StartupProfileScreen), findsOneWidget);
    });
  });

  group('Programs', () {
    testWidgets('lists the programs, and only the first opens its page', (tester) async {
      await openTab(tester, founder, NavigationStrings.programs);
      expect(find.byTooltip('Back'), findsNothing); // a main tab: no back arrow
      expect(find.text(ProgramStrings.intro), findsOneWidget);
      expect(find.text('Badir Program'), findsOneWidget);
      expect(find.text('BIM Ventures'), findsOneWidget);

      await tester.tap(find.text('Badir Program'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramProfileScreen), findsNothing);

      await tester.tap(find.text('TAQADAM by KAUST'));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramProfileScreen), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget); // the page itself has one
      expect(find.text(ProgramStrings.visitWebsite), findsOneWidget);
      expect(find.text('6 months'), findsOneWidget);
      expect(find.text('HealthTech'), findsOneWidget);
    });
  });
}
