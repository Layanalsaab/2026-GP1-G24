import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/investor_criteria.dart';

class InvestorDraftStore {
  /// The app-wide instance.
  static InvestorDraftStore instance = InvestorDraftStore();

  static String _key(String uid) => 'investor_draft_$uid';

  Future<InvestorCriteria?> load(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(uid));
      if (raw == null) return null;
      return InvestorCriteria.fromMap(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String uid, InvestorCriteria answers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(uid), jsonEncode(answers.toMap()));
    } catch (_) {
      // Still kept for this session.
    }
  }

  Future<void> clear(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(uid));
    } catch (_) {}
  }
}
