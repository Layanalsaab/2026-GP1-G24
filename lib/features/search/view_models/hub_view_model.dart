import 'package:flutter/foundation.dart';

import '../../../data_access/mock_data/mock_investors.dart';
import '../../../data_access/mock_data/mock_startups.dart';
import '../../../helpers/safe_notifier.dart';
import '../../../models/app_user.dart';
import '../../../models/investor_profile.dart';
import '../../../models/startup_listing.dart';

/// Logic for the Hub tab (search and browse). For now the lists come from
/// sample data (design phase). Founders browse investors; investors browse
/// startups.
class HubViewModel extends ChangeNotifier with SafeNotifier {
  HubViewModel({required this.role});

  final AccountRole role;

  int filterIndex = 0;

  bool get isFounder => role == AccountRole.founder;

  List<InvestorProfile> get investors =>
      isFounder ? MockInvestors.forYou : const [];

  List<StartupListing> get startups =>
      isFounder ? const [] : MockStartups.forYou;

  void selectFilter(int index) {
    if (index == filterIndex) return;
    filterIndex = index;
    notifyListeners();
  }
}
