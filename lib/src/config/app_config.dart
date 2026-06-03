class AppConfig {
  // Configurable base URL - allows running frontend on any port independently
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Optional API prefix (currently not used but kept for future)
  static const String apiPrefix = '';

  /// Helper method to get full endpoint URL
  static String getEndpoint(String path) {
    // Ensure path starts with '/'
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$cleanPath';
  }

  /// Default headers for API calls
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}