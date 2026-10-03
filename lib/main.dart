import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/login_and_signup/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Show the splash immediately; Firebase initializes in the background so a
  // slow or failed init can never leave the app on a blank screen.
  runApp(const StartSaApp());
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }
}

class StartSaApp extends StatelessWidget {
  const StartSaApp({super.key});

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
      home: const SplashScreen(),
    );
  }
}
