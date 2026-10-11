import 'package:flutter/material.dart';

import '../../app_constants/explore_strings.dart';
import '../../models/investor_profile.dart';
import '../../models/program.dart';
import '../../models/startup_listing.dart';
import '../../navigation/placeholder_features.dart';
import '../theme/app_theme.dart';
import 'svg_asset.dart';

/// Building blocks of the three main tabs, following Figma "V2 · 38 – 45"
/// (Support Systems, Hub, Explore).

// ---------------------------------------------------------------------------
// Header pieces
// ---------------------------------------------------------------------------

/// Tabs under the top bar ("For You / Trending / Matches"): the selected label
/// is bold with a green bar under it.
class HomeTabs extends StatelessWidget {
  const HomeTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == selected,
                label: labels[i],
                excludeSemantics: true,
                onTap: () => onSelect(i),
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Center(
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sans(
                            size: 15,
                            color: i == selected
                                ? AppColors.ink
                                : AppColors.grey,
                            weight: i == selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (i == selected)
                        Container(
                          width: 56,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.moss600,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The search field (Figma "Search field"): white, 44 px high, 4 px corners.
/// It filters the list as the user types.
class HomeSearchField extends StatelessWidget {
  const HomeSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Row(
          children: [
            svgIcon('search.svg', size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                textInputAction: TextInputAction.search,
                maxLines: 1,
                style: AppText.sans(size: 15, color: AppColors.ink),
                cursorColor: AppColors.moss600,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: AppText.sans(size: 15, color: AppColors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The round filter button and the sector chips (Figma "Filters").
class HomeFilters extends StatelessWidget {
  const HomeFilters({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cream,
      height: 52,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Center(child: svgIcon('filter.svg', size: 18)),
            ),
            for (var i = 0; i < labels.length; i++) ...[
              const SizedBox(width: 8),
              _Chip(
                label: labels[i],
                selected: i == selected,
                onTap: () => onSelect(i),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 36,
          padding: EdgeInsets.only(left: selected ? 10 : 14, right: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.moss100 : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.moss600 : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.moss600,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                maxLines: 1,
                style: AppText.sans(
                  size: 14,
                  color: selected ? AppColors.moss600 : AppColors.ink,
                  weight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small shared bits
// ---------------------------------------------------------------------------

/// Outline bookmark. Bookmarks aren't built yet, so it is a visual
/// placeholder only: no tap, no ripple, no feedback.
class BookmarkIcon extends StatelessWidget {
  const BookmarkIcon({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return PlaceholderIcon(
      feature: PlaceholderFeature.bookmarks,
      size: 24,
      child: Icon(
        Icons.bookmark_border_rounded,
        size: size,
        color: AppColors.ink,
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(
    this.initials, {
    this.size = 44,
    this.circle = false,
    this.gold = false,
  });

  final String initials;
  final double size;
  final bool circle;

  /// Support systems use the gold tint.
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: gold ? AppColors.tagGoldFill : AppColors.moss100,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * 0.27),
      ),
      child: Text(
        initials,
        maxLines: 1,
        style: AppText.sans(
          size: size >= 44 ? 15 : 14,
          color: gold ? AppColors.tagGoldText : AppColors.moss600,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// "HealthTech · [pin] Riyadh": the grey subtitle under a name. Both parts
/// shrink with an ellipsis instead of overflowing.
class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.text, required this.city, this.size = 13});

  final String text;
  final String city;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = AppText.sans(size: size, color: AppColors.grey);
    return Row(
      children: [
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        Text(' · ', style: style),
        svgIcon('pin.svg', size: size),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

/// A grey 12 px label and its value, e.g. "Stage   Pre-seed".
class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {required this.gold});

  final String label;
  final String value;

  /// Stage and Type values are dark gold; the rest are green.
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(size: 12, color: AppColors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(
              size: 13,
              color: gold ? AppColors.tagGoldText : AppColors.moss600,
              weight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// A 38 px button. [filled] is the green primary style, otherwise the white
/// outlined one. With a null [onTap] it is an inert placeholder: same look,
/// but no tap, ripple or feedback.
class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.filled, this.onTap});

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(8);
    final content = Container(
      height: 38,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: filled ? AppColors.moss600 : AppColors.surface,
        borderRadius: shape,
        border: filled ? null : Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.sans(
          size: 14,
          color: filled ? Colors.white : AppColors.ink,
          weight: FontWeight.w600,
        ),
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: shape,
      child: InkWell(borderRadius: shape, onTap: onTap, child: content),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppColors.border),
);

/// The one card shared by Explore, Matches, Hub and Support Systems (Figma
/// "Card"): header (avatar, name, subtitle, bookmark), then either a
/// description or the match bar, the label/value rows and two buttons.
class _BrowseCard extends StatelessWidget {
  const _BrowseCard({
    required this.avatar,
    required this.name,
    required this.subtitle,
    required this.city,
    required this.facts,
    required this.secondaryLabel,
    required this.primaryLabel,
    this.description,
    this.matchPercent,
    this.matchReason,
    this.showBookmark = true,
    this.onSecondary,
    this.onPrimary,
  });

  final Widget avatar;
  final String name;
  final String subtitle;
  final String city;
  final String? description;
  final int? matchPercent;
  final String? matchReason;
  final List<Widget> facts;
  final bool showBookmark;
  final String secondaryLabel;
  final String primaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    final text = description?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        size: 16,
                        color: AppColors.ink,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _Subtitle(text: subtitle, city: city),
                  ],
                ),
              ),
              if (showBookmark) ...[
                const SizedBox(width: 8),
                const BookmarkIcon(),
              ],
            ],
          ),
          if (matchPercent != null) ...[
            const SizedBox(height: 12),
            _MatchBar(reason: matchReason, percent: matchPercent!),
          ] else if (text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              text,
              style: AppText.sans(size: 14, color: AppColors.ink, height: 19),
            ),
          ],
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var i = 0; i < facts.length; i++) ...[
              if (i > 0) const SizedBox(height: 6),
              facts[i],
            ],
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: secondaryLabel,
                  filled: false,
                  onTap: onSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CardButton(
                  label: primaryLabel,
                  filled: true,
                  onTap: onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Startup and investor cards
// ---------------------------------------------------------------------------

/// A startup (investor's For You / Hub / Matches, guest's Hub): "View profile"
/// and the inert "Send request" ("Express interest" for a guest).
///
/// With a match percentage it shows the match bar instead of the description.
class StartupBrowseCard extends StatelessWidget {
  const StartupBrowseCard({
    super.key,
    required this.listing,
    required this.onViewProfile,
    this.isGuest = false,
  });

  final StartupListing listing;
  final VoidCallback onViewProfile;

  /// A guest "expresses interest" and has no bookmark.
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final stage = listing.stageLabel;
    final needs = listing.needsLabel;
    return _BrowseCard(
      avatar: _Avatar(listing.initials),
      name: listing.name,
      subtitle: listing.sectorLabel,
      city: listing.city,
      description: listing.tagline,
      matchPercent: listing.matchPercent,
      matchReason: listing.matchReason,
      facts: [
        if (stage.isNotEmpty)
          _Fact(ExploreStrings.stageLabel, stage, gold: true),
        if (needs.isNotEmpty)
          _Fact(ExploreStrings.needsLabel, needs, gold: false),
      ],
      showBookmark: !isGuest,
      secondaryLabel: ExploreStrings.viewProfile,
      onSecondary: onViewProfile,
      primaryLabel: isGuest
          ? ExploreStrings.expressInterest
          : ExploreStrings.sendRequest,
    );
  }
}

/// An investor (founder's For You / Hub / Matches).
class InvestorBrowseCard extends StatelessWidget {
  const InvestorBrowseCard({
    super.key,
    required this.investor,
    required this.onViewProfile,
  });

  final InvestorProfile investor;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return _BrowseCard(
      avatar: _Avatar(investor.initials, circle: true),
      name: investor.name,
      subtitle: investor.title,
      city: investor.city,
      description: investor.about,
      matchPercent: investor.matchPercent,
      matchReason: investor.matchReason,
      facts: [
        _Fact(ExploreStrings.stageLabel, investor.stageRange, gold: true),
        _Fact(
          ExploreStrings.sectorsLabel,
          investor.sectors.join(', '),
          gold: false,
        ),
      ],
      secondaryLabel: ExploreStrings.viewProfile,
      onSecondary: onViewProfile,
      primaryLabel: ExploreStrings.sendRequest,
    );
  }
}

/// A support system (accelerator, incubator, studio, angel network): "View
/// details" opens its page. "Website" is for show only (design phase): it
/// looks like a button but does nothing.
class SupportSystemCard extends StatelessWidget {
  const SupportSystemCard({
    super.key,
    required this.program,
    required this.onViewDetails,
    this.showBookmark = true,
  });

  final Program program;
  final VoidCallback onViewDetails;

  /// False for a guest (startup seeker), who has no bookmarks.
  final bool showBookmark;

  @override
  Widget build(BuildContext context) {
    return _BrowseCard(
      avatar: _Avatar(program.initial, gold: true),
      name: program.name,
      subtitle: program.type.label,
      city: program.city,
      description: program.cardSummary,
      facts: [
        _Fact(ExploreStrings.typeLabel, program.type.label, gold: true),
        _Fact(ExploreStrings.focusLabel, program.cardFocus, gold: false),
      ],
      showBookmark: showBookmark,
      secondaryLabel: ExploreStrings.website,
      // Inert: no navigation, no ripple, no feedback.
      onSecondary: null,
      primaryLabel: ExploreStrings.viewDetails,
      onPrimary: onViewDetails,
    );
  }
}

/// A ranked card on the Trending tab (Figma "40t"): the rank, then a compact
/// card with the logo, name, "Sector · City", the bookmark and a
/// "Pre-seed · Funding" line. Tapping the card opens the startup.
class TrendingCard extends StatelessWidget {
  const TrendingCard({
    super.key,
    required this.rank,
    required this.listing,
    required this.onTap,
    this.showBookmark = true,
  });

  final int rank;
  final StartupListing listing;
  final VoidCallback onTap;
  final bool showBookmark;

  @override
  Widget build(BuildContext context) {
    final stage = listing.stageLabel;
    final needs = listing.needsNames;
    final shape = BorderRadius.circular(12);
    final dot = AppText.sans(size: 12, color: AppColors.grey);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 30,
          child: Text(
            '$rank',
            maxLines: 1,
            style: AppText.sans(
              size: 22,
              color: rank <= 3 ? AppColors.gold : AppColors.grey,
              weight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: _cardDecoration(),
            child: Stack(
              children: [
                // The card area that opens the startup; the bookmark sits
                // outside it, so tapping the bookmark does nothing.
                Padding(
                  padding: EdgeInsets.only(right: showBookmark ? 40 : 0),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: shape,
                    child: InkWell(
                      borderRadius: shape,
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _Avatar(listing.initials, size: 38),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listing.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.sans(
                                          size: 15,
                                          color: AppColors.ink,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      _Subtitle(
                                        text: listing.sectorLabel,
                                        city: listing.city,
                                        size: 12,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (stage.isNotEmpty || needs.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (stage.isNotEmpty)
                                    Text(
                                      stage,
                                      maxLines: 1,
                                      style: AppText.sans(
                                        size: 12,
                                        color: AppColors.tagGoldText,
                                        weight: FontWeight.w600,
                                      ),
                                    ),
                                  if (stage.isNotEmpty && needs.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text('·', style: dot),
                                    ),
                                  if (needs.isNotEmpty)
                                    Flexible(
                                      child: Text(
                                        needs,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.sans(
                                          size: 12,
                                          color: AppColors.moss600,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (showBookmark)
                  const Positioned(top: 21, right: 12, child: BookmarkIcon()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// "Based on your investment criteria" with the green "Edit" link, above an
/// investor's Matches list.
class MatchContextLine extends StatelessWidget {
  const MatchContextLine({super.key, required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              ExploreStrings.basedOnCriteria,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(size: 14, color: AppColors.grey),
            ),
          ),
          Semantics(
            button: true,
            label: ExploreStrings.edit,
            excludeSemantics: true,
            onTap: onEdit,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.moss600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ExploreStrings.edit,
                      style: AppText.sans(
                        size: 14,
                        color: AppColors.moss600,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "92% match  Same sector and stage" on Matches cards. The reason is cut
/// with an ellipsis on a narrow screen.
class _MatchBar extends StatelessWidget {
  const _MatchBar({required this.reason, required this.percent});

  final String? reason;
  final int percent;

  String get _text {
    var text = reason ?? '';
    if (text.toLowerCase().startsWith('why:')) text = text.substring(4).trim();
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.moss100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 15,
            color: AppColors.moss600,
          ),
          const SizedBox(width: 8),
          Text(
            ExploreStrings.matchPercent(percent),
            maxLines: 1,
            style: AppText.sans(
              size: 13,
              color: AppColors.moss600,
              weight: FontWeight.w700,
            ),
          ),
          if (_text.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(size: 13, color: AppColors.moss600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
