import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The last For You list the server gave each user (keys like `s-<id>` /
/// `i-<id>`), kept on the phone so the page can show it instantly while the
/// server wakes up.
class ForYouCache {
  /// The app-wide instance (replaceable in tests).
  static ForYouCache instance = ForYouCache();

  static String _key(String uid) => 'forYou.lastList.$uid';

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

  /// Saves the list; a storage failure is only logged.
  Future<void> write(String uid, List<String> keys) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key(uid), keys);
    } catch (e) {
      debugPrint('ForYouCache.write failed: $e');
    }
  }

  /// Forgets uid's list (account deletion); a storage failure is only logged.
  Future<void> remove(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (e) {
      debugPrint('ForYouCache.remove failed: $e');
    }
  }
}
