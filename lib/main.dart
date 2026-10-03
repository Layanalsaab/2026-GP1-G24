import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/login_and_signup/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Show the splash immediately; Firebase initializes while it plays. The
  // splash waits for this before checking for a saved session.
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

  /// Completes when Firebase is initialized. Null means "already ready" (tests).
  final Future<void>? firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Start.sa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E7A3C),
        ),
        useMaterial3: true,
      ),
      home: SplashScreen(firebaseReady: firebaseReady),
    );
  }
}
