import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/features/connection_requests/screens/interest_tab.dart';
import 'package:startsa/features/startups/widgets/draft_card.dart';
import 'package:startsa/features/startups/widgets/hover_lift_card.dart';
import 'package:startsa/features/startups/widgets/manage_card.dart';
import 'package:startsa/shared_ui/theme/app_colors.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(
      body: Center(child: SizedBox(width: 700, child: child)),
    ),
  ),
);

Future<TestGesture> _mouse(WidgetTester t, Finder f) async {
  final g = await t.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: const Offset(1, 1));
  addTearDown(g.removePointer);
  await g.moveTo(t.getCenter(f));
  await t.pump();
  await t.pump(const Duration(milliseconds: 300));
  return g;
}

AnimatedContainer _card(WidgetTester t) => t.widget<AnimatedContainer>(
  find
      .descendant(
        of: find.byType(HoverLiftCard),
        matching: find.byType(AnimatedContainer),
      )
      .first,
);

double _dy(WidgetTester t) => _card(t).transform!.getTranslation().y;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('HoverLiftCard (My Startups, draft, calculator link)', () {
    Widget card() => HoverLiftCard(onTap: () {}, child: const Text('Card'));

    testWidgets('mouse hover lifts 2 px with the hover shadow', (t) async {
      await t.pumpWidget(_app(card()));
      expect(_dy(t), 0);
      expect(
        (_card(t).decoration as BoxDecoration).boxShadow,
        isNot(kCardHoverShadow),
      );
      final g = await _mouse(t, find.text('Card'));
      expect(_dy(t), -2);
      expect(
        (_card(t).decoration as BoxDecoration).boxShadow,
        kCardHoverShadow,
      );
      await g.moveTo(const Offset(790, 590));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(_dy(t), 0);
    });

    testWidgets('the lift takes 220 ms', (t) async {
      await t.pumpWidget(_app(card()));
      expect(_card(t).duration, const Duration(milliseconds: 220));
    });

    testWidgets('press scales to .97', (t) async {
      await t.pumpWidget(_app(card()));
      final g = await t.startGesture(t.getCenter(find.text('Card')));
      await t.pump(const Duration(milliseconds: 200));
      final s = t.widget<AnimatedScale>(
        find
            .descendant(
              of: find.byType(HoverLiftCard),
              matching: find.byType(AnimatedScale),
            )
            .first,
      );
      expect(s.scale, 0.97);
      await g.up();
    });

    testWidgets('touch never lifts', (t) async {
      await t.pumpWidget(_app(card()));
      await t.tap(find.text('Card'));
      await t.pump(const Duration(milliseconds: 300));
      expect(_dy(t), 0);
    });

    testWidgets('reduced motion: no lift', (t) async {
      await t.pumpWidget(_app(card(), reduce: true));
      await _mouse(t, find.text('Card'));
      expect(_dy(t), 0);
    });

    testWidgets('without an action it does not hover', (t) async {
      await t.pumpWidget(_app(const HoverLiftCard(child: Text('Card'))));
      await _mouse(t, find.text('Card'));
      expect(_dy(t), 0);
    });
  });

  testWidgets('ManageCard with onTap lifts on hover', (t) async {
    var taps = 0;
    await t.pumpWidget(
      _app(ManageCard(onTap: () => taps++, child: const Text('Calc'))),
    );
    await _mouse(t, find.text('Calc'));
    expect(_dy(t), -2);
    await t.tap(find.text('Calc'));
    expect(taps, 1);
  });

  testWidgets('ManageCard without onTap is a plain card', (t) async {
    await t.pumpWidget(_app(const ManageCard(child: Text('Plain'))));
    expect(find.byType(HoverLiftCard), findsNothing);
  });

  testWidgets('draft card lifts on hover and keeps its tap', (t) async {
    var taps = 0;
    await t.pumpWidget(
      _app(
        DraftCard(
          draft: const {'name': 'Acme', 'step': 1},
          onTap: () => taps++,
          onDiscard: () {},
        ),
      ),
    );
    await _mouse(t, find.text('Acme'));
    expect(_dy(t), -2);
    await t.tap(find.text('Acme'));
    expect(taps, 1);
  });

  group('interest reply button', () {
    Color fill(WidgetTester t) =>
        (t
                    .widget<AnimatedContainer>(
                      find.descendant(
                        of: find.byType(InterestReplyButton),
                        matching: find.byType(AnimatedContainer),
                      ),
                    )
                    .decoration!
                as BoxDecoration)
            .color!;

    testWidgets('hover swaps moss50 for moss100 over 150 ms', (t) async {
      await t.pumpWidget(_app(const InterestReplyButton()));
      expect(fill(t), AppColors.moss50);
      final g = await _mouse(t, find.byType(InterestReplyButton));
      expect(fill(t), AppColors.moss100);
      await g.moveTo(const Offset(790, 590));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(fill(t), AppColors.moss50);
    });
  });
}
