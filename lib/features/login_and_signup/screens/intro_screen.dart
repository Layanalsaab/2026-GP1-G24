import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../widgets/auth_decor.dart';
import '../widgets/intro_widgets.dart';

/// The three intro pages (docs/05 A2-A4) in one screen. "Skip" and the last
/// page's "Get started" call [AppRouter.finishIntro]; the round arrow moves to
/// the next page (forward transition: slide from x +28 with a fade, 260 ms).
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  int _page = 0;
  int _from = 0;

  void _next() {
    if (_page >= 2) {
      _finish();
    } else {
      setState(() {
        _from = _page;
        _page++;
      });
    }
  }

  void _finish() => AppRouter.finishIntro(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page == 0 ? AppColors.green : AppColors.cream,
      body: _PageEnter(
        key: ValueKey(_page),
        child: switch (_page) {
          0 => _PageOne(onNext: _next, onSkip: _finish, from: _from),
          1 => _PageTwo(onNext: _next, onSkip: _finish, from: _from),
          _ => _PageThree(onStart: _finish, from: _from),
        },
      ),
    );
  }
}

/// Forward page transition inside the intro.
class _PageEnter extends StatelessWidget {
  const _PageEnter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = Motion.reduced(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      // Reduced motion: a 200 ms fade without the slide.
      duration: reduced ? Motion.reducedFade : Motion.medium,
      curve: Motion.easeOut,
      child: child,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(reduced ? 0 : 28 * (1 - v), 0),
          child: child,
        ),
      ),
    );
  }
}

TextStyle _headline(Color color) =>
    AppText.introHeadline.copyWith(color: color);

TextStyle _bodyStyle(Color color) =>
    AppText.sans(size: 15, color: color, height: 22);

class _Kicker extends StatelessWidget {
  const _Kicker(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppText.sans(
      size: 12,
      weight: FontWeight.w600,
      color: color,
      letterSpacing: 3,
    ),
  );
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.color, required this.onTap});

  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AuthStrings.skip,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Text(
            AuthStrings.skip,
            style: AppText.sans(size: 15, color: color),
          ),
        ),
      ),
    );
  }
}

/// Dots, then the Skip + round button row (pages 1 and 2).
class _Bottom extends StatelessWidget {
  const _Bottom({
    required this.from,
    required this.index,
    required this.skipColor,
    required this.onSkip,
    required this.button,
  });

  final int from;
  final int index;
  final Color skipColor;
  final VoidCallback onSkip;
  final Widget button;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IntroDots(index: index, fromIndex: from),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SkipButton(color: skipColor, onTap: onSkip),
              button,
            ],
          ),
        ),
      ],
    );
  }
}

class _PageOne extends StatelessWidget {
  const _PageOne({
    required this.onNext,
    required this.onSkip,
    required this.from,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int from;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      fit: StackFit.expand,
      children: [
        const Positioned(left: 0, right: 0, bottom: 70, child: IntroHouses()),
        FlexPage(
          children: [
            SizedBox(height: 62 + top),
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: IntroNetwork()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
              child: Rise(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        AuthStrings.intro1Headline,
                        style: _headline(AppColors.onDark),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AuthStrings.intro1Body,
                      style: _bodyStyle(const Color(0xCCFFFFFF)),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            _Bottom(
              from: from,
              index: 0,
              skipColor: const Color(0xCCFFFFFF),
              onSkip: onSkip,
              button: IntroNextButton(
                onTap: onNext,
                background: AppColors.gold,
                foreground: AppColors.green,
                shadowColor: const Color(0x66000000),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PageTwo extends StatelessWidget {
  const _PageTwo({
    required this.onNext,
    required this.onSkip,
    required this.from,
  });

  final VoidCallback onNext;
  final VoidCallback onSkip;
  final int from;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return FlexPage(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 70 + top),
          child: const Center(child: IntroBars()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
          child: Rise(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Kicker(AuthStrings.intro2Kicker, AppColors.gold700),
                const SizedBox(height: 10),
                Semantics(
                  header: true,
                  child: Text(
                    AuthStrings.intro2Headline,
                    style: _headline(AppColors.green),
                  ),
                ),
                const SizedBox(height: 14),
                Text(AuthStrings.intro2Body, style: _bodyStyle(AppColors.grey)),
              ],
            ),
          ),
        ),
        const Spacer(),
        _Bottom(
          from: from,
          index: 1,
          skipColor: AppColors.grey,
          onSkip: onSkip,
          button: IntroNextButton(
            onTap: onNext,
            background: AppColors.green,
            foreground: AppColors.onDark,
            shadowColor: const Color(0x991F3F27),
          ),
        ),
      ],
    );
  }
}

class _PageThree extends StatelessWidget {
  const _PageThree({required this.onStart, required this.from});

  final VoidCallback onStart;
  final int from;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return FlexPage(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 50 + top),
          child: const IntroCards(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
          child: Rise(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Kicker(AuthStrings.intro3Kicker, AppColors.green),
                const SizedBox(height: 10),
                Semantics(
                  header: true,
                  child: Text(
                    AuthStrings.intro3Headline,
                    style: _headline(AppColors.green),
                  ),
                ),
                const SizedBox(height: 14),
                Text(AuthStrings.intro3Body, style: _bodyStyle(AppColors.grey)),
              ],
            ),
          ),
        ),
        const Spacer(),
        IntroDots(index: 2, dark: true, fromIndex: from),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
          child: AppButton(
            label: AuthStrings.getStarted,
            variant: AppButtonVariant.dark,
            onPressed: onStart,
          ),
        ),
      ],
    );
  }
}
