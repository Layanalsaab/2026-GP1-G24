import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/app_constants/explore_strings.dart';
import 'package:startsa/app_constants/navigation_strings.dart';
import 'package:startsa/app_constants/program_strings.dart';
import 'package:startsa/app_constants/seeker_strings.dart';
import 'package:startsa/features/explore_startups/screens/express_interest_screen.dart';
import 'package:startsa/features/explore_startups/screens/seeker_explore_screen.dart';
import 'package:startsa/features/explore_startups/screens/seeker_startup_profile_screen.dart';
import 'package:startsa/features/programs/screens/program_profile_screen.dart';
import 'package:startsa/navigation/seeker_main_screen.dart';

/// The startup seeker has no account. These screens run on sample data
/// (design phase), so the tests check what is on screen and where taps lead.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> openSeeker(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SeekerMainScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on Explore, with only Hub, Explore and Programs in the bar', (tester) async {
    await openSeeker(tester);

    expect(find.byType(SeekerExploreScreen), findsOneWidget);
    expect(find.text(NavigationStrings.hub), findsOneWidget);
    expect(find.text(NavigationStrings.explore), findsWidgets);
    expect(find.text(NavigationStrings.programs), findsOneWidget);
    // A seeker has no Services or Account.
    expect(find.text(NavigationStrings.services), findsNothing);
    expect(find.text(NavigationStrings.account), findsNothing);
  });

  testWidgets('Explore shows ranked startups with Express Interest', (tester) async {
    await openSeeker(tester);

    expect(find.text('Rafeeq Health'), findsOneWidget);
    expect(find.text('Mizan Learn'), findsOneWidget);
    expect(find.text('Naql'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text(SeekerStrings.expressInterest), findsNWidgets(3));
    expect(find.text(ExploreStrings.sendRequest), findsNothing);
  });

  testWidgets('only the first startup opens its profile', (tester) async {
    await openSeeker(tester);

    await tester.tap(find.text(ExploreStrings.viewProfile).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text(SeekerStrings.expressInterest).first); // does nothing
    await tester.pumpAndSettle();
    expect(find.byType(SeekerStartupProfileScreen), findsNothing);
    expect(find.byType(ExpressInterestScreen), findsNothing);

    await tester.tap(find.text(ExploreStrings.viewProfile).first);
    await tester.pumpAndSettle();
    expect(find.byType(SeekerStartupProfileScreen), findsOneWidget);
    expect(find.text('SAR 500K'), findsOneWidget);
    expect(find.text(SeekerStrings.lookingFor), findsOneWidget);
    expect(find.text('Ahmad Hassan'), findsOneWidget);
  });

  testWidgets('the profile leads to the Express Interest form, which sends nothing', (tester) async {
    await openSeeker(tester);
    await tester.tap(find.text(ExploreStrings.viewProfile).first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(SeekerStrings.expressInterest)); // below the fold
    await tester.pumpAndSettle();
    await tester.tap(find.text(SeekerStrings.expressInterest));
    await tester.pumpAndSettle();
    expect(find.byType(ExpressInterestScreen), findsOneWidget);
    expect(find.text(SeekerStrings.formPrompt), findsOneWidget);
    expect(find.text(SeekerStrings.nameLabel), findsOneWidget);

    await tester.tap(find.text(SeekerStrings.submit));
    await tester.pumpAndSettle();
    expect(find.byType(ExpressInterestScreen), findsOneWidget); // nothing happens
  });

  testWidgets('Hub lists startups for seekers too, and its first opens the seeker profile', (tester) async {
    await openSeeker(tester);

    await tester.tap(find.text(NavigationStrings.hub));
    await tester.pumpAndSettle();
    expect(find.text(ExploreStrings.searchHint), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text(SeekerStrings.expressInterest), findsNWidgets(3));

    await tester.tap(find.text(ExploreStrings.viewProfile).first);
    await tester.pumpAndSettle();
    expect(find.byType(SeekerStartupProfileScreen), findsOneWidget);
  });

  testWidgets('Programs works for seekers', (tester) async {
    await openSeeker(tester);

    await tester.tap(find.text(NavigationStrings.programs));
    await tester.pumpAndSettle();
    expect(find.text(ProgramStrings.intro), findsOneWidget);

    await tester.tap(find.text('TAQADAM by KAUST'));
    await tester.pumpAndSettle();
    expect(find.byType(ProgramProfileScreen), findsOneWidget);
  });
}
