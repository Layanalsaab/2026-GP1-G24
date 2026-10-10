import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/explore_strings.dart';
import '../../../app_constants/seeker_strings.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/common_widgets/listing_card_parts.dart';
import '../../../shared_ui/common_widgets/search_filter_widgets.dart';
import '../../../shared_ui/common_widgets/seeker_exit_button.dart';
import '../../../shared_ui/common_widgets/startup_card.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/explore_view_model.dart';
import 'seeker_startup_profile_screen.dart';

/// Figma "V2 · 11 · Explore — Seeker": the startup seeker's main tab, a ranked
/// list of trending startups. Startup seekers have no account.
///
/// Design phase: the list is sample data, the buttons that need a backend do
/// nothing, and only the first card opens a profile.
class SeekerExploreScreen extends StatefulWidget {
  const SeekerExploreScreen({super.key});

  @override
  State<SeekerExploreScreen> createState() => _SeekerExploreScreenState();
}

class _SeekerExploreScreenState extends State<SeekerExploreScreen> {
  final _viewModel = ExploreViewModel.seeker();

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
            final entries = _viewModel.entries;
            return Column(
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
                  // Design only: notifications aren't built yet.
                  actions: [svgIcon('bell.svg', size: 44), const SeekerExitButton()],
                ),
                FilterChipsRow(
                  labels: ExploreStrings.filters,
                  selected: _viewModel.filterIndex,
                  onSelect: _viewModel.selectFilter,
                  showFilterButton: true,
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final listing = entry.startup!;
                      return Row(
                        children: [
                          SizedBox(
                            width: 18,
                            child: Text(
                              '${entry.rank}',
                              textAlign: TextAlign.center,
                              style: AppText.serif(
                                size: 26,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StartupCard(
                              listing: listing,
                              style: ListingStyle.seeker,
                              actionLabel: SeekerStrings.expressInterest,
                              // Only the first card leads to a profile.
                              onViewProfile: index == 0
                                  ? () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              SeekerStartupProfileScreen(
                                            listing: listing,
                                          ),
                                        ),
                                      )
                                  : null,
                            ),
                          ),
                        ],
                      );
                    },
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
