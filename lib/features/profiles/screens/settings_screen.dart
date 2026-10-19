import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../app_constants/app_strings.dart';
import '../../../app_constants/profile_strings.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../helpers/app_session.dart';
import '../../../models/app_user.dart';
import '../../../models/auth_failure.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/icons/app_icons.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_metrics.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../../../shared_ui/theme/theme_controller.dart';
import '../../../shared_ui/widgets/forms/app_switch.dart';
import '../../../shared_ui/widgets/headers/header_buttons.dart';
import '../../../shared_ui/widgets/lists/press_surface.dart';
import '../../../shared_ui/widgets/overlays/app_bottom_sheet.dart';
import '../../../shared_ui/widgets/overlays/app_toast.dart';
import 'change_password_screen.dart';
import 'delete_account_dialog.dart';

/// Settings (docs/05 C6, screenshot 42): Display (Dark mode), Notifications
/// (not designed yet: toast) and Account (Change password, Delete account).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  /// Opens Settings with the forward transition.
  static void open(BuildContext context) =>
      AppNav.push(context, const SettingsScreen());

  void _toggleDark(BuildContext context, bool on) {
    ThemeController.instance.setDark(on);
    AppToast.show(context, on ? ProfileStrings.darkOn : ProfileStrings.darkOff);
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final role = AppSession.instance.user?.role ?? AccountRole.founder;
    final sure = await showConfirmSheet(
      context,
      title: ProfileStrings.deleteTitle,
      message:
          '${role == AccountRole.founder ? AccountStrings.deleteWarningFounder : AccountStrings.deleteWarningInvestor} '
          '${AccountStrings.cannotBeUndone}',
      confirmLabel: ProfileStrings.deleteConfirm,
      cancelLabel: ProfileStrings.cancel,
    );
    if (!sure || !context.mounted) return;

    var deleted = false;
    try {
      await AuthRepository.instance.deleteAccount();
      deleted = true;
    } on AuthException catch (e) {
      if (!context.mounted) return;
      if (e.failure == AuthFailure.requiresRecentLogin) {
        // Firebase wants a fresh sign-in: ask for the password this once.
        deleted = await showDeleteAccountDialog(context, role: role) == true;
      } else {
        AppToast.show(
          context,
          e.failure == AuthFailure.network
              ? AppStrings.networkError
              : AppStrings.genericError,
        );
        return;
      }
    } catch (_) {
      if (context.mounted) AppToast.show(context, AppStrings.genericError);
      return;
    }
    if (!deleted || !context.mounted) return;
    // The account is gone and signed out: back to Welcome with no way back.
    AppSession.instance.signOut();
    AppRouter.openStart(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              MediaQuery.paddingOf(context).top,
              12,
              0,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  AppIconButton(
                    icon: AppIcons.arrowBack,
                    semanticLabel: 'Back',
                    onTap: () => AppNav.back(context),
                  ),
                  const SizedBox(width: 8),
                  Semantics(
                    header: true,
                    child: Text(
                      ProfileStrings.settings,
                      style: AppText.sans(size: 20, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _GroupLabel(ProfileStrings.display, top: 16),
                  _GroupCard(
                    children: [
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: ThemeController.instance,
                        builder: (context, mode, _) {
                          final on = mode == ThemeMode.dark;
                          return _SettingsRow(
                            icon: AppIcons.moon,
                            title: ProfileStrings.darkMode,
                            subtitle: ProfileStrings.darkModeHint,
                            onTap: () => _toggleDark(context, !on),
                            trailing: AppSwitch(
                              value: on,
                              semanticLabel: ProfileStrings.darkMode,
                              onChanged: (v) => _toggleDark(context, v),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const _GroupLabel(ProfileStrings.notifications, top: 22),
                  _GroupCard(
                    children: [
                      _SettingsRow(
                        icon: AppIcons.bell,
                        title: ProfileStrings.notificationSettings,
                        subtitle: ProfileStrings.notificationSettingsHint,
                        chevron: true,
                      ),
                    ],
                  ),
                  const _GroupLabel(ProfileStrings.account, top: 22),
                  _GroupCard(
                    children: [
                      _SettingsRow(
                        icon: AppIcons.lock,
                        title: ProfileStrings.changePassword,
                        chevron: true,
                        onTap: () => AppNav.push(
                          context,
                          const ChangePasswordScreen(),
                          greenHeader: true,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.dividerSoft,
                        ),
                      ),
                      _SettingsRow(
                        icon: AppIcons.trash,
                        title: ProfileStrings.deleteAccount,
                        subtitle: ProfileStrings.deleteAccountHint,
                        destructive: true,
                        onTap: () => _deleteAccount(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Caps label above a group (13/600 grey, letter spacing .4).
class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text, {required this.top});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(4, top, 4, 8),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: AppText.sans(
          size: 13,
          weight: FontWeight.w600,
          color: AppColors.grey,
          letterSpacing: 0.4,
        ),
      ),
    ),
  );
}

/// White card (radius 18, border `#EBE7DF`, padding 4 0) holding rows.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorder),
      boxShadow: AppShadow.card,
    ),
    child: Column(children: children),
  );
}

/// A settings row: 38 icon box (radius 12), title 15/600, grey 13 subtitle
/// and a switch ([trailing]) or a chevron. The destructive row is red.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.onTap,
    this.subtitle,
    this.trailing,
    this.chevron = false,
    this.destructive = false,
  });

  final String icon;
  final String title;
  final String? subtitle;

  /// Null: not built yet, so the row cannot be tapped.
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool chevron;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return PressSurface(
      onTap: onTap,
      hoverColor: const Color(0xFFF2F7F3),
      borderRadius: BorderRadius.circular(18),
      semanticLabel: subtitle == null ? title : '$title, $subtitle',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: destructive ? AppColors.errorFill : AppColors.moss100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: AppIcon.filled(
                icon,
                size: 20,
                color: destructive ? AppColors.error : AppColors.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.sans(
                      size: 15,
                      weight: FontWeight.w600,
                      color: destructive ? AppColors.error : AppColors.ink,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppText.sans(size: 13, color: AppColors.grey),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (chevron)
              const AppIcon.filled(
                AppIcons.chevRight,
                size: 22,
                color: AppColors.grey,
              ),
          ],
        ),
      ),
    );
  }
}
