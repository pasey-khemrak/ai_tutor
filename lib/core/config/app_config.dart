enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment fromName(String value) {
    return switch (value.trim().toLowerCase()) {
      'production' || 'prod' => AppEnvironment.production,
      'staging' || 'stage' => AppEnvironment.staging,
      _ => AppEnvironment.development,
    };
  }
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.backendBaseUrl,
    required this.aiServiceBaseUrl,
    required this.useDemoAuth,
    this.useDemoTutorData = false,
    this.hasExplicitAppEnvironment = true,
  });

  static String resolveDefaultBackendUrl([Uri? pageUri]) {
    final base = pageUri ?? Uri.base;
    final scheme = base.scheme.toLowerCase();
    final host = base.host.toLowerCase();
    if ((scheme == 'http' || scheme == 'https') &&
        (host == 'localhost' || host == '127.0.0.1')) {
      return 'http://localhost:4000/api/v1';
    }
    if ((scheme == 'http' || scheme == 'https') && host.isNotEmpty) {
      return '${base.origin}/api/v1';
    }
    return 'https://aitutor.mekhla.digital/api/v1';
  }

  factory AppConfig.fromEnvironment() {
    const envName = String.fromEnvironment(
      'APP_ENV',
      defaultValue: '',
    );
    const configuredBackendUrl = String.fromEnvironment(
      'BACKEND_BASE_URL',
      defaultValue: '',
    );
    final backendUrl = configuredBackendUrl.trim().isNotEmpty
        ? configuredBackendUrl.trim()
        : resolveDefaultBackendUrl();
    const aiServiceUrl = String.fromEnvironment(
      'AI_SERVICE_BASE_URL',
      defaultValue: 'http://localhost:8001/api/v1',
    );
    const useDemoAuth = bool.fromEnvironment(
      'USE_DEMO_AUTH',
      defaultValue: false,
    );
    const useDemoTutorData = bool.fromEnvironment(
      'USE_DEMO_TUTOR_DATA',
      defaultValue: false,
    );

    return AppConfig(
      environment: AppEnvironment.fromName(envName),
      backendBaseUrl: backendUrl,
      aiServiceBaseUrl: aiServiceUrl,
      useDemoAuth: useDemoAuth,
      useDemoTutorData: useDemoTutorData,
      hasExplicitAppEnvironment: envName.trim().toLowerCase() == 'development',
    );
  }

  final AppEnvironment environment;
  final String backendBaseUrl;
  final String aiServiceBaseUrl;
  final bool useDemoAuth;
  final bool useDemoTutorData;
  /// Demo paths are local-only and require an explicit APP_ENV=development.
  final bool hasExplicitAppEnvironment;

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get requiresProductionServices => !isDevelopment;
  bool get shouldUseDemoData =>
      isDevelopment && hasExplicitAppEnvironment && useDemoAuth;
  bool get shouldUseDemoTutorData =>
      isDevelopment && hasExplicitAppEnvironment && useDemoTutorData;

  Uri backendUri(String path, [Map<String, String>? queryParameters]) {
    return _joinUri(backendBaseUrl, path, queryParameters);
  }

  Uri aiServiceUri(String path, [Map<String, String>? queryParameters]) {
    return _joinUri(aiServiceBaseUrl, path, queryParameters);
  }

  static Uri _joinUri(
    String baseUrl,
    String path,
    Map<String, String>? queryParameters,
  ) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBase$normalizedPath');
    return queryParameters == null || queryParameters.isEmpty
        ? uri
        : uri.replace(queryParameters: queryParameters);
  }

  static final current = AppConfig.fromEnvironment();
}
