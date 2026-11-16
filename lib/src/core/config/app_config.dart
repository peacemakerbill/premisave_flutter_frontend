import 'package:flutter/foundation.dart';

/// Build-time configuration. Override with --dart-define, for example:
///
///   flutter run -d chrome --web-port=3000 --dart-define=BASE_URL=http://localhost:8080
///   flutter run --dart-define=BASE_URL=https://auth.example.com
class AppConfig {
  AppConfig._();

  static const String appName = 'Premisave';
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@premisave.com',
  );

  static const String _envBaseUrl = String.fromEnvironment('BASE_URL');

  /// Auth-service base URL without a trailing slash.
  ///
  /// Defaults: Android emulator reaches the host machine on 10.0.2.2, everything
  /// else (web, iOS simulator, desktop) uses localhost.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl.endsWith('/')
          ? _envBaseUrl.substring(0, _envBaseUrl.length - 1)
          : _envBaseUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  /// Turns a stored picture path into a full URL. Absolute URLs pass through untouched.
  static String? mediaUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://') || u.startsWith('data:')) return u;
    return u.startsWith('/') ? '$baseUrl$u' : '$baseUrl/$u';
  }

  /// Sent on every request. "mobile" tells the backend to return the remembered
  /// device token in the JSON body (instead of an HttpOnly cookie), which is what
  /// every Flutter target, including web, needs.
  static const String clientPlatform = 'mobile';

  /// OAuth web client ID (Google Cloud console). Needed on Android so Google
  /// returns an ID token the backend can verify. Optional on iOS and web.
  static const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

  /// GitHub OAuth app client ID (public). The sign-in button shows only when this and
  /// [githubRedirectUri] are set. The redirect URI must match the callback URL of the
  /// GitHub OAuth app, for example http://localhost:3000/auth.html while developing.
  static const String githubClientId = String.fromEnvironment('GITHUB_CLIENT_ID');
  static const String githubRedirectUri = String.fromEnvironment('GITHUB_REDIRECT_URI');

  /// Facebook app ID (public). Needed on web and desktop; mobile reads it from the native setup.
  static const String facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
