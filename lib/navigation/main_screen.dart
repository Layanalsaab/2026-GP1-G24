import 'package:flutter/material.dart';

import '../app_constants/home_strings.dart';
import '../data_access/repositories/bookmark_repository.dart';
import '../data_access/repositories/startup_repository.dart';
import '../features/explore_startups/screens/explore_screen.dart';
import '../features/login_and_signup/screens/choose_role_screen.dart';
import '../features/profiles/screens/account_screen.dart';
import '../features/profiles/screens/settings_screen.dart';
import '../features/programs/screens/programs_screen.dart';
import '../features/search/screens/hub_screen.dart';
import '../features/search/view_models/home_filters.dart';
import '../features/search/view_models/home_view_model.dart';
import '../features/startups/screens/my_startups_screen.dart';
import '../helpers/app_session.dart';
import '../shared_ui/icons/app_icons.dart';
import '../shared_ui/theme/app_colors.dart';
import '../shared_ui/widgets/headers/home_header.dart';
import '../shared_ui/widgets/nav/app_bottom_nav.dart';
import '../shared_ui/widgets/nav/app_side_drawer.dart';
import '../shared_ui/widgets/nav/home_search_bar.dart';
import '../shared_ui/widgets/overlays/advanced_search_sheet.dart';
import '../shared_ui/widgets/overlays/app_toast.dart';
import 'app_router.dart';

/// The home shell (Figma 20-27): green header with the avatar menu (or the
/// guest "Sign up" pill), the search bar with the advanced search sheet, the
/// page of the selected tab (Support Channels, Hub, Explore) and the 3-tab
/// bottom navigation. Reads the role from [AppSession]; guests have no drawer.
/// Opens on the Hub.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final HomeViewModel _vm;
  final ScrollController _scroll = ScrollController();

  AppSession get _session => AppSession.instance;

  @override
  void initState() {
    super.initState();
    _vm = HomeViewModel(
      role: _session.role,
      user: _session.user,
      ownStartupIds: _session.ownStartupIds,
    );
    _session.addListener(_onSession);
    if (_session.isFounder) _loadOwnStartups();
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _vm.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The founder's startups: hidden from the lists and shown in "Matches for".
  Future<void> _loadOwnStartups() async {
    try {
      final mine = await StartupRepository.instance.fetchMyStartups();
      if (!mounted) return;
      _session.setOwnStartupIds([for (final s in mine) s.id]);
      _vm.setOwnStartups(mine);
    } catch (_) {
      // Offline: the lists simply do not hide anything.
    }
  }

  /// Profile edited: refresh the avatar initials and the menu.
  void _onSession() {
    if (mounted) setState(() {});
  }

  void _selectTab(int index) {
    _vm.selectTab(HomeTab.values[index]);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _openAdvanced() async {
    final result = await showAdvancedSearchSheet(
      context,
      groups: HomeFilters.sheetGroups(_vm.context),
      initial: _vm.selection,
      countFor: _vm.countFor,
    );
    if (result != null) _vm.applySelection(result);
  }

  void _soon(String item) =>
      AppToast.show(context, HomeStrings.opensInFullApp(item));

  void _openMenu() {
    final user = _session.user;
    if (user == null) return;
    final founder = _session.isFounder;
    final city = user.city;
    openAppDrawer(
      context,
      name: user.fullName,
      initials: user.initials,
      roleLine:
          '${founder ? HomeStrings.founderRole : HomeStrings.investorRole}'
          '${city == null || city.isEmpty ? '' : ' · $city'}',
      items: [
        if (founder)
          AppDrawerItem(
            label: HomeStrings.myStartups,
            icon: AppIcons.menuRocket,
            onTap: () => MyStartupsScreen.open(context),
          )
        else
          AppDrawerItem(
            label: HomeStrings.wallet,
            icon: AppIcons.menuWallet,
            onTap: () => _soon(HomeStrings.wallet),
          ),
        AppDrawerItem(
          label: HomeStrings.bookmarks,
          icon: AppIcons.menuBookmark,
          badge: BookmarkRepository.instance.count,
          onTap: () => _soon(HomeStrings.bookmarks),
        ),
        if (founder)
          AppDrawerItem(
            label: HomeStrings.askGemini,
            icon: AppIcons.menuSpark,
            onTap: () => _soon(HomeStrings.askGemini),
          ),
        AppDrawerItem(
          label: HomeStrings.notifications,
          icon: AppIcons.menuBell,
          badge: HomeStrings.notificationCount,
          onTap: () => _soon(HomeStrings.notifications),
        ),
        AppDrawerItem(
          label: HomeStrings.settings,
          icon: AppIcons.menuGear,
          onTap: () => SettingsScreen.open(context),
        ),
      ],
      onViewProfile: () => OwnProfileScreen.open(context),
      onLogOut: () => AppRouter.logOut(context),
    );
  }

  Widget _page() {
    switch (_vm.tab) {
      case HomeTab.support:
        return ProgramsScreen(viewModel: _vm);
      case HomeTab.hub:
        return HubScreen(viewModel: _vm);
      case HomeTab.explore:
        return ExploreScreen(
          viewModel: _vm,
          onSignUp: () => ChooseRoleScreen.open(context),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guest = _vm.isGuest;
    return PopScope(
      // Back on Home does nothing.
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            Expanded(
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) {
                  final showTabs = _vm.tab == HomeTab.explore && !guest;
                  return SingleChildScrollView(
                    controller: _scroll,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        HomeHeader(
                          title: _vm.title,
                          initials: _session.user?.initials ?? '',
                          guest: guest,
                          hasNotification: !guest,
                          menuLabel: HomeStrings.menuLabel,
                          onAvatarTap: _openMenu,
                          onSignUp: () => ChooseRoleScreen.open(context),
                          tabs: showTabs ? ExploreTab.defaults : null,
                          selectedTab: _vm.exploreTab,
                          onTabChanged: _vm.selectExploreTab,
                        ),
                        HomeSearchBar(
                          controller: _vm.searchController,
                          hint: 'Search',
                          overlap: 0,
                          activeCount: _vm.selectionCount,
                          onChanged: _vm.setQuery,
                          onFilterTap: _openAdvanced,
                        ),
                        _page(),
                      ],
                    ),
                  );
                },
              ),
            ),
            ListenableBuilder(
              listenable: _vm,
              builder: (context, _) => AppBottomNav(
                currentIndex: _vm.tabIndex,
                onSelect: _selectTab,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
