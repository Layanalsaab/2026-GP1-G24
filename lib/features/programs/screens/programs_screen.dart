import 'package:flutter/material.dart';

import '../../../shared_ui/widgets/lists/empty_state.dart';
import '../../search/screens/hub_screen.dart';
import '../../search/view_models/home_view_model.dart';
import '../../search/widgets/home_layout.dart';
import '../../../app_constants/home_strings.dart';

/// The Support Channels page (Figma 24, 26e, 27c): program cards (tag = type)
/// filtered by the shell's search and advanced search (Type, Sector focus,
/// Program length, City, Sort by). No switch. Rendered inside the shell's
/// scroll view.
class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key, required this.viewModel});

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final vm = viewModel;
    final cards = vm.programCards;
    return KeyedSubtree(
      key: ValueKey(vm.paneKey),
      child: HomeColumn(
        slots: [
          if (vm.filtering)
            HomeSlot(
              homeResultsRow(vm, HomeStrings.resultCount(cards.length)),
              bottom: -2,
            ),
          if (cards.isNotEmpty) cardsSlot(cards),
          if (cards.isEmpty)
            HomeSlot(EmptyState.noMatches(onAction: vm.clearAll)),
        ],
      ),
    );
  }
}
