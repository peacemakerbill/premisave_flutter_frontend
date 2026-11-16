import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/config/app_config.dart';
import '../core/network/api_exception.dart';

/// Gets a provider token on the device. The backend turns it into a Premisave session
/// (POST /auth/google, POST /auth/facebook).
///
/// GitHub is not offered in the app: the backend expects an authorization code from a
/// browser redirect, which needs a web flow rather than a native sign-in sheet.
class SocialAuthService {
  SocialAuthService._();

  static GoogleSignIn? _google;

  static GoogleSignIn get _googleClient => _google ??= GoogleSignIn(
        scopes: const <String>['email', 'profile'],
        clientId: AppConfig.googleClientId.isEmpty ? null : AppConfig.googleClientId,
        serverClientId: AppConfig.googleServerClientId.isEmpty ? null : AppConfig.googleServerClientId,
      );

  /// Google ID token, or null when the person cancelled.
  static Future<String?> googleIdToken() async {
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
