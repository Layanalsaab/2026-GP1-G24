import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gold "line, diamond, line" divider. [lineTop] is the Y of the two lines in
/// Figma coordinates; returns [Positioned] widgets for a [DesignCanvas].
List<Widget> goldDivider({required double lineTop}) {
  Widget line(double left) => Positioned(
        left: left,
        top: lineTop,
        width: 48,
        height: 1.5,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      );

  return [
    line(114.5),
    Positioned(
      left: 178,
      top: lineTop - 7,
      child: Transform.rotate(
        angle: -0.7853981633974483,
        child: Container(width: 7, height: 7, color: AppColors.gold),
      ),
    ),
    line(197.5),
  ];
}
