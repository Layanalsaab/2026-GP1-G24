import 'package:flutter/material.dart';

import '../../../app_constants/home_strings.dart';
import '../../../data_access/repositories/bookmark_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../helpers/share_link.dart';
import '../../../models/home_item.dart';
import '../../../navigation/open_item.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/cards/home_card.dart';
import '../../../shared_ui/widgets/lists/empty_state.dart';
import '../view_models/home_view_model.dart';

/// One entry of a [HomeColumn]: the [child] plus the CSS-style margins the
/// prototype uses between list items (they may be negative).
class HomeSlot {
  const HomeSlot(
    this.child, {
    this.top = 0,
    this.bottom = 0,
    this.bleed = false,
  });

  final Widget child;
  final double top;
  final double bottom;

  /// Full width (ignores the 16 px side padding), e.g. the "New" rail.
  final bool bleed;
}

/// The home list (prototype `.hlst`): padding 18 16 28, 16 px gap between
/// items, each item's own margins added to the gap.
class HomeColumn extends StatelessWidget {
  const HomeColumn({super.key, required this.slots});

  static const double gap = 16;

  final List<HomeSlot> slots;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < slots.length; i++) {
      final s = slots[i];
      if (i > 0) {
        final space = gap + slots[i - 1].bottom + s.top;
        if (space > 0) children.add(SizedBox(height: space));
      }
      children.add(
        s.bleed
            ? s.child
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: s.child,
              ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

HueAvatarKind avatarKindOf(HomeItemKind kind) => switch (kind) {
  HomeItemKind.startup => HueAvatarKind.startup,
  HomeItemKind.investor => HueAvatarKind.investor,
  HomeItemKind.program => HueAvatarKind.program,
};

/// A [HomeCard] built from a [HomeItem]: opens the profile, share toast, and a
/// bookmark button that is absent for guests.
class HomeItemCard extends StatelessWidget {
  const HomeItemCard({
    super.key,
    required this.item,
    this.index = 0,
    this.showMatch = false,
  });

  final HomeItem item;
  final int index;

  /// Shows the "N% match" row (Explore, Matches).
  final bool showMatch;

  @override
  Widget build(BuildContext context) {
    // Guests never bookmark, and an investor can't bookmark their own profile.
    final session = AppSession.instance;
    final canBookmark =
        session.canBookmark &&
        !(item.kind == HomeItemKind.investor && item.id == session.user?.uid);
    return ValueListenableBuilder<Set<String>>(
      valueListenable: BookmarkRepository.instance.keys,
      builder: (context, keys, _) => RepaintBoundary(
        child: HomeCard(
          name: item.name,
          tag: item.tag,
          city: item.city,
          body: item.line,
          bodyMaxLines: item.kind == HomeItemKind.startup ? 2 : 3,
          kind: avatarKindOf(item.kind),
          imageUrl: item.imageUrl,
          imageData: item.imageData,
          index: index,
          bookmarked: keys.contains(item.bookmarkKey),
          matchPercent: showMatch ? item.matchPercent : null,
          matchReason: showMatch ? item.matchReason : null,
          onTap: () => openHomeItem(context, item),
          onShare: () => ShareLink.copyKey(context, item.bookmarkKey),
          onBookmark: canBookmark
              ? () => BookmarkRepository.instance.toggle(item.bookmarkKey)
              : null,
        ),
      ),
    );
  }
}

/// Cards of [items] with the staggered entrance (40 ms per card).
List<Widget> homeCardsOf(List<HomeItem> items, {bool showMatch = false}) => [
  for (var i = 0; i < items.length; i++)
    Padding(
      padding: EdgeInsets.only(top: i == 0 ? 0 : HomeColumn.gap),
      child: HomeItemCard(item: items[i], index: i, showMatch: showMatch),
    ),
];

/// The cards as one slot (the prototype's `.hcards`, gap 16). Only the first
/// page is built; "Show more" adds the next one, so a list of hundreds of
/// startups stays smooth to scroll.
///
/// The list is keyed by [scope] plus the content of [items], so whenever the
/// list changes (tab, sub-tab, switch side, search text, filters, "See all")
/// every card is built again and replays its staggered entrance.
HomeSlot cardsSlot(
  List<HomeItem> items, {
  bool showMatch = false,
  String scope = '',
}) => HomeSlot(
  PagedCards(
    key: ValueKey('$scope|${contentSignature(items)}|$showMatch'),
    items: items,
    showMatch: showMatch,
  ),
);

/// A value that changes whenever the items shown (or their order) change.
int contentSignature(List<HomeItem> items) =>
    Object.hashAll([for (final i in items) i.bookmarkKey]);

/// [homeCardsOf] in pages of [pageSize].
class PagedCards extends StatefulWidget {
  const PagedCards({
    super.key,
    required this.items,
    this.showMatch = false,
    this.pageSize = 20,
  });

  final List<HomeItem> items;
  final bool showMatch;
  final int pageSize;

  @override
  State<PagedCards> createState() => _PagedCardsState();
}

class _PagedCardsState extends State<PagedCards> {
  late int _visible = widget.pageSize;

  @override
  void didUpdateWidget(PagedCards old) {
    super.didUpdateWidget(old);
    // A different list (a filter, a search, another tab): back to page one.
    final a = old.items, b = widget.items;
    final same =
        a.length == b.length &&
        (a.isEmpty || (a.first.bookmarkKey == b.first.bookmarkKey));
    if (!same) _visible = widget.pageSize;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final shown = items.length <= _visible ? items : items.sublist(0, _visible);
    final left = items.length - shown.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...homeCardsOf(shown, showMatch: widget.showMatch),
        if (left > 0)
          Padding(
            padding: const EdgeInsets.only(top: HomeColumn.gap),
            child: Center(
              child: Pressable(
                scale: PressScale.smallPill,
                onTap: () => setState(() => _visible += widget.pageSize),
                child: Semantics(
                  button: true,
                  label: HomeStrings.showMore(left),
                  excludeSemantics: true,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        HomeStrings.showMore(left),
                        style: AppText.sans(
                          size: 14.5,
                          weight: FontWeight.w600,
                          color: AppColors.moss600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// The "‹ For You" link of the "See all" view (prototype `.xback`).
class BackLink extends StatelessWidget {
  const BackLink({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        onTap: onTap,
        child: Pressable(
          scale: 0.97,
          onTap: onTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.only(left: 4, right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon.outline(
                  AppIcons.profileBack,
                  size: 20,
                  stroke: 2,
                  color: AppColors.moss600,
                ),
                const SizedBox(width: 2),
                Text(
                  label,
                  style: AppText.sans(
                    size: 14.5,
                    weight: FontWeight.w600,
                    color: AppColors.moss600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What a list shows when it has no cards: a spinner while Firestore loads,
/// a retry when loading failed, "No matches" while filtering, otherwise a
/// plain "nothing here yet".
Widget homeEmptyState(HomeViewModel vm) {
  if (vm.isLoadingDirectory) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.moss600,
          ),
        ),
      ),
    );
  }
  if (vm.directoryFailed) {
    return EmptyState(
      title: HomeStrings.loadFailedTitle,
      message: HomeStrings.loadFailedMessage,
      actionLabel: HomeStrings.retry,
      onAction: vm.refreshDirectory,
    );
  }
  final searching = vm.query.trim().isNotEmpty;
  if (searching || vm.selectionCount > 0) return homeNoResults(vm);
  return const EmptyState(
    title: HomeStrings.nothingYetTitle,
    message: HomeStrings.nothingYetMessage,
  );
}

/// "No results" for a search, "No matches" when filters are on.
Widget homeNoResults(HomeViewModel vm) {
  final searching = vm.query.trim().isNotEmpty;
  if (vm.selectionCount > 0) {
    // Filters are on (with or without a search): the filter wording.
    return EmptyState.noMatches(onAction: vm.clearAll);
  }
  if (searching) {
    // Only a search: say it was not found, not that a filter is on.
    return EmptyState(
      title: HomeStrings.noResultsTitle(vm.query.trim()),
      message: '',
    );
  }
  return EmptyState.noMatches(onAction: vm.clearAll);
}
