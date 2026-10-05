import 'package:flutter/material.dart';

import '../features/explore_startups/screens/seeker_explore_screen.dart';
import '../features/programs/screens/programs_screen.dart';
import '../features/search/screens/hub_screen.dart';
import '../models/app_user.dart';
import '../shared_ui/common_widgets/app_bottom_bar.dart';
import '../shared_ui/theme/app_theme.dart';

/// Where a startup seeker lands (they have no account): the bottom bar with
/// Hub, Explore and Programs (Figma "Nav · Seeker"), opening on Explore.
///
/// Design phase: everything shows sample data.
class SeekerMainScreen extends StatefulWidget {
  const SeekerMainScreen({super.key});

  @override
  State<SeekerMainScreen> createState() => _SeekerMainScreenState();
}

class _SeekerMainScreenState extends State<SeekerMainScreen> {
  AppTab _current = AppTab.explore;

  static const _tabs = [AppTab.hub, AppTab.explore, AppTab.programs];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: _screenFor(_current),
      bottomNavigationBar: AppBottomBar(
        current: _current,
        tabs: _tabs,
        enabledTabs: _tabs.toSet(),
        onSelect: (tab) => setState(() => _current = tab),
      ),
    );
  }

  Widget _screenFor(AppTab tab) => switch (tab) {
    // Seekers browse startups, like investors, but express interest instead
    // of sending a request.
    AppTab.hub => const HubScreen(role: AccountRole.investor, isSeeker: true),
    AppTab.programs => const ProgramsScreen(),
    _ => const SeekerExploreScreen(),
  };
}
