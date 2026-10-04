import 'package:flutter/material.dart';

import '../features/profiles/screens/account_screen.dart';
import '../features/services/screens/services_screen.dart';
import '../models/app_user.dart';
import '../shared_ui/common_widgets/app_bottom_bar.dart';
import '../shared_ui/theme/app_theme.dart';

/// Where a signed-in founder or investor lands: the bottom bar plus the
/// selected tab's screen.
///
/// Built so far: Account (everyone) and, for founders, Services (Figma
/// "V2 · 35", which leads to My Startups). The app opens on Account; the other
/// tabs can't be opened yet. To switch a tab on later: add it to
/// [_enabledTabs] and return its screen from [_screenFor].
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  AppTab _current = AppTab.account;

  bool get _isFounder => widget.user.role == AccountRole.founder;

  Set<AppTab> get _enabledTabs => {
    AppTab.account,
    if (_isFounder) AppTab.services,
  };

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
    AppTab.services when _isFounder => const ServicesScreen(),
    // Not built yet; these tabs can't be selected (see _enabledTabs).
    AppTab.hub ||
    AppTab.programs ||
    AppTab.explore ||
    AppTab.services => const SizedBox.shrink(),
  };
}
