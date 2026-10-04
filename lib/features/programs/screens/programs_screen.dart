import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/program_strings.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/search_filter_widgets.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/programs_view_model.dart';
import '../widgets/program_card.dart';
import 'program_profile_screen.dart';

/// Figma "V2 · 16 · Programs — All".
///
/// Design phase: the list is sample data, the search box and category chips
/// are for show, and only the first program opens its page.
class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final programs = _viewModel.programs;
            return Column(
              children: [
                // A main tab has nowhere to go back to, so there is no back arrow.
                const GreenTopBar(title: ProgramStrings.programsTitle),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SearchBox(
                    hint: ProgramStrings.searchHint,
                    height: 44,
                    iconSize: 18,
                    fontSize: 14,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      Text(ProgramStrings.intro, style: AppText.bodyMuted),
                      const SizedBox(height: AppSpacing.md),
                      FilterChipsRow(
                        labels: ProgramStrings.filters,
                        selected: _viewModel.filterIndex,
                        onSelect: _viewModel.selectFilter,
                        padding: EdgeInsets.zero,
                      ),
                      for (var i = 0; i < programs.length; i++) ...[
                        const SizedBox(height: AppSpacing.md),
                        ProgramCard(
                          program: programs[i],
                          onTap: i == 0
                              ? () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProgramProfileScreen(
                                        program: programs[i],
                                      ),
                                    ),
                                  )
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
