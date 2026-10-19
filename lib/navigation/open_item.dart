import 'package:flutter/widgets.dart';

import '../data_access/repositories/discovery_repository.dart';
import '../data_access/repositories/interaction_repository.dart';
import '../features/program_details/screens/program_details_screen.dart';
import '../features/profiles/screens/investor_profile_screen.dart';
import '../features/startup_profile/screens/startup_profile_screen.dart';
import '../helpers/app_session.dart';
import '../models/home_item.dart';

/// Opens the profile behind a home card or row: startup -> Startup profile,
/// investor -> Investor profile, program -> Program details. The model is
/// resolved through [DiscoveryRepository]; a founder opening one of their own
/// startups gets the preview mode. Counts a profile view for Trending.
void openHomeItem(BuildContext context, HomeItem item) {
  final discovery = DiscoveryRepository.instance;
  switch (item.kind) {
    case HomeItemKind.startup:
      final startup = discovery.startupById(item.id);
      if (startup == null) return;
      InteractionRepository.instance.recordProfileView(item.bookmarkKey);
      final session = AppSession.instance;
      StartupProfileScreen.open(
        context,
        startup: startup,
        preview: session.isFounder && session.ownStartupIds.contains(item.id),
      );
    case HomeItemKind.investor:
      final investor = discovery.investorById(item.id);
      if (investor == null) return;
      InteractionRepository.instance.recordProfileView(item.bookmarkKey);
      InvestorProfileScreen.open(context, investor);
    case HomeItemKind.program:
      final program = discovery.programById(item.id);
      if (program == null) return;
      ProgramDetailsScreen.open(context, program);
  }
}
