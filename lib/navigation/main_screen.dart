import 'package:flutter/material.dart';

import '../features/explore_startups/screens/explore_screen.dart';
import '../features/profiles/screens/account_screen.dart';
import '../features/programs/screens/programs_screen.dart';
import '../features/search/screens/hub_screen.dart';
import '../features/services/screens/services_screen.dart';
import '../models/app_user.dart';
import '../shared_ui/common_widgets/app_bottom_bar.dart';
import '../shared_ui/theme/app_theme.dart';

/// Where a signed-in founder or investor lands: the bottom bar plus the
/// selected tab's screen.
///
/// All five tabs are built. Hub, Programs and Explore show sample data for
/// now, and Services is mostly design only (for founders it leads to My
/// Startups). The app opens on Account.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  AppTab _current = AppTab.account;

  /// Every tab is built, so every tab can be opened.
  Set<AppTab> get _enabledTabs => AppTab.values.toSet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: _screenFor(_current),
      bottomNavigationBar: AppBottomBar(
        current: _current,
        enabledTabs: _enabledTabs,
        onSelect: (tab) => setState(() => _current = tab),
      ),
    );
  }

  Widget _screenFor(AppTab tab) => switch (tab) {
    AppTab.account => AccountScreen(user: widget.user),
    AppTab.hub => HubScreen(role: widget.user.role),
    AppTab.programs => const ProgramsScreen(),
    AppTab.explore => ExploreScreen(role: widget.user.role),
    AppTab.services => ServicesScreen(role: widget.user.role),
  };
}
