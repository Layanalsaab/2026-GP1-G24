import 'package:flutter/material.dart';

import '../../search/screens/hub_screen.dart';
import '../../search/view_models/home_view_model.dart';
import '../../search/widgets/home_layout.dart';
import '../../../app_constants/home_strings.dart';
import '../../../shared_ui/widgets/lists/empty_state.dart';

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
    // No support channels exist yet: say so (no filter row, no "Clear all").
    if (vm.noSupportChannels) {
      return const HomeColumn(
        slots: [
          HomeSlot(
            EmptyState(
              title: HomeStrings.noSupportTitle,
              message: HomeStrings.noSupportMessage,
            ),
          ),
        ],
      );
    }
    final cards = vm.programCards;
    return HomeColumn(
      slots: [
        if (vm.filtering)
          HomeSlot(
            homeResultsRow(vm, HomeStrings.resultCount(cards.length)),
            bottom: -2,
          ),
        if (cards.isNotEmpty) cardsSlot(cards, scope: vm.paneKey),
        if (cards.isEmpty) HomeSlot(homeNoResults(vm)),
      ],
    );
  }
}
