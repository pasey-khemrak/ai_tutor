import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase options are not configured. Run FlutterFire CLI to generate '
      'lib/firebase_options.dart for connected environments.',
    );
  }
}
