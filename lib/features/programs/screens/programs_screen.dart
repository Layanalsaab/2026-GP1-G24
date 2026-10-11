import 'package:flutter/material.dart';

import '../../../app_constants/program_strings.dart';
import '../../../shared_ui/common_widgets/home_parts.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/programs_view_model.dart';
import 'program_profile_screen.dart';

/// Figma "V2 · 38 / 38b / 38c · Support Systems": accelerators, incubators
/// and studios, with search and category chips.
///
/// Design phase: the list is sample data. Search and the chips filter it.
class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key, required this.topBar, this.isGuest = false});

  /// The shell's top bar (avatar, logo, bell).
  final Widget topBar;

  /// A guest (startup seeker) has no bookmarks.
  final bool isGuest;

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  final _viewModel = ProgramsViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cream,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final programs = _viewModel.programs;
          return Column(
            children: [
              widget.topBar,
              HomeSearchField(
                hint: ProgramStrings.searchHint,
                onChanged: _viewModel.setQuery,
              ),
              HomeFilters(
                labels: _viewModel.filters,
                selected: _viewModel.filterIndex,
                onSelect: _viewModel.selectFilter,
              ),
              Expanded(
                child: programs.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No results match your search.',
                            textAlign: TextAlign.center,
                            style: AppText.bodyMuted,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: programs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) => SupportSystemCard(
                          program: programs[i],
                          showBookmark: !widget.isGuest,
                          onViewDetails: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProgramProfileScreen(program: programs[i]),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
