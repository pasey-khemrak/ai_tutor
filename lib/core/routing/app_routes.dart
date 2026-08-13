import 'package:flutter/material.dart';

import '../../app/tutor_shell.dart';
import '../../screens/auth/auth_gate_screen.dart';
import '../../screens/auth/auth_form_screen.dart';
import '../../screens/auth/auth_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/setup_flow_screen.dart';
import 'auth_route_guard.dart';

class AppRoutes {
  const AppRoutes._();

  static const intro = '/';
  static const authGate = '/auth/check';
  static const signIn = '/auth/sign-in';
  static const signUp = '/auth/sign-up';
  static const forgotPassword = '/auth/forgot-password';
  static const onboarding = '/onboarding';
  static const dashboard = '/dashboard';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    AuthRouteGuard? guard,
  }) {
    final resolvedName = guard == null
        ? settings.name
        : _resolveGuardedRoute(settings.name, guard);

    final builder = switch (resolvedName) {
      authGate => (_) => const AuthGateScreen(),
      intro => (_) => const AuthScreen(),
      signIn => (_) => const AuthFormScreen(initialIsSignUp: false),
      signUp => (_) => const AuthFormScreen(),
      forgotPassword => (_) => const ForgotPasswordScreen(),
      onboarding => (_) => const SetupFlowScreen(),
      dashboard => (_) => const TutorShell(),
      _ => (_) => const AuthScreen(),
    };

    return MaterialPageRoute<void>(settings: settings, builder: builder);
  }

  static String? _resolveGuardedRoute(String? routeName, AuthRouteGuard guard) {
    return switch (routeName) {
      dashboard => guard.resolveProtectedRoute(dashboard),
      _ => routeName,
    };
  }
}
