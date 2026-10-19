import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:startsa/features/login_and_signup/widgets/role_card.dart';
import 'package:startsa/features/startups/widgets/team_member_widgets.dart';
import 'package:startsa/shared_ui/icons/app_icons.dart';
import 'package:startsa/shared_ui/motion/motion.dart';
import 'package:startsa/shared_ui/theme/app_colors.dart';
import 'package:startsa/shared_ui/widgets/chips/app_chip.dart';
import 'package:startsa/shared_ui/widgets/forms/app_field.dart';
import 'package:startsa/shared_ui/widgets/forms/app_switch.dart';
import 'package:startsa/shared_ui/widgets/forms/app_text_field.dart';
import 'package:startsa/shared_ui/widgets/forms/select_field.dart';
import 'package:startsa/shared_ui/widgets/headers/header_buttons.dart';
import 'package:startsa/shared_ui/widgets/overlays/app_dialog.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce, size: const Size(412, 892)),
    child: Scaffold(body: Center(child: child)),
  ),
);

Future<TestGesture> _mouse(WidgetTester t, Finder f) async {
  final g = await t.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: const Offset(1, 1));
  addTearDown(g.removePointer);
  await g.moveTo(t.getCenter(f));
  return g;
}

Future<void> _settle(WidgetTester t) async {
  await t.pump();
  await t.pump(const Duration(milliseconds: 400));
}

/// The decoration of the first AnimatedContainer under [f] that has a border.
BoxDecoration _borderDeco(WidgetTester t, Finder f) {
  for (final c in t.widgetList<AnimatedContainer>(
    find.descendant(of: f, matching: find.byType(AnimatedContainer)),
  )) {
    final d = c.decoration;
    if (d is BoxDecoration && d.border != null) return d;
  }
  throw StateError('no bordered AnimatedContainer');
}

/// The decoration actually painted now (the AnimatedContainer widget only
/// holds the target).
BoxDecoration _live(WidgetTester t, Finder animated) =>
    t
            .widget<DecoratedBox>(
              find
                  .descendant(of: animated, matching: find.byType(DecoratedBox))
                  .first,
            )
            .decoration
        as BoxDecoration;

Color _borderColor(BoxDecoration d) => (d.border! as Border).top.color;

Color? _hoverFill(WidgetTester t, Finder f) {
  for (final c in t.widgetList<AnimatedContainer>(
    find.descendant(of: f, matching: find.byType(AnimatedContainer)),
  )) {
    final d = c.decoration;
    if (d is BoxDecoration && d.color != null) return d.color;
  }
  return null;
}

double _pressScale(WidgetTester t, Finder f) => t
    .widget<AnimatedScale>(
      find.descendant(of: f, matching: find.byType(AnimatedScale)).first,
    )
    .scale;

