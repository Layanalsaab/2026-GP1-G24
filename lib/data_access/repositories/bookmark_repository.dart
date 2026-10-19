import 'package:flutter/foundation.dart';

/// The signed-in user's bookmarks (cards, startup / investor / program
/// profiles). Guests never bookmark: screens hide the bookmark icon for them,
/// and [toggle] ignores a guest session.
///
/// Keys are `s-<startupId>`, `i-<investorId>` and `p-<programId>`
/// (see `HomeItem.bookmarkKey`).
///
/// TODO(backend): persist under `users/{uid}/bookmarks/{key}` once the
/// Firestore rules for it are published; today the set lives in memory for
/// the session and is cleared on log out.
class BookmarkRepository {
  BookmarkRepository();

  /// The app-wide instance. Tests replace it with a fake.
  static BookmarkRepository instance = BookmarkRepository();

  final ValueNotifier<Set<String>> _keys = ValueNotifier<Set<String>>({});

  /// The bookmarked keys; notifies when one is added or removed.
  ValueListenable<Set<String>> get keys => _keys;

  bool isBookmarked(String key) => _keys.value.contains(key);

  int get count => _keys.value.length;

  /// Adds or removes [key]. Returns true when it is now bookmarked.
  bool toggle(String key) {
    final next = {..._keys.value};
    final added = next.add(key);
    if (!added) next.remove(key);
    _keys.value = next;
    return added;
  }

  /// Forgets every bookmark (log out).
  void clear() => _keys.value = {};
}
