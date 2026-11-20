import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// The Firebase settings used by Firebase.initializeApp.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('Start.sa is built for Android only.');
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC7WlPAmIUI4jk5TzbtMBEtl5F5vXMNQrg',
    appId: '1:938448723456:android:ac296d037d3546c81582e5',
    messagingSenderId: '938448723456',
    projectId: 'startsa-ea49e',
    storageBucket: 'startsa-ea49e.firebasestorage.app',
  );
}
