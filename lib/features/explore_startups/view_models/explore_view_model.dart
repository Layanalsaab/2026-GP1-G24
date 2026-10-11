import 'package:flutter/foundation.dart';

import '../../../app_constants/explore_strings.dart';
import '../../../data_access/mock_data/mock_investors.dart';
import '../../../data_access/mock_data/mock_startups.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/app_user.dart';
import '../../../models/investor_profile.dart';
import '../../../models/startup_listing.dart';

enum ExploreTab { forYou, trending, matches }

/// One row of the Explore list: either a startup or an investor.
class ExploreEntry {
  const ExploreEntry.startup(StartupListing this.startup, {this.rank})
    : investor = null;

  const ExploreEntry.investor(InvestorProfile this.investor)
    : startup = null,
      rank = null;

  final StartupListing? startup;
  final InvestorProfile? investor;

  /// 1, 2, 3... on the Trending tab.
  final int? rank;
}

/// Logic for the Explore tab. For now the lists come from sample data
/// (design phase); later they will come from the recommender and Firestore.
///
/// Following the Figma: a founder browses investors on For You and Matches and
/// startups on Trending; an investor browses startups on all three tabs. The search box and
/// the sector chips filter whichever list is showing.
class ExploreViewModel extends ChangeNotifier with SafeNotifier {
  ExploreViewModel({required this.role});

  /// The guest (startup seeker) Explore: a single ranked list of trending
  /// startups, with no tabs.
  ExploreViewModel.seeker() : role = AccountRole.investor {
    tab = ExploreTab.trending;
  }

  final AccountRole role;

  ExploreTab tab = ExploreTab.forYou;
  int filterIndex = 0;
  String query = '';

  bool get isFounder => role == AccountRole.founder;

  void selectTab(ExploreTab value) {
    if (value == tab) return;
    tab = value;
    notifyListeners();
  }

  void selectFilter(int index) {
    if (index == filterIndex) return;
    filterIndex = index;
    notifyListeners();
  }

  void setQuery(String value) {
    if (value == query) return;
    query = value;
    notifyListeners();
  }

  /// Matches has no sector chips; the search box is only on For You.
  String get _sector => filterIndex == 0 || tab == ExploreTab.matches
      ? ''
      : ExploreStrings.filters[filterIndex];

  bool _startupMatches(StartupListing s) =>
      (_sector.isEmpty || s.sectorLabel == _sector) &&
      _queryMatches('${s.name} ${s.tagline} ${s.city}');

  bool _investorMatches(InvestorProfile i) =>
      (_sector.isEmpty || i.sectors.contains(_sector)) &&
      _queryMatches('${i.name} ${i.headline} ${i.city}');

  bool _queryMatches(String text) {
    if (tab != ExploreTab.forYou) return true;
    final q = query.trim().toLowerCase();
    return q.isEmpty || text.toLowerCase().contains(q);
  }

  List<ExploreEntry> get entries {
    switch (tab) {
      case ExploreTab.trending:
        final trending = MockStartups.trending;
        return [
          for (var i = 0; i < trending.length; i++)
            if (_startupMatches(trending[i]))
              ExploreEntry.startup(trending[i], rank: i + 1),
        ];
      case ExploreTab.matches:
        return isFounder
            ? [
                for (final i in MockInvestors.matches)
                  if (_investorMatches(i)) ExploreEntry.investor(i),
              ]
            : [
                for (final s in MockStartups.matches)
                  if (_startupMatches(s)) ExploreEntry.startup(s),
              ];
      case ExploreTab.forYou:
        return isFounder
            ? [
                for (final i in MockInvestors.forYou)
                  if (_investorMatches(i)) ExploreEntry.investor(i),
              ]
            : [
                for (final s in MockStartups.forYou)
                  if (_startupMatches(s)) ExploreEntry.startup(s),
              ];
    }
  }
}
