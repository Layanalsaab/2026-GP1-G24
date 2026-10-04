import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/app_strings.dart';
import '../../../app_constants/startup_strings.dart';
import '../../../models/app_user.dart';
import '../../../navigation/app_router.dart';
import '../../../navigation/placeholder_features.dart';
import '../../../shared_ui/common_widgets/coming_soon_screen.dart';
import '../../../shared_ui/common_widgets/green_top_bar.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../../startups/screens/my_startups_screen.dart';

/// Founder home: bottom tabs (Explore, My Startups, Matches, Bookmarks) and a
/// side menu with the founder tools. Only My Startups is built so far; every
/// other destination opens a "Coming in a later sprint" page.
class FounderHomeScreen extends StatefulWidget {
  const FounderHomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<FounderHomeScreen> createState() => _FounderHomeScreenState();
}

class _FounderHomeScreenState extends State<FounderHomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Opens on My Startups, the first finished founder screen.
  int _tab = 1;

  void _openMenu() => _scaffoldKey.currentState?.openDrawer();

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _PlaceholderTab(
        feature: PlaceholderFeature.explore,
        onOpenMenu: _openMenu,
      ),
      MyStartupsScreen(onOpenMenu: _openMenu),
      _PlaceholderTab(
        feature: PlaceholderFeature.matches,
        onOpenMenu: _openMenu,
      ),
      _PlaceholderTab(
        feature: PlaceholderFeature.bookmarks,
        onOpenMenu: _openMenu,
      ),
    ];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.cream,
        drawer: _FounderMenu(
          user: widget.user,
          // The home's context, not the drawer's: the drawer is gone by the
          // time sign-out finishes.
          onLogOut: () => AppRouter.logOut(context),
        ),
        // IndexedStack keeps each tab's state (e.g. the loaded list).
        body: IndexedStack(index: _tab, children: tabs),
        bottomNavigationBar: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.moss100,
            surfaceTintColor: Colors.transparent,
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => AppText.badge.copyWith(
                color: states.contains(WidgetState.selected)
                    ? AppColors.green
                    : AppColors.grey,
              ),
            ),
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                size: AppSizes.icon,
                color: states.contains(WidgetState.selected)
                    ? AppColors.moss600
                    : AppColors.grey,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                label: StartupStrings.tabExplore,
              ),
              NavigationDestination(
                icon: Icon(Icons.rocket_launch_outlined),
                label: StartupStrings.tabMyStartups,
              ),
              NavigationDestination(
                icon: Icon(Icons.handshake_outlined),
                label: StartupStrings.tabMatches,
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmark_border_rounded),
                label: StartupStrings.tabBookmarks,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.feature, required this.onOpenMenu});

  final PlaceholderFeature feature;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GreenTopBar(
          title: feature.label,
          leading: TopBarIconButton(
            icon: Icons.menu_rounded,
            tooltip: StartupStrings.menuTooltip,
            onPressed: onOpenMenu,
          ),
          actions: [
            TopBarIconButton(
              icon: Icons.search_rounded,
              tooltip: StartupStrings.searchTooltip,
              onPressed: () => PlaceholderFeature.search.open(context),
            ),
            TopBarIconButton(
              icon: Icons.notifications_none_rounded,
              tooltip: StartupStrings.notificationsTooltip,
              onPressed: () => PlaceholderFeature.notifications.open(context),
            ),
          ],
        ),
        Expanded(child: ComingSoonView(feature: feature)),
      ],
    );
  }
}

class _FounderMenu extends StatelessWidget {
  const _FounderMenu({required this.user, required this.onLogOut});

  final AppUser user;

  final VoidCallback onLogOut;

  static const _tools = [
    PlaceholderFeature.askGemini,
    PlaceholderFeature.fundraisingCalculator,
    PlaceholderFeature.activityDashboard,
    PlaceholderFeature.investmentAssociations,
    PlaceholderFeature.programs,
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.green,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.page,
              MediaQuery.paddingOf(context).top + AppSpacing.xl,
              AppSpacing.page,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: AppSizes.touchTarget,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(user.fullName, style: AppText.pageTitle),
                Text(
                  user.email,
                  style: AppText.caption.copyWith(color: AppColors.onDarkMuted),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                const _MenuHeading(StartupStrings.menuTools),
                for (final feature in _tools)
                  _MenuItem(
                    icon: feature.icon,
                    label: feature.label,
                    onTap: () {
                      Navigator.of(context).pop();
                      feature.open(context);
                    },
                  ),
                const Divider(color: AppColors.border),
                const _MenuHeading(StartupStrings.menuAccount),
                _MenuItem(
                  icon: Icons.logout_rounded,
                  label: AppStrings.logOut,
                  onTap: () {
                    Navigator.of(context).pop();
                    onLogOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuHeading extends StatelessWidget {
  const _MenuHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.page,
      AppSpacing.md,
      AppSpacing.page,
      AppSpacing.xs,
    ),
    child: Text(text, style: AppText.caption),
  );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
    leading: Icon(icon, color: AppColors.moss600, size: AppSizes.icon),
    title: Text(label, style: AppText.label),
    onTap: onTap,
  );
}
