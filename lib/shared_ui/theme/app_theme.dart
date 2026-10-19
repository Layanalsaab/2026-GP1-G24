import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The app's [ThemeData]. The design is light only: the Settings screen keeps
/// a Dark mode switch (wired to ThemeController) but no dark palette is
/// designed, so [dark] deliberately matches [light] (docs/02 §1, docs/09).
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build();
  static ThemeData get dark => _build();

  static ThemeData _build() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.moss600,
          onPrimary: AppColors.white,
          secondary: AppColors.gold,
          onSecondary: AppColors.green,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          error: AppColors.error,
          outline: AppColors.border,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      canvasColor: AppColors.cream,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      // Press feedback is the prototype's scale effect, not a ripple.
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      dividerColor: AppColors.border,
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.moss600,
        selectionColor: Color(0x332F5D3A),
        selectionHandleColor: AppColors.moss600,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(),
    );
  }
}
