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
    defaultValue: 'thepeacemakerske@gmail.com',
  );

  static const String _envBaseUrl = String.fromEnvironment('BASE_URL');
  static const String _envMessengerUrl = String.fromEnvironment('MESSENGER_URL');
  static const String _envInviteBaseUrl = String.fromEnvironment('GROUP_INVITE_BASE_URL');
  static const String _envListingUrl = String.fromEnvironment('LISTING_URL');
  static const String _envWalletUrl = String.fromEnvironment('WALLET_URL');
  static const String _envPropertyUrl = String.fromEnvironment('PROPERTY_URL');
  static const String _envC2bUrl = String.fromEnvironment('C2B_URL');
  static const String _envDeveloperUrl = String.fromEnvironment('DEVELOPER_URL');
  static const String _envGeocoderUrl = String.fromEnvironment('GEOCODER_URL');
  static const String _envMapTileUrl = String.fromEnvironment('MAP_TILE_URL');
  static const String _envMapsAndroid = String.fromEnvironment('GOOGLE_MAPS_ANDROID_KEY');
  static const String _envMapsIos = String.fromEnvironment('GOOGLE_MAPS_IOS_KEY');
  static const String _envMapsWeb = String.fromEnvironment('GOOGLE_MAPS_WEB_KEY');

  /// Address search server. The default is the free public Photon server, which is meant for modest traffic.
  /// For a large launch run your own Photon server or use a paid provider and set GEOCODER_URL.
  static String get geocoderUrl {
    final u = _envGeocoderUrl.isEmpty ? 'https://photon.komoot.io' : _envGeocoderUrl;
    return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
  }

  /// Map tile template. The default is the free OpenStreetMap server, which has a fair use policy.
  /// For a large launch use a tile provider with an account and set MAP_TILE_URL.
  static String get mapTileUrl => _envMapTileUrl.isEmpty ? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png' : _envMapTileUrl;

  /// True where Google's map component exists: Android, iOS and the web. It has no Linux, Windows or macOS version.
  static bool get googleMapsSupported => kIsWeb || defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

  /// The public Google Maps key for this platform, or an empty string when none is configured. Each platform has its
  /// own key, restricted to that platform in the Google Cloud console. These are not secrets, unlike the auth-service key.
  static String get googleMapsKey {
    if (kIsWeb) return _envMapsWeb;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _envMapsAndroid;
      case TargetPlatform.iOS:
        return _envMapsIos;
      default:
        return '';
    }
  }

  /// Draw maps with Google Maps. Otherwise they use OpenStreetMap.
  static bool get useGoogleMap => googleMapsSupported && googleMapsKey.isNotEmpty;

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

  /// Messenger service base URL without a trailing slash (REST under /api, live updates at /ws-messenger).
  ///
  /// Defaults: Android emulator reaches the host machine on 10.0.2.2, everything else uses localhost.
  static String get messengerUrl {
    if (_envMessengerUrl.isNotEmpty) {
      return _envMessengerUrl.endsWith('/') ? _envMessengerUrl.substring(0, _envMessengerUrl.length - 1) : _envMessengerUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8081';
    }
    return 'http://localhost:8081';
  }

  /// Address of one of the other Premisave services. [fromEnv] is the value given with --dart-define and [port] is
  /// where the service listens on a developer machine. The Android emulator reaches the host machine on 10.0.2.2.
  static String _serviceUrl(String fromEnv, int port) {
    if (fromEnv.isNotEmpty) {
      return fromEnv.endsWith('/') ? fromEnv.substring(0, fromEnv.length - 1) : fromEnv;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$port';
    }
    return 'http://localhost:$port';
  }

  /// Listing service: listings, bookings, interests and availability. Default port 8082.
  static String get listingUrl => _serviceUrl(_envListingUrl, 8082);

  /// Wallet service: balance, deposits, withdrawals, transfers and history. Default port 8084.
  static String get walletUrl => _serviceUrl(_envWalletUrl, 8084);

  /// Property management service: properties, units, leases, rent and maintenance. Default port 8085.
  static String get propertyUrl => _serviceUrl(_envPropertyUrl, 8085);

  /// C2B Hakikisha service: M-Pesa account name lookup. Default port 8090.
  static String get c2bUrl => _serviceUrl(_envC2bUrl, 8090);

  /// Developer service: the developer portal API. It has its own accounts. Default port 8091.
  static String get developerUrl => _serviceUrl(_envDeveloperUrl, 8091);

  /// The live updates address: the messenger URL with http turned into ws.
  static String get messengerSocketUrl => '${messengerUrl.replaceFirst(RegExp('^http', caseSensitive: false), 'ws')}/ws-messenger';

  /// Start of every shared group invite link. It must match GROUP_INVITE_BASE_URL on the messenger service,
  /// because the app reads the invite code from the end of a pasted or scanned link.
  static String get inviteBaseUrl {
    final u = _envInviteBaseUrl.isEmpty ? 'https://premisave.com/join' : _envInviteBaseUrl;
    return u.endsWith('/') ? u.substring(0, u.length - 1) : u;
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
  static const String _googleWebClient = '836161536260-b3p6bk2q8tdtrdd636faeka3dhps3d6m.apps.googleusercontent.com';
  static const String googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: _googleWebClient);
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: _googleWebClient);

  /// GitHub OAuth app client ID (public). The sign-in button shows only when this and
  /// [githubRedirectUri] are set. The redirect URI must match the callback URL of the
  /// GitHub OAuth app, for example http://localhost:3000/auth.html while developing.
  static const String githubClientId = String.fromEnvironment('GITHUB_CLIENT_ID', defaultValue: 'Ov23lipa2Rcs6Nj7Bgbj');
  static const String _envGithubRedirect = String.fromEnvironment('GITHUB_REDIRECT_URI');

  /// Debug builds fall back to the local web address, so GitHub sign in works with no extra setup.
  static String get githubRedirectUri =>
      _envGithubRedirect.isNotEmpty ? _envGithubRedirect : (kDebugMode ? 'http://localhost:3000/auth.html' : '');

  /// Facebook app ID (public). Needed on web and desktop; mobile reads it from the native setup.
  static const String facebookAppId = String.fromEnvironment('FACEBOOK_APP_ID', defaultValue: '2045533782824957');

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
