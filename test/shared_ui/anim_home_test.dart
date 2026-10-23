import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/shared_ui/motion/motion.dart';
import 'package:startsa/shared_ui/theme/app_colors.dart';
import 'package:startsa/shared_ui/theme/app_theme.dart';
import 'package:startsa/shared_ui/widgets/cards/home_card.dart';
import 'package:startsa/shared_ui/widgets/cards/trending.dart';
import 'package:startsa/shared_ui/widgets/headers/home_header.dart';
import 'package:startsa/shared_ui/widgets/lists/results_row.dart';
import 'package:startsa/shared_ui/widgets/lists/segmented_switch.dart';
import 'package:startsa/shared_ui/widgets/nav/app_side_drawer.dart';
import 'package:startsa/shared_ui/widgets/nav/home_search_bar.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_dropdown.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_toast.dart';
import 'package:startsa/shared_ui/widgets/overlays/picker_sheet.dart';

Widget _app(
  Widget child, {
  bool reduce = false,
  bool scroll = true,
}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(size: const Size(412, 892), disableAnimations: reduce),
    child: Scaffold(body: scroll ? SingleChildScrollView(child: child) : child),
  ),
);

Future<TestGesture> _mouse(WidgetTester t) async {
  final g = await t.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: const Offset(1, 1));
  addTearDown(g.removePointer);
  await t.pump();
  return g;
}

