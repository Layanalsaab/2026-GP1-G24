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

  // Startup management tokens, derived from the palette above.
  static const moss400 = Color(0xFF5E8A68);
  static const moss50 = Color(0xFFF2F7F3);
  static const gold100 = Color(0xFFF7EDD5);
  static const gold700 = Color(0xFF8A6A1F);
  static const errorFill = Color(0xFFFBEAE9);
  static const onDark = Colors.white;
  static const onDarkMuted = Color(0xCCFFFFFF);
  static const shadow = Color(0x1A1F3F27);
  static const scrim = Color(0x661C1F1D);
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

  // Named styles, so widgets never pick font sizes themselves. Colours can be
  // changed per use with `.copyWith(color: ...)`.

  /// Large serif title on a hero header (startup profile name).
  static TextStyle get display =>
      serif(size: 28, color: AppColors.onDark, height: 34);

  /// Page title in a top bar.
  static TextStyle get pageTitle =>
      serif(size: 22, color: AppColors.onDark, height: 28);

  /// Title in the flat green top bar (Figma: serif, left-aligned).
  static TextStyle get topBarTitle =>
      serif(size: 18, color: AppColors.onDark, height: 24);

  /// Startup name on a list card, tile labels (Figma: Inter semibold).
  static TextStyle get itemTitle =>
      sans(size: 14, color: AppColors.ink, weight: FontWeight.w600, height: 20);

  /// Initials inside a logo placeholder; scaled to the square size.
  static TextStyle initials(double boxSize) => sans(
        size: boxSize * 0.32,
        color: AppColors.green,
        weight: FontWeight.w700,
      );

  /// Small grey heading above a group of fields.
  static TextStyle get groupLabel => sans(
        size: 12,
        color: AppColors.grey,
        weight: FontWeight.w600,
        height: 16,
        letterSpacing: 0.6,
      );

  /// Section heading inside a page (serif).
  static TextStyle get sectionTitle =>
      serif(size: 18, color: AppColors.ink, height: 24);

  /// Startup name on a card.
  static TextStyle get cardTitle =>
      serif(size: 17, color: AppColors.ink, height: 22);

  static TextStyle get body => sans(size: 15, color: AppColors.ink, height: 22);

  static TextStyle get bodyMuted =>
      sans(size: 14, color: AppColors.grey, height: 20);

  /// Text typed into an input.
  static TextStyle get input => sans(size: 16, color: AppColors.ink, height: 24);

  /// Field label above an input.
  static TextStyle get label =>
      sans(size: 14, color: AppColors.ink, weight: FontWeight.w500, height: 20);

  static TextStyle get caption =>
      sans(size: 12, color: AppColors.grey, height: 16);

  /// Small uppercase-ish tag text (badges, meta).
  static TextStyle get badge => sans(
        size: 12,
        color: AppColors.ink,
        weight: FontWeight.w600,
        height: 16,
        letterSpacing: 0.2,
      );

  static TextStyle get button => sans(
        size: 16,
        color: AppColors.onDark,
        weight: FontWeight.w600,
        height: 20,
      );

  static TextStyle get link => sans(
        size: 14,
        color: AppColors.moss600,
        weight: FontWeight.w600,
        height: 20,
      );

  /// Big number (funding amount).
  static TextStyle get figure =>
      serif(size: 24, color: AppColors.ink, height: 30);

}

/// Spacing scale (logical pixels).
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  /// Horizontal page padding used by every screen.
  static const double page = 24;
}

/// Corner radii. Shapes are soft and rounded throughout.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

/// Sizes that are part of the design (icons, avatars, controls).
class AppSizes {
  AppSizes._();

  static const double iconSm = 16;
  static const double icon = 22;
  static const double iconLg = 28;
  static const double touchTarget = 48;
  static const double buttonHeight = 48;
  static const double cardLogo = 56;
  static const double formLogo = 64;
  static const double profileLogo = 88;
  static const double emptyStateIcon = 88;
  static const double topBarHeight = 56;
  static const double listLogo = 40;
  static const double tileIconBox = 40;
  static const double fieldHeight = 44;
}

class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(color: AppColors.shadow, offset: Offset(0, 4), blurRadius: 14),
  ];

  static const raised = [
    BoxShadow(color: AppColors.shadow, offset: Offset(0, 8), blurRadius: 24),
  ];
}
