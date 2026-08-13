import 'package:ai_tutor/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production configuration cannot enable demo auth or tutor data', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      backendBaseUrl: 'https://api.example.com/api/v1',
      aiServiceBaseUrl: 'https://ai.example.com/api/v1',
      useDemoAuth: true,
      useDemoTutorData: true,
    );

    expect(config.shouldUseDemoData, isFalse);
    expect(config.shouldUseDemoTutorData, isFalse);
    expect(config.requiresProductionServices, isTrue);
  });

  test('staging configuration cannot enable demo auth or tutor data', () {
    const config = AppConfig(
      environment: AppEnvironment.staging,
      backendBaseUrl: 'https://staging-api.example.com/api/v1',
      aiServiceBaseUrl: 'https://staging-ai.example.com/api/v1',
      useDemoAuth: true,
      useDemoTutorData: true,
    );

    expect(config.shouldUseDemoData, isFalse);
    expect(config.shouldUseDemoTutorData, isFalse);
    expect(config.requiresProductionServices, isTrue);
  });

  test('development does not require deployed service configuration', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      backendBaseUrl: 'http://localhost:4000/api/v1',
      aiServiceBaseUrl: 'http://localhost:8001/api/v1',
      useDemoAuth: false,
    );

    expect(config.requiresProductionServices, isFalse);
  });

  test('an undeclared app environment cannot enable development demos', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      backendBaseUrl: 'http://localhost:4000/api/v1',
      aiServiceBaseUrl: 'http://localhost:8001/api/v1',
      useDemoAuth: true,
      useDemoTutorData: true,
      hasExplicitAppEnvironment: false,
    );

    expect(config.shouldUseDemoData, isFalse);
    expect(config.shouldUseDemoTutorData, isFalse);
  });
}
