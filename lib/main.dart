import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/login_and_signup/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'navigation/invite_links.dart';
import 'shared_ui/theme/app_colors.dart';
import 'shared_ui/theme/app_theme.dart';
import 'shared_ui/theme/theme_controller.dart';
import 'shared_ui/widgets/overlays/app_toast.dart';
import 'navigation/app_route_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.load();
  unawaited(InviteLinks.init());
  runApp(StartSaApp(firebaseReady: _initFirebase()));
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
}

class StartSaApp extends StatelessWidget {
  const StartSaApp({super.key, this.firebaseReady});

  /// Completes when Firebase is initialized.
  final Future<void>? firebaseReady;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) => MaterialApp(
        title: 'Start.sa',
        debugShowCheckedModeBanner: false,
        navigatorKey: AppToast.navigatorKey,
        navigatorObservers: [appRouteObserver],
        themeMode: mode,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        builder: (context, child) => mode == ThemeMode.dark
            ? AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                  statusBarBrightness: Brightness.dark,
                  systemNavigationBarColor: AppColors.cream,
                  systemNavigationBarIconBrightness: Brightness.light,
                  systemNavigationBarDividerColor: AppColors.cream,
                ),
                child: child ?? const SizedBox.shrink(),
              )
            : (child ?? const SizedBox.shrink()),
        home: SplashScreen(firebaseReady: firebaseReady),
      ),
    );
  }
}
