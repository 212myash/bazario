class AppConstants {
  static const String appName = 'Bazario';

  // Use your deployed backend URL for release builds.
  static const String baseUrl = String.fromEnvironment(
    'BAZARIO_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
