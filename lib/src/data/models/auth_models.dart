import 'json_utils.dart';

/// What sign-in, social sign-in and refresh return.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.role,
    this.expiresInSeconds,
    this.deviceToken,
  });

  final String accessToken;
  final String? refreshToken;
  final String? role;
  final int? expiresInSeconds;
  final String? deviceToken;

  static AuthTokens? tryParse(Object? body) {
    final m = asMap(body);
    final token = str(m['token']);
    if (token == null) return null;
    return AuthTokens(
      accessToken: token,
      refreshToken: str(m['refreshToken']),
      role: str(m['role']),
      expiresInSeconds: intOrNull(m['expiresIn']),
      deviceToken: str(m['deviceToken']),
    );
  }
}

/// Result of POST /auth/signup. The backend either signs the user in (200 with tokens)
/// or, when it hides existing accounts, answers 202 with only a message.
class SignUpResult {
  const SignUpResult({this.tokens, this.message});

  final AuthTokens? tokens;
  final String? message;

  bool get signedIn => tokens != null;
}
