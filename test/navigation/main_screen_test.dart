import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/navigation/main_screen.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/nav/app_side_drawer.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_bottom_sheet.dart';
import 'package:startsa/shared_ui/icons/app_icons.dart';

import '../support/fakes.dart';

/// The home shell: header, search, 3-tab bottom nav, per-role behaviour.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const founder = AppUser(
    uid: 'uid1',
    role: AccountRole.founder,
    fullName: 'Shahad Alabdulkarim',
    email: 'shahad@example.com',
    city: 'Riyadh',
  );

  setUp(() {
    StartupRepository.instance = FakeStartupRepository();
    AppSession.instance.reset();
  });

  Future<void> pumpMain(WidgetTester tester) async {
    tester.view.physicalSize = const Size(824, 1784);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const MainScreen()),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('founder opens on the Hub with the avatar and no Sign up', (
    tester,
  ) async {
    AppSession.instance.signIn(founder);
    await pumpMain(tester);
    expect(find.text('Hub'), findsOneWidget);
    expect(find.text('SA'), findsWidgets);
    expect(find.text('Sign up'), findsNothing);
    expect(find.text('Startups'), findsOneWidget);
    expect(find.text('Investors'), findsOneWidget);
  });

  testWidgets('guest sees the Sign up pill, no avatar, no bookmarks', (
    tester,
  ) async {
    AppSession.instance.signInAsGuest();
    await pumpMain(tester);
    expect(find.text('Sign up'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Open menu')), findsNothing);
  });

  testWidgets('bottom nav switches to Explore and shows the sub-tabs', (
    tester,
  ) async {
    AppSession.instance.signIn(founder);
    await pumpMain(tester);
    await tester.tap(find.bySemanticsLabel('Explore').last);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Explore'), findsWidgets);
    expect(find.text('For You'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Matches'), findsOneWidget);
  });

  testWidgets('typing in search with no match shows No matches', (
    tester,
  ) async {
    AppSession.instance.signIn(founder);
    await pumpMain(tester);
    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('0 results'), findsOneWidget);
  });

  testWidgets('drawer and bottom sheets open with semantics on, no assertion', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    AppSession.instance.signIn(founder);
    await pumpMain(tester);
    final ctx = tester.element(find.byType(MainScreen));
    openAppDrawer(
      ctx,
      name: 'Shahad Alabdulkarim',
      initials: 'SA',
      roleLine: 'Founder',
      items: [
        AppDrawerItem(label: 'Settings', icon: AppIcons.menuGear, onTap: () {}),
      ],
      onViewProfile: () {},
      onLogOut: () {},
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Navigator.of(ctx, rootNavigator: true).pop();
    await tester.pump(const Duration(milliseconds: 600));

    showInfoSheet(ctx, title: 'Hello', text: 'Body');
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Hello'), findsOneWidget);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
