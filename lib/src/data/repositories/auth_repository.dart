import '../../core/network/api_client.dart';
import '../models/auth_models.dart';
import '../models/json_utils.dart';
import '../models/security_models.dart';

/// Endpoints under /auth.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Future<AuthTokens> signIn({required String email, required String password}) async {
    final res = await _api.post('/auth/signin', body: {'email': email.trim(), 'password': password});
    return _tokens(res);
  }

  /// Registers a client account. Depending on server settings the answer is either
  /// tokens (signed in straight away) or a plain message asking the user to check email.
  Future<SignUpResult> signUp({
    required String firstName,
    String? middleName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
    String? username,
    String? address1,
    String? address2,
    String? country,
  }) async {
    final res = await _api.post(
      '/auth/signup',
      body: compact({
        'username': username,
        'firstName': firstName.trim(),
        'middleName': middleName,
        'lastName': lastName.trim(),
        'email': email.trim(),
        'phoneNumber': phoneNumber.trim(),
        'address1': address1,
        'address2': address2,
        'country': country,
        'language': 'ENGLISH',
        'password': password,
      }),
    );
    final tokens = AuthTokens.tryParse(res);
    return SignUpResult(tokens: tokens, message: str(asMap(res)['message']));
  }

  Future<AuthTokens> google(String idToken) async =>
      _tokens(await _api.post('/auth/google', body: {'token': idToken}));

  Future<AuthTokens> facebook(String accessToken) async =>
      _tokens(await _api.post('/auth/facebook', body: {'token': accessToken}));

  /// [code] is the authorization code GitHub sent back after the person approved.
  Future<AuthTokens> github(String code) async =>
      _tokens(await _api.post('/auth/github', body: {'token': code}));

  /// Ends the session on the server. Failures are ignored by callers: the local
  /// session is cleared either way.
  Future<void> logout() async {
    await _api.post('/auth/logout');
  }

  Future<String> verify(String token) async {
    final res = await _api.get('/auth/verify/${Uri.encodeComponent(token)}');
    return strOr(asMap(res)['message'], 'Account verified. You can sign in now.');
  }

  Future<String> resendActivation(String email) async {
    final res = await _api.post('/auth/resend-activation', query: {'email': email.trim()});
    return strOr(asMap(res)['message'], 'If an unverified account exists, a new email is on its way.');
  }

  Future<String> forgotPassword(String email) async {
    final res = await _api.post('/auth/forgot-password', body: {'email': email.trim()});
    return strOr(asMap(res)['message'], 'If an account exists, a reset link has been sent.');
  }

  Future<String> resetPassword({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await _api.post('/auth/reset-password', body: {
      'token': token.trim(),
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
    return strOr(asMap(res)['message'], 'Password reset successfully.');
  }

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await _api.post('/auth/change-password', body: {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
    return strOr(asMap(res)['message'], 'Password changed successfully.');
  }

  Future<String> acceptAdminInvitation({
    required String token,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await _api.post('/auth/admin-invitation/accept', body: {
      'token': token.trim(),
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
    return strOr(asMap(res)['message'], 'Your administrator account is active.');
  }

  Future<ReportPreview> inspectReport(String token) async =>
      ReportPreview(asMap(await _api.post('/auth/security-actions/inspect', body: {'token': token.trim()})));

  Future<ReportResult> confirmReport(String token, {required bool requestPasswordReset}) async =>
      ReportResult(asMap(await _api.post('/auth/security-actions/confirm', body: {
        'token': token.trim(),
        'requestPasswordReset': requestPasswordReset,
      })));

  AuthTokens _tokens(Object? res) {
    final t = AuthTokens.tryParse(res);
    if (t == null) {
      throw StateError('The server did not return a sign-in token.');
    }
    return t;
  }
}
