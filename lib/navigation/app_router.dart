import 'dart:async';

import 'package:flutter/material.dart';

import '../app_constants/app_strings.dart';
import '../data_access/repositories/app_settings_repository.dart';
import '../data_access/repositories/auth_repository.dart';
import '../data_access/repositories/bookmark_repository.dart';
import '../data_access/repositories/not_interested_repository.dart';
import '../data_access/repositories/invitation_repository.dart';
import '../data_access/repositories/team_lookup.dart';
import '../app_constants/app_config.dart';
import '../features/startups/widgets/invitation_dialogs.dart';
import '../features/startups/widgets/startup_notices.dart';
import '../helpers/invitation_claimer.dart';
import '../data_access/repositories/startup_repository.dart';
import '../features/login_and_signup/screens/investor_investments_screen.dart';
import '../features/login_and_signup/screens/welcome_screen.dart';
import '../features/login_and_signup/screens/login_screen.dart';
import '../features/login_and_signup/screens/signup_screen.dart';
import '../features/login_and_signup/view_models/signup_flow.dart';
import '../features/startups/screens/startup_steps_screen.dart';
import '../helpers/app_session.dart';
import '../models/app_user.dart';
import '../shared_ui/navigation/app_route.dart';
import '../shared_ui/widgets/overlays/app_toast.dart';
import 'main_screen.dart';

/// Moving between the top-level areas of the app.
class AppRouter {
  AppRouter._();

  /// The Start screen (Welcome), with the back transition.
  static void openStart(BuildContext context) => WelcomeScreen.open(context);

  static void finishIntro(BuildContext context) {
    AppSettingsRepository.instance.markIntroSeen();
    openStart(context);
  }

  /// Home: reset, "up" transition.
  static void openHome(BuildContext context) => AppNav.reset(
    context,
    const MainScreen(),
    kind: RouteKind.up,
    greenHeader: true,
  );

  /// Where a user lands after log in, sign up or a restored session.
  static Future<void> openAfterLogin(
    BuildContext context,
    AppUser user, {
    bool welcomeBack = false,
    bool lostStartup = false,
  }) async {
    AppSession.instance.signIn(user);
    unawaited(BookmarkRepository.instance.load(user.uid));
    unawaited(NotInterestedRepository.instance.load(user.uid));
    // Teams can find this account by e-mail from now on.
    unawaited(TeamLookup.instance.publish(user, emailVerified: true));
    // Invitations to a team waiting for this e-mail.
    final joined = await _handleInvitations(context, user);
    if (!context.mounted) return;
    var needsStartup = false;
    if (user.role == AccountRole.founder) {
      try {
        final mine = await StartupRepository.instance.fetchMyStartups();
        AppSession.instance.setOwnStartupIds([for (final s in mine) s.id]);
        needsStartup = mine.isEmpty;
        if (needsStartup) {
          // Somebody who joined a team doesn't have to create a startup.
          try {
            needsStartup =
                (await StartupRepository.instance.fetchMemberStartups())
                    .isEmpty;
          } catch (_) {}
        }
      } catch (_) {}
    }
    if (!context.mounted) return;
    if (needsStartup) {
      StartupStepsScreen.openOnboarding(
        context,
        lostStartup: lostStartup || user.onboardingCompleted,
      );
      // Why the startup went (deleted, removed from the team, ...).
      _showNoticesLater();
      return;
    }
    if (user.role == AccountRole.investor && !user.onboardingCompleted) {
      InvestorInvestmentsScreen.open(context, user, resume: true);
      return;
    }
    openHome(context);
    if (joined.isNotEmpty) {
      AppToast.showGlobal(InvitationClaimer.addedMessage(joined));
    } else if (welcomeBack) {
      AppToast.showGlobal('Welcome back, ${user.firstName}');
    }
    if (user.role == AccountRole.founder) _showNoticesLater();
  }

