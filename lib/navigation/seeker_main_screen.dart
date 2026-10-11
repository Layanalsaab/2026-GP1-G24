import 'package:flutter/material.dart';

import '../features/explore_startups/screens/explore_screen.dart';
import '../features/programs/screens/programs_screen.dart';
import '../features/search/screens/hub_screen.dart';
import '../models/app_user.dart';
import '../shared_ui/common_widgets/app_bottom_bar.dart';
import '../shared_ui/common_widgets/app_menu_drawer.dart';
import '../shared_ui/common_widgets/main_top_bar.dart';
import '../shared_ui/theme/app_theme.dart';

/// Where a startup seeker (a guest, with no account) lands (Figma "V2 · 40c ·
/// Explore — Guest"): the same three tabs as everyone else, opening on
/// Explore, with the guest menu (Expressions of Interest and Exit).
///
/// Design phase: everything shows sample data.
class SeekerMainScreen extends StatefulWidget {
  const SeekerMainScreen({super.key});

  @override
  State<SeekerMainScreen> createState() => _SeekerMainScreenState();
}

class _SeekerMainScreenState extends State<SeekerMainScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AppTab _current = AppTab.explore;

  @override
  Widget build(BuildContext context) {
    final topBar = MainTopBar(
      onMenu: () => _scaffoldKey.currentState?.openDrawer(),
    );
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.cream,
      drawer: const AppMenuDrawer.guest(),
      drawerScrimColor: const Color(0x660F1412),
      body: switch (_current) {
        AppTab.supportSystems => ProgramsScreen(topBar: topBar, isGuest: true),
        // Guests browse startups, like investors, but express interest
        // instead of sending a request.
        AppTab.hub => HubScreen(
          role: AccountRole.investor,
          isSeeker: true,
          topBar: topBar,
        ),
        AppTab.explore => ExploreScreen(
          role: AccountRole.investor,
          isGuest: true,
          topBar: topBar,
        ),
      },
      bottomNavigationBar: AppBottomBar(
        current: _current,
        onSelect: (tab) => setState(() => _current = tab),
      ),
    );
  }
}
