import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'app_routes.dart';

class AuthSession extends ValueNotifier<bool> {
  AuthSession({required bool isAuthenticated}) : super(isAuthenticated);

  bool get isAuthenticated => value;

  void markSignedIn() => value = true;
  void markSignedOut() => value = false;
}

final appAuthSession = AuthSession(isAuthenticated: false);

class AuthRouteGuard {
  const AuthRouteGuard({required this.config, required this.session});

  final AppConfig config;
  final AuthSession session;

  String resolveInitialRoute() {
    if (config.shouldUseDemoData) {
      session.markSignedIn();
      return AppRoutes.dashboard;
    }
    return AppRoutes.authGate;
  }

  String resolveProtectedRoute(String requestedRoute) {
    if (config.shouldUseDemoData || session.isAuthenticated) {
      return requestedRoute;
    }
    return AppRoutes.signIn;
  }
}
