import 'package:flutter/material.dart';

import '../../app_constants/navigation_strings.dart';
import '../../data_access/repositories/startup_repository.dart';
import '../../features/profiles/screens/account_dialogs.dart';
import '../../features/profiles/screens/account_screen.dart';
import '../../features/profiles/screens/settings_screen.dart';
import '../../features/startups/screens/my_startups_screen.dart';
import '../../models/app_user.dart';
import '../../navigation/app_router.dart';
import '../../navigation/placeholder_features.dart';
import '../theme/app_theme.dart';
import 'seeker_exit_button.dart';
import 'user_avatar.dart';

/// The side menu that opens from the avatar (Figma "V2 · 41 · Menu —
/// Founder / Investor / Guest").
///
/// Profile, My Startups, Settings and Log out work. The rest (Wallet,
/// Associations, Requests, Gemini, Expressions of Interest, Bookmarks and
/// Notifications) are visual placeholders: shown, but not tappable.
class AppMenuDrawer extends StatelessWidget {
  /// The menu for a signed-in founder or investor.
  const AppMenuDrawer({super.key, required AppUser this.user});

  /// The guest (startup seeker) menu: no account.
  const AppMenuDrawer.guest({super.key}) : user = null;

  final AppUser? user;

  bool get _isGuest => user == null;
  bool get _isFounder => user?.role == AccountRole.founder;

  /// Closes the menu, then runs [action] on the screen underneath.
  void _go(BuildContext context, void Function(BuildContext) action) {
    final navigator = Navigator.of(context);
    navigator.pop();
    action(navigator.context);
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<void> _logOut(BuildContext context) async {
    final confirmed = await showLogOutDialog(context);
    if (confirmed != true || !context.mounted) return;
    await AppRouter.logOut(context);
  }

  @override
  Widget build(BuildContext context) {
    final items = _items(context);
    return Drawer(
      width: 292,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _Header(user: user, isFounder: _isFounder),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8),
                children: items,
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppColors.border),
            _Item(
              icon: Icons.logout_rounded,
              label: _isGuest
                  ? NavigationStrings.menuExit
                  : NavigationStrings.menuLogOut,
              height: 56,
              color: AppColors.error,
              onTap: () => _go(context, _isGuest ? exitSeekerMode : _logOut),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _items(BuildContext context) {
    Widget placeholder(IconData icon, String label, PlaceholderFeature f) =>
        _Item(icon: icon, label: label);

    if (_isGuest) {
      return [
        placeholder(
          Icons.inbox_outlined,
          NavigationStrings.menuExpressionsOfInterest,
          PlaceholderFeature.expressionsOfInterest,
        ),
      ];
    }

    final account = user!;
    return [
      _Item(
        icon: Icons.person_outline_rounded,
        label: NavigationStrings.menuProfile,
        onTap: () =>
            _go(context, (c) => _push(c, AccountScreen(user: account))),
      ),
      if (_isFounder) ...[
        _Item(
          icon: Icons.rocket_launch_outlined,
          label: NavigationStrings.menuMyStartups,
          onTap: () => _go(context, (c) => _push(c, const MyStartupsScreen())),
        ),
        placeholder(
          Icons.send_outlined,
          NavigationStrings.menuMyRequests,
          PlaceholderFeature.requests,
        ),
        placeholder(
          Icons.auto_awesome_outlined,
          NavigationStrings.menuAskGemini,
          PlaceholderFeature.askGemini,
        ),
        placeholder(
          Icons.inbox_outlined,
          NavigationStrings.menuExpressionsOfInterest,
          PlaceholderFeature.expressionsOfInterest,
        ),
      ] else ...[
        placeholder(
          Icons.account_balance_wallet_outlined,
          NavigationStrings.menuInvestmentWallet,
          PlaceholderFeature.investorWallet,
        ),
        placeholder(
          Icons.link_rounded,
          NavigationStrings.menuAssociations,
          PlaceholderFeature.investmentAssociations,
        ),
        placeholder(
          Icons.send_outlined,
          NavigationStrings.menuMyRequests,
          PlaceholderFeature.requests,
        ),
      ],
      placeholder(
        Icons.bookmark_border_rounded,
        NavigationStrings.menuBookmarks,
        PlaceholderFeature.bookmarks,
      ),
      placeholder(
        Icons.notifications_none_rounded,
        NavigationStrings.menuNotifications,
        PlaceholderFeature.notifications,
      ),
      _Item(
        icon: Icons.settings_outlined,
        label: NavigationStrings.menuSettings,
        onTap: () =>
            _go(context, (c) => _push(c, SettingsScreen(user: account))),
      ),
    ];
  }
}

/// Avatar, name, "Role · City" and the count line.
class _Header extends StatelessWidget {
  const _Header({required this.user, required this.isFounder});

  final AppUser? user;
  final bool isFounder;

  @override
  Widget build(BuildContext context) {
    final u = user;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (u == null)
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.moss100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 24,
                color: AppColors.moss600,
              ),
            )
          else
            UserAvatar(name: u.fullName, photoUrl: u.photoUrl, size: 44),
          const SizedBox(height: 10),
          Text(
            u?.fullName ?? NavigationStrings.guest,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.sans(
              size: 17,
              color: AppColors.ink,
              weight: FontWeight.w700,
            ),
          ),
          if (u != null) ...[
            const SizedBox(height: 4),
            Text(
              _roleLine(u),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.sans(size: 14, color: AppColors.grey),
            ),
            if (isFounder) const _StartupCount(),
          ],
        ],
      ),
    );
  }

  String _roleLine(AppUser u) {
    final role = u.role == AccountRole.founder ? 'Founder' : 'Investor';
    final city = u.city;
    return city == null || city.isEmpty ? role : '$role · $city';
  }
}

/// "2 Startups" under a founder's name. Hidden until the count is known, and
/// if it can't be loaded.
class _StartupCount extends StatefulWidget {
  const _StartupCount();

  @override
  State<_StartupCount> createState() => _StartupCountState();
}

class _StartupCountState extends State<_StartupCount> {
  late final Future<int> _count = StartupRepository.instance
      .fetchMyStartups()
      .then((list) => list.length);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _count,
      builder: (context, snapshot) {
        final count = snapshot.data;
        if (count == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$count ',
                  style: AppText.sans(
                    size: 14,
                    color: AppColors.ink,
                    weight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: NavigationStrings.startupCount(count),
                  style: AppText.sans(size: 14, color: AppColors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    this.onTap,
    this.height = 54,
    this.color = AppColors.ink,
  });

  final IconData icon;
  final String label;

  /// Null for a placeholder item: shown exactly the same, but inert (no tap,
  /// no ripple, no feedback).
  final VoidCallback? onTap;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final row = SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(left: 28, right: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(
                  size: 17,
                  color: color,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    final tap = onTap;
    if (tap == null) {
      // Placeholder: keeps its label for screen readers, but is not a button.
      return Semantics(label: label, excludeSemantics: true, child: row);
    }
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: tap,
      child: InkWell(onTap: tap, child: row),
    );
  }
}
