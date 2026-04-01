import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static const String _placeholder = 'REPLACE_WITH_FIREBASE_VALUE';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return android;
    }
  }

  static bool get isConfigured {
    final options = currentPlatform;
    return options.apiKey != _placeholder &&
        options.appId != _placeholder &&
        options.projectId != _placeholder;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDSAao27qGYY2D6LKuxK3PQG4sQk7jVArY',
    appId: '1:836285276754:web:753c0f788c5c1e0923f58b',
    messagingSenderId: '836285276754',
    projectId: 'shecares-c000d',
    authDomain: 'shecares-c000d.firebaseapp.com',
    storageBucket: 'shecares-c000d.firebasestorage.app',
    measurementId: 'G-C3YG542NVS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4amSu0YgJ2yIK45CO9l6UA_Zo8bH92Z0',
    appId: '1:836285276754:android:bd697927522393b223f58b',
    messagingSenderId: '836285276754',
    projectId: 'shecares-c000d',
    storageBucket: 'shecares-c000d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD3rp1d3cIgcXTEHhuhB_m_cskV3uqrZxk',
    appId: '1:836285276754:ios:3b99f30a543d4e5923f58b',
    messagingSenderId: '836285276754',
    projectId: 'shecares-c000d',
    storageBucket: 'shecares-c000d.firebasestorage.app',
    iosBundleId: 'com.example.shecaresApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _placeholder,
    appId: _placeholder,
    messagingSenderId: _placeholder,
    projectId: _placeholder,
    storageBucket: 'shecares-placeholder.firebasestorage.app',
    iosBundleId: 'com.shecares.app',
  );
}