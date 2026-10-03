import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A [Positioned] SVG from `assets/images/`, sized in Figma coordinates.
Widget positionedSvg(
  String name, {
  required double left,
  required double top,
  required double width,
  required double height,
}) =>
    Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: SvgPicture.asset('assets/images/$name', fit: BoxFit.fill),
    );
