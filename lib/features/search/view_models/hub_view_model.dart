import 'package:flutter/foundation.dart';

import '../../../app_constants/explore_strings.dart';
import '../../../data_access/mock_data/mock_investors.dart';
import '../../../data_access/mock_data/mock_startups.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/app_user.dart';
import '../../../models/investor_profile.dart';
import '../../../models/startup_listing.dart';

/// Logic for the Hub tab (search and browse). For now the lists come from
/// sample data (design phase). Founders browse investors; investors and
/// guests browse startups. The search box and the sector chips filter the
/// list.
class HubViewModel extends ChangeNotifier with SafeNotifier {
  HubViewModel({required this.role});

  final AccountRole role;

  int filterIndex = 0;
  String query = '';

  bool get isFounder => role == AccountRole.founder;

  String get _sector =>
      filterIndex == 0 ? '' : ExploreStrings.filters[filterIndex];

  bool _queryMatches(String text) {
    final q = query.trim().toLowerCase();
    return q.isEmpty || text.toLowerCase().contains(q);
  }

  List<InvestorProfile> get investors => !isFounder
      ? const []
      : [
          for (final i in MockInvestors.forYou)
            if ((_sector.isEmpty || i.sectors.contains(_sector)) &&
                _queryMatches('${i.name} ${i.headline} ${i.city}'))
              i,
        ];

  List<StartupListing> get startups => isFounder
      ? const []
      : [
          for (final s in MockStartups.forYou)
            if ((_sector.isEmpty || s.sectorLabel == _sector) &&
                _queryMatches('${s.name} ${s.tagline} ${s.city}'))
              s,
        ];

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
}
