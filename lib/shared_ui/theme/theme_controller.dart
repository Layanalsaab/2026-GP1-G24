import 'package:flutter/material.dart';

import '../../data_access/repositories/app_settings_repository.dart';

/// The app-wide light / dark choice. The Settings "Dark mode" switch changes
/// it, [StartSaApp] listens to it (MaterialApp.themeMode) and it is saved on
/// the device so it survives restarts.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController({this._settings}) : super(ThemeMode.light);

  /// The app-wide instance. Tests replace it with their own.
  static ThemeController instance = ThemeController();

  final AppSettingsRepository? _settings;

  AppSettingsRepository get _repo =>
      _settings ?? AppSettingsRepository.instance;

  bool get isDark => value == ThemeMode.dark;

  /// Applies the saved choice (called once at start-up).
  Future<void> load() async {
    final dark = await _repo.isDarkMode();
    value = dark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Switches immediately, then remembers the choice.
  Future<void> setDark(bool dark) async {
    value = dark ? ThemeMode.dark : ThemeMode.light;
    await _repo.setDarkMode(dark);
  }
}