BoxDecoration _firstDeco(WidgetTester t) =>
    t
            .widget<AnimatedContainer>(find.byType(AnimatedContainer).first)
            .decoration!
        as BoxDecoration;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('role card', () {
    Widget card({bool selected = false}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoleCard(
          icon: AppIcons.check,
          title: 'Founder',
          description: 'desc',
          selected: selected,
          onTap: () {},
        ),
      ],
    );

    testWidgets('hover lifts 2 px, shows border and shadow', (t) async {
      await t.pumpWidget(_app(card()));
      final before = t.getTopLeft(find.byType(Row).first);
      final g = await _mouse(t, find.byType(RoleCard));
      await _settle(t);
      final after = t.getTopLeft(find.byType(Row).first);
      expect(after.dy - before.dy, -2);
      final d = _borderDeco(t, find.byType(RoleCard));
      expect(_borderColor(d), const Color(0xFFD9D4C9));
      expect(d.boxShadow!.last.blurRadius, 28);
      await g.moveTo(const Offset(5, 590));
      await _settle(t);
      expect(t.getTopLeft(find.byType(Row).first).dy, before.dy);
      expect(_borderColor(_borderDeco(t, find.byType(RoleCard))).a, 0);
    });

    testWidgets('no lift under reduced motion', (t) async {
      await t.pumpWidget(_app(card(), reduce: true));
      final before = t.getTopLeft(find.byType(Row).first);
      await _mouse(t, find.byType(RoleCard));
      await _settle(t);
      expect(t.getTopLeft(find.byType(Row).first), before);
    });

    testWidgets('press scales to .97', (t) async {
      await t.pumpWidget(_app(card()));
      final g = await t.startGesture(t.getCenter(find.byType(RoleCard)));
      await t.pump(const Duration(milliseconds: 200));
      expect(_pressScale(t, find.byType(RoleCard)), 0.97);
      await g.up();
    });

    testWidgets('selected: moss border 2 px animates, radio pops', (t) async {
      await t.pumpWidget(_app(card()));
      expect(find.byType(Pop), findsNothing);
      await t.pumpWidget(_app(card(selected: true)));
      await t.pump(const Duration(milliseconds: 110));
      final mid = _borderColor(
        _live(
          t,
          find
              .descendant(
                of: find.byType(RoleCard),
                matching: find.byType(AnimatedContainer),
              )
              .first,
        ),
      );
      expect(mid, isNot(AppColors.moss600));
      expect(find.byType(Pop), findsOneWidget);
      await _settle(t);
      final d = _borderDeco(t, find.byType(RoleCard));
      expect(_borderColor(d), AppColors.moss600);
      expect((d.border! as Border).top.width, 2);
    });
  });

  group('form chips', () {
    testWidgets('hover border on unselected chip', (t) async {
      await t.pumpWidget(
        _app(AppChip(label: 'Seed', selected: false, onTap: () {})),
      );
      expect(_borderColor(_borderDeco(t, find.byType(AppChip))).a, 0);
      await _mouse(t, find.byType(AppChip));
      await _settle(t);
      expect(
        _borderColor(_borderDeco(t, find.byType(AppChip))),
        AppColors.borderStrong,
      );
    });

    testWidgets('selected shows check pop, moss fill, padding 12', (t) async {
      await t.pumpWidget(
        _app(AppChip(label: 'Seed', selected: false, onTap: () {})),
      );
      expect(find.byKey(const ValueKey('chip-check')), findsNothing);
      await t.pumpWidget(
        _app(AppChip(label: 'Seed', selected: true, onTap: () {})),
      );
      await t.pump();
      expect(find.byKey(const ValueKey('chip-check')), findsOneWidget);
      await _settle(t);
      final c = t.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(AppChip),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect((c.decoration! as BoxDecoration).color, AppColors.moss600);
      expect(c.padding, const EdgeInsets.only(left: 12, right: 16));
    });

    testWidgets('colors animate (not instant)', (t) async {
      await t.pumpWidget(
        _app(AppChip(label: 'Seed', selected: false, onTap: () {})),
      );
      await t.pumpWidget(
        _app(AppChip(label: 'Seed', selected: true, onTap: () {})),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      final col = _live(
        t,
        find.descendant(
          of: find.byType(AppChip),
          matching: find.byType(AnimatedContainer),
        ),
      ).color!;
      expect(col, isNot(AppColors.moss600));
      expect(col, isNot(AppColors.moss50));
    });

    testWidgets('press scales to .96', (t) async {
      await t.pumpWidget(
        _app(AppChip(label: 'Seed', selected: false, onTap: () {})),
      );
      final g = await t.startGesture(t.getCenter(find.byType(AppChip)));
      await t.pump(const Duration(milliseconds: 200));
      expect(_pressScale(t, find.byType(AppChip)), 0.96);
      await g.up();
    });

    testWidgets('request filter chip hover border', (t) async {
      await t.pumpWidget(
        _app(AppFilterChip(label: 'Pending', selected: false, onTap: () {})),
      );
      await _mouse(t, find.byType(AppFilterChip));
      await _settle(t);
      expect(
        _borderColor(_borderDeco(t, find.byType(AppFilterChip))),
        AppColors.borderStrong,
      );
    });

    testWidgets('range control selected pill animates', (t) async {
      Widget w(int i) => RangeControl(
        labels: const ['A', 'B'],
        selectedIndex: i,
        onChanged: (_) {},
      );
      await t.pumpWidget(_app(w(0)));
      await t.pumpWidget(_app(w(1)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      final b = _live(
        t,
        find
            .descendant(
              of: find.byType(RangeControl),
              matching: find.byType(AnimatedContainer),
            )
            .last,
      ).color!;
      expect(b, isNot(AppColors.surface));
      expect(b, isNot(const Color(0x00FFFFFF)));
    });
  });

  group('text field', () {
    testWidgets('focus ring animates in', (t) async {
      await t.pumpWidget(
        _app(const SizedBox(width: 300, child: AppTextField())),
      );
      await t.tap(find.byType(TextField));
      await t.pump();
      await t.pump(const Duration(milliseconds: 80));
      expect(
        _live(t, find.byType(AnimatedContainer).first).boxShadow!.first.color,
        isNot(AppColors.focusRing),
      );
      await _settle(t);
      final d = _firstDeco(t);
      expect(d.boxShadow!.first.color, AppColors.focusRing);
      expect(d.boxShadow!.first.spreadRadius, 3);
      expect(_borderColor(d), AppColors.moss600);
    });

    testWidgets('error ring and valid check pop', (t) async {
      await t.pumpWidget(
        _app(const SizedBox(width: 300, child: AppTextField(hasError: true))),
      );
      await _settle(t);
      final d = _firstDeco(t);
      expect(_borderColor(d), AppColors.error);
      expect(d.boxShadow!.first.color, AppColors.errorRing);

      await t.pumpWidget(
        _app(const SizedBox(width: 300, child: AppTextField(valid: true))),
      );
      await t.pump();
      expect(find.byKey(const ValueKey('ok-check')), findsOneWidget);
      expect(find.byType(Pop), findsOneWidget);
    });

    testWidgets('eye toggle hovers and presses', (t) async {
      await t.pumpWidget(
        _app(const SizedBox(width: 300, child: AppTextField(password: true))),
      );
      final eye = find.byType(Pressable);
      await _mouse(t, eye);
      await _settle(t);
      expect(_hoverFill(t, eye), const Color(0x0F1F3F27));
      final g = await t.startGesture(t.getCenter(eye));
      await t.pump(const Duration(milliseconds: 200));
      expect(_pressScale(t, eye), 0.92);
      await g.up();
    });
  });

  testWidgets('info button hover, tip animates, one open at a time', (t) async {
    await t.pumpWidget(
      _app(
        const SingleChildScrollView(
          child: Column(
            children: [
              AppField(
                label: 'One',
                info: 'first tip',
                child: SizedBox(height: 20),
              ),
              AppField(
                label: 'Two',
                info: 'second tip',
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
    final first = find.byType(InfoButton).first;
    await _mouse(t, first);
    await _settle(t);
    expect(_hoverFill(t, first), AppColors.moss50);

    await t.tap(first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 40));
    final op = t.widget<Opacity>(
      find.descendant(of: find.byType(InfoTip), matching: find.byType(Opacity)),
    );
    expect(op.opacity, lessThan(1));
    expect(op.opacity, greaterThan(0));
    await _settle(t);
    expect(find.text('first tip'), findsOneWidget);

    await t.tap(find.byType(InfoButton).last);
    await _settle(t);
    expect(find.text('first tip'), findsNothing);
    expect(find.text('second tip'), findsOneWidget);

    await t.tap(find.byType(InfoButton).last);
    await t.pump();
    expect(find.text('second tip'), findsNothing);
  });

  testWidgets('select field presses to .97', (t) async {
    await t.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          child: SelectField(placeholder: 'x', onTap: () {}),
        ),
      ),
    );
    final g = await t.startGesture(t.getCenter(find.byType(SelectField)));
    await t.pump(const Duration(milliseconds: 200));
    expect(_pressScale(t, find.byType(SelectField)), 0.97);
    await g.up();
  });

  testWidgets('switch track 200 ms and knob 220 ms', (t) async {
    Widget w(bool v) => AppSwitch(value: v, onChanged: (_) {});
    await t.pumpWidget(_app(w(false)));
    await t.pumpWidget(_app(w(true)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    final track = t.widget<AnimatedContainer>(find.byType(AnimatedContainer));
    expect(track.duration, const Duration(milliseconds: 200));
    expect(
      _live(t, find.byType(AnimatedContainer)).color,
      isNot(AppColors.moss600),
    );
    final knob = t.widget<AnimatedAlign>(find.byType(AnimatedAlign));
    expect(knob.duration, const Duration(milliseconds: 220));
    await _settle(t);
    expect(_firstDeco(t).color, AppColors.moss600);
  });

  group('header buttons', () {
    testWidgets('icon button on green hovers and presses .92', (t) async {
      await t.pumpWidget(_app(HeaderBackButton(onTap: () {})));
      final f = find.byType(AppIconButton);
      await _mouse(t, f);
      await _settle(t);
      expect(_hoverFill(t, f), const Color(0x1FFFFFFF));
      final g = await t.startGesture(t.getCenter(f));
      await t.pump(const Duration(milliseconds: 200));
      expect(_pressScale(t, f), 0.92);
      await g.up();
    });

    testWidgets('icon button on light hovers', (t) async {
      await t.pumpWidget(
        _app(
          AppIconButton(icon: AppIcons.check, onTap: () {}, semanticLabel: 'x'),
        ),
      );
      await _mouse(t, find.byType(AppIconButton));
      await _settle(t);
      expect(
        _hoverFill(t, find.byType(AppIconButton)),
        const Color(0x0F1F3F27),
      );
    });

    testWidgets('glass button hover adds fill', (t) async {
      await t.pumpWidget(_app(GlassIconButton.share(onTap: () {})));
      expect(_hoverFill(t, find.byType(GlassIconButton)), isNull);
      await _mouse(t, find.byType(GlassIconButton));
      await _settle(t);
      expect(
        _hoverFill(t, find.byType(GlassIconButton)),
        const Color(0x17FFFFFF),
      );
    });

    testWidgets('bookmark on pops', (t) async {
      await t.pumpWidget(
        _app(HeaderBookmarkButton(bookmarked: false, onTap: () {})),
      );
      expect(find.byType(Pop), findsNothing);
      await t.pumpWidget(
        _app(HeaderBookmarkButton(bookmarked: true, onTap: () {})),
      );
      expect(find.byType(Pop), findsOneWidget);
    });
  });

  testWidgets('Add team member hover fill and press', (t) async {
    await t.pumpWidget(_app(AddMemberButton(onTap: () {})));
    await _mouse(t, find.byType(AddMemberButton));
    await _settle(t);
    expect(_hoverFill(t, find.byType(AddMemberButton)), AppColors.moss50);
    final g = await t.startGesture(t.getCenter(find.byType(AddMemberButton)));
    await t.pump(const Duration(milliseconds: 200));
    expect(_pressScale(t, find.byType(AddMemberButton)), 0.97);
    await g.up();
  });

  testWidgets('verify dialog fades in, mail pops, scrim closes', (t) async {
    await t.binding.setSurfaceSize(const Size(412, 892));
    late BuildContext ctx;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            ctx = c;
            return const Scaffold(body: SizedBox());
          },
        ),
      ),
    );
    showAppDialog<void>(
      ctx,
      builder: (c) => VerifyEmailDialog(
        email: 'a@b.sa',
        onResend: () {},
        onClose: () => Navigator.of(c).pop(),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));
    final fades = t.widgetList<FadeTransition>(find.byType(FadeTransition));
    expect(fades.any((f) => f.opacity.value > 0 && f.opacity.value < 1), true);
    expect(find.byType(Pop), findsOneWidget);
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Verify your email'), findsOneWidget);
    await t.tapAt(const Offset(5, 5));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Verify your email'), findsNothing);
  });
}
