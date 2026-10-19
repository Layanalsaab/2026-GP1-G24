import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/profiles/widgets/profile_widgets.dart';
import 'package:startsa/shared_ui/motion/motion.dart';
import 'package:startsa/shared_ui/widgets/cards/charts.dart';
import 'package:startsa/shared_ui/widgets/cards/profile_blocks.dart';
import 'package:startsa/shared_ui/widgets/headers/tabbed_header.dart';
import 'package:startsa/shared_ui/widgets/lists/press_surface.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

Future<TestGesture> _mouse(WidgetTester t, Finder f) async {
  final g = await t.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: const Offset(1, 1));
  addTearDown(g.removePointer);
  await g.moveTo(t.getCenter(f));
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
  return g;
}

Color? _surfaceColor(WidgetTester t) {
  final c = t.widget<AnimatedContainer>(
    find
        .descendant(
          of: find.byType(PressSurface),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return (c.decoration as BoxDecoration?)?.color;
}

ProfileHead _head({String? linkedin}) => ProfileHead(
  initials: 'AB',
  name: 'Ada B',
  role: 'Founder',
  metaTail: 'Joined 2024',
  tagsLabel: 'Interested in',
  tags: const ['Fintech'],
  linkedin: linkedin,
  onLinkedin: () {},
);

Widget _row() => ListRow(
  leading: const SizedBox(width: 40, height: 40),
  title: 'Row',
  onTap: () {},
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('profile avatar', () {
    double opacity(WidgetTester t) => t
        .widget<Opacity>(
          find
              .ancestor(of: find.text('AB'), matching: find.byType(Opacity))
              .first,
        )
        .opacity;

    testWidgets('fades in over 450 ms', (t) async {
      await t.pumpWidget(_app(_head()));
      expect(opacity(t), 0);
      await t.pump(const Duration(milliseconds: 100));
      expect(opacity(t), greaterThan(0));
      expect(opacity(t), lessThan(1));
      await t.pump(const Duration(milliseconds: 400));
      expect(opacity(t), 1);
    });

    testWidgets('scales from .9 to 1', (t) async {
      await t.pumpWidget(_app(_head()));
      double scale() => t
          .widgetList<Transform>(
            find.ancestor(
              of: find.text('AB'),
              matching: find.byType(Transform),
            ),
          )
          .map((x) => x.transform.storage[0])
          .reduce((a, b) => a < b ? a : b);
      expect(scale(), closeTo(0.9, 0.001));
      await t.pump(const Duration(milliseconds: 500));
      expect(scale(), closeTo(1, 0.001));
    });

    testWidgets('reduced motion: 200 ms fade, no scale', (t) async {
      await t.pumpWidget(_app(_head(), reduce: true));
      await t.pump(const Duration(milliseconds: 100));
      expect(opacity(t), greaterThan(0));
      await t.pump(const Duration(milliseconds: 150));
      expect(opacity(t), 1);
    });
  });

  testWidgets('LinkedIn pill scales to .96 while pressed', (t) async {
    await t.pumpWidget(_app(_head(linkedin: 'https://x')));
    await t.pump(const Duration(milliseconds: 600));
    final target = find.ancestor(
      of: find.text('LinkedIn'),
      matching: find.byType(Pressable),
    );
    expect(target, findsOneWidget);
    final g = await t.startGesture(t.getCenter(find.text('LinkedIn')));
    await t.pump(const Duration(milliseconds: 200));
    final s = t.widget<AnimatedScale>(
      find.descendant(of: target, matching: find.byType(AnimatedScale)).first,
    );
    expect(s.scale, 0.96);
    await g.up();
  });

  group('rows', () {
    testWidgets('ListRow hover paints #F7F5F0 only for a mouse', (t) async {
      await t.pumpWidget(_app(_row()));
      expect(_surfaceColor(t), Colors.transparent);
      final g = await _mouse(t, find.text('Row'));
      expect(_surfaceColor(t), const Color(0xFFF7F5F0));
      await g.moveTo(const Offset(790, 590));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(_surfaceColor(t), Colors.transparent);
    });

    testWidgets('a touch tap never leaves the hover colour', (t) async {
      await t.pumpWidget(_app(_row()));
      await t.tap(find.text('Row'));
      await t.pump(const Duration(milliseconds: 400));
      expect(_surfaceColor(t), Colors.transparent);
    });

    testWidgets('PressSurface hover colour (settings #F2F7F3)', (t) async {
      await t.pumpWidget(
        _app(
          PressSurface(
            onTap: () {},
            hoverColor: const Color(0xFFF2F7F3),
            child: const SizedBox(width: 200, height: 50, child: Text('S')),
          ),
        ),
      );
      await _mouse(t, find.text('S'));
      expect(_surfaceColor(t), const Color(0xFFF2F7F3));
    });

    testWidgets('a disabled row does not hover', (t) async {
      await t.pumpWidget(
        _app(
          const PressSurface(
            hoverColor: Color(0xFFF2F7F3),
            child: SizedBox(width: 200, height: 50, child: Text('S')),
          ),
        ),
      );
      await _mouse(t, find.text('S'));
      expect(_surfaceColor(t), Colors.transparent);
    });
  });

  testWidgets('ProfileSection rises in after its delay', (t) async {
    await t.pumpWidget(
      _app(
        const ProfileSection(
          title: 'About',
          delay: Duration(milliseconds: 120),
          child: Text('x'),
        ),
      ),
    );
    Opacity op() => t.widget<Opacity>(find.byType(Opacity).first);
    expect(op().opacity, 0);
    await t.pump(const Duration(milliseconds: 130));
    await t.pump(const Duration(milliseconds: 100));
    expect(op().opacity, greaterThan(0));
    await t.pump(const Duration(milliseconds: 500));
    expect(op().opacity, 1);
  });

  group('TabPaneSlide', () {
    Future<double> dx(WidgetTester t, int from, int to) async {
      var idx = from;
      late StateSetter set;
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (c, s) {
              set = s;
              return TabPaneSlide(index: idx, child: const Text('pane'));
            },
          ),
        ),
      );
      set(() => idx = to);
      await t.pump();
      await t.pump(const Duration(milliseconds: 20));
      return t
          .widget<Transform>(
            find
                .ancestor(
                  of: find.text('pane'),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .getTranslation()
          .x;
    }

    testWidgets('moving right slides in from the right', (t) async {
      expect(await dx(t, 0, 2), greaterThan(0));
    });
    testWidgets('moving left slides in from the left', (t) async {
      expect(await dx(t, 2, 0), lessThan(0));
    });
  });

  testWidgets('tab label colour animates', (t) async {
    var sel = 0;
    late StateSetter set;
    await t.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (c, s) {
            set = s;
            return HeaderTabBar(
              tabs: const [HeaderTab('One'), HeaderTab('Two')],
              selectedIndex: sel,
              onChanged: (_) {},
            );
          },
        ),
      ),
    );
    Color col() => t
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Two'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style
        .color!;
    final before = col();
    set(() => sel = 1);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    final mid = col();
    await t.pump(const Duration(milliseconds: 300));
    final after = col();
    expect(mid, isNot(before));
    expect(mid, isNot(after));
  });

  testWidgets('RevenueBars: every bar Grows in', (t) async {
    await t.pumpWidget(
      _app(
        const RevenueBars(
          values: [1, 2, 3],
          labels: ['Year 1', 'Year 2', 'Year 3'],
          valueLabels: ['1', '2', '3'],
        ),
      ),
    );
    expect(find.byType(Grow), findsNWidgets(3));
    double sy() => t
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(Grow).first,
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getMaxScaleOnAxis();
    expect(sy(), closeTo(1, 0.001)); // x scale is 1, y starts at .08
    await t.pump(const Duration(milliseconds: 100));
    expect(t.binding.transientCallbackCount, greaterThan(0));
    await t.pump(const Duration(milliseconds: 600));
    expect(t.binding.transientCallbackCount, 0);
  });

  testWidgets('AreaChart and OwnershipBar animate 400 ms on change', (t) async {
    var v = const [1.0, 2.0, 3.0];
    var seg = 20.0;
    late StateSetter set;
    await t.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (c, s) {
            set = s;
            return Column(
              children: [
                AreaChart(values: v),
                OwnershipBar(
                  segments: [
                    OwnershipSegment(seg, Colors.green),
                    OwnershipSegment(100 - seg, Colors.amber),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
    await t.pump();
    expect(t.binding.transientCallbackCount, 0);
    set(() {
      v = const [3.0, 1.0, 2.0];
      seg = 70;
    });
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(t.binding.transientCallbackCount, greaterThan(0));
    await t.pump(const Duration(milliseconds: 500));
    expect(t.binding.transientCallbackCount, 0);
  });

  testWidgets('chart morph is instant under reduced motion', (t) async {
    var seg = 20.0;
    late StateSetter set;
    await t.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (c, s) {
            set = s;
            return OwnershipBar(
              segments: [
                OwnershipSegment(seg, Colors.green),
                OwnershipSegment(100 - seg, Colors.amber),
              ],
            );
          },
        ),
        reduce: true,
      ),
    );
    set(() => seg = 70);
    await t.pump();
    await t.pump();
    expect(t.binding.transientCallbackCount, 0);
  });
}
