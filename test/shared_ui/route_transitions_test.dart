import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:startsa/shared_ui/navigation/app_route.dart';
import 'package:startsa/shared_ui/theme/app_colors.dart';

/// STARTSA_ANIMATIONS.md §1: the screen transitions.
const _oldKey = Key('old');
const _newKey = Key('new');

Widget _screen(Key key, {String label = 'screen'}) => Scaffold(
  backgroundColor: AppColors.cream,
  body: Align(
    alignment: Alignment.topLeft,
    child: SizedBox(key: key, width: 100, height: 100, child: Text(label)),
  ),
);

Future<void> _pumpApp(WidgetTester t, {bool reduce = false}) async {
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: child!,
      ),
      home: _screen(_oldKey),
    ),
  );
}

BuildContext _ctx(WidgetTester t) => t.element(find.byKey(_oldKey));

double _opacityOfNew(WidgetTester t) {
  final ops = find.ancestor(
    of: find.byKey(_newKey),
    matching: find.byType(Opacity),
  );
  if (ops.evaluate().isEmpty) return 1;
  return t.widget<Opacity>(ops.first).opacity;
}

double _x(WidgetTester t, Key k) => t.getTopLeft(find.byKey(k)).dx;
double _y(WidgetTester t, Key k) => t.getTopLeft(find.byKey(k)).dy;

void main() {
  Future<void> push(WidgetTester t, RouteKind kind, bool green) async {
    Navigator.of(_ctx(t)).push(
      AppRoute<void>(
        builder: (_) => _screen(_newKey),
        kind: kind,
        greenHeader: green,
      ),
    );
    await t.pump(); // route built, animation at 0
    await t.pump(const Duration(milliseconds: 1));
  }

  testWidgets('forward: fades in and slides from x +28, 260 ms', (t) async {
    await _pumpApp(t);
    await push(t, RouteKind.forward, false);
    expect(_x(t, _newKey), closeTo(28, 1));
    expect(_opacityOfNew(t), lessThan(0.2));
    await t.pump(const Duration(milliseconds: 130));
    expect(_x(t, _newKey), inExclusiveRange(0, 28));
    await t.pump(const Duration(milliseconds: 200));
    expect(_x(t, _newKey), 0);
    expect(_opacityOfNew(t), 1);
  });

  testWidgets('up: fades in and slides from y +24', (t) async {
    await _pumpApp(t);
    await push(t, RouteKind.up, false);
    expect(_y(t, _newKey), closeTo(24, 1));
    expect(_x(t, _newKey), 0);
    expect(_opacityOfNew(t), lessThan(0.2));
    await t.pump(const Duration(milliseconds: 300));
    expect(_y(t, _newKey), 0);
  });

  testWidgets('fade: opacity only, no movement', (t) async {
    await _pumpApp(t);
    await push(t, RouteKind.fade, false);
    expect(_x(t, _newKey), 0);
    expect(_y(t, _newKey), 0);
    expect(_opacityOfNew(t), lessThan(0.2));
    await t.pump(const Duration(milliseconds: 300));
    expect(_opacityOfNew(t), 1);
  });

  testWidgets('green-header screens never fade and slide only 12 px', (
    t,
  ) async {
    await _pumpApp(t);
    await push(t, RouteKind.forward, true);
    expect(_x(t, _newKey), closeTo(12, 1));
    expect(_opacityOfNew(t), 1, reason: 'opacity stays 1');
    await t.pump(const Duration(milliseconds: 300));
    expect(_x(t, _newKey), 0);
  });

  testWidgets('the old screen disappears instantly (no exit animation)', (
    t,
  ) async {
    await _pumpApp(t);
    await push(t, RouteKind.forward, false);
    // Covered from the first frame by the cream backdrop of the new route and
    // not moving: its position never changes.
    expect(_x(t, _oldKey), 0);
    await t.pump(const Duration(milliseconds: 100));
    expect(_x(t, _oldKey), 0);
    final old = find.byKey(_oldKey, skipOffstage: false);
    expect(old, findsOneWidget);
  });

  testWidgets('back: the revealed screen fades in from x -28', (t) async {
    await t.pumpWidget(const MaterialApp(home: SizedBox(key: Key('boot'))));
    Navigator.of(t.element(find.byKey(const Key('boot')))).push(
      AppRoute<void>(
        builder: (context) => Scaffold(
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => AppNav.push(context, _screen(_newKey)),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(key: _oldKey, width: 100, height: 100),
            ),
          ),
        ),
        instant: true,
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byKey(_oldKey));
    await t.pumpAndSettle();
    // Pop from the new screen (the on-screen back button and the Android back
    // gesture both do this).
    Navigator.of(t.element(find.byKey(_newKey))).pop();
    await t.pump();
    await t.pump(const Duration(milliseconds: 1));
    expect(_x(t, _oldKey), closeTo(-28, 1));
    final ops = find.ancestor(
      of: find.byKey(_oldKey),
      matching: find.byType(Opacity),
    );
    final visible = ops
        .evaluate()
        .map((e) => (e.widget as Opacity).opacity)
        .fold<double>(1, (a, b) => a * b);
    expect(visible, lessThan(0.2));
    await t.pump(const Duration(milliseconds: 300));
    expect(_x(t, _oldKey), 0);
  });

  testWidgets('reduced motion: a 200 ms fade, no slide', (t) async {
    await _pumpApp(t, reduce: true);
    await push(t, RouteKind.forward, false);
    expect(_x(t, _newKey), 0, reason: 'no slide');
    expect(_opacityOfNew(t), lessThan(0.2));
    await t.pump(const Duration(milliseconds: 100));
    expect(_opacityOfNew(t), inExclusiveRange(0.2, 1));
    await t.pump(const Duration(milliseconds: 110));
    expect(_opacityOfNew(t), 1, reason: 'done after ~200 ms');
  });

  testWidgets('reduced motion: green-header screens fade too', (t) async {
    await _pumpApp(t, reduce: true);
    await push(t, RouteKind.forward, true);
    expect(_x(t, _newKey), 0);
    expect(_opacityOfNew(t), lessThan(0.2));
  });
}
