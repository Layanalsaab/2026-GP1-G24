import 'package:flutter/material.dart';

import '../../../navigation/app_router.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../../../shared_ui/common_widgets/design_canvas.dart';
import '../../../shared_ui/common_widgets/onboarding_parts.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import 'intro_two_screen.dart';

/// Figma: "V2 · 00a · Intro 1 — Connect"
class IntroOneScreen extends StatelessWidget {
  const IntroOneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      background: AppColors.green,
      children: [
        positionedSvg('intro1_house_left.svg', left: -40, top: 560, width: 150, height: 170),
        positionedSvg('intro1_house_mid.svg', left: 100, top: 560, width: 150, height: 170),
        positionedSvg('intro1_house_right.svg', left: 240, top: 560, width: 150, height: 170),
        positionedSvg('intro1_network.svg', left: 40, top: 120, width: 280, height: 260),
        Positioned(
          left: 157,
          top: 18,
          width: 46,
          height: 44,
          child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
        ),
        onboardingText(
          eyebrow: null,
          eyebrowColor: AppColors.gold,
          title: 'Where Saudi startups\nmeet opportunity.',
          titleColor: Colors.white,
          titleTop: 430,
          body: 'One hub for founders, investors,\nand startup seekers.',
          bodyColor: Colors.white.withValues(alpha: 0.65),
          bodyTop: 520,
        ),
        onboardingDots(
          index: 0,
          activeColor: AppColors.gold,
          inactiveColor: Colors.white.withValues(alpha: 0.3),
        ),
        onboardingSkip(
          color: Colors.white.withValues(alpha: 0.6),
          onTap: () => AppRouter.finishIntro(context),
        ),
        onboardingNext(
          circleColor: AppColors.gold,
          arrowAsset: 'intro1_next_arrow.svg',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const IntroTwoScreen()),
          ),
        ),
      ],
    );
  }
}
