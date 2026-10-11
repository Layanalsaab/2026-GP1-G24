import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/explore_strings.dart';
import 'package:startsa/app_constants/navigation_strings.dart';
import 'package:startsa/app_constants/startup_strings.dart';
import 'package:startsa/data_access/mock_data/mock_startups.dart';
import 'package:startsa/features/explore_startups/screens/explore_screen.dart';
import 'package:startsa/features/explore_startups/screens/seeker_startup_profile_screen.dart';
import 'package:startsa/features/programs/screens/program_profile_screen.dart';
import 'package:startsa/navigation/seeker_main_screen.dart';
import 'package:startsa/shared_ui/common_widgets/home_parts.dart';

/// The startup seeker (a guest) has no account. These screens run on sample
/// data (design phase), so the tests check what is on screen and where taps
/// lead.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> openSeeker(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SeekerMainScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on Explore, with the same three tabs as everyone', (
    tester,
  ) async {
    await openSeeker(tester);

    expect(find.byType(ExploreScreen), findsOneWidget);
    expect(find.text(NavigationStrings.supportSystems), findsOneWidget);
    expect(find.text(NavigationStrings.hub), findsOneWidget);
    expect(find.text(NavigationStrings.explore), findsOneWidget);
    // A guest has no notifications bell.
    expect(
      find.bySemanticsLabel(NavigationStrings.notificationsLabel),
      findsNothing,
    );
  });

  testWidgets('Explore shows ranked trending startups and no bookmark', (
    tester,
  ) async {
    await openSeeker(tester);

    // Only the Trending tab: no For You / Matches, no search.
    expect(find.text(ExploreStrings.tabTrending), findsOneWidget);
    expect(find.text(ExploreStrings.tabForYou), findsNothing);
    expect(find.text(ExploreStrings.tabMatches), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Rafeeq Health'), findsOneWidget);
    expect(find.text('Mizan Learn'), findsOneWidget);
    expect(find.text('Sanabil Agri'), findsOneWidget);
    expect(find.text('Funding'), findsWidgets);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text(ExploreStrings.sendRequest), findsNothing);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
  });

  testWidgets('a trending startup opens the seeker profile', (tester) async {
    await openSeeker(tester);
    // Tall enough that the whole profile is built (it is a lazy list).
    tester.view.physicalSize = const Size(1080, 4200);

    await tester.tap(find.text('Rafeeq Health'));
    await tester.pumpAndSettle();
    expect(find.byType(SeekerStartupProfileScreen), findsOneWidget);
    // Figma "V2 · 45c": founder row, about, looking for, details, associations.
    expect(find.text(StartupStrings.foundedBy), findsNothing);
    expect(find.textContaining(StartupStrings.foundedBy), findsOneWidget);
    expect(find.textContaining('Shahad Alabdulkarim'), findsOneWidget);
    expect(find.text(StartupStrings.expressInterest), findsOneWidget);
    expect(find.text(StartupStrings.sendRequest), findsNothing);
    expect(find.text(StartupStrings.lookingForTitle), findsOneWidget);
    expect(find.text('SAR 500,000'), findsOneWidget);
    expect(find.text(StartupStrings.raisingThisRound), findsOneWidget);
    expect(find.text(StartupStrings.detailsTitle), findsOneWidget);
    expect(find.text('B2C'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
    expect(find.text(StartupStrings.associationsTitle), findsOneWidget);
    expect(find.text('Ahmad Hassan'), findsOneWidget);
    // A guest has no preview banner and no bookmark.
    expect(find.text(StartupStrings.previewBanner), findsNothing);
    expect(
      find.bySemanticsLabel(NavigationStrings.menuBookmarks),
      findsNothing,
    );
  });

  testWidgets('Express interest on the profile is inert', (tester) async {
    await openSeeker(tester);
    await tester.tap(find.text('Rafeeq Health'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(StartupStrings.expressInterest));
    await tester.pumpAndSettle();
    await tester.tap(find.text(StartupStrings.expressInterest));
    await tester.pumpAndSettle();
    expect(find.byType(SeekerStartupProfileScreen), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('Hub lists startups with Express interest and no bookmark', (
    tester,
  ) async {
    await openSeeker(tester);

    await tester.tap(find.text(NavigationStrings.hub));
    await tester.pumpAndSettle();
    expect(find.text(ExploreStrings.searchStartups), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Express interest'), findsWidgets);
    expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);

    // Tapping the inert button changes nothing.
    await tester.tap(find.text('Express interest').first);
    await tester.pumpAndSettle();
    expect(find.byType(SeekerStartupProfileScreen), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('every startup in the guest Hub opens its own profile', (
    tester,
  ) async {
    await openSeeker(tester);
    tester.view.physicalSize = const Size(1080, 4200);
    await tester.tap(find.text(NavigationStrings.hub));
    await tester.pumpAndSettle();

    for (final l in MockStartups.forYou) {
      await tester.scrollUntilVisible(
        find.text(l.name),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      final button = find.descendant(
        of: find.ancestor(
          of: find.text(l.name),
          matching: find.byType(StartupBrowseCard),
        ),
        matching: find.text(ExploreStrings.viewProfile),
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(SeekerStartupProfileScreen), findsOneWidget);
      expect(find.text(l.name), findsWidgets, reason: l.name);
      expect(find.text(l.startup.description), findsOneWidget);
      expect(find.text(StartupStrings.expressInterest), findsOneWidget);
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

  testWidgets('Support Systems works for guests', (tester) async {
    await openSeeker(tester);

    await tester.tap(find.text(NavigationStrings.supportSystems));
    await tester.pumpAndSettle();
    expect(find.text('TAQADAM by KAUST'), findsOneWidget);
    // A guest has no bookmarks, even on support systems.
    expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);

    await tester.tap(find.text('View details').first);
    await tester.pumpAndSettle();
    expect(find.byType(ProgramProfileScreen), findsOneWidget);
  });

  testWidgets('the guest menu has Expressions of Interest and Exit', (
    tester,
  ) async {
    await openSeeker(tester);

    await tester.tap(find.bySemanticsLabel(NavigationStrings.openMenu));
    await tester.pumpAndSettle();
    expect(find.text(NavigationStrings.guest), findsOneWidget);
    expect(find.text(NavigationStrings.menuExit), findsOneWidget);
    expect(find.text(NavigationStrings.menuProfile), findsNothing);

    // The placeholder item is shown but inert: the menu stays open.
    await tester.tap(find.text(NavigationStrings.menuExpressionsOfInterest));
    await tester.pumpAndSettle();
    expect(find.text(NavigationStrings.menuExit), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
  });
}
