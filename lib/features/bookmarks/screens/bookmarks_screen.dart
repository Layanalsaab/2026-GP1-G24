import 'package:flutter/material.dart';

import '../../../app_constants/home_strings.dart';
import '../../../models/list_entries.dart';
import '../../../navigation/open_item.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/buttons/app_button.dart';
import '../../../shared_ui/widgets/cards/home_card.dart';
import '../../../shared_ui/widgets/headers/list_screen_header.dart';
import '../../../shared_ui/widgets/lists/empty_state.dart';
import '../../../shared_ui/widgets/lists/filter_sort_pills.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import '../../../shared_ui/widgets/overlays/picker_sheet.dart';
import '../../../models/home_item.dart';
import '../../search/widgets/home_layout.dart' show avatarKindOf;
import '../view_models/bookmarks_view_model.dart';

/// Bookmarks (side menu): the startups, investors and support channels the
/// user saved, with a type filter and a sort, using the same card as the Hub.
///
/// The list is passed in as [items] (the user's bookmarks, loaded by
/// `BookmarkRepository.savedItems`). [onRemove] deletes the bookmark.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({
    super.key,
    required this.items,
    this.onRemove,
    this.onExplore,
  });

  /// The saved items.
  final List<SavedBookmark> items;

  /// Called when a bookmark is removed from the list.
  final void Function(SavedBookmark removed)? onRemove;

  /// The "Explore" button of the empty state (goes to the Explore tab).
  final VoidCallback? onExplore;

  /// Opens the screen with the forward transition.
  static void open(
    BuildContext context, {
    required List<SavedBookmark> items,
    void Function(SavedBookmark removed)? onRemove,
    VoidCallback? onExplore,
  }) => AppNav.push(
    context,
    BookmarksScreen(items: items, onRemove: onRemove, onExplore: onExplore),
    greenHeader: true,
  );

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late final BookmarksViewModel _vm = BookmarksViewModel(
    widget.items,
    onRemove: widget.onRemove,
  );

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _pickFilter() async {
    final r = await showPickerSheet(
      context,
      title: HomeStrings.filterByTypeTitle,
      options: [for (final t in BookmarkType.values) t.label],
      selected: _vm.type.label,
    );
    if (r == null) return;
    _vm.setType(BookmarkType.values.firstWhere((t) => t.label == r.value));
  }

  Future<void> _pickSort() async {
    final r = await showPickerSheet(
      context,
      title: HomeStrings.sortBookmarksTitle,
      options: [for (final s in BookmarkSort.values) s.label],
      selected: _vm.sort.label,
    );
    if (r == null) return;
    _vm.setSort(BookmarkSort.values.firstWhere((s) => s.label == r.value));
  }

  void _remove(SavedBookmark b) {
    _vm.remove(b);
    AppToast.show(context, HomeStrings.bookmarkRemoved);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final items = _vm.visible;
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListScreenHeader(
                  title: HomeStrings.bookmarksTitle,
                  onBack: () => AppNav.back(context),
                  pills: _vm.isEmpty
                      ? null
                      : FilterSortPills(
                          filterLabel: _vm.type.label,
                          filterActive: _vm.filtered,
                          sortLabel: _vm.sort.label,
                          onFilter: _pickFilter,
                          onSort: _pickSort,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  child: _vm.isEmpty
                      ? _NoBookmarks(onExplore: widget.onExplore)
                      : items.isEmpty
                      ? _NoneOfType(
                          plural: _vm.type.plural,
                          onShowAll: _vm.resetFilter,
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < items.length; i++)
                              Padding(
                                padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
                                child: _BookmarkCard(
                                  key: ObjectKey(items[i]),
                                  bookmark: items[i],
                                  index: i,
                                  onRemove: () => _remove(items[i]),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The same [HomeCard] as For You / Hub / Support Channels, always showing the
/// filled gold bookmark; tapping it removes the card from the list.
class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    super.key,
    required this.bookmark,
    required this.index,
    required this.onRemove,
  });

  final SavedBookmark bookmark;
  final int index;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final HomeItem item = bookmark.item;
    return HomeCard(
      name: item.name,
      tag: item.tag,
      city: item.city,
      body: item.line,
      bodyMaxLines: item.kind == HomeItemKind.startup ? 2 : 3,
      kind: avatarKindOf(item.kind),
      index: index,
      bookmarked: true,
      onTap: () => openHomeItem(context, item),
      onShare: () => AppToast.show(context, HomeStrings.linkCopied),
      onBookmark: onRemove,
    );
  }
}

/// Nothing saved at all: a bookmark icon in a light green circle, a title, a
/// message and a primary "Explore" button.
class _NoBookmarks extends StatelessWidget {
  const _NoBookmarks({this.onExplore});

  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return IllustratedEmptyCard(
      illustration: Container(
        width: 96,
        height: 96,
        decoration: const BoxDecoration(
          color: AppColors.mossChip,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const AppIcon.outline(
          AppIcons.menuBookmark,
          size: 40,
          color: AppColors.moss600,
        ),
      ),
      float: false,
      title: HomeStrings.noBookmarksTitle,
      message: HomeStrings.noBookmarksMessage,
      actionLabel: onExplore == null ? null : HomeStrings.explore,
      actionIcon: null,
      onAction: onExplore,
    );
  }
}

/// A type filter with no results: a small card with "Show all bookmarks".
class _NoneOfType extends StatelessWidget {
  const _NoneOfType({required this.plural, required this.onShowAll});

  final String plural;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F2314),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            HomeStrings.noSavedOfType(plural),
            textAlign: TextAlign.center,
            style: AppText.sans(size: 15, color: AppColors.grey, height: 22),
          ),
          const SizedBox(height: 4),
          AppButton(
            label: HomeStrings.showAllBookmarks,
            variant: AppButtonVariant.ghost,
            expanded: false,
            onPressed: onShowAll,
          ),
        ],
      ),
    );
  }
}
