import 'package:flutter/foundation.dart';

import '../../../app_constants/home_strings.dart';
import '../../../models/home_item.dart';
import '../../../models/list_entries.dart';

/// Which kinds of saved items the Bookmarks list shows.
enum BookmarkType {
  all(HomeStrings.allTypes, null),
  startups(HomeStrings.typeStartups, HomeItemKind.startup),
  investors(HomeStrings.typeInvestors, HomeItemKind.investor),
  programs(HomeStrings.typePrograms, HomeItemKind.program);

  const BookmarkType(this.label, this.kind);

  final String label;
  final HomeItemKind? kind;

  /// "startups" / "investors" / "support channels" for the empty message.
  String get plural => label.toLowerCase();
}

enum BookmarkSort {
  newest(HomeStrings.newestFirst),
  oldest(HomeStrings.oldestFirst),
  name(HomeStrings.nameAZ);

  const BookmarkSort(this.label);

  final String label;
}

/// Local state of the Bookmarks screen: the saved items it was given, the
/// current type filter and sort, and removing an item. INTERFACE ONLY: it
/// holds the list in memory; the backend connects the real list (and the
/// real "remove") through [onRemove].
class BookmarksViewModel extends ChangeNotifier {
  BookmarksViewModel(List<SavedBookmark> items, {this.onRemove})
    : _all = List.of(items);

  /// Called after an item is removed from the list, so the real bookmark can
  /// be deleted too. Null = just the list changes.
  final void Function(SavedBookmark removed)? onRemove;

  final List<SavedBookmark> _all;

  BookmarkType type = BookmarkType.all;
  BookmarkSort sort = BookmarkSort.newest;

  /// Nothing is saved at all (the pills are hidden).
  bool get isEmpty => _all.isEmpty;

  bool get filtered => type != BookmarkType.all;

  /// The items after the type filter and the sort.
  List<SavedBookmark> get visible {
    final list = [
      for (final b in _all)
        if (type.kind == null || b.item.kind == type.kind) b,
    ];
    switch (sort) {
      case BookmarkSort.newest:
        list.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      case BookmarkSort.oldest:
        list.sort((a, b) => a.savedAt.compareTo(b.savedAt));
      case BookmarkSort.name:
        list.sort(
          (a, b) =>
              a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase()),
        );
    }
    return list;
  }

  void setType(BookmarkType value) {
    type = value;
    notifyListeners();
  }

  void setSort(BookmarkSort value) {
    sort = value;
    notifyListeners();
  }

  void resetFilter() => setType(BookmarkType.all);

  void remove(SavedBookmark bookmark) {
    if (_all.remove(bookmark)) {
      onRemove?.call(bookmark);
      notifyListeners();
    }
  }
}
