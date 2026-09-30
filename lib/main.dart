import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
//tests shahad
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const StartSaApp());
}

class StartSaApp extends StatelessWidget {
  const StartSaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Start.sa',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E7A3C),
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rocket_launch, size: 80, color: Color(0xFF1E7A3C)),
              SizedBox(height: 20),
              Text(
                'Start.sa',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F4A24),
                ),
              ),
              SizedBox(height: 10),
              Text(
                '🔥 Firebase Connected!',
                style: TextStyle(fontSize: 18, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}