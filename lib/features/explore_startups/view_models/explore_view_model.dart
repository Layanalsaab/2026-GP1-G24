import 'package:flutter/foundation.dart';

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

  /// 1, 2, 3 on the Trending tab.
  final int? rank;
}

/// Logic for the Explore tab. For now the lists come from sample data
/// (design phase); later they will come from the recommender and Firestore.
///
/// Founders are shown investors (For You, Matches) and trending startups;
/// investors are shown startups on every tab.
class ExploreViewModel extends ChangeNotifier with SafeNotifier {
  ExploreViewModel({required this.role});

  /// The startup seeker's Explore (Figma "V2 · 11"): a single ranked list of
  /// trending startups, with no tabs.
  ExploreViewModel.seeker() : role = AccountRole.investor {
    tab = ExploreTab.trending;
  }

  final AccountRole role;

  ExploreTab tab = ExploreTab.forYou;
  int filterIndex = 0;

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

  List<ExploreEntry> get entries {
    switch (tab) {
      case ExploreTab.trending:
        final trending = MockStartups.trending;
        return [
          for (var i = 0; i < trending.length; i++)
            ExploreEntry.startup(trending[i], rank: i + 1),
        ];
      case ExploreTab.matches:
        return isFounder
            ? [for (final i in MockInvestors.matches) ExploreEntry.investor(i)]
            : [for (final s in MockStartups.matches) ExploreEntry.startup(s)];
      case ExploreTab.forYou:
        return isFounder
            ? [for (final i in MockInvestors.forYou) ExploreEntry.investor(i)]
            : [for (final s in MockStartups.forYou) ExploreEntry.startup(s)];
    }
  }
}
