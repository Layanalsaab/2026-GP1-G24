import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/repositories/discovery_repository.dart';
import 'package:startsa/data_access/repositories/startup_repository.dart';
import 'package:startsa/features/search/widgets/home_layout.dart';
import 'package:startsa/helpers/app_session.dart';
import 'package:startsa/models/app_user.dart';
import 'package:startsa/models/home_item.dart';
import 'package:startsa/navigation/main_screen.dart';
import 'package:startsa/shared_ui/motion/motion.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/cards/home_card.dart';
import 'package:startsa/shared_ui/widgets/cards/trending.dart';
import 'package:startsa/shared_ui/widgets/lists/segmented_switch.dart';

import '../../support/fakes.dart';

HomeItem _item(int i) => HomeItem(
  kind: HomeItemKind.startup,
  id: 's$i',
  name: 'Startup $i',
  initials: 'S$i',
  tag: 'Fintech',
  city: 'Riyadh',
  line: 'Line $i',
);

/// Opacity of the entrance of the [index]th card (1 once it has settled).
double _cardOpacity(WidgetTester t, [int index = 0]) => t
    .widget<Opacity>(
      find
          .descendant(
            of: find.byType(HomeCard).at(index),
            matching: find.byType(Opacity),
          )
          .first,
    )
    .opacity;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('cards replay their stagger when the list changes (4.5)', () {
    Widget app(List<HomeItem> items, {String scope = ''}) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: SingleChildScrollView(
          child: HomeColumn(slots: [cardsSlot(items, scope: scope)]),
        ),
      ),
    );

    testWidgets('different content replays, identical content does not', (
      t,
    ) async {
      t.view.physicalSize = const Size(412, 2000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final a = [for (var i = 0; i < 3; i++) _item(i)];
      final b = [for (var i = 5; i < 8; i++) _item(i)];

      await t.pumpWidget(app(a));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(_cardOpacity(t), inExclusiveRange(0, 1));
      await t.pump(const Duration(seconds: 2));
      expect(_cardOpacity(t), 1);

      // The same items again (a bookmark toggle rebuilds like this): no replay.
      await t.pumpWidget(app([...a]));
      await t.pump(const Duration(milliseconds: 16));
      expect(_cardOpacity(t), 1);

      // Other content (search text, filter, tab): the stagger plays again.
      await t.pumpWidget(app(b));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(_cardOpacity(t), inExclusiveRange(0, 1));
      await t.pump(const Duration(seconds: 2));
      expect(_cardOpacity(t), 1);

      // The same items under another scope (another tab) replay too.
      await t.pumpWidget(app(b, scope: 'other-tab'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(_cardOpacity(t), inExclusiveRange(0, 1));
      await t.pump(const Duration(seconds: 2));
    });

    testWidgets('later cards start later (40 ms x index)', (t) async {
      t.view.physicalSize = const Size(412, 2000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(app([for (var i = 0; i < 4; i++) _item(i)]));
      await t.pump(const Duration(milliseconds: 60));
      await t.pump(const Duration(milliseconds: 16));
      await t.pump(const Duration(milliseconds: 60));
      expect(_cardOpacity(t, 0), greaterThan(_cardOpacity(t, 3)));
      await t.pump(const Duration(seconds: 2));
    });
  });

  group('in the home shell', () {
    const founder = AppUser(
      uid: 'uid1',
      role: AccountRole.founder,
      fullName: 'Shahad Alabdulkarim',
      email: 'shahad@example.com',
      city: 'Riyadh',
    );

    setUp(() {
      StartupRepository.instance = FakeStartupRepository();
      DiscoveryRepository.instance = DiscoveryRepository.sample();
      AppSession.instance.reset();
      AppSession.instance.signIn(founder);
    });

    Future<void> pumpMain(WidgetTester t) async {
      t.view.physicalSize = const Size(824, 1784);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const MainScreen()),
      );
      await t.pump(const Duration(milliseconds: 600));
    }

    double thumbX(WidgetTester t) => t
        .getTopLeft(
          find
              .descendant(
                of: find.byType(SegmentedSwitch),
                matching: find.byType(FractionallySizedBox),
              )
              .first,
        )
        .dx;

    testWidgets('switching Startups/Investors slides the thumb and replays', (
      t,
    ) async {
      await pumpMain(t);
      final x0 = thumbX(t);
      // A founder starts on the Investors side, so Startups is the other one.
      final other = x0 > 100 ? 'Startups' : 'Investors';
      await t.tap(find.text(other));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      final mid = thumbX(t);
      // The switch kept its state: the thumb is travelling, not teleported.
      expect(mid, isNot(x0));
      expect(find.byType(SegmentedSwitch), findsOneWidget);
      if (find.byType(HomeCard).evaluate().isNotEmpty) {
        expect(_cardOpacity(t), inExclusiveRange(0, 1));
      }
      await t.pump(const Duration(milliseconds: 600));
      expect(thumbX(t), isNot(x0));
      await t.pump(const Duration(seconds: 2));
    });

    testWidgets('typing in the search bar replays the new results', (t) async {
      await pumpMain(t);
      await t.pump(const Duration(seconds: 2));
      expect(find.byType(HomeCard), findsWidgets);
      await t.enterText(find.byType(TextField), 'a');
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      if (find.byType(HomeCard).evaluate().isNotEmpty) {
        expect(_cardOpacity(t), inExclusiveRange(0, 1));
      }
      await t.pump(const Duration(seconds: 2));
    });

    testWidgets('Explore: rail cards are static, Trending box rises in', (
      t,
    ) async {
      await pumpMain(t);
      await t.tap(find.bySemanticsLabel('Explore').last);
      await t.pump(const Duration(milliseconds: 600));
      final rails = find.byType(RailCard);
      if (rails.evaluate().isNotEmpty) {
        expect(
          find.ancestor(of: rails.first, matching: find.byType(Rise)),
          findsNothing,
        );
      }
      await t.tap(find.text('Trending').first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(TrendingBox), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TrendingBox),
          matching: find.byType(Rise),
        ),
        findsOneWidget,
      );
      await t.pump(const Duration(seconds: 2));
    });
  });
}
