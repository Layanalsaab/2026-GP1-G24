import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// The app's two ThemeDatas, light and dark, built from the same tokens (AppColors).
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(dark: false);
  static ThemeData get dark => _build(dark: true);

  static ThemeData _build({required bool dark}) {
    final before = AppColors.isDark;
    AppColors.setDark(dark);
    try {
      final scheme =
          ColorScheme.fromSeed(
            seedColor: AppColors.green,
            brightness: dark ? Brightness.dark : Brightness.light,
          ).copyWith(
            primary: dark ? AppColors.mossText : AppColors.moss600,
            onPrimary: dark ? AppColors.cream : AppColors.white,
            secondary: AppColors.gold,
            onSecondary: AppColors.green,
            surface: AppColors.surface,
            onSurface: AppColors.ink,
            error: AppColors.error,
            outline: AppColors.border,
          );
      return ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
        colorScheme: scheme,
        scaffoldBackgroundColor: AppColors.cream,
        canvasColor: AppColors.cream,
        textTheme: GoogleFonts.interTextTheme(
          dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        ).apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        dividerColor: AppColors.border,
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: dark ? AppColors.mossText : AppColors.moss600,
          selectionColor: dark
              ? const Color(0x4086BB92)
              : const Color(0x332F5D3A),
          selectionHandleColor: dark ? AppColors.mossText : AppColors.moss600,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(),
      );
    } finally {
      AppColors.setDark(before);
    }
  }
}
