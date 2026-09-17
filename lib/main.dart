import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/ai_tutor_app.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebaseIfConfigured();
  runApp(const AiTutorApp());
}

Future<void> _initializeFirebaseIfConfigured() async {
  // Local demo mode deliberately has no Firebase dependency. Waiting for the
  // web SDK here can leave the first frame blank when the local browser is
  // offline or Firebase is unavailable.
  if (AppConfig.current.shouldUseDemoData) {
    return;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    // A staging/production build must not render a sign-in form that cannot
    // authenticate. Native Firebase config files (or generated options) are a
    // deployment requirement; development may still run without them.
    if (AppConfig.current.requiresProductionServices) {
      throw StateError(
        'Firebase is not configured for this ${AppConfig.current.environment.name} build: $error',
      );
    }
  }
}
