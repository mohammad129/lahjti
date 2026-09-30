/// Environment configuration for the Lahjti application.
///
/// Secrets and environment-specific values should never be hardcoded.
/// Pass values at build/run time using:
/// `flutter run --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://...`
/// or `flutter run --dart-define-from-file=.env`
enum AppEnvironment {
  dev,
  pilot,
  staging,
  prod;

  static AppEnvironment fromString(String env) {
    switch (env.toLowerCase().trim()) {
      case 'pilot':
        return AppEnvironment.pilot;
      case 'staging':
        return AppEnvironment.staging;
      case 'prod':
      case 'production':
        return AppEnvironment.prod;
      case 'dev':
      case 'development':
      default:
        return AppEnvironment.dev;
    }
  }

  bool get isDev => this == AppEnvironment.dev;
  bool get isPilot => this == AppEnvironment.pilot;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProd => this == AppEnvironment.prod;
}

class EnvConfig {
  EnvConfig._();

  /// Current application environment
  static final AppEnvironment environment = AppEnvironment.fromString(
    // A release APK must never silently point at a private LAN address. Local
    // development remains available explicitly through --dart-define=APP_ENV=dev.
    const String.fromEnvironment('APP_ENV', defaultValue: 'pilot'),
  );

  /// Configurable host used only when APP_ENV=dev.
  static const String devHost = String.fromEnvironment(
    'BACKEND_HOST',
    defaultValue: '',
  );

  /// Configurable Port for local development
  static const String devPort = String.fromEnvironment(
    'BACKEND_PORT',
    defaultValue: '3000',
  );

  /// API Base URL (defaults according to environment)
  static String get apiBaseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (customUrl.isNotEmpty) {
      return customUrl.trim();
    }

    switch (environment) {
      case AppEnvironment.dev:
        if (devHost.isEmpty) {
          throw StateError(
            'Development requires API_BASE_URL or BACKEND_HOST via --dart-define.',
          );
        }
        return 'http://$devHost:$devPort/api/v1';
      case AppEnvironment.pilot:
        const pilotUrl = String.fromEnvironment(
          'PILOT_API_URL',
          defaultValue: 'https://lahjti-backend.onrender.com/api/v1',
        );
        return pilotUrl.trim();
      case AppEnvironment.staging:
        return 'https://api-staging.lahjti.com/api/v1';
      case AppEnvironment.prod:
        return 'https://api.lahjti.com/api/v1';
    }
  }

  /// Request connection & receive timeout in milliseconds
  static const int connectTimeoutMs = int.fromEnvironment(
    'API_CONNECT_TIMEOUT_MS',
    defaultValue: 15000,
  );

  static const int receiveTimeoutMs = int.fromEnvironment(
    'API_RECEIVE_TIMEOUT_MS',
    defaultValue: 25000,
  );

  /// Enable detailed network logging in non-production environments
  static bool get enableLogging => !environment.isProd;
}
