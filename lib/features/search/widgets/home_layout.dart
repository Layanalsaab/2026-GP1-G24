import 'package:flutter/material.dart';

import '../../../app_constants/home_strings.dart';
import '../../../data_access/repositories/bookmark_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../models/home_item.dart';
import '../../../navigation/open_item.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/cards/avatars.dart';
import '../../../shared_ui/widgets/cards/home_card.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';

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
    final canBookmark = AppSession.instance.canBookmark;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: BookmarkRepository.instance.keys,
      builder: (context, keys, _) => HomeCard(
        name: item.name,
        tag: item.tag,
        city: item.city,
        body: item.line,
        kind: avatarKindOf(item.kind),
        index: index,
        bookmarked: keys.contains(item.bookmarkKey),
        matchPercent: showMatch ? item.matchPercent : null,
        matchReason: showMatch ? item.matchReason : null,
        onTap: () => openHomeItem(context, item),
        onShare: () => AppToast.show(context, HomeStrings.linkCopied),
        onBookmark: canBookmark
            ? () {
                final added = BookmarkRepository.instance.toggle(
                  item.bookmarkKey,
                );
                AppToast.show(
                  context,
                  added
                      ? HomeStrings.bookmarkAdded
                      : HomeStrings.bookmarkRemoved,
                );
              }
            : null,
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

/// The cards as one slot (the prototype's `.hcards`, gap 16).
HomeSlot cardsSlot(List<HomeItem> items, {bool showMatch = false}) => HomeSlot(
  Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: homeCardsOf(items, showMatch: showMatch),
  ),
);

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
