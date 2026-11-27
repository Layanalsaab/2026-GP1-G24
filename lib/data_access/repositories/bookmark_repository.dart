import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../helpers/app_session.dart';
import '../../models/list_entries.dart';
import '../firebase_services/firestore_service.dart';
import 'discovery_repository.dart';

/// The signed-in user's bookmarks (cards, startup / investor / program profiles).
class BookmarkRepository {
  BookmarkRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  /// The app-wide instance.
  static BookmarkRepository instance = BookmarkRepository();

  final FirestoreService _firestore;

  final ValueNotifier<Set<String>> _keys = ValueNotifier<Set<String>>({});

  /// When each key was bookmarked (for the newest-first order).
  final Map<String, DateTime> _savedAt = {};

  /// The user whose bookmarks are in memory (null when signed out).
  String? _uid;

  /// The bookmarked keys; notifies when one is added or removed.
  ValueListenable<Set<String>> get keys => _keys;

  bool isBookmarked(String key) => _keys.value.contains(key);

  int get count => _keys.value.length;

  /// When key was bookmarked, if known.
  DateTime? savedAt(String key) => _savedAt[key];

  /// Counts finished saves (a bookmark written or deleted in Firestore): For
  /// You asks the server again only once the server can see the change.
  ValueListenable<int> get saved => _saved;
  final ValueNotifier<int> _saved = ValueNotifier<int>(0);

  /// Every bookmarked key, the most recently saved first.
  List<String> newestFirst({String? type}) {
    final list = [
      for (final k in _keys.value)
        if (type == null || typeOf(k) == type) k,
    ];
    final old = DateTime.fromMillisecondsSinceEpoch(0);
    list.sort((a, b) => (_savedAt[b] ?? old).compareTo(_savedAt[a] ?? old));
    return list;
  }

  /// The user's bookmarks as cards for My Bookmarks, newest first.
  Future<List<SavedBookmark>> savedItems({
    DiscoveryRepository? discovery,
  }) async {
    final source = discovery ?? DiscoveryRepository.instance;
    final keys = newestFirst();
    final found = await Future.wait([
      for (final k in keys) source.itemForBookmark(k),
    ]);
    final never = DateTime.fromMillisecondsSinceEpoch(0);
    final list = <SavedBookmark>[];
    for (var i = 0; i < keys.length; i++) {
      final item = found[i].item;
      if (item != null) {
        list.add(
          SavedBookmark(item: item, savedAt: _savedAt[keys[i]] ?? never),
        );
      } else if (found[i].deleted) {
        remove(keys[i]);
      }
    }
    return list;
  }

  /// Removes key if it is bookmarked (remove button on My Bookmarks).
  void remove(String key) {
    if (isBookmarked(key)) toggle(key);
  }

  /// users/{uid}/bookmarks
  static String _collectionOf(String uid) =>
      '${FirestoreCollections.users}/$uid/${FirestoreCollections.bookmarks}';

  /// What a key is about: s- startup, i- investor, p- program.
  static String typeOf(String key) {
    if (key.startsWith('s-')) return 'startup';
    if (key.startsWith('i-')) return 'investor';
    if (key.startsWith('p-')) return 'program';
    return 'other';
  }

  /// The id after the s- / i- / p- prefix.
  static String targetIdOf(String key) {
    final dash = key.indexOf('-');
    return dash < 0 ? key : key.substring(dash + 1);
  }

  /// Adds or removes key.
  bool toggle(String key) {
    final next = {..._keys.value};
    final added = next.add(key);
    if (added) {
      _savedAt[key] = DateTime.now();
    } else {
      next.remove(key);
      _savedAt.remove(key);
    }
    _keys.value = next;

    final uid = AppSession.instance.user?.uid;
    if (uid != null) _save(uid, key, added);
    return added;
  }

  Future<void> _save(String uid, String key, bool added) async {
    try {
      if (added) {
        await _firestore.setDocument(_collectionOf(uid), key, {
          'type': typeOf(key),
          'targetId': targetIdOf(key),
          'createdAt': _firestore.serverTimestamp(),
        });
      } else {
        await _firestore.deleteDocument(_collectionOf(uid), key);
      }
      _saved.value++;
    } catch (e) {
      debugPrint('Bookmark "$key" was not saved: $e');
    }
  }

  /// Reads uid's saved bookmarks (after log in or a restored session).
  Future<void> load(String uid) async {
    _uid = uid;
    try {
      final docs = await _firestore.listCollection(
        _collectionOf(uid),
        limit: 1000,
      );
      if (_uid != uid) return; // Signed out (or another user) meanwhile.
      for (final d in docs) {
        final at = d.data['createdAt'];
        if (at is DateTime) _savedAt.putIfAbsent(d.id, () => at);
      }
      _keys.value = {..._keys.value, for (final d in docs) d.id};
    } catch (e) {
      debugPrint('Bookmarks could not be loaded: $e');
    }
  }

  /// Deletes every saved bookmark of uid (account deletion).
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

  /// Forgets the bookmarks in memory (log out).
  void clear() {
    _uid = null;
    _savedAt.clear();
    _keys.value = {};
  }
}
