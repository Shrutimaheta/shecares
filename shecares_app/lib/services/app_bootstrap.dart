import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class AppBootstrap {
  AppBootstrap._();

  static final AppBootstrap instance = AppBootstrap._();

  bool _initialized = false;
  bool firebaseReady = false;

  bool get isConfigured => DefaultFirebaseOptions.isConfigured;
  bool get allowsLocalFallback => !firebaseReady && !kReleaseMode;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    if (!DefaultFirebaseOptions.isConfigured) {
      if (kReleaseMode) {
        throw StateError(
          'Firebase is not configured for release builds. Add the generated Firebase options first.',
        );
      }

      debugPrint(
        'Firebase config is still using placeholders. Live backend is disabled until project files are added.',
      );
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseReady = true;
    } catch (error, stackTrace) {
      debugPrint('Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      firebaseReady = false;

      if (kReleaseMode) {
        rethrow;
      }
    }
  }
}
