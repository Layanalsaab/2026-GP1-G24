import 'package:flutter/material.dart';

import '../../../data_access/repositories/app_settings_repository.dart';
import '../../../data_access/repositories/auth_repository.dart';
import '../../../models/app_user.dart';
import '../../../navigation/app_router.dart';
import '../../../shared_ui/common_widgets/design_canvas.dart';
import '../../../shared_ui/common_widgets/gold_divider.dart';
import '../../../shared_ui/common_widgets/house_rings.dart';
import '../../../shared_ui/theme/app_theme.dart';
import 'intro_one_screen.dart';

/// Figma: "V2 · 01 · Splash"
///
/// While the logo shows, it waits for Firebase and checks for a saved session:
/// a verified, signed-in user goes straight to their home; everyone else
/// goes to Welcome, or to the intro screens on the very first launch.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.firebaseReady});

  /// Completes when Firebase has finished initializing. Null means ready.
  final Future<void>? firebaseReady;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  static const _sparkles = [
    Offset(48, 90),
    Offset(310, 130),
    Offset(70, 560),
    Offset(300, 600),
    Offset(40, 260),
    Offset(320, 310),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _continueAfterSplash();
  }

  Future<void> _continueAfterSplash() async {
    final minimumSplash = Future<void>.delayed(const Duration(milliseconds: 2800));

    final introSeenFuture = AppSettingsRepository.instance.hasSeenIntro();

    AppUser? user;
    try {
      await widget.firebaseReady;
      user = await AuthRepository.instance.restoreSession();
    } catch (_) {
      user = null; // Any problem restoring the session just means "not signed in".
    }
    final introSeen = await introSeenFuture;
    await minimumSplash;
    if (!mounted) return;

    if (user != null) {
      AppRouter.openHome(context, user); // signed in: straight to their screen
    } else if (introSeen) {
      AppRouter.openStart(context); // returning visitor: skip the intros
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const IntroOneScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesignCanvas(
      background: AppColors.cream,
      children: [
        ...houseRings(sparkles: _sparkles),
        Positioned.fill(
          child: FadeTransition(
            opacity: _fade,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 87,
                  top: 222,
                  width: 186,
                  height: 177,
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 432,
                  child: Text(
                    'Start.sa',
                    textAlign: TextAlign.center,
                    style: AppText.serif(size: 44, color: AppColors.green),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 492,
                  child: Text(
                    'Connect. Invest. Grow.',
                    textAlign: TextAlign.center,
                    style: AppText.sans(size: 15, color: AppColors.grey),
                  ),
                ),
                ...goldDivider(lineTop: 540),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
