import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../shared_ui/theme/app_theme.dart';
import '../../../shared_ui/common_widgets/design_canvas.dart';
import '../../../shared_ui/common_widgets/onboarding_parts.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';

/// Figma: "V2 · 00c · Intro 3 — Grow"
class IntroThreeScreen extends StatelessWidget {
  const IntroThreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: navigate to the Welcome screen once it exists.
    void getStarted() {}

    return DesignCanvas(
      background: AppColors.cream,
      children: [
        // Illustration frame: 320 x 290 at (20, 100).
        Positioned(
          left: 20,
          top: 100,
          width: 320,
          height: 290,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              positionedSvg('intro3_ellipse.svg', left: 35, top: 10, width: 250, height: 250),
              _programsCard(),
              _insightsCard(),
              // AI bubble: the artwork includes its shadow, hence the bleed.
              positionedSvg('intro3_ai_bubble.svg', left: 62 - 24, top: 184 - 14, width: 254, height: 144),
              positionedSvg('intro3_star_large.svg', left: 22 - 1.58, top: 20 - 1.58, width: 23.16, height: 23.16),
              positionedSvg('intro3_star_mid.svg', left: 292 - 1.58, top: 6 - 1.58, width: 16.16, height: 16.16),
              positionedSvg('intro3_star_small.svg', left: 14 - 1.58, top: 240 - 1.58, width: 14.16, height: 14.16),
            ],
          ),
        ),
        onboardingText(
          eyebrow: 'GROW FURTHER',
          eyebrowColor: AppColors.green,
          title: 'Programs, insights,\nand AI guidance.',
          titleColor: AppColors.green,
          titleTop: 450,
          body: 'Accelerators and incubators directory,\nfundraising tools, and Ask Gemini for founders.',
          bodyColor: AppColors.green.withValues(alpha: 0.75),
          bodyTop: 540,
        ),
        onboardingDots(
          index: 2,
          activeColor: AppColors.green,
          inactiveColor: AppColors.green.withValues(alpha: 0.25),
        ),
        Positioned(
          left: 28,
          top: 716,
          width: 304,
          height: 52,
          child: Material(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: getStarted,
              child: Center(
                child: Text(
                  'Get started',
                  style: AppText.sans(
                    size: 15,
                    color: Colors.white,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// "Programs card": 142 x 124 card tilted -8 degrees.
  Widget _programsCard() => Positioned(
        left: 84.94 - 71,
        top: 109.52 - 62,
        width: 142,
        height: 124,
        child: Transform.rotate(
          angle: -8 * math.pi / 180,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x40332605),
                  offset: Offset(0, 10),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Stack(
              children: [
                positionedSvg('intro3_programs_icon.svg', left: 16, top: 16, width: 34, height: 34),
                _bar(left: 16, top: 62, width: 78, height: 8, color: const Color(0xFFD9D6CF)),
                _bar(left: 16, top: 76, width: 52, height: 7, color: const Color(0xFFEDEAE3)),
                _bar(left: 16, top: 94, width: 60, height: 20, color: const Color(0xFFE6EFE7), radius: 999),
                _bar(left: 31, top: 101, width: 30, height: 6, color: const Color(0xFF5E8A64)),
              ],
            ),
          ),
        ),
      );

  /// "Insights card": 138 x 130 artwork tilted 7 degrees.
  Widget _insightsCard() => Positioned(
        left: 236.57 - 69,
        top: 112.92 - 65,
        width: 138,
        height: 130,
        child: Transform.rotate(
          angle: 7 * math.pi / 180,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The artwork includes its shadow, hence the bleed around the card.
              positionedSvg('intro3_insights_card.svg', left: -24, top: -14, width: 186, height: 178),
            ],
          ),
        ),
      );

  Widget _bar({
    required double left,
    required double top,
    required double width,
    required double height,
    required Color color,
    double radius = 4,
  }) =>
      Positioned(
        left: left,
        top: top,
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
}
