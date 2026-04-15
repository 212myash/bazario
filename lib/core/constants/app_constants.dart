class AppConstants {
  static const String appName = 'Bazario';

  // Use the deployed backend by default; override with --dart-define when needed.
  static const String baseUrl = String.fromEnvironment(
    'BAZARIO_BASE_URL',
    defaultValue: 'https://bazario-5ahc.onrender.com',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
