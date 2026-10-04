import 'package:flutter/material.dart';

import '../features/profiles/screens/account_screen.dart';
import '../models/app_user.dart';
import '../shared_ui/common_widgets/app_bottom_bar.dart';
import '../shared_ui/theme/app_theme.dart';

/// Where a signed-in founder or investor lands: the bottom bar plus the
/// selected tab's screen.
///
/// Only the Account tab is built so far, so the app opens on it and the other
/// tabs can't be opened yet. To switch a tab on later: add it to
/// [_enabledTabs] and return its screen from [_screenFor].
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _enabledTabs = {AppTab.account};

  AppTab _current = AppTab.account;

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
        // Not built yet; these tabs can't be selected (see _enabledTabs).
        AppTab.hub ||
        AppTab.programs ||
        AppTab.explore ||
        AppTab.services =>
          const SizedBox.shrink(),
      };
}
