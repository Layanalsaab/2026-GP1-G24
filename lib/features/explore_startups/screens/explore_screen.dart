import 'package:flutter/material.dart';

import '../../../app_constants/home_strings.dart';
import '../../../models/latest_range.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../models/home_item.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/widgets/forms/app_field.dart';
import '../../../shared_ui/widgets/lists/empty_state.dart';
import '../../../shared_ui/widgets/lists/section_header.dart';
import '../../../shared_ui/widgets/lists/segmented_switch.dart';
import '../../../shared_ui/widgets/overlays/app_dropdown.dart';
import '../../search/screens/hub_screen.dart';
import '../../search/view_models/home_view_model.dart';
import '../../search/widgets/home_layout.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

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

  /// The section heading (.shd2: margin 4 2 -2, or 4 2 0 with a dropdown).
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

  List<HomeSlot> _latest(HomeViewModel vm) {
    final items = vm.latest;
    final investors = vm.latestSwitch == 1;
    return [
      _switch('latest', vm.latestSwitch, vm.setLatestSwitch),
      _heading(
        SectionHeader(
          title: investors
              ? HomeStrings.newestInvestors
              : HomeStrings.newestStartups,
          trailing: RangeDropdown(
            options: [for (final r in LatestRange.values) r.label],
            selectedIndex: vm.latestRange.index,
            onSelected: vm.setLatestRange,
          ),
        ),
        bottom: 0,
      ),
      if (items.isEmpty)
        HomeSlot(
          EmptyState(
            title: investors
                ? HomeStrings.noNewInvestorsTitle
                : HomeStrings.noNewStartupsTitle,
            message: investors
                ? HomeStrings.noNewInvestorsMessage
                : HomeStrings.noNewStartupsMessage,
            icon: AppIcons.target,
          ),
        )
      else
        cardsSlot(items, scope: vm.paneKey),
    ];
  }

  /// For You: the recommended list only.
  List<HomeSlot> _forYou(BuildContext context, HomeViewModel vm) => [
    _heading(
      _InfoHeading(title: vm.recommendedTitle, info: vm.recommendedInfo),
      bottom: 0,
    ),
    cardsSlot(
      vm.recommended,
      showMatch: true,
      scope: vm.paneKey,
      onNotInterested: (item) => _hide(context, vm, item),
    ),
  ];

  /// The ✕: the card leaves For You at once; the message offers Undo (only
  /// the latest hide can be undone, so a new message replaces the old one).
  /// It goes away on its own after the usual 4 seconds.
  void _hide(BuildContext context, HomeViewModel vm, HomeItem item) {
    vm.hideForYou(item);
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        // A SnackBar with an action stays until dismissed unless told not to.
        persist: false,
        backgroundColor: AppColors.toastFill,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(HomeStrings.hiddenFromForYou, style: AppText.toast),
        action: SnackBarAction(
          label: HomeStrings.undo,
          textColor: AppColors.gold,
          onPressed: () => vm.undoHideForYou(item),
        ),
      ),
    );
  }

  List<HomeSlot> get _trending => const [
    HomeSlot(
      EmptyState(
        title: HomeStrings.noTrendingTitle,
        message: HomeStrings.noTrendingMessage,
      ),
    ),
  ];

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
          slots = _trending;
        default:
          slots = _forYou(context, vm);
      }
    }
    return HomeColumn(slots: slots);
  }
}

class _InfoHeading extends StatefulWidget {
  const _InfoHeading({required this.title, this.info});

  final String title;

  /// The tip behind the (i) button; null shows no button.
  final String? info;

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
