import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app_constants/account_strings.dart';
import '../../../models/app_user.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/theme/app_theme.dart';
import '../../../shared_ui/theme/theme_controller.dart';
import 'account_dialogs.dart';
import 'change_password_screen.dart';

/// Figma: "V2 · 42 · Settings — Founder and Investor". Sections Display (Dark
/// mode), Notifications (placeholder feature) and Account (Change password,
/// Delete account).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _changePassword() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));

  Future<void> _deleteAccount() async {
    final deleted = await showDeleteAccountDialog(
      context,
      role: widget.user.role,
    );
    if (deleted != true || !mounted) return;
    // The account is gone and signed out: back to the Start screen, with no
    // way to go Back into the app.
    AppRouter.openStart(context);
  }

  @override
  Widget build(BuildContext context) {
    const chevron = Icon(Icons.chevron_right, size: 22, color: AppColors.grey);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Column(
            children: [
              _header(context),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const _SectionTitle(AccountStrings.sectionDisplay),
                    ValueListenableBuilder<ThemeMode>(
                      valueListenable: ThemeController.instance,
                      builder: (context, mode, _) => _SettingsRow(
                        icon: Icons.dark_mode_outlined,
                        label: AccountStrings.darkMode,
                        subtitle: AccountStrings.darkModeHint,
                        trailing: Switch(
                          value: mode == ThemeMode.dark,
                          activeTrackColor: AppColors.moss600,
                          onChanged: ThemeController.instance.setDark,
                        ),
                        onTap: () => ThemeController.instance.setDark(
                          mode != ThemeMode.dark,
                        ),
                      ),
                    ),
                    const _SectionDivider(),
                    const _SectionTitle(AccountStrings.sectionNotifications),
                    _SettingsRow(
                      icon: Icons.notifications_none,
                      label: AccountStrings.notificationSettings,
                      subtitle: AccountStrings.notificationSettingsHint,
                      trailing: chevron,
                    ),
                    const _SectionDivider(),
                    const _SectionTitle(AccountStrings.sectionAccount),
                    _SettingsRow(
                      icon: Icons.lock_outline,
                      label: AccountStrings.changePassword,
                      trailing: chevron,
                      onTap: _changePassword,
                    ),
                    _SettingsRow(
                      icon: Icons.delete_outline,
                      label: AccountStrings.deleteAccount,
                      subtitle: AccountStrings.deleteAccountHint,
                      destructive: true,
                      onTap: _deleteAccount,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => SizedBox(
    height: 56,
    child: Row(
      children: [
        const SizedBox(width: 4),
        IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
        ),
        const SizedBox(width: 4),
        Text(
          AccountStrings.settings,
          style: AppText.sans(
            size: 18,
            color: AppColors.ink,
            weight: FontWeight.w600,
            height: 24,
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Text(
      text,
      style: AppText.sans(
        size: 15,
        color: AppColors.ink,
        weight: FontWeight.w600,
        height: 22,
      ),
    ),
  );
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(top: 12),
    child: Divider(height: 1, thickness: 1, color: AppColors.border),
  );
}

/// One flat settings row: outline icon, label, optional grey second line and
/// a trailing switch or chevron.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    this.onTap,
    this.subtitle,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final bool destructive;

  /// Null for a placeholder row: shown, but inert.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.error : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppText.sans(
                        size: 15,
                        color: color,
                        weight: FontWeight.w500,
                        height: 22,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppText.sans(
                          size: 13,
                          color: AppColors.grey,
                          height: 18,
                        ),
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
