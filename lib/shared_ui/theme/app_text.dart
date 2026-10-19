import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography (docs/02_design_system.md §2).
///
/// Inter everywhere (400/500/600/700). The only serif is the "Start.sa"
/// wordmark on Splash and Welcome ([wordmark]). Headings the CSS calls
/// `.serif` are Inter 700 with letter-spacing -0.4, never a serif.
class AppText {
  AppText._();

  /// Inter. [height] is the line height in logical pixels (CSS `line-height`),
  /// converted to Flutter's multiplier.
  static TextStyle sans({
    required double size,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
    double? height,
    double? letterSpacing,
    bool tabular = false,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height == null ? null : height / size,
    letterSpacing: letterSpacing,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );

  /// Source Serif 4 700: the "Start.sa" wordmark only.
  static TextStyle wordmark({
    required double size,
    required double height,
    Color color = AppColors.green,
  }) => GoogleFonts.sourceSerif4(
    fontSize: size,
    fontWeight: FontWeight.w700,
    color: color,
    height: height / size,
  );

  /// Splash wordmark (44/48).
  static TextStyle get wordmarkSplash => wordmark(size: 44, height: 48);

  /// Welcome wordmark (40/44).
  static TextStyle get wordmarkWelcome => wordmark(size: 40, height: 44);

  // ---- Headings on green headers (white) ----

  /// Auth header title: log in, forgot password, my startups, calculator.
  static TextStyle get authTitle => sans(
    size: 32,
    color: AppColors.onDark,
    weight: FontWeight.w700,
    height: 38,
    letterSpacing: -0.2,
  );

  /// Step header title: sign-up and add-startup steps.
  static TextStyle get stepTitle => sans(
    size: 28,
    color: AppColors.onDark,
    weight: FontWeight.w700,
    height: 34,
    letterSpacing: -0.2,
  );

  /// Choose-role title.
  static TextStyle get roleTitle => sans(
    size: 34,
    color: AppColors.onDark,
    weight: FontWeight.w700,
    height: 40,
    letterSpacing: -0.2,
  );

  /// Home page title (Hub / Explore / Support Channels).
  static TextStyle get homeTitle => sans(
    size: 21,
    color: AppColors.onDark,
    weight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  /// Startup profile / manage header name.
  static TextStyle get profileHeaderName => sans(
    size: 26,
    color: AppColors.onDark,
    weight: FontWeight.w700,
    height: 32,
    letterSpacing: -0.2,
  );

  /// Pitch / sub text under the header name.
  static TextStyle get headerPitch =>
      sans(size: 14, color: AppColors.onGreenPitch, height: 20);

  /// Small muted line on green (sub-line, meta).
  static TextStyle get onGreenMeta =>
      sans(size: 13, color: AppColors.onGreenMuted);

  /// "STEP 3 OF 6".
  static TextStyle get stepLabel => sans(
    size: 11,
    color: AppColors.goldLight,
    weight: FontWeight.w700,
    letterSpacing: 1.32, // 0.12em
  );

  // ---- Page-level text on cream ----

  /// Own / investor profile name.
  static TextStyle get profileName =>
      sans(size: 24, weight: FontWeight.w700, height: 30, letterSpacing: -0.3);

  /// Intro headline.
  static TextStyle get introHeadline =>
      sans(size: 31, weight: FontWeight.w700, height: 38, letterSpacing: -0.3);

  /// Section title on home ("New on Start.sa", "Top 30 trending").
  static TextStyle get sectionTitle =>
      sans(size: 16, weight: FontWeight.w700, letterSpacing: -0.1);

  /// Card name on home cards and trending rows.
  static TextStyle get cardName =>
      sans(size: 18, weight: FontWeight.w700, height: 23);

  static TextStyle get trendingName =>
      sans(size: 18, weight: FontWeight.w700, height: 24);

  /// Card body line.
  static TextStyle get cardBody =>
      sans(size: 15.5, color: AppColors.bodyLine, height: 23);

  /// Paragraph inside profile cards.
  static TextStyle get paragraph =>
      sans(size: 14.5, color: AppColors.paragraph, height: 22);

  // ---- Forms ----

  /// Field label above an input.
  static TextStyle get label =>
      sans(size: 14, weight: FontWeight.w500, height: 20);

  /// Text typed into an input.
  static TextStyle get input => sans(size: 16, height: 24);

  static TextStyle get placeholder =>
      sans(size: 16, color: AppColors.placeholder, height: 24);

  /// Helper / counter under a field.
  static TextStyle get helper =>
      sans(size: 12, color: AppColors.grey, height: 16);

  static TextStyle get error =>
      sans(size: 12, color: AppColors.error, height: 16);

  /// Form chip.
  static TextStyle get chip => sans(size: 13, weight: FontWeight.w500);

  // ---- Buttons and small UI ----

  static TextStyle get button =>
      sans(size: 16, color: AppColors.onDark, weight: FontWeight.w600);

  static TextStyle get buttonSmall =>
      sans(size: 14, color: AppColors.onDark, weight: FontWeight.w600);

  static TextStyle get toast =>
      sans(size: 14, color: AppColors.onDark, height: 20);

  static TextStyle get link => sans(
    size: 14,
    color: AppColors.moss600,
    weight: FontWeight.w600,
    height: 20,
  );

  static TextStyle get caption => sans(size: 12, color: AppColors.grey);

  /// Pill text (13/500).
  static TextStyle get pill => sans(size: 13, weight: FontWeight.w500);

  /// Card tag chip (12/600 moss).
  static TextStyle get tag =>
      sans(size: 12, color: AppColors.moss600, weight: FontWeight.w600);
}
