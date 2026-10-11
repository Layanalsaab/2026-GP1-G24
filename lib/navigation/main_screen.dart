import 'package:flutter/material.dart';

import '../features/explore_startups/screens/explore_screen.dart';
import '../features/programs/screens/programs_screen.dart';
import '../features/search/screens/hub_screen.dart';
import '../helpers/current_user.dart';
import '../models/app_user.dart';
import '../shared_ui/common_widgets/app_bottom_bar.dart';
import '../shared_ui/common_widgets/app_menu_drawer.dart';
import '../shared_ui/common_widgets/main_top_bar.dart';
import '../shared_ui/theme/app_theme.dart';

/// Where a signed-in founder or investor lands: the top bar with the avatar
/// menu, the selected tab's screen and the 3-tab bottom bar (Support Systems,
/// Hub, Explore). Opens on the Hub, after sign up and after log in.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  AppTab _current = AppTab.hub;

  late AppUser _user = widget.user;

  @override
  void initState() {
    super.initState();
    CurrentUser.changes.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    CurrentUser.changes.removeListener(_onUserChanged);
    super.dispose();
  }

  /// Profile edited (name, photo, ...): show it in the top bar and menu.
  void _onUserChanged() {
    final updated = CurrentUser.changes.value;
    if (updated == null || updated.uid != _user.uid || !mounted) return;
    setState(() => _user = updated);
  }

  @override
  Widget build(BuildContext context) {
    final topBar = MainTopBar(
      name: _user.fullName,
      photoUrl: _user.photoUrl,
      onMenu: () => _scaffoldKey.currentState?.openDrawer(),
    );
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.cream,
      drawer: AppMenuDrawer(user: _user),
      drawerScrimColor: const Color(0x660F1412),
      body: switch (_current) {
        AppTab.supportSystems => ProgramsScreen(topBar: topBar),
        AppTab.hub => HubScreen(role: _user.role, topBar: topBar),
        AppTab.explore => ExploreScreen(
          role: _user.role,
          user: _user,
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
