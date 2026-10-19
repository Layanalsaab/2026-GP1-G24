import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app_constants/auth_strings.dart';
import '../../../data_access/repositories/app_settings_repository.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../models/app_user.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/motion/motion.dart';
import '../../../shared_ui/navigation/app_route.dart';
import '../../../shared_ui/theme/app_colors.dart';
import '../../../shared_ui/theme/app_text.dart';
import '../widgets/auth_decor.dart';
import 'intro_screen.dart';
import 'welcome_screen.dart';

/// Splash (docs/05 A1): cream, three arches drawing in, the logo, "Start.sa",
/// the tagline and a gold divider. Holds 2.6 s (or until tapped), meanwhile
/// waiting for Firebase and looking for a saved session: a signed-in user
/// goes to their home, a first-time visitor to the intro, everyone else to
/// Welcome.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.firebaseReady});

  /// Completes when Firebase has finished initializing. Null means ready.
  final Future<void>? firebaseReady;

  /// How long the splash holds before moving on.
  static const hold = Duration(milliseconds: 2600);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Completer<void> _tap = Completer<void>();
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final decision = _decide();
    await Future.any<void>([
      Future<void>.delayed(SplashScreen.hold),
      _tap.future,
    ]);
    final result = await decision;
    if (!mounted || _left) return;
    _left = true;
    if (result.user != null) {
      AppRouter.openAfterLogin(context, result.user!);
    } else if (result.introSeen) {
      AppNav.reset(context, const WelcomeScreen(), kind: RouteKind.fade);
    } else {
      AppNav.reset(context, const IntroScreen(), kind: RouteKind.fade);
    }
  }

  Future<({AppUser? user, bool introSeen})> _decide() async {
    final seen = AppSettingsRepository.instance.hasSeenIntro();
    AppUser? user;
    try {
      await widget.firebaseReady;
      user = await AuthRepository.instance.restoreSession();
    } catch (_) {
      user = null; // Any problem restoring the session means "not signed in".
    }
    return (user: user, introSeen: await seen);
  }

  void _skip() {
    if (!_tap.isCompleted) _tap.complete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Semantics(
        button: true,
        label: 'Continue',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _skip,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const SplashBackdrop(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LogoIn(child: const BrandLogo(width: 150, height: 143)),
                    const SizedBox(height: 24),
                    FadeInOnce(
                      delay: const Duration(milliseconds: 350),
                      child: Text(
                        AuthStrings.appName,
                        style: AppText.wordmarkSplash,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeInOnce(
                      delay: const Duration(milliseconds: 550),
                      child: Text(
                        AuthStrings.tagline,
                        style: AppText.sans(size: 15, color: AppColors.grey),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const FadeInOnce(
                      delay: Duration(milliseconds: 700),
                      child: GoldDivider(),
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
}