  /// The notice inbox, once the next screen is up.
  static void _showNoticesLater() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = AppToast.navigatorKey.currentContext;
      if (ctx != null) unawaited(StartupNotices.showPending(ctx));
    });
  }

  static Future<bool> openIfNoStartupLeft(BuildContext context) async {
    final user = AppSession.instance.user;
    if (user == null || user.role != AccountRole.founder) return false;
    try {
      if (await StartupRepository.instance.hasAnyStartup()) return false;
    } catch (_) {
      return false;
    }
    if (!context.mounted) return false;
    await openAfterLogin(context, user, lostStartup: true);
    return true;
  }

  static Future<List<String>> _handleInvitations(
    BuildContext context,
    AppUser user,
  ) async {
    if (user.role != AccountRole.founder) {
      await InvitationClaimer.declineAll();
      return const [];
    }
    final joined = <String>[];
    final repo = InvitationRepository.instance;
    for (final invitation in await InvitationClaimer.pending()) {
      final ask = invitation.isOwner || !AppConfig.autoJoinExistingAccounts;
      var accept = !ask;
      if (ask) {
        if (!context.mounted) return joined;
        final answer = await showInvitationDecision(context, invitation);
        if (answer == null) continue; // decide later
        if (!answer) {
          try {
            await repo.decline(invitation);
          } catch (_) {}
          continue;
        }
        accept = true;
      }
      if (!accept) continue;
      try {
        await repo.accept(invitation, fullName: user.fullName);
        joined.add(invitation.startupName);
      } catch (_) {
        // Stays pending: it is offered again next time.
      }
    }
    return joined;
  }

  static Future<List<String>> askOwnerInvitations(
    BuildContext context,
    AppUser user,
  ) async {
    final owned = <String>[];
    final repo = InvitationRepository.instance;
    for (final invitation in await InvitationClaimer.pending()) {
      if (!invitation.isOwner) continue;
      if (!context.mounted) break;
      final answer = await showInvitationDecision(context, invitation);
      if (answer == null) continue;
      try {
        if (answer) {
          await repo.accept(invitation, fullName: user.fullName);
          owned.add(invitation.startupName);
        } else {
          await repo.decline(invitation);
        }
      } catch (_) {
        // Stays pending: it is asked again next time.
      }
    }
    return owned;
  }

  static Future<List<String>> checkInvitations(BuildContext context) async {
    final user = AppSession.instance.user;
    if (user == null || AppSession.instance.isGuest) return const [];
    try {
      final joined = await _handleInvitations(context, user);
      if (joined.isNotEmpty) {
        AppToast.showGlobal(InvitationClaimer.addedMessage(joined));
      }
      return joined;
    } catch (_) {
      return const [];
    }
  }

  /// "Continue as guest": Home as a guest (reset, "up").
  static void openGuest(BuildContext context) {
    AppSession.instance.signInAsGuest();
    openHome(context);
  }

  static Future<void> logOut(
    BuildContext context, {
    bool toLogin = false,
    String? email,
    bool signup = false,
  }) async {
    // Taken before the wait: the message lives above every screen.
    final messenger = ScaffoldMessenger.maybeOf(context);
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
    NotInterestedRepository.instance.clear();
    AppSession.instance.signOut();
    // A message such as "We’ll show fewer startups like this · Undo" must not
    // follow the user to the next screen.
    messenger?.hideCurrentSnackBar();
    if (!context.mounted) return;
    if (toLogin) {
      // Back transition to the Log in screen (the stack is cleared).
      Widget screen = LoginScreen(email: email);
      if (signup && email != null) {
        final flow = SignupFlow(role: AccountRole.founder)..fromInvite = true;
        SignupFlow.current = flow;
        screen = SignupScreen(
          role: AccountRole.founder,
          flow: flow,
          email: email,
        );
      }
      AppNav.reset(context, screen, kind: RouteKind.back, greenHeader: true);
    } else {
      openStart(context);
    }
  }
}
