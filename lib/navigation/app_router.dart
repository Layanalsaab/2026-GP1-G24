import 'dart:async';

import 'package:flutter/material.dart';

import '../app_constants/app_strings.dart';
import '../data_access/repositories/app_settings_repository.dart';
import '../data_access/repositories/auth_repository.dart';
import '../data_access/repositories/bookmark_repository.dart';
import '../data_access/repositories/interest_repository.dart';
import '../data_access/repositories/request_repository.dart';
import '../data_access/repositories/startup_repository.dart';
import '../features/login_and_signup/screens/investor_investments_screen.dart';
import '../features/login_and_signup/screens/welcome_screen.dart';
import '../features/login_and_signup/screens/login_screen.dart';
import '../features/login_and_signup/view_models/signup_flow.dart';
import '../features/startups/screens/startup_steps_screen.dart';
import '../helpers/app_session.dart';
import '../models/app_user.dart';
import '../shared_ui/navigation/app_route.dart';
import '../shared_ui/widgets/overlays/app_toast.dart';
import 'main_screen.dart';

/// Moving between the top-level areas of the app. Each of these clears the
/// navigation stack, so Back can never return to a screen the user left.
class AppRouter {
  AppRouter._();

  /// The Start screen (Welcome), with the back transition.
  static void openStart(BuildContext context) => WelcomeScreen.open(context);

  /// Called when the user finishes or skips the intro screens: remembers that
  /// they have seen them (so they never show again) and opens Welcome.
  static void finishIntro(BuildContext context) {
    AppSettingsRepository.instance.markIntroSeen();
    openStart(context);
  }

  /// Home: reset, "up" transition. The role comes from [AppSession]; the Hub
  /// opens on Startups for guests and Investors for everyone else.
  static void openHome(BuildContext context) => AppNav.reset(
    context,
    const MainScreen(),
    kind: RouteKind.up,
    greenHeader: true,
  );

  /// Where a user lands after log in, sign up or a restored session. A founder
  /// with no startup goes to the onboarding "Add your startup" steps, an
  /// investor who did not finish the investor steps to step 3; everyone else
  /// to Home. [welcomeBack] shows "Welcome back" with the first name.
  static Future<void> openAfterLogin(
    BuildContext context,
    AppUser user, {
    bool welcomeBack = false,
  }) async {
    AppSession.instance.signIn(user);
    // The saved bookmarks load in the background (icons fill when ready).
    unawaited(BookmarkRepository.instance.load(user.uid));
    var needsStartup = false;
    if (user.role == AccountRole.founder) {
      try {
        final mine = await StartupRepository.instance.fetchMyStartups();
        AppSession.instance.setOwnStartupIds([for (final s in mine) s.id]);
        needsStartup = mine.isEmpty;
      } catch (_) {
        // Offline or denied: open Home; the shell loads the list again.
      }
    }
    if (!context.mounted) return;
    if (needsStartup) {
      // A verified founder who never created a startup continues where they
      // stopped: the first "Add your startup" step (no second verification).
      StartupStepsScreen.openOnboarding(context);
      return;
    }
    if (user.role == AccountRole.investor && !user.onboardingCompleted) {
      // Likewise a verified investor who did not finish the investor steps
      // continues at "Your investments" (step 3 of 4).
      InvestorInvestmentsScreen.open(context, user);
      return;
    }
    openHome(context);
    if (welcomeBack) {
      AppToast.showGlobal('Welcome back, ${user.firstName}');
    }
  }

  /// "Continue as guest": Home as a guest (reset, "up").
  static void openGuest(BuildContext context) {
    AppSession.instance.signInAsGuest();
    openHome(context);
  }

  /// Signs out of Firebase, forgets the session data and returns to Welcome
  /// with the back transition. A guest simply leaves.
  static Future<void> logOut(
    BuildContext context, {
    bool toLogin = false,
  }) async {
    if (!AppSession.instance.isGuest) {
      try {
        await AuthRepository.instance.signOut();
      } catch (_) {
        if (context.mounted) {
          AppToast.error(context, AppStrings.genericError);
        }
        return;
      }
    }
    SignupFlow.current = null;
    BookmarkRepository.instance.clear();
    RequestRepository.instance.clear();
    InterestRepository.instance.clear();
    AppSession.instance.signOut();
    if (!context.mounted) return;
    if (toLogin) {
      // Back transition to the Log in screen (the stack is cleared).
      AppNav.reset(
        context,
        const LoginScreen(),
        kind: RouteKind.back,
        greenHeader: true,
      );
    } else {
      openStart(context);
    }
  }
}
