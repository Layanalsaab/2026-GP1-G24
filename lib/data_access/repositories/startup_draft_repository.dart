import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one unfinished "Add startup" form a founder can save as a draft. It is
/// kept on the phone (per account), not in Firebase, so an incomplete startup
/// never reaches the public `startups` collection.
class StartupDraftRepository {
  /// The app-wide instance. Tests replace it with a fake.
  static StartupDraftRepository instance = StartupDraftRepository();

  /// The current draft (null when there is none). My Startups listens to it.
  final ValueNotifier<Map<String, Object?>?> current = ValueNotifier(null);

  static String _key(String uid) => 'startup_draft_$uid';

  /// Reads the saved draft of [uid] into [current].
  Future<void> load(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(uid));
      current.value = raw == null
          ? null
          : (jsonDecode(raw) as Map).cast<String, Object?>();
    } catch (_) {
      current.value = null;
    }
  }

  Future<void> save(String uid, Map<String, Object?> draft) async {
    current.value = draft;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(uid), jsonEncode(draft));
    } catch (_) {
      // Still available for this session.
    }
  }

  Future<void> clear(String uid) async {
    current.value = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (_) {}
  }
}
