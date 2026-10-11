import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/explore_strings.dart';
import 'package:startsa/app_constants/investor_strings.dart';
import 'package:startsa/app_constants/navigation_strings.dart';
import 'package:startsa/app_constants/startup_strings.dart';
import 'package:startsa/data_access/mock_data/mock_investors.dart';
import 'package:startsa/data_access/mock_data/mock_startups.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/data_access/repositories/user_repository.dart';
import 'package:startsa/features/explore_startups/screens/explore_screen.dart';
import 'package:startsa/features/profiles/screens/edit_criteria_screen.dart';
import 'package:startsa/features/profiles/screens/investor_profile_screen.dart';
import 'package:startsa/features/programs/screens/program_profile_screen.dart';
import 'package:startsa/features/startups/screens/startup_profile_screen.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/navigation/main_screen.dart';
import 'package:startsa/shared_ui/common_widgets/home_parts.dart';

import '../../support/fakes.dart';

/// The Explore, Hub and Support Systems tabs run on sample data (design
/// phase), so these tests check what is on screen and where each tap leads.
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

  /// Opens the shell on [tab] (Explore is where it starts).
  Future<void> openTab(WidgetTester tester, AppUser user, String tab) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: MainScreen(user: user)));
    await tester.pumpAndSettle();
    // The app opens on the Hub, so every tab (Explore too) is tapped.
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
  }

  /// Scrolls the list to [name] and taps "View profile" on its card.
  Future<void> viewProfileOf(
    WidgetTester tester,
    String name,
    Type cardType,
  ) async {
    await tester.scrollUntilVisible(
      find.text(name),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    final button = find.descendant(
      of: find.ancestor(of: find.text(name), matching: find.byType(cardType)),
      matching: find.text(ExploreStrings.viewProfile),
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('Explore', () {
    testWidgets('a founder sees investors with Stage and Sectors rows', (
      tester,
    ) async {
      await openTab(tester, founder, NavigationStrings.explore);

      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.text(ExploreStrings.searchInvestors), findsOneWidget);
      expect(find.text('Ahmad Hassan'), findsOneWidget);
      expect(find.text('Angel Investor'), findsWidgets);
      expect(
        find.text(
          'Backing early-stage health and fintech founders building for '
          'Saudi families and small businesses.',
        ),
        findsOneWidget,
      );
      expect(find.text('Pre-seed – Seed'), findsOneWidget);
      expect(find.text('HealthTech, Fintech'), findsOneWidget);
      expect(find.text(ExploreStrings.stageLabel), findsWidgets);
      expect(find.text(ExploreStrings.sectorsLabel), findsWidgets);
      expect(find.text(ExploreStrings.viewProfile), findsWidgets);
      expect(find.text(ExploreStrings.sendRequest), findsWidgets);
      // Ask Gemini lives in the side menu, not as a floating button.
      expect(find.text(ExploreStrings.askGemini), findsNothing);
    });

    testWidgets('an investor sees startups with Stage and Needs rows', (
      tester,
    ) async {
      await openTab(tester, investor, NavigationStrings.explore);

      expect(find.text(ExploreStrings.searchStartups), findsOneWidget);
      expect(find.text('Rafeeq Health'), findsOneWidget);
      expect(find.text('Pre-seed'), findsWidgets);
      expect(find.text(ExploreStrings.needsLabel), findsWidgets);
      expect(find.text('Funding · SAR 500K'), findsOneWidget);
      expect(find.text('Partnership'), findsOneWidget);
      expect(find.text(ExploreStrings.sendRequest), findsWidgets);
    });

    testWidgets('the tabs switch between For You, Trending and Matches', (
      tester,
    ) async {
      await openTab(tester, investor, NavigationStrings.explore);

      await tester.tap(find.text(ExploreStrings.tabTrending));
      await tester.pumpAndSettle();
      // The old heading is gone; five ranked startups.
      expect(find.text('Trending startups this week'), findsNothing);
      expect(find.text('Mizan Learn'), findsOneWidget);
      expect(find.text('Sanabil Agri'), findsOneWidget);
      for (final rank in ['1', '2', '3', '4', '5']) {
        expect(find.text(rank), findsOneWidget, reason: rank);
      }
      // Trending has no search box.
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text(ExploreStrings.tabMatches));
      await tester.pumpAndSettle();
      expect(find.text(ExploreStrings.matchPercent(94)), findsOneWidget);
      expect(find.text('Same sector, stage and region'), findsOneWidget);
      expect(find.text(ExploreStrings.basedOnCriteria), findsOneWidget);
    });

    testWidgets(
      "a founder's Matches are investors, for one of their startups",
      (tester) async {
        await openTab(tester, founder, NavigationStrings.explore);

        await tester.tap(find.text(ExploreStrings.tabMatches));
        await tester.pumpAndSettle();
        expect(find.text(ExploreStrings.matchesFor), findsOneWidget);
        expect(find.text('Ahmad Hassan'), findsOneWidget);
        expect(find.text(ExploreStrings.matchPercent(92)), findsOneWidget);
        expect(find.text('Same sector and stage'), findsOneWidget);
        expect(find.text('Same region'), findsOneWidget);
        expect(find.text(ExploreStrings.sendRequest), findsNWidgets(3));
      },
    );

    testWidgets('an investor edits the criteria from Matches', (tester) async {
      await openTab(tester, investor, NavigationStrings.explore);
      await tester.tap(find.text(ExploreStrings.tabMatches));
      await tester.pumpAndSettle();

      await tester.tap(find.text(ExploreStrings.edit));
      await tester.pumpAndSettle();

      expect(find.byType(EditCriteriaScreen), findsOneWidget);
      expect(find.text(InvestorStrings.editCriteriaTitle), findsWidgets);
    });

    testWidgets("an investor's startup opens the startup profile", (
      tester,
    ) async {
      await openTab(tester, investor, NavigationStrings.explore);

      await tester.tap(find.text(ExploreStrings.viewProfile).first);
      await tester.pumpAndSettle();

      expect(find.byType(StartupProfileScreen), findsOneWidget);
      expect(find.text('Rafeeq Health'), findsWidgets);
    });

    testWidgets('the investor view has Send request and no preview banner', (
      tester,
    ) async {
      await openTab(tester, investor, NavigationStrings.explore);
      // Tall enough that the whole profile is built (it is a lazy list).
      tester.view.physicalSize = const Size(1080, 4200);
      await tester.tap(find.text(ExploreStrings.viewProfile).first);
      await tester.pumpAndSettle();

      expect(find.text(StartupStrings.previewBanner), findsNothing);
      expect(find.text(StartupStrings.expressInterest), findsNothing);
      expect(find.textContaining('Shahad Alabdulkarim'), findsOneWidget);
      expect(find.text(StartupStrings.lookingForTitle), findsOneWidget);
      expect(find.text(StartupStrings.associationsTitle), findsOneWidget);
      expect(
        find.bySemanticsLabel(NavigationStrings.menuBookmarks),
        findsOneWidget,
      );

      // Send request is an inert placeholder: nothing opens.
      await tester.tap(find.text(StartupStrings.sendRequest));
      await tester.pumpAndSettle();
      expect(find.byType(StartupProfileScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets("a founder's matched investor opens the investor profile", (
      tester,
    ) async {
      await openTab(tester, founder, NavigationStrings.explore);
      await tester.tap(find.text(ExploreStrings.tabMatches));
      await tester.pumpAndSettle();

      await tester.tap(find.text(ExploreStrings.viewProfile).first);
      await tester.pumpAndSettle();

      expect(find.byType(InvestorProfileScreen), findsOneWidget);
      expect(find.text(ExploreStrings.investmentPreferences), findsOneWidget);
      expect(find.text('SAR 100K – 500K'), findsOneWidget);
    });

    testWidgets('the search box and chips filter the list', (tester) async {
      await openTab(tester, investor, NavigationStrings.explore);

      await tester.enterText(find.byType(TextField), 'naql');
      await tester.pumpAndSettle();
      expect(find.text('Naql'), findsOneWidget);
      expect(find.text('Rafeeq Health'), findsNothing);

      await tester.enterText(find.byType(TextField), '');
      await tester.ensureVisible(find.text('Fintech').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fintech').first);
      await tester.pumpAndSettle();
      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('Rafeeq Health'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      expect(find.text('No results match your search.'), findsOneWidget);
    });

    testWidgets('placeholders are inert: bell, bookmark and Send request', (
      tester,
    ) async {
      await openTab(tester, investor, NavigationStrings.explore);

      Future<void> expectNothing() async {
        await tester.pumpAndSettle();
        expect(find.byType(ExploreScreen), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        expect(find.byType(Drawer), findsNothing);
      }

      await tester.tap(
        find.bySemanticsLabel(NavigationStrings.notificationsLabel),
        warnIfMissed: false,
      );
      await expectNothing();
      await tester.tap(
        find.byIcon(Icons.bookmark_border_rounded).first,
        warnIfMissed: false,
      );
      await expectNothing();
      await tester.tap(
        find.text(ExploreStrings.sendRequest).first,
        warnIfMissed: false,
      );
      await expectNothing();
    });

    testWidgets('a trending bookmark does not open the startup', (
      tester,
    ) async {
      await openTab(tester, investor, NavigationStrings.explore);
      await tester.tap(find.text(ExploreStrings.tabTrending));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.bookmark_border_rounded).first);
      await tester.pumpAndSettle();
      expect(find.byType(ExploreScreen), findsOneWidget);
      expect(find.byType(StartupProfileScreen), findsNothing);

      // The card itself still opens the startup.
      await tester.tap(find.text('Rafeeq Health'));
      await tester.pumpAndSettle();
      expect(find.byType(StartupProfileScreen), findsOneWidget);
    });

    testWidgets('founder and investor have the bell with the gold dot', (
      tester,
    ) async {
      await openTab(tester, founder, NavigationStrings.explore);
      expect(
        find.bySemanticsLabel(NavigationStrings.notificationsLabel),
        findsOneWidget,
      );
    });
  });

  group('Hub', () {
    testWidgets('a founder browses investors, who each open a profile', (
      tester,
    ) async {
      await openTab(tester, founder, NavigationStrings.hub);
      tester.view.physicalSize = const Size(1080, 4200);
      expect(find.text(ExploreStrings.searchInvestors), findsOneWidget);
      expect(find.text('Ahmad Hassan'), findsOneWidget);
      expect(find.text('Send request'), findsWidgets);

      for (final i in MockInvestors.forYou) {
        await viewProfileOf(tester, i.name, InvestorBrowseCard);
        expect(find.byType(InvestorProfileScreen), findsOneWidget);
        expect(find.text(i.name), findsWidgets, reason: i.name);
        expect(find.text(i.profileBio), findsOneWidget, reason: i.name);
        expect(find.text(i.ticketRange), findsOneWidget, reason: i.name);
        expect(find.text(i.stageRange), findsOneWidget, reason: i.name);
        expect(find.text(i.sectors.join(', ')), findsOneWidget);
        expect(find.text(i.locations.join(', ')), findsWidgets);
        expect(find.text(ExploreStrings.sendRequest), findsOneWidget);

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('an investor opens every startup profile', (tester) async {
      await openTab(tester, investor, NavigationStrings.hub);
      expect(find.text(ExploreStrings.searchStartups), findsOneWidget);
      tester.view.physicalSize = const Size(1080, 4200);

      for (final l in MockStartups.forYou) {
        await viewProfileOf(tester, l.name, StartupBrowseCard);
        expect(find.byType(StartupProfileScreen), findsOneWidget);
        expect(find.text(l.name), findsWidgets, reason: l.name);
        expect(find.text(l.startup.description), findsOneWidget);
        expect(find.text(StartupStrings.lookingForTitle), findsOneWidget);
        expect(find.text(StartupStrings.detailsTitle), findsOneWidget);
        expect(find.text(l.startup.businessModel.shortLabel), findsOneWidget);
        expect(find.text('${l.startup.foundedYear}'), findsOneWidget);
        expect(
          find.textContaining(MockStartups.founderNameOf(l.startup)!),
          findsOneWidget,
        );

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
      }
    });
  });

  group('large text', () {
    testWidgets('cards and match bars do not overflow at 1.8x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      for (final user in [founder, investor]) {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.8)),
              child: child!,
            ),
            home: MainScreen(key: UniqueKey(), user: user),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(NavigationStrings.explore)); // opens on Hub
        await tester.pumpAndSettle();
        for (final tab in [
          ExploreStrings.tabTrending,
          ExploreStrings.tabMatches,
          ExploreStrings.tabForYou,
        ]) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: "${user.role} $tab");
        }
        for (final tab in [
          NavigationStrings.hub,
          NavigationStrings.supportSystems,
        ]) {
          await tester.tap(find.text(tab));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: "${user.role} $tab");
        }
      }
    });
  });

  group('Support Systems', () {
    testWidgets('lists the programs and every one opens its page', (
      tester,
    ) async {
      await openTab(tester, founder, NavigationStrings.supportSystems);
      expect(find.byTooltip('Back'), findsNothing); // a main tab: no back arrow
      expect(find.text('TAQADAM by KAUST'), findsOneWidget);
      expect(
        find.text('University startup accelerator run by KAUST.'),
        findsOneWidget,
      );
      expect(find.text('University and deep-tech startups'), findsOneWidget);
      expect(find.text('Badir Program'), findsOneWidget);
      expect(find.text('BIM Ventures'), findsOneWidget);
      expect(find.text('Website'), findsWidgets);
      expect(find.text('View details'), findsWidgets);
      // Founders and investors can bookmark a support system.
      expect(find.byIcon(Icons.bookmark_border_rounded), findsWidgets);

      await tester.tap(find.text('View details').at(1));
      await tester.pumpAndSettle();
      expect(find.byType(ProgramProfileScreen), findsOneWidget);
      expect(find.byTooltip('Back'), findsOneWidget); // the page itself has one
    });

    testWidgets('the category chips filter by type', (tester) async {
      await openTab(tester, founder, NavigationStrings.supportSystems);

      await tester.ensureVisible(find.text('Incubators'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Incubators'));
      await tester.pumpAndSettle();
      expect(find.text('Badir Program'), findsOneWidget);
      expect(find.text('TAQADAM by KAUST'), findsNothing);
    });
  });
}
