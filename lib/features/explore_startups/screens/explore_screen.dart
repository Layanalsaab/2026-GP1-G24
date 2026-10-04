import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/explore_strings.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/investor_card.dart';
import '../../../shared_ui/common_widgets/listing_card_parts.dart';
import '../../../shared_ui/common_widgets/search_filter_widgets.dart';
import '../../../shared_ui/common_widgets/startup_card.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import '../../startups/screens/startup_profile_screen.dart';
import '../view_models/explore_view_model.dart';

/// Figma "V2 · 09b / 10 · Explore" (with the Trending and Matches tabs).
///
/// Design phase: the lists are sample data, buttons that need a backend do
/// nothing, and only the first card of each list opens a profile.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.role});

  final AccountRole role;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final ExploreViewModel _viewModel = ExploreViewModel(role: widget.role);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _open(ExploreEntry entry) {
    final Widget page = entry.startup != null
        ? StartupProfileScreen(startup: entry.startup!.startup)
        : InvestorProfileScreen(investor: entry.investor!);
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final entries = _viewModel.entries;
            return Stack(
              children: [
                Column(
                  children: [
                    GreenTopBar(
                      title: ExploreStrings.exploreTitle,
                      titleStyle: AppText.serif(
                        size: 22,
                        color: AppColors.onDark,
                        height: 28,
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 30,
                          height: 28.5,
                          fit: BoxFit.cover,
                        ),
                      ),
                      actions: [
                        // Design only: bookmarks and notifications aren't built yet.
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(child: svgIcon('bookmark_white.svg', size: 22)),
                        ),
                        svgIcon('bell.svg', size: 44),
                      ],
                    ),
                    _Tabs(
                      selected: _viewModel.tab,
                      onSelect: _viewModel.selectTab,
                    ),
                    FilterChipsRow(
                      labels: ExploreStrings.filters,
                      selected: _viewModel.filterIndex,
                      onSelect: _viewModel.selectFilter,
                      showFilterButton: true,
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _row(entries[index], index),
                      ),
                    ),
                  ],
                ),
                if (_viewModel.isFounder) const _GeminiBubble(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(ExploreEntry entry, int index) {
    // Only the first card in each list leads to a profile.
    final onOpen = index == 0 ? () => _open(entry) : null;
    final style = _viewModel.tab == ExploreTab.matches
        ? ListingStyle.match
        : ListingStyle.explore;
    final card = entry.startup != null
        ? StartupCard(listing: entry.startup!, style: style, onViewProfile: onOpen)
        : InvestorCard(investor: entry.investor!, style: style, onViewProfile: onOpen);

    if (entry.rank == null) return card;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: AppText.serif(size: 22, color: AppColors.gold, height: 28),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: card),
      ],
    );
  }
}

/// "For You / Trending / Matches" on the green header.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.selected, required this.onSelect});

  final ExploreTab selected;
  final ValueChanged<ExploreTab> onSelect;

  static const _items = [
    (tab: ExploreTab.forYou, label: ExploreStrings.tabForYou),
    (tab: ExploreTab.trending, label: ExploreStrings.tabTrending),
    (tab: ExploreTab.matches, label: ExploreStrings.tabMatches),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.green,
      child: Row(
        children: [
          for (final item in _items)
            Expanded(
              child: InkWell(
                onTap: () => onSelect(item.tab),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 10),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: item.tab == selected ? 3 : 1,
                        decoration: BoxDecoration(
                          color: item.tab == selected
                              ? AppColors.gold
                              : const Color(0x1FFFFFFF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        style: AppText.sans(
                          size: 14,
                          color: item.tab == selected
                              ? AppColors.gold
                              : const Color(0xB8FFFFFF),
                          weight: item.tab == selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          height: 20,
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

/// The floating "Ask Gemini" button on a founder's Explore. Design only.
class _GeminiBubble extends StatelessWidget {
  const _GeminiBubble();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              ExploreStrings.askGemini,
              style: AppText.sans(
                size: 12,
                color: Colors.white,
                weight: FontWeight.w600,
                height: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.moss600,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x591F4026),
                  offset: Offset(0, 4),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Center(child: svgIcon('gemini_sparkle.svg', size: 24)),
          ),
        ],
      ),
    );
  }
}
