import 'package:flutter/material.dart';

import '../../data_access/repositories/app_settings_repository.dart';
import 'app_colors.dart';

/// The app-wide light / dark choice. The Settings "Dark mode" switch changes
/// it, [StartSaApp] listens to it (MaterialApp.themeMode) and it is saved on
/// the device so it survives restarts. Off by default; it does not follow the
/// system theme.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController({this._settings}) : super(ThemeMode.light);

  /// The app-wide instance. Tests replace it with their own.
  static ThemeController instance = ThemeController();

  final AppSettingsRepository? _settings;

  AppSettingsRepository get _repo =>
      _settings ?? AppSettingsRepository.instance;

  bool get isDark => value == ThemeMode.dark;

  /// Applies the saved choice (called once at start-up, before the first
  /// screen, so even the splash has the right colors).
  Future<void> load() async {
    final dark = await _repo.isDarkMode();
    AppColors.setDark(dark);
    value = dark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Switches immediately (every screen repaints in the new colors, without
  /// losing where the user is), then remembers the choice.
  Future<void> setDark(bool dark) async {
    if (dark == isDark) return;
    AppColors.setDark(dark);
    value = dark ? ThemeMode.dark : ThemeMode.light;
    repaintEverything();
    await _repo.setDarkMode(dark);
  }

  /// Colors are read from [AppColors] when a widget builds or paints, so a
  /// change of palette needs every widget to build and paint again (the same
  /// thing a hot reload does). State, scroll positions and the screens that
  /// are open are kept.
  static void repaintEverything() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    void visit(Element e) {
      e.markNeedsBuild();
      final render = e.renderObject;
      render?.markNeedsPaint();
      e.visitChildren(visit);
    }

    root.visitChildren(visit);
  }
}
