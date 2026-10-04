import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../models/app_user.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/common_widgets/menu_row.dart';
import '../../../shared_ui/common_widgets/profile_avatar.dart';
import '../../../shared_ui/common_widgets/svg_asset.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../view_models/account_view_model.dart';
import 'account_dialogs.dart';
import 'edit_account_screen.dart';
import 'settings_screen.dart';

/// Figma: "V2 · 18 · Account — Founder" and "V2 · 19 · Account — Investor"
/// (PBIs 9 and 11). Shows the user's saved information and links to Edit
/// account, Settings, Help & Support and Log out.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AccountViewModel _viewModel = AccountViewModel(user: widget.user);

  @override
  void initState() {
    super.initState();
    _viewModel.reload();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  AppUser get _user => _viewModel.user;

  Future<void> _editAccount() async {
    final updated = await Navigator.of(context).push<AppUser>(
      MaterialPageRoute(builder: (_) => EditAccountScreen(user: _user)),
    );
    if (updated == null || !mounted) return;
    _viewModel.updateUser(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AccountStrings.changesSaved)),
    );
  }

  void _openSettings() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SettingsScreen(user: _user)),
      );

  void _showComingSoon(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _logOut() async {
    final confirmed = await showLogOutDialog(context);
    if (confirmed != true || !mounted) return;
    await AppRouter.logOut(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => Scaffold(
          backgroundColor: AppColors.cream,
          body: Column(
            children: [
              _header(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _InfoCard(user: _user),
                    const SizedBox(height: 16),
                    MenuCard(
                      children: [
                        MenuRow(
                          icon: Icons.settings_outlined,
                          label: AccountStrings.settings,
                          onTap: _openSettings,
                        ),
                        MenuRow(
                          icon: Icons.help_outline,
                          label: AccountStrings.helpAndSupport,
                          onTap: () =>
                              _showComingSoon(AccountStrings.helpComingSoon),
                        ),
                        MenuRow(
                          icon: Icons.logout,
                          label: AppStrings.logOut,
                          destructive: true,
                          onTap: _logOut,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Green header: back button, avatar, name, role · city, Edit account.
  Widget _header(BuildContext context) {
    // Asks about this screen's own page, not the whole app: as a tab it is
    // the first page, so no arrow, even while Settings is open on top.
    final canGoBack = ModalRoute.of(context)?.canPop ?? false;
    return Container(
      width: double.infinity,
      color: AppColors.green,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 24,
      ),
      child: Column(
        children: [
          // As a tab on the main screen there is nothing to go back to, so
          // the back-button row shrinks to a small gap.
          if (canGoBack)
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Semantics(
                    button: true,
                    label: 'Back',
                    child: InkResponse(
                      onTap: () => Navigator.of(context).maybePop(),
                      radius: 26,
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(child: svgIcon('back.svg', size: 22)),
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 20),
          ProfileAvatar(name: _user.fullName, goldBorder: true),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _user.fullName,
              textAlign: TextAlign.center,
              style: AppText.serif(size: 22, color: Colors.white, height: 28),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AccountStrings.roleLine(_user.role, _user.city),
            style: AppText.sans(
              size: 13,
              color: Colors.white.withValues(alpha: 0.8),
              height: 18,
            ),
          ),
          const SizedBox(height: 16),
          _EditAccountButton(onPressed: _editAccount),
        ],
      ),
    );
  }
}

/// White button with a gold outline, on the green header.
class _EditAccountButton extends StatelessWidget {
  const _EditAccountButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Ink(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold, width: 1.5),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              AccountStrings.editAccount,
              style: AppText.sans(
                size: 14,
                color: AppColors.green,
                weight: FontWeight.w600,
                height: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The user's saved details: email, city and bio.
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final bio = user.bio.trim();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(label: AccountStrings.emailLabel, value: user.email),
          const SizedBox(height: 12),
          _InfoLine(label: AccountStrings.cityLabel, value: user.city),
          const SizedBox(height: 12),
          _InfoLine(
            label: AccountStrings.bioLabel,
            value: bio.isEmpty ? null : bio,
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;

  /// Null shows "Not added yet".
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppText.sans(size: 12, color: AppColors.grey, height: 16),
        ),
        const SizedBox(height: 2),
        Text(
          value ?? AccountStrings.notAddedYet,
          style: AppText.sans(
            size: 15,
            color: value == null ? AppColors.grey : AppColors.ink,
            height: 22,
          ),
        ),
      ],
    );
  }
}
