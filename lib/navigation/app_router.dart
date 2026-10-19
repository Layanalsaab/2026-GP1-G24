import 'package:flutter/material.dart';

import '../app_constants/app_strings.dart';
import '../data_access/repositories/app_settings_repository.dart';
import '../data_access/repositories/auth_repository.dart';
import '../data_access/repositories/bookmark_repository.dart';
import '../data_access/repositories/interest_repository.dart';
import '../data_access/repositories/request_repository.dart';
import '../data_access/repositories/startup_repository.dart';
import '../features/login_and_signup/screens/verify_email_screen.dart';
import '../features/login_and_signup/screens/welcome_screen.dart';
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
  /// with no startup goes to the onboarding "Add your startup" steps; everyone
  /// else to Home. [welcomeBack] shows "Welcome back" with the first name.
  static Future<void> openAfterLogin(
    BuildContext context,
    AppUser user, {
    bool welcomeBack = false,
  }) async {
    AppSession.instance.signIn(user);
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
      // The founder never created a startup, so the account is not complete:
      // they authenticate again before "Add your startup".
      await VerifyEmailScreen.openForIncompleteFounder(context, user);
      return;
    } else {
      openHome(context);
    }
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
  static Future<void> logOut(BuildContext context) async {
    if (!AppSession.instance.isGuest) {
      try {
        await AuthRepository.instance.signOut();
      } catch (_) {
        if (context.mounted) {
          AppToast.show(context, AppStrings.genericError);
        }
        return;
      }
    }
    BookmarkRepository.instance.clear();
    RequestRepository.instance.clear();
    InterestRepository.instance.clear();
    AppSession.instance.signOut();
    if (context.mounted) openStart(context);
  }
}
