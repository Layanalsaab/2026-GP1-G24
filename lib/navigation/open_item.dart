import 'package:flutter/widgets.dart';

import '../data_access/repositories/discovery_repository.dart';
import '../data_access/repositories/interaction_repository.dart';
import '../data_access/repositories/matching_repository.dart';
import '../features/program_details/screens/program_details_screen.dart';
import '../features/profiles/screens/investor_profile_screen.dart';
import '../features/startup_profile/screens/startup_profile_screen.dart';
import '../features/startups/screens/manage_startup_screen.dart';
import '../models/list_entries.dart';
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
      // Matches cards come from Firestore, the other lists from the samples.
      final startup =
          discovery.startupById(item.id) ??
          MatchingRepository.instance.startupById(item.id);
      if (startup == null) return;
      InteractionRepository.instance.recordProfileView(item.bookmarkKey);
      final session = AppSession.instance;
      // A startup I belong to never opens as a public page (no bookmark): a
      // co-founder gets Manage, a team member Manage view only. The founder
      // sees the preview of the startup page.
      if (!session.ownStartupIds.contains(item.id)) {
        final role =
            session.memberRoleOf(item.id) ??
            StartupRole.of(startup, session.user?.uid);
        if (role != null && role != StartupRole.founder) {
          ManageStartupScreen.open(context, startup, role: role);
          return;
        }
      }
      StartupProfileScreen.open(
        context,
        startup: startup,
        preview: session.isFounder && session.ownStartupIds.contains(item.id),
      );
    case HomeItemKind.investor:
      final investor =
          discovery.investorById(item.id) ??
          MatchingRepository.instance.investorById(item.id);
      if (investor == null) return;
      InteractionRepository.instance.recordProfileView(item.bookmarkKey);
      InvestorProfileScreen.open(context, investor);
    case HomeItemKind.program:
      final program = discovery.programById(item.id);
      if (program == null) return;
      ProgramDetailsScreen.open(context, program);
  }
}
