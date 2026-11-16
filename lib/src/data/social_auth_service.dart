import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/config/app_config.dart';
import '../core/network/api_exception.dart';

/// Gets a provider token on the device. The backend turns it into a Premisave session
/// (POST /auth/google, POST /auth/facebook, POST /auth/github).
///
/// GitHub uses a browser window: the person approves in GitHub and the app receives an
/// authorization code, which the backend exchanges for their profile.
class SocialAuthService {
  SocialAuthService._();

  static bool get _isWeb => kIsWeb;
  static bool get _android => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static bool get _ios => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static bool get _mac => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  static bool get _windows => !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  static bool get _linux => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

  /// Google's plugin has no Linux or Windows implementation, and its web version often returns
  /// no ID token. On those platforms Google opens in the browser instead, like GitHub does.
  static bool get _googleViaBrowser => _isWeb || _linux || _windows;

  static bool get googleAvailable {
    if (_googleViaBrowser) {
      return AppConfig.googleClientId.isNotEmpty && AppConfig.githubRedirectUri.isNotEmpty;
    }
    return _android || _ios || _mac;
  }

  /// Facebook's plugin has no Linux implementation, and web and desktop need the app ID.
  static bool get facebookAvailable {
    if (_linux) return false;
    if (_isWeb || _windows || _mac) return AppConfig.facebookAppId.isNotEmpty;
    return true;
  }

  /// GitHub works everywhere a browser can open, once the client ID and redirect are set.
  static bool get githubAvailable =>
      AppConfig.githubClientId.isNotEmpty && AppConfig.githubRedirectUri.isNotEmpty;

  static bool get anyAvailable => googleAvailable || facebookAvailable || githubAvailable;

  static String get _where {
    if (_linux) return 'Linux desktop';
    if (_windows) return 'Windows desktop';
    return 'this device';
  }

  /// Why [provider] cannot be used here, or null when it can.
  static String? unavailableReason(String provider) {
    switch (provider) {
      case 'google':
        if (googleAvailable) return null;
        if (_googleViaBrowser) {
          return 'Google sign in needs GOOGLE_CLIENT_ID and GITHUB_REDIRECT_URI (the shared browser redirect) in your environment file.';
        }
        return 'Google sign in is not available on $_where. Use the web app, Android or iOS, or sign in another way.';
      case 'facebook':
        if (facebookAvailable) return null;
        if (_linux) return 'Facebook sign in is not available on Linux desktop. Use the web app, Android or iOS, or sign in another way.';
        return 'Facebook sign in needs FACEBOOK_APP_ID in your environment file.';
      default:
        if (githubAvailable) return null;
        return 'GitHub sign in is not set up for this build. Set GITHUB_REDIRECT_URI in your environment file.';
    }
  }

  /// Call once at start-up. Facebook on web and desktop must be told the app ID first.
  static Future<void> init() async {
    if (!(_isWeb || _windows || _mac) || AppConfig.facebookAppId.isEmpty) return;
    try {
      await FacebookAuth.instance.webAndDesktopInitialize(
        appId: AppConfig.facebookAppId,
        cookie: true,
        xfbml: true,
        version: 'v19.0',
      );
    } catch (_) {
      // The button then reports the problem when it is pressed.
    }
  }

  static GoogleSignIn? _google;

  static GoogleSignIn get _googleClient => _google ??= GoogleSignIn(
        scopes: const <String>['email', 'profile'],
        clientId: AppConfig.googleClientId.isEmpty ? null : AppConfig.googleClientId,
        serverClientId: AppConfig.googleServerClientId.isEmpty ? null : AppConfig.googleServerClientId,
      );

  /// Google ID token, or null when the person cancelled.
  static Future<String?> googleIdToken() async {
    if (_googleViaBrowser) return _googleIdTokenViaBrowser();
    try {
      final account = await _googleClient.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      final token = auth.idToken;
      if (token == null || token.isEmpty) {
        throw ApiException(
          'Google did not return an ID token. Set GOOGLE_SERVER_CLIENT_ID to your OAuth web client ID '
          'and run the app again.',
        );
      }
      return token;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Google sign-in could not start: ${_short(e)}');
    }
  }

