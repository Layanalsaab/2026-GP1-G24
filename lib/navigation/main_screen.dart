import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_constants/home_strings.dart';
import '../data_access/repositories/bookmark_repository.dart';
import '../data_access/repositories/startup_repository.dart';
import '../features/bookmarks/screens/bookmarks_screen.dart';
import '../features/explore_startups/screens/explore_screen.dart';
import '../features/login_and_signup/screens/choose_role_screen.dart';
import '../features/profiles/screens/account_screen.dart';
import '../features/profiles/screens/settings_screen.dart';
import '../features/programs/screens/programs_screen.dart';
import '../features/search/screens/hub_screen.dart';
import '../features/search/view_models/home_filters.dart';
import '../features/search/view_models/home_view_model.dart';
import '../features/wallet/screens/wallet_screen.dart';
import '../features/startups/screens/my_startups_screen.dart';
import '../helpers/app_session.dart';
import '../models/list_entries.dart';
import '../shared_ui/icons/app_icons.dart';
import '../shared_ui/navigation/app_route.dart';
import '../shared_ui/theme/app_colors.dart';
import '../shared_ui/widgets/headers/home_header.dart';
import '../shared_ui/widgets/lists/app_refresh.dart';
import '../shared_ui/widgets/nav/app_bottom_nav.dart';
import '../shared_ui/widgets/nav/app_side_drawer.dart';
import '../shared_ui/widgets/nav/home_search_bar.dart';
import '../shared_ui/widgets/overlays/advanced_search_sheet.dart';
import '../shared_ui/widgets/overlays/picker_sheet.dart';
import '../shared_ui/widgets/overlays/app_bottom_sheet.dart';
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

  /// Kept so the same notifier is removed in dispose (tests swap instances).
  late final StartupRepository _startups = StartupRepository.instance;

  @override
  void initState() {
    super.initState();
    _vm = HomeViewModel(
      role: _session.role,
      user: _session.user,
      ownStartupIds: _session.belongingStartupIds,
    );
    _session.addListener(_onSession);
    // A startup was created, edited (stage, round opened or closed...),
    // deleted or left: "Matches for" and the hidden ids follow.
    _startups.changes.addListener(_onStartupsChanged);
    if (_session.isFounder) _loadOwnStartups();
    _vm.refreshDirectory();
  }

  /// Pull down: new invitations are accepted, then the lists are read again
  /// (the directory, the startups the person owns or belongs to, bookmarks).
  Future<void> _refresh() async {
    if (_session.isGuest) {
      await _vm.refreshDirectory();
      return;
    }
    await AppRouter.checkInvitations(context);
    if (!mounted) return;
    final uid = _session.user?.uid;
    if (uid != null) unawaited(BookmarkRepository.instance.load(uid));
    await Future.wait([
      _vm.refreshDirectory(),
      if (_session.isFounder) _loadOwnStartups(),
    ]);
  }

  void _onStartupsChanged() {
    if (_session.isFounder) _loadOwnStartups();
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _startups.changes.removeListener(_onStartupsChanged);
    _vm.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The founder's startups: hidden from the lists and shown in "Matches for".
  Future<void> _loadOwnStartups() async {
    try {
      final mine = await _startups.fetchMyStartups();
      if (!mounted) return;
      _session.setOwnStartupIds([for (final s in mine) s.id]);
      // The startups they belong to (co-founder / team member) are hidden
      // from Hub and For You too.
      final member = <String>{};
      final roles = <String, StartupRole>{};
      final uid = _session.user?.uid;
      try {
        for (final s in await _startups.fetchMemberStartups()) {
          member.add(s.id);
          roles[s.id] = StartupRole.of(s, uid) ?? StartupRole.member;
        }
      } catch (_) {
        // Memberships are an extra; the founder's own are still hidden.
      }
      if (!mounted) return;
      _session.setMemberRoles(roles);
      _session.setMemberStartupIds(member);
      // "Matches for" lists the startups the user owns, but not closed
      // ones (they are not raising); every startup of theirs stays hidden.
      _vm.setOwnStartups(
        [
          for (final s in mine)
            if (!s.isClosed) s,
        ],
        alsoHide: {...member, for (final s in mine) s.id},
      );
    } catch (_) {
      // Offline: the lists simply do not hide anything.
    }
  }

  /// Profile edited: refresh the avatar initials and the menu, and give
  /// Matches the new answers (an investor's preferences).
  void _onSession() {
    if (!mounted) return;
    _vm.setUser(_session.user);
    setState(() {});
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

  /// The Hub's sort button: Newest or Name A–Z; picking the chosen one again
  /// goes back to the default order.
  Future<void> _openSort() async {
    final r = await showPickerSheet(
      context,
      title: HomeStrings.sortTitle,
      options: const [HomeStrings.sortNewest, HomeStrings.sortNameAZ],
      selected: _vm.sortChoice,
    );
    if (r != null) _vm.setSort(r.value);
  }

  /// "Log out" asks first.
  Future<void> _confirmLogOut() async {
    final ok = await showConfirmSheet(
      context,
      title: HomeStrings.logOutTitle,
      message: HomeStrings.logOutMessage,
      confirmLabel: HomeStrings.logOut,
      cancelLabel: HomeStrings.cancel,
      icon: AppIcons.logout,
    );
    if (ok && mounted) AppRouter.logOut(context);
  }

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
            onTap: () => WalletScreen.open(context),
          ),
        AppDrawerItem(
          label: HomeStrings.bookmarks,
          icon: AppIcons.menuBookmark,
          // No number badge on this item.
          onTap: () async {
            // The user's saved bookmarks (Firestore).
            final items = await BookmarkRepository.instance.savedItems();
            if (!mounted) return;
            BookmarksScreen.open(
              context,
              items: items,
              // Removing a card deletes the bookmark too.
              onRemove: (b) =>
                  BookmarkRepository.instance.remove(b.item.bookmarkKey),
              // "Explore" in the empty state goes to the Explore tab.
              onExplore: () {
                AppNav.back(context);
                _vm.selectTab(HomeTab.explore);
              },
            );
          },
        ),
        if (founder)
          AppDrawerItem(label: HomeStrings.askGemini, icon: AppIcons.menuSpark),
        AppDrawerItem(
          label: HomeStrings.notifications,
          icon: AppIcons.menuBell,
        ),
        AppDrawerItem(
          label: HomeStrings.settings,
          icon: AppIcons.menuGear,
          onTap: () => SettingsScreen.open(context),
        ),
      ],
      onViewProfile: () => OwnProfileScreen.open(context),
      onLogOut: _confirmLogOut,
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
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        // The system navigation area under the green bar is green too, so
        // there is no pale strip below it.
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: AppColors.green,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: AppColors.green,
        ),
        child: Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              Expanded(
                child: ListenableBuilder(
                  listenable: _vm,
                  builder: (context, _) {
                    final showTabs = _vm.tab == HomeTab.explore && !guest;
                    return AppRefresh(
                      onRefresh: _refresh,
                      child: SingleChildScrollView(
                        controller: _scroll,
                        physics: AppRefresh.physics,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            HomeHeader(
                              title: _vm.title,
                              initials: _session.user?.initials ?? '',
                              guest: guest,
                              // No dot until notifications exist.
                              hasNotification: false,
                              menuLabel: HomeStrings.menuLabel,
                              onAvatarTap: _openMenu,
                              onSignUp: () => ChooseRoleScreen.open(context),
                              tabs: showTabs
                                  ? ExploreTab.forRole(founder: _vm.isFounder)
                                  : null,
                              selectedTab: _vm.effectiveExploreTab,
                              onTabChanged: _vm.selectExploreTab,
                            ),
                            HomeSearchBar(
                              controller: _vm.searchController,
                              hint: 'Search',
                              overlap: 0,
                              activeCount: _vm.selectionCount,
                              onChanged: _vm.setQuery,
                              onFilterTap: _openAdvanced,
                              onSortTap: _vm.hasSortButton ? _openSort : null,
                              sortActive: _vm.sortChoice != null,
                            ),
                            _page(),
                          ],
                        ),
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
      ),
    );
  }
}
