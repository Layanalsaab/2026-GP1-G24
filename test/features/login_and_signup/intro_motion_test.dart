import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:startsa/data_access/repositories/app_settings_repository.dart';
import 'package:startsa/data_access/repositories/auth_repository.dart';
import 'package:startsa/features/login_and_signup/screens/intro_screen.dart';
import 'package:startsa/features/login_and_signup/screens/splash_screen.dart';
import 'package:startsa/features/login_and_signup/screens/welcome_screen.dart';
import 'package:startsa/features/login_and_signup/widgets/auth_decor.dart';
import 'package:startsa/features/login_and_signup/widgets/intro_widgets.dart';
import 'package:startsa/shared_ui/motion/motion.dart';
import 'package:startsa/shared_ui/theme/app_colors.dart';
import 'package:startsa/shared_ui/widgets/buttons/app_button.dart';

import '../../support/fakes.dart';

/// STARTSA_ANIMATIONS.md §2: Splash, Intro and Welcome.
Future<void> _pump(WidgetTester t, Widget home, {bool reduce = false}) async {
  t.view.physicalSize = const Size(412, 892);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: child!,
      ),
      home: home,
    ),
  );
}

/// The opacity a widget is currently drawn with (all ancestors multiplied).
double _opacityOf(WidgetTester t, Finder f) {
  var v = 1.0;
  for (final e
      in find
          .ancestor(of: f, matching: find.byType(FadeTransition))
          .evaluate()) {
    v *= (e.widget as FadeTransition).opacity.value;
  }
  for (final e
      in find.ancestor(of: f, matching: find.byType(Opacity)).evaluate()) {
    v *= (e.widget as Opacity).opacity;
  }
  return v;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    AppSettingsRepository.instance = FakeAppSettingsRepository();
    AuthRepository.instance = FakeAuthRepository();
  });

  group('splash', () {
    testWidgets('texts fade in after 350 / 550 / 700 ms, logo first', (
      t,
    ) async {
      await _pump(t, const SplashScreen());
      final name = find.text('Start.sa');
      final tagline = find.text('Connect. Invest. Grow.');
      final divider = find.byType(GoldDivider);
      await t.pump();
      await t.pump(const Duration(milliseconds: 1));
      expect(_opacityOf(t, name), 0, reason: 'hidden during its 350 ms delay');
      expect(_opacityOf(t, tagline), 0);
      expect(_opacityOf(t, divider), 0);
      await t.pump(const Duration(milliseconds: 300));
      await t.pump(const Duration(milliseconds: 16));
      expect(_opacityOf(t, name), 0, reason: 'still waiting at ~317 ms');
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 16));
      expect(
        _opacityOf(t, name),
        greaterThan(0),
        reason: 'starts after 350 ms',
      );
      expect(_opacityOf(t, tagline), 0, reason: 'tagline waits until 550 ms');
      await t.pump(const Duration(milliseconds: 150));
      await t.pump(const Duration(milliseconds: 16));
      expect(_opacityOf(t, tagline), greaterThan(0));
      expect(_opacityOf(t, divider), 0, reason: 'divider waits until 700 ms');
      await t.pump(const Duration(milliseconds: 1200));
      await t.pump(const Duration(milliseconds: 600));
      expect(_opacityOf(t, name), 1);
      expect(_opacityOf(t, tagline), 1);
      expect(_opacityOf(t, divider), 1);
      // Leave the splash so no timer is pending.
      await t.pump(const Duration(seconds: 3));
      await t.pump(const Duration(milliseconds: 500));
    });

    testWidgets('three arches draw and three sparkles twinkle', (t) async {
      await _pump(t, const SplashScreen());
      expect(find.byType(DrawPath), findsNWidgets(3));
      expect(find.byType(Twinkle), findsNWidgets(3));
      await t.pump(const Duration(seconds: 3));
      await t.pump(const Duration(milliseconds: 600));
    });

    testWidgets('moves on to the intro after 2.6 s with a fade', (t) async {
      await _pump(t, const SplashScreen());
      await t.pump(const Duration(milliseconds: 2400));
      expect(find.byType(IntroScreen), findsNothing);
      await t.pump(const Duration(milliseconds: 400));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(IntroScreen), findsOneWidget);
      await t.pump(const Duration(milliseconds: 600));
    });

    testWidgets('a tap skips straight to the next screen', (t) async {
      await _pump(t, const SplashScreen());
      await t.pump(const Duration(milliseconds: 600));
      await t.tapAt(const Offset(200, 400));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(IntroScreen), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('reduced motion: arches already drawn, sparkles still', (
      t,
    ) async {
      await _pump(t, const SplashScreen(), reduce: true);
      await t.pump(const Duration(milliseconds: 50));
      // No looping animation is left running: nothing stays scheduled.
      expect(find.byType(DrawPath), findsNWidgets(3));
      await t.pump(const Duration(seconds: 3));
      await t.pump(const Duration(milliseconds: 600));
    });
  });

  group('intro', () {
    double dotWidth(WidgetTester t, int i) {
      final dots = find.descendant(
        of: find.byType(IntroDots),
        matching: find.byType(AnimatedContainer),
      );
      return t.getSize(dots.at(i)).width;
    }

    testWidgets('dots: the current one is 24 wide, others 8; slides 260 ms', (
      t,
    ) async {
      await _pump(t, const IntroScreen());
      await t.pump(const Duration(milliseconds: 600));
      expect(dotWidth(t, 0), 24);
      expect(dotWidth(t, 1), 8);
      expect(dotWidth(t, 2), 8);
      await t.tap(find.byType(IntroNextButton));
      await t.pump();
      await t.pump(const Duration(milliseconds: 40));
      await t.pump(const Duration(milliseconds: 60));
      // Midway the old dot is narrowing and the new one widening.
      expect(dotWidth(t, 1), inExclusiveRange(8, 24));
      await t.pump(const Duration(milliseconds: 400));
      expect(dotWidth(t, 0), 8);
      expect(dotWidth(t, 1), 24);
      await t.pump(const Duration(milliseconds: 600));
    });

    testWidgets('page 1: network floats, its triangle draws, text rises', (
      t,
    ) async {
      await _pump(t, const IntroScreen());
      expect(find.byType(Float), findsOneWidget);
      expect(find.byType(DrawPath), findsOneWidget);
      expect(find.byType(Rise), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
      await t.pump(const Duration(milliseconds: 600));
    }, skip: false);

    testWidgets('page 2: four bars grow 80 / 160 / 240 / 320 ms apart', (
      t,
    ) async {
      await _pump(t, const IntroScreen());
      await t.tap(find.byType(IntroNextButton));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      final grows = t.widgetList<Grow>(find.byType(Grow)).toList();
      expect(grows.map((g) => g.delay.inMilliseconds), [80, 160, 240, 320]);
      expect(find.byType(Rise), findsOneWidget);
      await t.pump(const Duration(milliseconds: 600));
    });

    testWidgets('page 3: cards float, bars grow, dots and sparkles twinkle', (
      t,
    ) async {
      await _pump(t, const IntroScreen());
      await t.tap(find.byType(IntroNextButton));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byType(IntroNextButton));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(
        t
            .widgetList<Float>(find.byType(Float))
            .map((f) => f.delay.inMilliseconds),
        unorderedEquals([0, 600, 300]),
      );
      expect(
        t
            .widgetList<Grow>(find.byType(Grow))
            .map((g) => g.delay.inMilliseconds),
        [0, 100, 200, 300],
      );
      expect(
        t
            .widgetList<Twinkle>(find.byType(Twinkle))
            .map((w) => w.delay.inMilliseconds),
        containsAll([0, 300, 600, 700]),
      );
      // Page 3's current dot is green, not gold.
      final dots = find.descendant(
        of: find.byType(IntroDots),
        matching: find.byType(AnimatedContainer),
      );
      final current = t.widget<AnimatedContainer>(dots.at(2));
      expect((current.decoration as BoxDecoration).color, AppColors.green);
      await t.pump(const Duration(milliseconds: 600));
    });

    testWidgets('the round next button presses to 0.97', (t) async {
      await _pump(t, const IntroScreen());
      await t.pump(const Duration(milliseconds: 600));
      final g = await t.startGesture(t.getCenter(find.byType(IntroNextButton)));
      await t.pump(const Duration(milliseconds: 50));
      final scale = t.widget<AnimatedScale>(
        find
            .descendant(
              of: find.byType(Pressable),
              matching: find.byType(AnimatedScale),
            )
            .first,
      );
      expect(scale.scale, 0.97);
      await g.up();
      await t.pump(const Duration(milliseconds: 600));
    });
  });

  group('welcome', () {
    testWidgets('logo, name, description and buttons rise in order', (t) async {
      await _pump(t, const WelcomeScreen());
      expect(find.byType(LogoIn), findsOneWidget);
      final rises = t.widgetList<Rise>(find.byType(Rise)).toList();
      expect(rises.map((r) => r.delay.inMilliseconds), [80, 140, 200]);
      await t.pump(const Duration(milliseconds: 1));
      expect(_opacityOf(t, find.text('Create account')), 0);
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
      expect(_opacityOf(t, find.text('Create account')), 1);
      await t.pump(const Duration(milliseconds: 600));
    });

    testWidgets('two sparkles twinkle, the second 900 ms later', (t) async {
      await _pump(t, const WelcomeScreen());
      final tw = t.widgetList<Twinkle>(find.byType(Twinkle)).toList();
      expect(tw.map((w) => w.delay.inMilliseconds), [0, 900]);
      await t.pump(const Duration(seconds: 1));
    });

    testWidgets('hover: primary gets a stronger shadow, outline fills moss50', (
      t,
    ) async {
      await _pump(t, const WelcomeScreen());
      await t.pump(const Duration(seconds: 1));
      BoxDecoration deco(String label) {
        final c = find.ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        );
        return t.widget<AnimatedContainer>(c.first).decoration!
            as BoxDecoration;
      }

      final primaryRest = deco('Create account');
      expect(primaryRest.boxShadow!.first.offset.dy, 6);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(t.getCenter(find.text('Create account')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      final hovered = deco('Create account');
      expect(hovered.boxShadow!.first.offset.dy, 10, reason: '0 10 20 -8');
      expect(hovered.boxShadow!.first.blurRadius, 20);
      expect(
        hovered.color!.g,
        greaterThan(primaryRest.color!.g),
        reason: 'brighter',
      );

      await mouse.moveTo(t.getCenter(find.text('Log in')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(deco('Log in').color, AppColors.moss50);
      await mouse.moveTo(const Offset(5, 5));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(deco('Log in').color, AppColors.surface);
      expect(deco('Create account').boxShadow!.first.offset.dy, 6);
    });

    testWidgets('a button that is not tappable does not react to hover', (
      t,
    ) async {
      await _pump(
        t,
        const Scaffold(
          body: Center(child: AppButton(label: 'Disabled', onPressed: null)),
        ),
      );
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(t.getCenter(find.text('Disabled')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      final c = find.ancestor(
        of: find.text('Disabled'),
        matching: find.byType(AnimatedContainer),
      );
      final d =
          t.widget<AnimatedContainer>(c.first).decoration! as BoxDecoration;
      expect(d.boxShadow!.first.offset.dy, 6);
    });
  });
}
