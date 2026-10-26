import 'package:flutter/material.dart';

import '../../../app_constants/home_strings.dart';
import '../../../app_constants/matching_strings.dart';
import '../../../data_access/repositories/interaction_repository.dart';
import '../../../models/home_item.dart';
import '../../../navigation/open_item.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/widgets/cards/home_card.dart';
import '../../../shared_ui/widgets/cards/trending.dart';
import '../../../shared_ui/widgets/lists/empty_state.dart';
import '../../../shared_ui/widgets/lists/section_header.dart';
import '../../../shared_ui/widgets/lists/segmented_switch.dart';
import '../../../shared_ui/widgets/overlays/app_dropdown.dart';
import '../../search/screens/hub_screen.dart';
import '../../search/view_models/home_view_model.dart';
import '../../search/widgets/home_layout.dart';

/// The Explore page (Figma 21-23, 26b-d, 27b): For You, Trending and Matches
/// (the sub-tabs live in the shell's header; guests only get Trending).
/// Searching or filtering on any sub-tab turns it into the results view.
/// Rendered inside the shell's scroll view.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({
    super.key,
    required this.viewModel,
    required this.onSignUp,
  });

  final HomeViewModel viewModel;

  /// Guest "Sign up" button of the Join Start.sa card.
  final VoidCallback onSignUp;

  HomeSlot _switch(String id, int selected, ValueChanged<int> onChanged) =>
      HomeSlot(
        SegmentedSwitch(
          key: ValueKey('switch-$id'),
          labels: HomeStrings.switchLabels,
          selectedIndex: selected,
          onChanged: onChanged,
        ),
        top: 2,
      );

  /// The section heading (`.shd2`: margin 4 2 -2, or 4 2 0 with a dropdown).
  HomeSlot _heading(Widget header, {double bottom = -2}) =>
      HomeSlot(header, top: 4, bottom: bottom);

  List<HomeSlot> _results(HomeViewModel vm) {
    final res = vm.exploreResults;
    return [
      HomeSlot(homeResultsRow(vm, HomeStrings.results), bottom: -2),
      _switch('results', vm.resultsSwitch, vm.setResultsSwitch),
      _heading(
        SectionHeader(title: HomeStrings.matchCount(res.length)),
        bottom: 0,
      ),
      if (res.isNotEmpty) cardsSlot(res, scope: vm.paneKey),
      if (res.isEmpty) HomeSlot(homeEmptyState(vm)),
    ];
  }

  List<HomeSlot> _forYou(HomeViewModel vm) {
    final newItems = vm.newItems;
    if (vm.showAllNew) {
      return [
        HomeSlot(
          Transform.translate(
            offset: const Offset(-6, 0),
            child: BackLink(
              label: HomeStrings.forYouBack,
              onTap: () => vm.setShowAllNew(false),
            ),
          ),
          top: -4,
          bottom: -4,
        ),
        _switch('for-you', vm.forYouSwitch, vm.setForYouSwitch),
        _heading(
          const SectionHeader(title: HomeStrings.newOnStartSa),
          bottom: 0,
        ),
        cardsSlot(newItems, scope: vm.paneKey),
      ];
    }
    return [
      _switch('for-you', vm.forYouSwitch, vm.setForYouSwitch),
      _heading(
        SectionHeader(
          title: HomeStrings.newOnStartSa,
          onSeeAll: () => vm.setShowAllNew(true),
        ),
        bottom: -8,
      ),
      HomeSlot(_NewRail(items: newItems), bleed: true),
      _heading(const SectionHeader(title: HomeStrings.recommended)),
      cardsSlot(vm.recommended, scope: vm.paneKey),
    ];
  }

  List<HomeSlot> _trending(BuildContext context, HomeViewModel vm) {
    final items = vm.trending;
    return [
      _switch('trending', vm.trendingSwitch, vm.setTrendingSwitch),
      _heading(
        SectionHeader(
          title: HomeStrings.top30,
          trailing: RangeDropdown(
            options: [for (final r in TrendingRange.values) r.label],
            selectedIndex: vm.range.index,
            onSelected: vm.setRange,
          ),
        ),
        bottom: 0,
      ),
      HomeSlot(
        TrendingBox(
          // A new ranking (another range or side) enters again.
          key: ValueKey(
            '${vm.paneKey}|${vm.range.name}|${contentSignature(items)}',
          ),
          children: [
            for (var i = 0; i < items.length; i++)
              TrendingRow(
                rank: i + 1,
                category: items[i].tag,
                name: items[i].name,
                kind: avatarKindOf(items[i].kind),
                onTap: () => openHomeItem(context, items[i]),
              ),
          ],
        ),
      ),
      HomeSlot(TrendingNote(vm.range.note), top: -2),
      if (vm.isGuest) HomeSlot(GuestJoinCard(onSignUp: onSignUp)),
    ];
  }

  List<HomeSlot> _matches(HomeViewModel vm) {
    final own = vm.ownStartups;
    return [
      if (vm.isFounder && own.isNotEmpty)
        HomeSlot(
          MatchesForDropdown(
            options: [
              for (final s in own)
                MatchesForOption(
                  name: s.name,
                  subtitle: '${s.sectorLabel} · ${s.stageLabel}',
                ),
            ],
            selectedIndex: vm.matchFor.clamp(0, own.length - 1),
            onSelected: vm.setMatchFor,
          ),
        ),
      ..._matchCards(vm),
    ];
  }

  /// The cards, or the loading / failed / empty state (data from Firestore).
  List<HomeSlot> _matchCards(HomeViewModel vm) {
    final items = vm.matches; // starts the load when needed
    if (items.isNotEmpty) {
      return [cardsSlot(items, showMatch: true, scope: vm.paneKey)];
    }
    if (vm.matchesLoading) {
      return const [
        HomeSlot(
          Padding(
            padding: EdgeInsets.only(top: 56),
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
          ),
        ),
      ];
    }
    if (vm.matchesFailed) {
      return [
        HomeSlot(
          EmptyState(
            title: MatchingStrings.loadFailed,
            message: MatchingStrings.loadFailedMessage,
            icon: AppIcons.warn,
            actionLabel: MatchingStrings.retry,
            onAction: vm.refreshMatches,
          ),
        ),
      ];
    }
    final String message;
    if (vm.isFounder) {
      message = vm.ownStartups.isEmpty
          ? MatchingStrings.noneFounderNoStartup
          : MatchingStrings.noneFounder;
    } else {
      message = vm.user?.investorCriteria == null
          ? MatchingStrings.noneInvestor
          : MatchingStrings.noneInvestorNoFit;
    }
    return [
      HomeSlot(
        EmptyState(
          title: MatchingStrings.noneTitle,
          message: message,
          icon: AppIcons.target,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final List<HomeSlot> slots;
    if (vm.filtering) {
      slots = _results(vm);
    } else {
      switch (vm.effectiveExploreTab) {
        case 0:
          slots = _forYou(vm);
        case 1:
          slots = _trending(context, vm);
        default:
          slots = _matches(vm);
      }
    }
    return HomeColumn(slots: slots);
  }
}

/// The "New on Start.sa" rail: snapping, full-bleed rail cards.
class _NewRail extends StatelessWidget {
  const _NewRail({required this.items});

  final List<HomeItem> items;

  @override
  Widget build(BuildContext context) {
    return SnapRail(
      children: [
        for (final it in items)
          RailCard(
            name: it.name,
            tag: it.tag,
            city: it.city,
            body: it.line,
            joined: it.joinedLabel ?? 'Joined this week',
            kind: avatarKindOf(it.kind),
            onTap: () => openHomeItem(context, it),
          ),
      ],
    );
  }
}
