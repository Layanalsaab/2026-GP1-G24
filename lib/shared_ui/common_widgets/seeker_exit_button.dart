import 'package:flutter/material.dart';

import '../../app_constants/seeker_strings.dart';
import '../../features/login_and_signup/screens/choose_role_screen.dart';
import '../../features/login_and_signup/screens/welcome_screen.dart';
import 'confirm_dialog.dart';
import 'green_top_bar.dart';

/// Top-bar button that lets a startup seeker (who has no account) switch to
/// another role: on to "Choose your role", after a confirmation. Back from
/// there returns to the Welcome screen.
class SeekerExitButton extends StatelessWidget {
  const SeekerExitButton({super.key});

  Future<void> _exit(BuildContext context) async {
    final confirmed = await showConfirmDialog(
      context,
      title: SeekerStrings.exitTitle,
      message: SeekerStrings.exitMessage,
      confirmLabel: SeekerStrings.exitConfirm,
      cancelLabel: SeekerStrings.exitCancel,
      icon: Icons.swap_horiz_rounded,
    );
    if (!confirmed || !context.mounted) return;
    // Rebuild the history as Welcome -> Choose role, so Back has somewhere
    // to go and the seeker screens can't be reached by going back.
    final navigator = Navigator.of(context);
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
    navigator.push(
      MaterialPageRoute(builder: (_) => const ChooseRoleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) => TopBarIconButton(
    icon: Icons.swap_horiz_rounded,
    tooltip: SeekerStrings.switchRole,
    onPressed: () => _exit(context),
  );
}
