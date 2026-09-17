import 'package:ai_tutor/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression specification for the Firebase branch in `lib/main.dart`.
///
/// The initializer is intentionally private to the app entrypoint, so this
/// test verifies the immutable configuration policy used by that branch:
/// local demo startup bypasses Firebase, while staging and production do not.
void main() {
  group('app startup Firebase policy', () {
    test('explicit development demo mode is eligible to bypass Firebase', () {
      const config = AppConfig(
        environment: AppEnvironment.development,
        backendBaseUrl: 'http://localhost:4000/api/v1',
        aiServiceBaseUrl: 'http://localhost:8001/api/v1',
        useDemoAuth: true,
        hasExplicitAppEnvironment: true,
      );

      expect(config.shouldUseDemoData, isTrue);
      expect(config.requiresProductionServices, isFalse);
    });

    test('staging remains in the Firebase-required startup path', () {
      const config = AppConfig(
        environment: AppEnvironment.staging,
        backendBaseUrl: 'https://staging.example.com/api/v1',
        aiServiceBaseUrl: 'https://staging-ai.example.com/api/v1',
        useDemoAuth: true,
      );

      expect(config.shouldUseDemoData, isFalse);
      expect(config.requiresProductionServices, isTrue);
    });

    test('production remains in the Firebase-required startup path', () {
      const config = AppConfig(
        environment: AppEnvironment.production,
        backendBaseUrl: 'https://example.com/api/v1',
        aiServiceBaseUrl: 'https://ai.example.com/api/v1',
        useDemoAuth: true,
      );

      expect(config.shouldUseDemoData, isFalse);
      expect(config.requiresProductionServices, isTrue);
    });
  });
}