  /// Google's own sign in page in a browser window. It hands back an ID token in the address
  /// fragment, which is what the backend verifies. The redirect (the same one GitHub uses) must be
  /// listed under Authorized redirect URIs on the Google OAuth client.
  static Future<String?> _googleIdTokenViaBrowser() async {
    final redirect = Uri.tryParse(AppConfig.githubRedirectUri);
    if (redirect == null || AppConfig.googleClientId.isEmpty) {
      throw ApiException(unavailableReason('google') ?? 'Google sign in is not set up.');
    }
    final state = _randomState();
    final nonce = _randomState();
    final authorize = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', <String, String>{
      'client_id': AppConfig.googleClientId,
      'redirect_uri': AppConfig.githubRedirectUri,
      'response_type': 'id_token',
      'scope': 'openid email profile',
      'state': state,
      'nonce': nonce,
      'prompt': 'select_account',
    });
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authorize.toString(),
        callbackUrlScheme: _callbackScheme(redirect),
        options: const FlutterWebAuth2Options(useWebview: false),
      );
      final back = Uri.parse(result);
      final params = <String, String>{
        ...back.queryParameters,
        if (back.fragment.isNotEmpty) ...Uri.splitQueryString(back.fragment),
      };
      final error = params['error'];
      if (error != null) {
        if (error == 'access_denied') return null;
        throw ApiException(params['error_description'] ?? 'Google sign-in did not complete ($error).');
      }
      if (params['state'] != state) {
        throw ApiException('Google sign-in could not be verified. Please try again.');
      }
      final token = params['id_token'];
      if (token == null || token.isEmpty) throw ApiException('Google did not return an ID token.');
      return token;
    } on ApiException {
      rethrow;
    } on PlatformException catch (e) {
      if (_cancelled(e.code) || _cancelled(e.message)) return null;
      throw ApiException('Google sign-in could not start: ${_short(e)}');
    } catch (e) {
      if (_cancelled(e.toString())) return null;
      throw ApiException('Google sign-in could not start: ${_short(e)}');
    }
  }

  /// Facebook user access token, or null when the person cancelled.
  static Future<String?> facebookAccessToken() async {
    try {
      final result = await FacebookAuth.instance.login(permissions: const <String>['email', 'public_profile']);
      if (result.status == LoginStatus.cancelled) return null;
      if (result.status != LoginStatus.success) {
        throw ApiException(result.message ?? 'Facebook sign-in did not complete.');
      }
      final token = result.accessToken?.tokenString;
      if (token == null || token.isEmpty) {
        throw ApiException('Facebook did not return an access token.');
      }
      return token;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Facebook sign-in could not start: ${_short(e)}');
    }
  }

  /// GitHub authorization code, or null when the person cancelled.
  static Future<String?> githubCode() async {
    final redirect = Uri.tryParse(AppConfig.githubRedirectUri);
    if (redirect == null || AppConfig.githubClientId.isEmpty) {
      throw ApiException('GitHub sign-in is not set up. Add GITHUB_CLIENT_ID and GITHUB_REDIRECT_URI to your environment file.');
    }
    final state = _randomState();
    final authorize = Uri.https('github.com', '/login/oauth/authorize', <String, String>{
      'client_id': AppConfig.githubClientId,
      'redirect_uri': AppConfig.githubRedirectUri,
      'scope': 'read:user user:email',
      'state': state,
      'allow_signup': 'true',
    });
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authorize.toString(),
        callbackUrlScheme: _callbackScheme(redirect),
        options: const FlutterWebAuth2Options(useWebview: false),
      );
      final back = Uri.parse(result);
      final error = back.queryParameters['error'];
      if (error != null) {
        if (error == 'access_denied') return null;
        throw ApiException(back.queryParameters['error_description'] ?? 'GitHub sign-in did not complete.');
      }
      if (back.queryParameters['state'] != state) {
        throw ApiException('GitHub sign-in could not be verified. Please try again.');
      }
      final code = back.queryParameters['code'];
      if (code == null || code.isEmpty) throw ApiException('GitHub did not return an authorization code.');
      return code;
    } on ApiException {
      rethrow;
    } on PlatformException catch (e) {
      if (_cancelled(e.code) || _cancelled(e.message)) return null;
      throw ApiException('GitHub sign-in could not start: ${_short(e)}');
    } catch (e) {
      if (_cancelled(e.toString())) return null;
      throw ApiException('GitHub sign-in could not start: ${_short(e)}');
    }
  }

  static bool _cancelled(String? text) => text != null && text.toUpperCase().contains('CANCEL');

  /// Linux and Windows catch the redirect on a local port; everything else on a link scheme.
  static String _callbackScheme(Uri redirect) {
    if (kIsWeb) return redirect.scheme;
    if (_linux || _windows) return '${redirect.scheme}://${redirect.host}:${redirect.port}';
    return 'premisave';
  }

  static String _randomState() {
    final rnd = Random.secure();
    return List<String>.generate(24, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<void> signOut() async {
    try {
      await _google?.signOut();
    } catch (_) {}
    if (!kIsWeb) {
      try {
        await FacebookAuth.instance.logOut();
      } catch (_) {}
    }
  }

  static String _short(Object e) {
    final s = e.toString();
    return s.length > 120 ? '${s.substring(0, 120)}...' : s;
  }
}
