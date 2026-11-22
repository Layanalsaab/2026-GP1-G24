import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../helpers/app_session.dart';
import '../firebase_services/firestore_service.dart';
import 'bookmark_repository.dart';

/// The cards the signed-in user hid from For You with "Not interested".
/// Stored like bookmarks (same keys and fields); the For You server reads it.
class NotInterestedRepository {
  NotInterestedRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  /// The app-wide instance.
  static NotInterestedRepository instance = NotInterestedRepository();

  final FirestoreService _firestore;

  final ValueNotifier<Set<String>> _keys = ValueNotifier<Set<String>>({});

  /// The user whose items are in memory (null when signed out).
  String? _uid;

  /// The hidden keys; notifies when one is added or removed.
  ValueListenable<Set<String>> get keys => _keys;

  bool contains(String key) => _keys.value.contains(key);

  /// users/{uid}/notInterested
  static String _collectionOf(String uid) =>
      '${FirestoreCollections.users}/$uid/${FirestoreCollections.notInterested}';

  /// Hides key at once; completes when the write is done. A failed write is
  /// logged and key is put back.
  Future<void> add(String key) async {
    if (contains(key)) return;
    _keys.value = {..._keys.value, key};
    final uid = AppSession.instance.user?.uid;
    if (uid == null) return;
    try {
      await _firestore.setDocument(_collectionOf(uid), key, {
        'type': BookmarkRepository.typeOf(key),
        'targetId': BookmarkRepository.targetIdOf(key),
        'createdAt': _firestore.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Not interested "$key" was not saved: $e');
      _keys.value = {..._keys.value}..remove(key);
    }
  }

  /// Un-hides key (Undo) at once; completes when the delete is done. A failed
  /// delete is logged and key is put back.
  Future<void> remove(String key) async {
    if (!contains(key)) return;
    _keys.value = {..._keys.value}..remove(key);
    final uid = AppSession.instance.user?.uid;
    if (uid == null) return;
    try {
      await _firestore.deleteDocument(_collectionOf(uid), key);
    } catch (e) {
      debugPrint('Not interested "$key" was not removed: $e');
      _keys.value = {..._keys.value, key};
    }
  }

  /// Reads uid's saved items (after log in or a restored session).
  Future<void> load(String uid) async {
    _uid = uid;
    try {
      final docs = await _firestore.listCollection(
        _collectionOf(uid),
        limit: 1000,
      );
      if (_uid != uid) return; // Signed out (or another user) meanwhile.
      _keys.value = {..._keys.value, for (final d in docs) d.id};
    } catch (e) {
      debugPrint('Not interested could not be loaded: $e');
    }
  }

  /// Deletes every saved item of uid (account deletion).
  Future<void> deleteAll(String uid) async {
    final docs = await _firestore.listCollection(
      _collectionOf(uid),
      limit: 1000,
    );
    for (final d in docs) {
      await _firestore.deleteDocument(_collectionOf(uid), d.id);
    }
    clear();
  }

  /// Forgets the items in memory (log out).
  void clear() {
    _uid = null;
    _keys.value = {};
  }
}
