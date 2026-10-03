import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'svg_asset.dart';

/// The three page dots. The active one is a 22px pill. Position matches Figma.
Widget onboardingDots({
  required int index,
  required Color activeColor,
  required Color inactiveColor,
}) {
  Widget dot(int i) => Container(
        width: i == index ? 22 : 7,
        height: 7,
        decoration: BoxDecoration(
          color: i == index ? activeColor : inactiveColor,
          borderRadius: BorderRadius.circular(4),
        ),
      );
  return Positioned(
    left: 141,
    top: 690,
    child: Row(
      children: [dot(0), const SizedBox(width: 8), dot(1), const SizedBox(width: 8), dot(2)],
    ),
  );
}

/// "Skip" text button at the bottom left.
Widget onboardingSkip({required Color color, required VoidCallback onTap}) =>
    Positioned(
      left: 16,
      top: 724,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Text(
            'Skip',
            style: AppText.sans(
              size: 14,
              color: color,
              weight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );

/// Round next button at the bottom right with an arrow icon.
Widget onboardingNext({
  required Color circleColor,
  required String arrowAsset,
  required VoidCallback onTap,
}) =>
    Positioned(
      left: 284,
      top: 724,
      width: 48,
      height: 48,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
            ),
            positionedSvg(arrowAsset, left: 14, top: 14, width: 20, height: 20),
          ],
        ),
      ),
    );

/// Gold label + two-line serif headline + two-line body used by the intros.
Widget onboardingText({
  required String? eyebrow,
  required Color eyebrowColor,
  required String title,
  required Color titleColor,
  required String body,
  required Color bodyColor,
  required double titleTop,
  required double bodyTop,
}) =>
    Positioned.fill(
      child: Stack(
      clipBehavior: Clip.none,
      children: [
        if (eyebrow != null)
          Positioned(
            left: 28,
            top: 430,
            child: Text(
              eyebrow,
              style: AppText.sans(
                size: 10,
                color: eyebrowColor,
                weight: FontWeight.w500,
                letterSpacing: 3,
              ),
            ),
          ),
        Positioned(
          left: 28,
          top: titleTop,
          child: Text(title, style: AppText.serif(size: 30, color: titleColor, height: 38)),
        ),
        Positioned(
          left: 28,
          top: bodyTop,
          child: Text(body, style: AppText.sans(size: 14, color: bodyColor, height: 22)),
        ),
      ],
    ));