Future<void> _hover(WidgetTester t, TestGesture g, Finder f) async {
  await g.moveTo(t.getCenter(f));
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

Future<void> _leave(WidgetTester t, TestGesture g) async {
  await g.moveTo(const Offset(1, 1));
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

Color? _textColor(WidgetTester t, String text) => t
    .widget<AnimatedDefaultTextStyle>(
      find.byWidgetPredicate(
        (w) =>
            w is AnimatedDefaultTextStyle &&
            w.child is Text &&
            (w.child as Text).data == text,
      ),
    )
    .style
    .color;

/// The fill of the closest AnimatedContainer around [text].
Color? _rowColor(WidgetTester t, String text) =>
    (t
                .widget<AnimatedContainer>(
                  find
                      .ancestor(
                        of: find.text(text),
                        matching: find.byType(AnimatedContainer),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .color;

Iterable<double> _scales(WidgetTester t, Finder within) => t
    .widgetList<AnimatedScale>(
      find.descendant(of: within, matching: find.byType(AnimatedScale)),
    )
    .map((s) => s.scale);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('HomeCard (4.5)', () {
    Widget card({
      VoidCallback? onTap,
      VoidCallback? onShare,
      VoidCallback? onBookmark,
      bool bookmarked = false,
      bool animate = false,
      bool reduce = false,
    }) => _app(
      Padding(
        padding: const EdgeInsets.all(16),
        child: HomeCard(
          name: 'Acme',
          tag: 'Fintech',
          city: 'Riyadh',
          body: 'Body',
          onTap: onTap ?? () {},
          onShare: onShare,
          onBookmark: onBookmark,
          bookmarked: bookmarked,
          animate: animate,
        ),
      ),
      reduce: reduce,
    );

    AnimatedContainer outer(WidgetTester t) => t.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(HomeCard),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );

    testWidgets('hover lifts 2 px with shadow and ring, then settles back', (
      t,
    ) async {
      await t.pumpWidget(card());
      expect((outer(t).decoration as BoxDecoration).boxShadow, isNull);
      final g = await _mouse(t);
      await _hover(t, g, find.text('Acme'));
      final d = outer(t).decoration as BoxDecoration;
      expect(d.boxShadow, hasLength(2));
      expect(d.boxShadow![0].offset, const Offset(0, 18));
      expect(d.boxShadow![0].blurRadius, 30);
      expect(d.boxShadow![0].spreadRadius, -20);
      expect(d.boxShadow![1].color, const Color(0xFFCFDCD2));
      expect(d.boxShadow![1].spreadRadius, 1.5);
      expect(outer(t).transform!.getTranslation().y, -2);
      await _leave(t, g);
      expect((outer(t).decoration as BoxDecoration).boxShadow, isNull);
      expect(outer(t).transform!.getTranslation().y, 0);
    });

    testWidgets('the chevron moves 2 px right on hover', (t) async {
      await t.pumpWidget(card());
      double dx() => t
          .widget<AnimatedContainer>(
            find
                .descendant(
                  of: find.byType(HomeCard),
                  matching: find.byType(AnimatedContainer),
                )
                .last,
          )
          .transform!
          .getTranslation()
          .x;
      expect(dx(), 0);
      final g = await _mouse(t);
      await _hover(t, g, find.text('Acme'));
      expect(dx(), 2);
    });

    testWidgets('press scales to .985 and touch never hovers', (t) async {
      await t.pumpWidget(card());
      final g = await t.startGesture(t.getCenter(find.text('Acme')));
      await t.pump(const Duration(milliseconds: 160));
      expect(_scales(t, find.byType(HomeCard)), contains(PressScale.homeCard));
      await g.up();
      await t.pump(const Duration(milliseconds: 400));
      expect((outer(t).decoration as BoxDecoration).boxShadow, isNull);
    });

    testWidgets('reduced motion: no lift and no press scale', (t) async {
      await t.pumpWidget(card(reduce: true));
      final g = await _mouse(t);
      await _hover(t, g, find.text('Acme'));
      expect(outer(t).transform!.getTranslation().y, 0);
      final p = await t.startGesture(t.getCenter(find.text('Acme')));
      await t.pump(const Duration(milliseconds: 160));
      expect(_scales(t, find.byType(HomeCard)).every((s) => s == 1), isTrue);
      await p.up();
    });

    testWidgets('bookmark/share: hover fill, press .90, never open the card', (
      t,
    ) async {
      var opened = 0, marked = 0, shared = 0;
      final handle = t.ensureSemantics();
      await t.pumpWidget(
        card(
          onTap: () => opened++,
          onBookmark: () => marked++,
          onShare: () => shared++,
        ),
      );
      final bm = find.bySemanticsLabel('Add bookmark');
      final fill = find.byWidgetPredicate(
        (w) =>
            w is AnimatedContainer &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == const Color(0xFFF3F1EC),
      );
      final g = await _mouse(t);
      await _hover(t, g, bm);
      expect(fill, findsOneWidget);
      await _leave(t, g);
      expect(fill, findsNothing);

      final p = await t.startGesture(t.getCenter(bm));
      await t.pump(const Duration(milliseconds: 160));
      expect(
        _scales(t, find.byType(HomeCard)),
        contains(PressScale.cardAction),
      );
      await p.up();
      await t.pump(const Duration(milliseconds: 300));
      expect(marked, 1);
      expect(opened, 0);

      await t.tap(find.bySemanticsLabel('Share'));
      await t.pump(const Duration(milliseconds: 300));
      expect(shared, 1);
      expect(opened, 0);

      await t.pumpWidget(card(onBookmark: () {}, bookmarked: true));
      expect(find.byType(Pop), findsOneWidget);
      handle.dispose();
    });

    testWidgets('animate: false has no entrance, animate: true rises in', (
      t,
    ) async {
      await t.pumpWidget(card());
      expect(find.byType(Rise), findsNothing);
      await t.pumpWidget(card(animate: true));
      expect(find.byType(Rise), findsOneWidget);
      await t.pump(const Duration(seconds: 1));
    });
  });

  testWidgets('RailCard hovers like a home card and has no entrance', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        Padding(
          padding: const EdgeInsets.all(16),
          child: RailCard(
            name: 'Rail Co',
            tag: 'AgriTech',
            city: 'Jeddah',
            body: 'Body',
            joined: 'Joined today',
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.byType(Rise), findsNothing);
    final g = await _mouse(t);
    await _hover(t, g, find.text('Rail Co'));
    final c = t.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(RailCard),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect((c.decoration as BoxDecoration).boxShadow, hasLength(2));
    expect(c.transform!.getTranslation().y, -2);
  });

  group('Trending (4.9)', () {
    testWidgets('row hover #F7F5F0, pressed #F6F4EF, no scale', (t) async {
      await t.pumpWidget(
        _app(
          TrendingBox(
            children: [
              TrendingRow(
                rank: 1,
                category: 'Fintech',
                name: 'Zed',
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      Color? bg() =>
          (t
                      .widget<AnimatedContainer>(
                        find
                            .descendant(
                              of: find.byType(TrendingRow),
                              matching: find.byType(AnimatedContainer),
                            )
                            .first,
                      )
                      .decoration
                  as BoxDecoration)
              .color;
      expect(bg(), Colors.transparent);
      final g = await _mouse(t);
      await _hover(t, g, find.text('Zed'));
      expect(bg(), const Color(0xFFF7F5F0));
      await g.down(t.getCenter(find.text('Zed')));
      await t.pump(const Duration(milliseconds: 200));
      expect(bg(), const Color(0xFFF6F4EF));
      expect(find.byType(AnimatedScale), findsNothing);
      await g.up();
    });

    testWidgets('the box enters with a 300 ms rise', (t) async {
      await t.pumpWidget(_app(const TrendingBox(children: [Text('x')])));
      expect(
        t.widget<Rise>(find.byType(Rise)).duration,
        const Duration(milliseconds: 300),
      );
      await t.pump(const Duration(seconds: 1));
    });
  });

  group('SegmentedSwitch (4.4)', () {
    testWidgets('hover turns the unselected label moss600, not the selected', (
      t,
    ) async {
      await t.pumpWidget(
        _app(
          SegmentedSwitch(
            labels: const ['Startups', 'Investors'],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      );
      expect(_textColor(t, 'Investors'), AppColors.metaText);
      final g = await _mouse(t);
      await _hover(t, g, find.text('Investors'));
      expect(_textColor(t, 'Investors'), AppColors.moss600);
      await _leave(t, g);
      expect(_textColor(t, 'Investors'), AppColors.metaText);
      await _hover(t, g, find.text('Startups'));
      expect(_textColor(t, 'Startups'), AppColors.green);
    });

    testWidgets('the thumb slides over 300 ms; no press scale', (t) async {
      var sel = 0;
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (c, s) => SegmentedSwitch(
              labels: const ['Startups', 'Investors'],
              selectedIndex: sel,
              onChanged: (i) => s(() => sel = i),
            ),
          ),
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);
      final x0 = t.getTopLeft(find.byType(FractionallySizedBox)).dx;
      await t.tap(find.text('Investors'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      final mid = t.getTopLeft(find.byType(FractionallySizedBox)).dx;
      expect(
        t.widget<AnimatedAlign>(find.byType(AnimatedAlign)).duration,
        const Duration(milliseconds: 300),
      );
      await t.pump(const Duration(milliseconds: 400));
      final x1 = t.getTopLeft(find.byType(FractionallySizedBox)).dx;
      expect(mid, greaterThan(x0));
      expect(mid, lessThan(x1));
    });
  });

  testWidgets('result chips use ChipIn (4.8)', (t) async {
    await t.pumpWidget(
      _app(
        ResultsRow(
          title: '2 results',
          onClearAll: () {},
          chips: [
            ResultChip(label: 'Fintech', onRemove: () {}),
            ResultChip.query('riyadh', onRemove: () {}),
          ],
        ),
      ),
    );
    expect(find.byType(ChipIn), findsNWidgets(2));
    await t.pump(const Duration(seconds: 1));
  });

  group('Header (4.1/4.2)', () {
    testWidgets('notification dot appears after 250 ms over 400 ms', (t) async {
      await t.pumpWidget(
        _app(
          const HomeHeader(title: 'Hub', initials: 'SA', hasNotification: true),
        ),
      );
      double op() => t
          .widget<Opacity>(
            find
                .descendant(
                  of: find.byType(HomeHeader),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      await t.pump(const Duration(milliseconds: 100));
      expect(op(), 0);
      await t.pump(const Duration(milliseconds: 250));
      await t.pump(const Duration(milliseconds: 100));
      expect(op(), inInclusiveRange(0.01, 0.99));
      await t.pump(const Duration(milliseconds: 600));
      expect(op(), 1);
    });

    testWidgets('avatar presses to .94', (t) async {
      await t.pumpWidget(
        _app(HomeHeader(title: 'Hub', initials: 'SA', onAvatarTap: () {})),
      );
      final g = await t.startGesture(t.getCenter(find.text('SA')));
      await t.pump(const Duration(milliseconds: 160));
      expect(_scales(t, find.byType(HomeHeader)), contains(0.94));
      await g.up();
      await t.pump(const Duration(seconds: 1));
    });

    testWidgets('sub-tab indicator slides over 300 ms to the new tab', (
      t,
    ) async {
      var sel = 0;
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (c, s) => HomeHeader(
              title: 'Explore',
              tabs: ExploreTab.defaults,
              selectedTab: sel,
              onTabChanged: (i) => s(() => sel = i),
            ),
          ),
        ),
      );
      final ind = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.constraints?.maxWidth == 28 &&
            w.constraints?.maxHeight == 3,
      );
      final x0 = t.getCenter(ind).dx;
      await t.tap(find.text('Matches'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      final mid = t.getCenter(ind).dx;
      await t.pump(const Duration(milliseconds: 500));
      final x1 = t.getCenter(ind).dx;
      expect(mid, greaterThan(x0));
      expect(mid, lessThan(x1));
      expect(x1, closeTo(t.getCenter(find.text('Matches')).dx, 25));
    });
  });

  testWidgets('tune button: press .94, active fill #EEF4EF (4.3)', (t) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    Widget bar(int n) => _app(
      HomeSearchBar(
        controller: c,
        onFilterTap: () {},
        activeCount: n,
        overlap: 0,
      ),
    );
    await t.pumpWidget(bar(0));
    Color? fill() =>
        (t
                    .widget<AnimatedContainer>(
                      find
                          .descendant(
                            of: find.byType(HomeSearchBar),
                            matching: find.byType(AnimatedContainer),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .color;
    expect(fill(), Colors.transparent);
    final g = await t.startGesture(t.getCenter(find.byType(Pressable)));
    await t.pump(const Duration(milliseconds: 160));
    expect(_scales(t, find.byType(Pressable)), contains(0.94));
    await g.up();
    await t.pumpWidget(bar(2));
    await t.pump(const Duration(milliseconds: 300));
    expect(fill(), AppColors.mossChip);
  });

  group('Side drawer (4.13)', () {
    Widget drawer(List<AppDrawerItem> items) => _app(
      AppSideDrawer(
        name: 'Shahad',
        initials: 'SA',
        roleLine: 'Founder',
        items: items,
        onViewProfile: () {},
        onLogOut: () {},
      ),
      scroll: false,
    );

    testWidgets('row hover #EFECE5 and pressed #EBE8E1, no scale', (t) async {
      await t.pumpWidget(
        drawer([AppDrawerItem(label: 'Settings', icon: 'M0 0', onTap: () {})]),
      );
      await t.pump(const Duration(seconds: 1));
      final g = await _mouse(t);
      await _hover(t, g, find.text('Settings'));
      expect(_rowColor(t, 'Settings'), const Color(0xFFEFECE5));
      await g.down(t.getCenter(find.text('Settings')));
      await t.pump(const Duration(milliseconds: 200));
      expect(_rowColor(t, 'Settings'), const Color(0xFFEBE8E1));
      await g.up();
      await t.pump(const Duration(seconds: 1));
    });

    testWidgets('View profile presses to .96', (t) async {
      await t.pumpWidget(drawer(const []));
      await t.pump(const Duration(seconds: 1));
      final g = await t.startGesture(t.getCenter(find.text('View profile')));
      await t.pump(const Duration(milliseconds: 160));
      expect(_scales(t, find.byType(AppSideDrawer)), contains(0.96));
      await g.up();
    });

    testWidgets('rows stagger in: later rows start later', (t) async {
      await t.pumpWidget(
        drawer([
          for (var i = 0; i < 3; i++)
            AppDrawerItem(label: 'Row $i', icon: 'M0 0', onTap: () {}),
        ]),
      );
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 16));
      await t.pump(const Duration(milliseconds: 100));
      double op(String l) => t
          .widget<Opacity>(
            find
                .ancestor(of: find.text(l), matching: find.byType(Opacity))
                .first,
          )
          .opacity;
      expect(op('Row 0'), greaterThan(op('Row 2')));
      await t.pump(const Duration(seconds: 1));
      expect(op('Row 2'), 1);
    });
  });

  group('Dropdowns (4.10)', () {
    testWidgets('range: caret turns, selected bold moss600, option hover', (
      t,
    ) async {
      await t.pumpWidget(
        _app(
          Align(
            alignment: Alignment.topRight,
            child: RangeDropdown(
              options: const ['Today', 'Last 7 days', 'Last 30 days'],
              selectedIndex: 1,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      double turns() =>
          t.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns;
      expect(turns(), 0);
      await t.tap(find.text('Last 7 days'));
      await t.pump();
      expect(turns(), 0.5);
      await t.pump(const Duration(milliseconds: 500));
      final sel = t.widget<Text>(find.text('Last 7 days').last);
      expect(sel.style!.fontWeight, FontWeight.w700);
      expect(sel.style!.color, AppColors.moss600);
      expect(_rowColor(t, 'Last 7 days'), AppColors.mossChip);
      final g = await _mouse(t);
      await _hover(t, g, find.text('Today'));
      expect(_rowColor(t, 'Today'), const Color(0xFFF6F4EF));
      await t.tapAt(const Offset(5, 500));
      await t.pump();
      expect(turns(), 0);
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Today'), findsNothing);
    });

    testWidgets('"Matches for" button border hovers to #B9C8BD', (t) async {
      await t.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: MatchesForDropdown(
              options: const [
                MatchesForOption(name: 'Acme', subtitle: 'Fintech · Seed'),
                MatchesForOption(name: 'Beta', subtitle: 'EdTech · Seed'),
              ],
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      Color? border() =>
          ((t
                              .widget<AnimatedContainer>(
                                find
                                    .ancestor(
                                      of: find.text('Matches for'),
                                      matching: find.byType(AnimatedContainer),
                                    )
                                    .first,
                              )
                              .decoration
                          as BoxDecoration)
                      .border!
                  as Border)
              .top
              .color;
      expect(border(), AppColors.border);
      final g = await _mouse(t);
      await _hover(t, g, find.text('Matches for'));
      expect(border(), const Color(0xFFB9C8BD));
      await t.tap(find.text('Matches for'));
      await t.pump(const Duration(milliseconds: 500));
      await _hover(t, g, find.text('Beta'));
      expect(_rowColor(t, 'Beta'), const Color(0xFFF6F4EF));
    });
  });

  testWidgets('picker option hover #F2F7F3, selected moss100 + check Pop (7)', (
    t,
  ) async {
    await t.pumpWidget(
      _app(
        const SizedBox(
          height: 600,
          child: PickerSheet(
            title: 'City',
            options: ['Riyadh', 'Jeddah'],
            selected: 'Riyadh',
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    expect(_rowColor(t, 'Riyadh'), AppColors.moss100);
    expect(find.byType(Pop), findsOneWidget);
    final g = await _mouse(t);
    await _hover(t, g, find.text('Jeddah'));
    expect(_rowColor(t, 'Jeddah'), const Color(0xFFF2F7F3));
    await _hover(t, g, find.text('Riyadh'));
    expect(_rowColor(t, 'Riyadh'), AppColors.moss100);
  });

  testWidgets('toast: appears, holds 2400 ms, fades; a new one replaces it', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (c) => TextButton(
              onPressed: () => AppToast.error(c, 'Hello'),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    double op(String s) => t
        .widget<Opacity>(
          find.ancestor(of: find.text(s), matching: find.byType(Opacity)).first,
        )
        .opacity;
    expect(op('Hello'), inInclusiveRange(0.01, 0.99));
    await t.pump(const Duration(milliseconds: 300));
    expect(op('Hello'), 1);
    await t.pump(const Duration(milliseconds: 2000));
    AppToast.error(t.element(find.text('go')), 'Second');
    await t.pump();
    expect(find.text('Hello'), findsNothing);
    expect(find.text('Second'), findsOneWidget);
    // The old timer (400 ms left) must not dismiss the new toast.
    await t.pump(const Duration(milliseconds: 2300));
    expect(find.text('Second'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 150));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Second'), findsNothing);
  });
}
