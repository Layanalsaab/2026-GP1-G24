import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens taken from the Start.sa Figma file.
class AppColors {
  AppColors._();

  static const cream = Color(0xFFFAF8F4);
  static const green = Color(0xFF1F3F27);
  static const gold = Color(0xFFC9A24A);
  static const ink = Color(0xFF1C1F1D);
  static const grey = Color(0xFF5B625D);

  // Form / UI tokens (Figma: moss/*, neutral/*).
  static const moss600 = Color(0xFF2F5D3A);
  static const moss100 = Color(0xFFE6EFE7);
  static const surface = Colors.white;
  static const border = Color(0xFFE4E1DA);
  static const borderStrong = Color(0xFF8C918D);
  static const mutedFill = Color(0xFFF1EFEA);
  static const error = Color(0xFFB3261E);
}

class AppText {
  AppText._();

  /// Headlines — Source Serif 4 Bold.
  static TextStyle serif({
    required double size,
    required Color color,
    double? height,
  }) =>
      GoogleFonts.sourceSerif4(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        height: height == null ? null : height / size,
      );

  /// Body / UI text — Inter.
  static TextStyle sans({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height == null ? null : height / size,
        letterSpacing: letterSpacing,
      );
}
