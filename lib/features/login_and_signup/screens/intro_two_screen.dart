import 'package:flutter/material.dart';

import '../../../shared_ui/theme/app_theme.dart';
import '../../../shared_ui/common_widgets/design_canvas.dart';
import '../../../shared_ui/common_widgets/onboarding_parts.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import 'intro_three_screen.dart';

/// Figma: "V2 · 00b · Intro 2 — Match"
class IntroTwoScreen extends StatelessWidget {
  const IntroTwoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void goNext() => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const IntroThreeScreen()),
        );

    return DesignCanvas(
      background: AppColors.cream,
      children: [
        positionedSvg('intro2_bars.svg', left: 50, top: 150, width: 260, height: 240),
        onboardingText(
          eyebrow: 'SMART MATCHING',
          eyebrowColor: AppColors.gold,
          title: 'Matched with the\nright partners.',
          titleColor: AppColors.ink,
          titleTop: 450,
          body: 'Discover startups and investors\nthat fit your interests.',
          bodyColor: AppColors.grey,
          bodyTop: 540,
        ),
        onboardingDots(
          index: 1,
          activeColor: AppColors.gold,
          inactiveColor: AppColors.ink.withValues(alpha: 0.2),
        ),
        onboardingSkip(color: AppColors.grey, onTap: goNext),
        onboardingNext(
          circleColor: AppColors.green,
          arrowAsset: 'intro2_next_arrow.svg',
          onTap: goNext,
        ),
      ],
    );
  }
}
