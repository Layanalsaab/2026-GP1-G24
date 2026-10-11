import 'package:flutter/material.dart';

import '../../../app_constants/explore_strings.dart';
import '../../../data_access/mock_data/mock_startups.dart';
import '../../../models/app_user.dart';
import '../../../shared_ui/common_widgets/home_parts.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../../profiles/screens/investor_profile_screen.dart';
import '../../profiles/screens/edit_criteria_screen.dart';
import '../../startups/screens/startup_profile_screen.dart';
import '../view_models/explore_view_model.dart';
import 'seeker_startup_profile_screen.dart';

/// Figma "V2 · 40 / 40b / 40c · Explore" (Founder, Investor, Guest), with the
/// For You, Trending and Matches tabs.
///
/// Design phase: the lists are sample data. Search and the sector chips
/// filter them. A guest (startup seeker) has only the Trending list.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({
    super.key,
    required this.role,
    required this.topBar,
    this.isGuest = false,
    this.user,
  });

  final AccountRole role;

  /// The signed-in user; needed to edit the investor's criteria from Matches.
  final AppUser? user;

  /// The shell's top bar (avatar, logo, bell).
  final Widget topBar;
  final bool isGuest;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final ExploreViewModel _viewModel = widget.isGuest
      ? ExploreViewModel.seeker()
      : ExploreViewModel(role: widget.role);

  /// Which of the founder's startups the Matches tab is "for".
  late String _matchesFor = MockStartups.forYou.first.name;

  static const _tabs = [
    ExploreTab.forYou,
    ExploreTab.trending,
    ExploreTab.matches,
  ];

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _open(ExploreEntry entry) {
    final Widget page;
    if (entry.investor != null) {
      page = InvestorProfileScreen(investor: entry.investor!);
    } else if (widget.isGuest) {
      page = SeekerStartupProfileScreen(
        listing: entry.startup!,
        founderName: MockStartups.founderNameOf(entry.startup!.startup),
      );
    } else {
      page = StartupProfileScreen(
        startup: entry.startup!.startup,
        founderName: MockStartups.founderNameOf(entry.startup!.startup),
        associations: entry.startup!.associations,
      );
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.cream,
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          final entries = _viewModel.entries;
          final trending = _viewModel.tab == ExploreTab.trending;
          return Column(
            children: [
              widget.topBar,
              if (widget.isGuest)
                HomeTabs(
                  labels: const [ExploreStrings.tabTrending],
                  selected: 0,
                  onSelect: (_) {},
                )
              else ...[
                HomeTabs(
                  labels: const [
                    ExploreStrings.tabForYou,
                    ExploreStrings.tabTrending,
                    ExploreStrings.tabMatches,
                  ],
                  selected: _tabs.indexOf(_viewModel.tab),
                  onSelect: (i) => _viewModel.selectTab(_tabs[i]),
                ),
                if (_viewModel.tab == ExploreTab.forYou)
                  HomeSearchField(
                    hint: _viewModel.isFounder
                        ? ExploreStrings.searchInvestors
                        : ExploreStrings.searchStartups,
                    onChanged: _viewModel.setQuery,
                  )
                else if (_viewModel.tab == ExploreTab.matches)
                  if (_viewModel.isFounder)
                    _matchesFor_()
                  else
                    MatchContextLine(onEdit: _editCriteria),
              ],
              // Figma: Matches has no sector chips.
              if (_viewModel.tab != ExploreTab.matches)
                HomeFilters(
                  labels: ExploreStrings.filters,
                  selected: _viewModel.filterIndex,
                  onSelect: _viewModel.selectFilter,
                ),
              Expanded(
                child: entries.isEmpty
                    ? const _EmptyList()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        children: [
                          for (final entry in entries) ...[
                            if (trending)
                              TrendingCard(
                                rank: entry.rank ?? 0,
                                listing: entry.startup!,
                                showBookmark: !widget.isGuest,
                                onTap: () => _open(entry),
                              )
                            else
                              _card(entry),
                            const SizedBox(height: 8),
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

  Widget _card(ExploreEntry entry) {
    final investor = entry.investor;
    if (investor != null) {
      return InvestorBrowseCard(
        investor: investor,
        onViewProfile: () => _open(entry),
      );
    }
    return StartupBrowseCard(
      listing: entry.startup!,
      isGuest: widget.isGuest,
      onViewProfile: () => _open(entry),
    );
  }

  /// Opens the investor's criteria editor (Matches > Edit).
  void _editCriteria() {
    final user = widget.user;
    if (user == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EditCriteriaScreen(user: user)));
  }

  /// "Matches for [Rafeeq Health v]": the founder picks which of their
  /// startups the investor matches are for.
  // ignore: non_constant_identifier_names
  Widget _matchesFor_() {
    final names = [for (final s in MockStartups.forYou) s.name];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Flexible(
            flex: 1,
            child: Text(
              ExploreStrings.matchesFor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(size: 14, color: AppColors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: PopupMenuButton<String>(
              onSelected: (name) => setState(() => _matchesFor = name),
              position: PopupMenuPosition.under,
              color: AppColors.surface,
              itemBuilder: (_) => [
                for (final name in names)
                  PopupMenuItem(value: name, child: Text(name)),
              ],
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _matchesFor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.sans(
                          size: 14,
                          color: AppColors.ink,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.ink,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'No results match your search.',
          textAlign: TextAlign.center,
          style: AppText.bodyMuted,
        ),
      ),
    );
  }
}
