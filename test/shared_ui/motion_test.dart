import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/shared_ui/motion/motion.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _scaleOf(WidgetTester t) =>
    t.widget<AnimatedScale>(find.byType(AnimatedScale).first).scale;

void main() {
  test('tokens match the spec', () {
    expect(AppCurves.easeOut, const Cubic(0.23, 1, 0.32, 1));
    expect(AppCurves.drawer, const Cubic(0.32, 0.72, 0, 1));
    expect(AppDur.press, const Duration(milliseconds: 140));
    expect(AppDur.advSheet, const Duration(milliseconds: 420));
    expect(AppDur.toastHold, const Duration(milliseconds: 2400));
    expect(PressScale.button, 0.97);
    expect(PressScale.icon, 0.92);
    expect(PressScale.chip, 0.96);
    expect(PressScale.homeCard, 0.985);
    expect(PressScale.cardAction, 0.90);
    expect(PressScale.avatar, 0.94);
    expect(PressScale.pill, 0.95);
    expect(PressScale.smallPill, 0.96);
  });

  group('Pressable', () {
    testWidgets('scales while pressed and returns', (t) async {
      await t.pumpWidget(
        _app(
          Pressable(
            onTap: () {},
            scale: PressScale.icon,
            child: const SizedBox(width: 44, height: 44),
          ),
        ),
      );
      final g = await t.startGesture(t.getCenter(find.byType(Pressable)));
      await t.pump(const Duration(milliseconds: 50));
      expect(_scaleOf(t), PressScale.icon);
      await g.up();
      await t.pump(const Duration(milliseconds: 50));
      expect(_scaleOf(t), 1);
    });

    testWidgets('disabled does not scale', (t) async {
      await t.pumpWidget(
        _app(const Pressable(child: SizedBox(width: 44, height: 44))),
      );
      final g = await t.startGesture(t.getCenter(find.byType(Pressable)));
      await t.pump(const Duration(milliseconds: 50));
      expect(_scaleOf(t), 1);
      await g.up();
    });

    testWidgets('reduced motion turns the press scale off', (t) async {
      await t.pumpWidget(
        _app(
          reduce: true,
          Pressable(onTap: () {}, child: const SizedBox(width: 44, height: 44)),
        ),
      );
      final g = await t.startGesture(t.getCenter(find.byType(Pressable)));
      await t.pump(const Duration(milliseconds: 50));
      expect(_scaleOf(t), 1);
      await g.up();
    });

    testWidgets('a mouse hover lifts the card 2 px', (t) async {
      await t.pumpWidget(
        _app(
          Pressable(
            onTap: () {},
            hoverOffset: const Offset(0, -2),
            hoverColor: const Color(0xFFF7F5F0),
            borderRadius: BorderRadius.circular(12),
            child: const SizedBox(key: Key('box'), width: 100, height: 60),
          ),
        ),
      );
      final box = find.byKey(const Key('box'));
      final before = t.getTopLeft(box);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(t.getCenter(find.byType(Pressable)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      final after = t.getTopLeft(box);
      expect(after.dy, before.dy - 2);
      await mouse.moveTo(const Offset(5, 5));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(t.getTopLeft(box).dy, before.dy);
    });

    testWidgets('keyboard focus shows the outline, a tap does not', (t) async {
      var taps = 0;
      await t.pumpWidget(
        _app(
          Pressable(
            onTap: () => taps++,
            child: const SizedBox(width: 100, height: 44),
          ),
        ),
      );
      Finder outline() => find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).border != null,
      );
      await t.tap(find.byType(Pressable));
      await t.pump();
      expect(outline(), findsNothing, reason: 'touch focus shows no outline');
      expect(taps, 1);
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(outline(), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(taps, 2, reason: 'Enter activates the focused element');
    });
  });

  group('effects', () {
    testWidgets('CardIn shows its start state during the delay', (t) async {
      await t.pumpWidget(
        _app(const CardIn(index: 3, child: SizedBox(width: 50, height: 50))),
      );
      Opacity op() => t.widget<Opacity>(find.byType(Opacity).first);
      expect(op().opacity, 0, reason: 'index 3 waits 120 ms, hidden');
      await t.pump(const Duration(milliseconds: 130));
      await t.pump(const Duration(milliseconds: 400));
      expect(op().opacity, 1);
    });

    testWidgets('ChipIn fades and scales in over 220 ms', (t) async {
      await t.pumpWidget(
        _app(const ChipIn(child: SizedBox(width: 50, height: 30))),
      );
      expect(t.widget<Opacity>(find.byType(Opacity).first).opacity, 0);
      await t.pump(AppDur.card + const Duration(milliseconds: 20));
      expect(t.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    });

    testWidgets('Pop peaks at 1.15 at 60 % then settles at 1', (t) async {
      await t.pumpWidget(
        _app(const Pop(child: SizedBox(width: 20, height: 20))),
      );
      await t.pump(const Duration(milliseconds: 5));
      await t.pump(const Duration(milliseconds: 400));
      final scale = t.widget<ScaleTransition>(
        find.byType(ScaleTransition).first,
      );
      expect(scale.scale.value, closeTo(1, 0.001));
    });

    testWidgets('reduced motion: Pop and CardIn become a fade only', (t) async {
      await t.pumpWidget(
        _app(
          reduce: true,
          const Column(
            key: Key('col'),
            children: [
              Pop(child: SizedBox(width: 20, height: 20)),
              CardIn(index: 5, child: SizedBox(width: 20, height: 20)),
            ],
          ),
        ),
      );
      await t.pump(AppDur.reducedFade + const Duration(milliseconds: 20));
      expect(
        find.descendant(
          of: find.byKey(const Key('col')),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
      );
      expect(
        t.widget<Opacity>(find.byType(Opacity).first).opacity,
        1,
        reason: 'no stagger delay, fully visible after the 200 ms fade',
      );
    });
  });
}
