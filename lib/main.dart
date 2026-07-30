import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/ai_tutor_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebaseIfConfigured();
  runApp(const AiTutorApp());
}

Future<void> _initializeFirebaseIfConfigured() async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // The quiz catalog falls back to local demo data until Firebase config
    // files/options are added for this app.
  }
}
