import 'package:flutter/material.dart';

import '../app_constants/app_strings.dart';
import '../data_access/repositories/app_settings_repository.dart';
import '../data_access/repositories/auth_repository.dart';
import '../features/login_and_signup/screens/welcome_screen.dart';
import '../features/profiles/screens/founder_onboarding_screen.dart';
import '../features/profiles/screens/investor_onboarding_screen.dart';
import '../models/app_user.dart';
import 'main_screen.dart';

/// Moving between the top-level areas of the app. Each of these clears the
/// navigation stack, so Back can never return to a screen the user left.
class AppRouter {
  AppRouter._();

  /// The Start screen (Welcome: Create account / Log in).
  static void openStart(BuildContext context) => WelcomeScreen.open(context);

  /// Called when the user finishes or skips the intro screens: remembers that
  /// they have seen them (so they never show again) and opens the Start screen.
  static void finishIntro(BuildContext context) {
    AppSettingsRepository.instance.markIntroSeen();
    openStart(context);
  }

  /// Where a signed-in user lands: the main screen with the bottom bar, or
  /// their role's onboarding first if they haven't completed it yet.
  static void openHome(BuildContext context, AppUser user) {
    debugPrint(
      'openHome: role=${user.role.value} '
      'onboardingCompleted=${user.onboardingCompleted}',
    );
    final Widget home = switch (user.role) {
      // Each role answers its onboarding questions once, before their home.
      AccountRole.founder => user.onboardingCompleted
          ? MainScreen(user: user)
          : FounderOnboardingScreen(user: user),
      AccountRole.investor => user.onboardingCompleted
          ? MainScreen(user: user)
          : InvestorOnboardingScreen(user: user),
    };
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => home),
      (route) => false,
    );
  }

  /// Signs out of Firebase, then returns to the Start screen.
  static Future<void> logOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AuthRepository.instance.signOut();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.genericError)),
      );
      return;
    }
    if (context.mounted) openStart(context);
  }
}
