import 'package:flutter/foundation.dart';

import '../../app_constants/firestore_collections.dart';
import '../../helpers/app_session.dart';
import '../firebase_services/firestore_service.dart';

/// The signed-in user's bookmarks (cards, startup / investor / program
/// profiles). Guests never bookmark: screens hide the bookmark icon for them,
/// and nothing is saved without a signed-in user.
///
/// Keys are `s-<startupId>`, `i-<investorId>` and `p-<programId>`
/// (see `HomeItem.bookmarkKey`).
///
/// Saved in Firestore at `users/{uid}/bookmarks/{key}` (one document per
/// bookmark), so bookmarks survive log out and reinstalling the app:
/// - [toggle] updates the in-memory set at once (the icon fills straight
///   away) and then writes or deletes the document in the background;
/// - [load] reads the user's bookmarks after log in;
/// - [clear] only forgets the in-memory set (log out); the saved bookmarks
///   stay in Firestore;
/// - [deleteAll] removes the saved bookmarks (account deletion).
///
/// Bookmarks belong to the account, not to a startup.
///
/// My Bookmarks shows startups, investors and programs together, newest
/// first, with a filter by type: use [newestFirst] and [typeOf].
class BookmarkRepository {
  BookmarkRepository({FirestoreService? firestore})
    : _firestore = firestore ?? FirestoreService();

  /// The app-wide instance. Tests replace it with a fake.
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

  /// When [key] was bookmarked, if known.
  DateTime? savedAt(String key) => _savedAt[key];

  /// Every bookmarked key, the most recently saved first. Pass [type]
  /// (`startup`, `investor` or `program`) for the My Bookmarks filter.
  List<String> newestFirst({String? type}) {
    final list = [
      for (final k in _keys.value)
        if (type == null || typeOf(k) == type) k,
    ];
    final old = DateTime.fromMillisecondsSinceEpoch(0);
    list.sort(
      (a, b) => (_savedAt[b] ?? old).compareTo(_savedAt[a] ?? old),
    );
    return list;
  }

  /// `users/{uid}/bookmarks`
  static String _collectionOf(String uid) =>
      '${FirestoreCollections.users}/$uid/${FirestoreCollections.bookmarks}';

  /// What a key is about: `s-` startup, `i-` investor, `p-` program.
  static String typeOf(String key) {
    if (key.startsWith('s-')) return 'startup';
    if (key.startsWith('i-')) return 'investor';
    if (key.startsWith('p-')) return 'program';
    return 'other';
  }

  /// The id after the `s-` / `i-` / `p-` prefix.
  static String targetIdOf(String key) {
    final dash = key.indexOf('-');
    return dash < 0 ? key : key.substring(dash + 1);
  }

  /// Adds or removes [key]. Returns true when it is now bookmarked.
  ///
  /// The change shows at once; saving to Firestore happens in the background.
  /// Firestore keeps the write on the phone while offline and sends it when
  /// the connection is back, so a failed save is only logged.
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
    } catch (e) {
      debugPrint('Bookmark "$key" was not saved: $e');
    }
  }

  /// Reads [uid]'s saved bookmarks (after log in or a restored session).
  /// Keys toggled while loading are kept. A failure keeps what is in memory.
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

  /// Deletes every saved bookmark of [uid] (account deletion). Firestore
  /// doesn't delete a user's bookmarks when the user document is deleted.
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

  /// Forgets the bookmarks in memory (log out). The saved ones stay in
  /// Firestore and come back with [load] at the next log in.
  void clear() {
    _uid = null;
    _savedAt.clear();
    _keys.value = {};
  }
}
