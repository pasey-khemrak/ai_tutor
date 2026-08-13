import 'package:ai_tutor/core/auth/auth_service.dart';
import 'package:ai_tutor/core/config/app_config.dart';
import 'package:ai_tutor/core/routing/app_routes.dart';
import 'package:ai_tutor/core/routing/auth_route_guard.dart';
import 'package:ai_tutor/screens/auth/auth_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.development,
    backendBaseUrl: 'http://localhost:4000/api/v1',
    aiServiceBaseUrl: 'http://localhost:8001/api/v1',
    useDemoAuth: false,
    useDemoTutorData: true,
  );

  setUp(() {
    appAuthSession.markSignedOut();
  });

  testWidgets('login validation requires valid email and password', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AuthFormScreen(initialIsSignUp: false)),
    );

    await tester.tap(find.text('Sign In').last);
    await tester.pump();

    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('auth-email-field')), 'bad');
    await tester.enterText(find.byKey(const Key('auth-password-field')), '123');
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Password must be at least 6 characters.'),
      findsOneWidget,
    );
  });

  testWidgets('register validation requires name email and password', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AuthFormScreen()));

    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  test('protected route redirects when auth is required', () {
    final guard = AuthRouteGuard(
      config: const AppConfig(
        environment: AppEnvironment.development,
        backendBaseUrl: 'http://localhost:4000/api/v1',
        aiServiceBaseUrl: 'http://localhost:8001/api/v1',
        useDemoAuth: false,
        useDemoTutorData: false,
      ),
      session: AuthSession(isAuthenticated: false),
    );

    expect(guard.resolveProtectedRoute(AppRoutes.dashboard), AppRoutes.signIn);
  });

  test('logout clears a locally held authenticated session without Firebase', () async {
    final session = AuthSession(isAuthenticated: true);
    final service = AuthService(config: config, session: session);

    await service.signOut();

    expect(session.isAuthenticated, isFalse);
  });
}
