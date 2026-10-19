import 'package:flutter/material.dart';

import '../../../app_constants/home_strings.dart';
import '../../../shared_ui/widgets/lists/results_row.dart';
import '../../../shared_ui/widgets/lists/segmented_switch.dart';
import '../view_models/home_view_model.dart';
import '../widgets/home_layout.dart';

/// Results row for the current search text and filters (shared by the pages).
ResultsRow homeResultsRow(HomeViewModel vm, String title) => ResultsRow(
  title: title,
  onClearAll: vm.clearAll,
  chips: [
    for (final c in vm.chips)
      ResultChip(
        label: c.isQuery ? '“${c.label}”' : c.label,
        quoted: c.isQuery,
        onRemove: c.onRemove,
      ),
  ],
);

/// The Hub page (Figma 20-20e, 26, 27): the Startups | Investors switch and the
/// cards of the selected side. While searching or filtering a results row
/// ("N results" + removable chips) shows above the cards; nothing found shows
/// the "No matches" state. Rendered inside the shell's scroll view.
class HubScreen extends StatelessWidget {
  const HubScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final cards = vm.hubCards;
    return KeyedSubtree(
      key: ValueKey(vm.paneKey),
      child: HomeColumn(
        slots: [
          if (vm.filtering)
            HomeSlot(
              homeResultsRow(vm, HomeStrings.resultCount(cards.length)),
              bottom: -2,
            ),
          HomeSlot(
            SegmentedSwitch(
              labels: HomeStrings.switchLabels,
              selectedIndex: vm.hubSwitch,
              onChanged: vm.setHubSwitch,
            ),
            top: 2,
          ),
          if (cards.isNotEmpty) cardsSlot(cards),
          if (cards.isEmpty) HomeSlot(homeEmptyState(vm)),
        ],
      ),
    );
  }
}
