import 'package:flutter/material.dart';

import '../../../app_constants/explore_strings.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/home_parts.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../../../data_access/mock_data/mock_startups.dart';
import '../../explore_startups/screens/seeker_startup_profile_screen.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import '../../startups/screens/startup_profile_screen.dart';
import '../view_models/hub_view_model.dart';

/// Figma "V2 · 39 / 39b / 39c · Hub" (Founder, Investor, Guest): search,
/// sector chips and a list to browse. A founder browses investors; an
/// investor or guest browses startups.
///
/// Design phase: the list is sample data. Search and the chips filter it.
class HubScreen extends StatefulWidget {
  const HubScreen({
    super.key,
    required this.role,
    required this.topBar,
    this.isSeeker = false,
  });

  final AccountRole role;

  /// The shell's top bar (avatar, logo, bell).
  final Widget topBar;

  /// A guest's Hub: the same startups, with "Express interest" instead of
  /// "Send request", opening the guest's startup profile.
  final bool isSeeker;

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  late final HubViewModel _viewModel = HubViewModel(role: widget.role);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _open(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cream,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final investors = _viewModel.investors;
          final startups = _viewModel.startups;
          final empty = investors.isEmpty && startups.isEmpty;
          return Column(
            children: [
              widget.topBar,
              HomeSearchField(
                hint: _viewModel.isFounder
                    ? ExploreStrings.searchInvestors
                    : ExploreStrings.searchStartups,
                onChanged: _viewModel.setQuery,
              ),
              HomeFilters(
                labels: ExploreStrings.filters,
                selected: _viewModel.filterIndex,
                onSelect: _viewModel.selectFilter,
              ),
              Expanded(
                child: empty
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
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        children: [
                          for (final investor in investors) ...[
                            InvestorBrowseCard(
                              investor: investor,
                              onViewProfile: () => _open(
                                InvestorProfileScreen(investor: investor),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          for (final listing in startups) ...[
                            StartupBrowseCard(
                              listing: listing,
                              isGuest: widget.isSeeker,
                              onViewProfile: () => _open(
                                widget.isSeeker
                                    ? SeekerStartupProfileScreen(
                                        listing: listing,
                                        founderName: MockStartups.founderNameOf(
                                          listing.startup,
                                        ),
                                      )
                                    : StartupProfileScreen(
                                        startup: listing.startup,
                                        founderName: MockStartups.founderNameOf(
                                          listing.startup,
                                        ),
                                        associations: listing.associations,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
