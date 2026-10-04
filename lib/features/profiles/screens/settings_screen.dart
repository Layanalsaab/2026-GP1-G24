import 'package:flutter/material.dart';

import '../../../app_constants/account_strings.dart';
import '../../../models/app_user.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/common_widgets/form_page_scaffold.dart';
import '../../../shared_ui/common_widgets/menu_row.dart';
import 'account_dialogs.dart';
import 'change_password_screen.dart';

/// Settings: the read-only email, Change password (PBI 7), Notification
/// preferences (Sprint 5, PBIs 71 and 74) and Delete account (PBI 13).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _changePassword() => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
      );

  void _showComingSoon() => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text(AccountStrings.notificationsComingSoon)),
    );

  Future<void> _deleteAccount() async {
    final deleted = await showDeleteAccountDialog(context, role: widget.user.role);
    if (deleted != true || !mounted) return;
    // The account is gone and signed out: back to the Start screen, with no
    // way to go Back into the app.
    AppRouter.openStart(context);
  }

  @override
  Widget build(BuildContext context) {
    return FormPageScaffold(
      title: AccountStrings.settings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MenuSectionLabel(AccountStrings.sectionAccount),
          MenuCard(
            children: [
              MenuRow(
                icon: Icons.mail_outline,
                label: AccountStrings.emailLabel,
                subtitle: widget.user.email,
                showChevron: false,
                onTap: null,
              ),
              MenuRow(
                icon: Icons.key_outlined,
                label: AccountStrings.changePassword,
                subtitle: AccountStrings.changePasswordHint,
                onTap: _changePassword,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const MenuSectionLabel(AccountStrings.sectionPreferences),
          MenuCard(
            children: [
              MenuRow(
                icon: Icons.notifications_none,
                label: AccountStrings.notificationPreferences,
                subtitle: AccountStrings.notificationPreferencesHint,
                onTap: _showComingSoon,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const MenuSectionLabel(AccountStrings.sectionRemoval),
          MenuCard(
            children: [
              MenuRow(
                icon: Icons.delete_outline,
                label: AccountStrings.deleteAccount,
                subtitle: AccountStrings.deleteAccountHint,
                destructive: true,
                onTap: _deleteAccount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
