import 'package:flutter/material.dart';

import '../../data_access/repositories/app_settings_repository.dart';
import 'app_colors.dart';

/// The app-wide light / dark choice.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController({this._settings}) : super(ThemeMode.light);

  /// The app-wide instance.
  static ThemeController instance = ThemeController();

  final AppSettingsRepository? _settings;

  AppSettingsRepository get _repo =>
      _settings ?? AppSettingsRepository.instance;

  bool get isDark => value == ThemeMode.dark;

  Future<void> load() async {
    final dark = await _repo.isDarkMode();
    AppColors.setDark(dark);
    value = dark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setDark(bool dark) async {
    if (dark == isDark) return;
    AppColors.setDark(dark);
    value = dark ? ThemeMode.dark : ThemeMode.light;
    repaintEverything();
    await _repo.setDarkMode(dark);
  }

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
