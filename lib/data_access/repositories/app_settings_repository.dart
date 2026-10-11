import 'package:shared_preferences/shared_preferences.dart';

/// Small settings kept on the phone itself (not in Firebase).
class AppSettingsRepository {
  /// The app-wide instance. Tests replace it with a fake.
  static AppSettingsRepository instance = AppSettingsRepository();

  static const _introSeenKey = 'intro_seen';
  static const _darkModeKey = 'dark_mode';

  /// Whether the user switched Dark mode on (Settings). Off when unreadable.
  Future<bool> isDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_darkModeKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, value);
    } catch (_) {
      // The choice still applies for this session.
    }
  }

  /// Whether the three intro screens have already been shown on this device.
  /// If storage can't be read we show them again rather than fail.
  Future<bool> hasSeenIntro() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_introSeenKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> markIntroSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_introSeenKey, true);
    } catch (_) {
      // Not being able to remember just means the intros may show once more.
    }
  }
}
