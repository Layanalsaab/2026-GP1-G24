import 'package:flutter/material.dart';

import '../../../app_constants/home_strings.dart';
import '../../../data_access/repositories/interaction_repository.dart';
import '../../../models/latest_range.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/lists/empty_state.dart';
import '../../../shared_ui/widgets/lists/section_header.dart';
import '../../../shared_ui/widgets/lists/segmented_switch.dart';
import '../../../shared_ui/widgets/overlays/app_dropdown.dart';
import '../../search/screens/hub_screen.dart';
import '../../search/view_models/home_view_model.dart';
import '../../search/widgets/home_layout.dart';

/// The Explore page: Latest, Trending and For You (the sub-tabs live in the
/// shell's header; guests only get Trending). Searching or filtering on any
/// sub-tab turns it into the results view. Rendered inside the shell's scroll
/// view.
///
/// There is no Matches tab: matching lives inside each ticket of the
/// Investment Wallet and inside each open round of a startup.
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

  /// Latest: "Newest startups" with the time range, each card with its
  /// "Joined 2 days ago" line.
  List<HomeSlot> _latest(HomeViewModel vm) {
    final items = vm.latest;
    return [
      _heading(
        SectionHeader(
          title: HomeStrings.newestStartups,
          trailing: RangeDropdown(
            options: [for (final r in LatestRange.values) r.label],
            selectedIndex: vm.latestRange.index,
            onSelected: vm.setLatestRange,
          ),
        ),
        bottom: 0,
      ),
      if (items.isEmpty)
        const HomeSlot(
          EmptyState(
            title: HomeStrings.noNewStartupsTitle,
            message: HomeStrings.noNewStartupsMessage,
            icon: AppIcons.target,
          ),
        )
      else
        cardsSlot(items, scope: vm.paneKey),
    ];
  }

  /// For You: the recommended list only. An investor sees startups, a founder
  /// investors. The match percentage shows only on a card that has one.
  List<HomeSlot> _forYou(HomeViewModel vm) => [
    _heading(
      _InfoHeading(title: vm.recommendedTitle, info: vm.recommendedInfo),
      bottom: 0,
    ),
    cardsSlot(vm.recommended, showMatch: true, scope: vm.paneKey),
  ];

  /// Trending: "Top 30 trending" with the range, each card with its rank
  /// ("#1"). No analytics are shown (no growth, no view counts).
  List<HomeSlot> _trending(HomeViewModel vm) {
    final items = vm.trending;
    return [
      _switch('trending', vm.trendingSwitch, vm.setTrendingSwitch),
      _heading(
        _InfoHeading(
          title: HomeStrings.top30,
          trailing: RangeDropdown(
            options: [for (final r in TrendingRange.values) r.label],
            selectedIndex: vm.range.index,
            onSelected: vm.setRange,
          ),
        ),
        bottom: 0,
      ),
      cardsSlot(items, scope: '${vm.paneKey}|${vm.range.name}'),
      if (vm.isGuest) HomeSlot(GuestJoinCard(onSignUp: onSignUp)),
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
          slots = _latest(vm);
        case 1:
          slots = _trending(vm);
        default:
          slots = _forYou(vm);
      }
    }
    return HomeColumn(slots: slots);
  }
}

/// A section heading with an (i) button after the title that opens a tip
/// under it, and an optional [trailing] widget (the range dropdown).
class _InfoHeading extends StatefulWidget {
  const _InfoHeading({required this.title, this.info, this.trailing});

  final String title;

  /// The tip behind the (i) button; null shows no button.
  final String? info;
  final Widget? trailing;

  @override
  State<_InfoHeading> createState() => _InfoHeadingState();
}

class _InfoHeadingState extends State<_InfoHeading> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(widget.title, style: AppText.sectionTitle),
                ),
              ),
              if (widget.info != null) ...[
                const SizedBox(width: 2),
                InfoButton(
                  open: _open,
                  semanticLabel: 'About this list',
                  onTap: () => setState(() => _open = !_open),
                ),
              ],
              if (widget.trailing != null) ...[
                const Spacer(),
                widget.trailing!,
              ],
            ],
          ),
        ),
        if (_open && widget.info != null) ...[
          const SizedBox(height: 6),
          InfoTip(widget.info!),
        ],
      ],
    );
  }
}
