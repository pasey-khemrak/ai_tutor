import 'dart:convert';

import 'package:ai_tutor/app/ai_tutor_app.dart';
import 'package:ai_tutor/core/config/app_config.dart';
import 'package:ai_tutor/core/network/api_client.dart';
import 'package:ai_tutor/core/routing/app_routes.dart';
import 'package:ai_tutor/core/routing/auth_route_guard.dart';
import 'package:ai_tutor/features/quizzes/quiz_catalog.dart';
import 'package:ai_tutor/shared/state_widgets/app_empty_state.dart';
import 'package:ai_tutor/shared/state_widgets/app_error_state.dart';
import 'package:ai_tutor/shared/state_widgets/app_loading_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('AppConfig builds stable backend URLs', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      backendBaseUrl: 'http://localhost:4000/api/v1/',
      aiServiceBaseUrl: 'http://localhost:8001/api/v1',
      useDemoAuth: true,
      useDemoTutorData: false,
    );

    expect(
      config.backendUri('/profile', {'grade': '10'}).toString(),
      'http://localhost:4000/api/v1/profile?grade=10',
    );
    expect(config.shouldUseDemoTutorData, isFalse);
  });

  test('AppConfig gates demo tutor data separately from demo auth', () {
    const demoAuthOnly = AppConfig(
      environment: AppEnvironment.development,
      backendBaseUrl: 'http://localhost:4000/api/v1',
      aiServiceBaseUrl: 'http://localhost:8001/api/v1',
      useDemoAuth: true,
      useDemoTutorData: false,
    );
    const demoTutor = AppConfig(
      environment: AppEnvironment.development,
      backendBaseUrl: 'http://localhost:4000/api/v1',
      aiServiceBaseUrl: 'http://localhost:8001/api/v1',
      useDemoAuth: true,
      useDemoTutorData: true,
    );
    const productionDemoFlag = AppConfig(
      environment: AppEnvironment.production,
      backendBaseUrl: 'http://localhost:4000/api/v1',
      aiServiceBaseUrl: 'http://localhost:8001/api/v1',
      useDemoAuth: true,
      useDemoTutorData: true,
    );

    expect(demoAuthOnly.shouldUseDemoData, isTrue);
    expect(demoAuthOnly.shouldUseDemoTutorData, isFalse);
    expect(demoTutor.shouldUseDemoTutorData, isTrue);
    expect(productionDemoFlag.shouldUseDemoTutorData, isFalse);
    expect(productionDemoFlag.shouldUseDemoData, isFalse);
  });

  test(
    'production configuration cannot provide the demo quiz catalog',
    () async {
      const production = AppConfig(
        environment: AppEnvironment.production,
        backendBaseUrl: 'http://localhost:4000/api/v1',
        aiServiceBaseUrl: 'http://localhost:8001/api/v1',
        useDemoAuth: true,
        useDemoTutorData: true,
      );

      final catalog = await QuizCatalogRepository(
        config: production,
      ).watchQuizzes().first;
      expect(catalog, isEmpty);
    },
  );

  test(
    'AuthRouteGuard redirects protected route when demo auth is disabled',
    () {
      final session = AuthSession(isAuthenticated: false);
      const config = AppConfig(
        environment: AppEnvironment.development,
        backendBaseUrl: 'http://localhost:4000/api/v1',
        aiServiceBaseUrl: 'http://localhost:8001/api/v1',
        useDemoAuth: false,
        useDemoTutorData: false,
      );

      final guard = AuthRouteGuard(config: config, session: session);

      expect(
        guard.resolveProtectedRoute(AppRoutes.dashboard),
        AppRoutes.signIn,
      );
      session.markSignedIn();
      expect(
        guard.resolveProtectedRoute(AppRoutes.dashboard),
        AppRoutes.dashboard,
      );
    },
  );

  test('ApiClient decodes JSON and includes bearer token', () async {
    final client = ApiClient(
      config: const AppConfig(
        environment: AppEnvironment.development,
        backendBaseUrl: 'http://localhost:4000/api/v1',
        aiServiceBaseUrl: 'http://localhost:8001/api/v1',
        useDemoAuth: true,
        useDemoTutorData: false,
      ),
      tokenProvider: () async => 'demo-token',
      httpClient: MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:4000/api/v1/health');
        expect(request.headers['Authorization'], 'Bearer demo-token');
        return http.Response(jsonEncode({'ok': true}), 200);
      }),
    );

    expect(await client.get('/health'), {'ok': true});
    client.close();
  });

  testWidgets('Reusable state widgets render in app theme', (tester) async {
    await tester.pumpWidget(
      const AiTutorApp(
        config: AppConfig(
          environment: AppEnvironment.development,
          backendBaseUrl: 'http://localhost:4000/api/v1',
          aiServiceBaseUrl: 'http://localhost:8001/api/v1',
          useDemoAuth: true,
          useDemoTutorData: false,
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Column(
          children: [
            Expanded(child: AppLoadingState(message: 'Loading data')),
            Expanded(child: AppEmptyState(title: 'No lessons')),
            Expanded(child: AppErrorState(message: 'Could not load')),
          ],
        ),
      ),
    );

    expect(find.text('Loading data'), findsOneWidget);
    expect(find.text('No lessons'), findsOneWidget);
    expect(find.text('Could not load'), findsOneWidget);
  });
}
