import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last For You list the server gave each user (keys like `s-<id>` /
/// `i-<id>`), kept on the phone so the page can show it instantly while the
/// server wakes up.
class ForYouCache {
  /// The app-wide instance (replaceable in tests).
  static ForYouCache instance = ForYouCache();

  static String _key(String uid) => 'forYou.lastList.$uid';
  static String _atKey(String uid) => 'forYou.lastListAt.$uid';

  /// The saved list, or an empty list when none is saved or storage fails.
  Future<List<String>> read(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key(uid)) ?? const [];
    } catch (e) {
      debugPrint('ForYouCache.read failed: $e');
      return const [];
    }
  }

  /// When the saved list was saved, or null when unknown (none saved, an
  /// older app version, or storage fails).
  Future<DateTime?> savedAt(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_atKey(uid));
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (e) {
      debugPrint('ForYouCache.savedAt failed: $e');
      return null;
    }
  }

  /// Saves the list and the time; a storage failure is only logged.
  Future<void> write(String uid, List<String> keys) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key(uid), keys);
      await prefs.setInt(_atKey(uid), DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('ForYouCache.write failed: $e');
    }
  }

  /// Forgets uid's list (account deletion); a storage failure is only logged.
  Future<void> remove(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
      await prefs.remove(_atKey(uid));
    } catch (e) {
      debugPrint('ForYouCache.remove failed: $e');
    }
  }
}
