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
  newest(HomeStrings.sortNewest),
  oldest(HomeStrings.sortOldest),
  name(HomeStrings.sortNameAZ),
  nameDesc(HomeStrings.sortNameZA);

  const BookmarkSort(this.label);

  final String label;
}

class BookmarksViewModel extends ChangeNotifier {
  BookmarksViewModel(List<SavedBookmark> items, {this.onRemove})
    : _all = List.of(items);

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
      case BookmarkSort.nameDesc:
        list.sort(
          (a, b) =>
              b.item.name.toLowerCase().compareTo(a.item.name.toLowerCase()),
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

  /// Pull to refresh: the list is replaced by the freshly read bookmarks.
  void replaceAll(List<SavedBookmark> items) {
    _all
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  void remove(SavedBookmark bookmark) {
    if (_all.remove(bookmark)) {
      onRemove?.call(bookmark);
      notifyListeners();
    }
  }
}
