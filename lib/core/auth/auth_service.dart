import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config/app_config.dart';
import '../routing/auth_route_guard.dart';

class AuthResult {
  const AuthResult({required this.isDemo});

  final bool isDemo;
}

class AuthService {
  AuthService({
    required this.config,
    required this.session,
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth;

  final AppConfig config;
  final AuthSession session;
  final FirebaseAuth? _firebaseAuth;

  bool get _hasFirebase => Firebase.apps.isNotEmpty;
  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  Future<bool> restoreSession() async {
    if (_hasFirebase && _auth.currentUser != null) {
      session.markSignedIn();
      return true;
    }
    if (config.shouldUseDemoData && session.isAuthenticated) {
      return true;
    }
    session.markSignedOut();
    return false;
  }

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_hasFirebase) {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      session.markSignedIn();
      return const AuthResult(isDemo: false);
    }

    if (!config.shouldUseDemoData) {
      throw const AuthException('Firebase is not configured for this app.');
    }

    session.markSignedIn();
    return const AuthResult(isDemo: true);
  }

  Future<AuthResult> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    if (_hasFirebase) {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (name.trim().isNotEmpty) {
        await _auth.currentUser?.updateDisplayName(name.trim());
      }
      session.markSignedIn();
      return const AuthResult(isDemo: false);
    }

    if (!config.shouldUseDemoData) {
      throw const AuthException('Firebase is not configured for this app.');
    }

    session.markSignedIn();
    return const AuthResult(isDemo: true);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (_hasFirebase) {
      await _auth.sendPasswordResetEmail(email: email);
      return;
    }

    if (!config.shouldUseDemoData) {
      throw const AuthException('Firebase is not configured for this app.');
    }
  }

  Future<void> signOut() async {
    if (_hasFirebase) {
      await _auth.signOut();
    }
    session.markSignedOut();
  }

  /// Supplies the Firebase ID token to authenticated API calls. Demo credentials
  /// are intentionally available only when the explicit development flag is on.
  Future<String?> getAccessToken() async {
    if (_hasFirebase) return _auth.currentUser?.getIdToken();
    return config.shouldUseDemoData ? 'demo-token' : null;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

final appAuthService = AuthService(
  config: AppConfig.current,
  session: appAuthSession,
);
