import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';

/// HTTP client for the auth-service.
///
/// What it does for every request:
///  * sends `X-Client-Platform: mobile` and, once known, `X-Device-Token`
///  * adds `Authorization: Bearer <access token>` on protected endpoints
///  * refreshes the access token shortly before it expires, and once more on a 401
///    (refresh tokens rotate: each one works once and the response carries the next)
///  * runs only one refresh at a time, so parallel requests never burn the same token
///  * turns every failure into an [ApiException] with a readable message
class ApiClient {
  /// [baseUrl] points the client at another service (the messenger). That client shares the same saved tokens,
  /// and hands token refreshes to [authClient], so the single refresh rule below still holds across services.
  ApiClient(this._tokens, {String? baseUrl, ApiClient? authClient})
      : _authClient = authClient,
        dio = Dio(_options(baseUrl)),
        _bare = Dio(_options(baseUrl)) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest, onError: _onError));
  }

  final TokenStore _tokens;
  final ApiClient? _authClient;

  /// Authenticated client with interceptors.
  final Dio dio;

  /// Plain client used by the refresh call itself (no interceptors, no recursion).
  final Dio _bare;

  /// Called once when the server rejects the refresh token. The session layer
  /// uses it to send the user back to the sign-in screen.
  void Function()? onSessionExpired;

  Future<bool>? _refreshing;

  static BaseOptions _options(String? baseUrl) => BaseOptions(
        baseUrl: baseUrl ?? AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: <String, dynamic>{
          'Accept': 'application/json',
          // Only the auth-service reads this. Other services (the messenger) do not list it in their CORS
          // headers, so sending it there makes the browser block every request before it is sent.
          if (baseUrl == null) 'X-Client-Platform': AppConfig.clientPlatform,
        },
      );

  // Endpoints that must never carry a bearer token (a stale one can get rejected).
  static const Set<String> _publicPaths = <String>{
    '/auth/signin',
    '/auth/signup',
    '/auth/google',
    '/auth/facebook',
    '/auth/github',
    '/auth/refresh',
    '/auth/forgot-password',
    '/auth/reset-password',
    '/auth/resend-activation',
    '/auth/admin-invitation/accept',
    '/auth/security-actions/inspect',
    '/auth/security-actions/confirm',
    '/profile/public/directory',
  };

  static bool _isPublic(String path) =>
      _publicPaths.contains(path) || path.startsWith('/auth/verify/');

  // ---------------------------------------------------------------- interceptors

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await _tokens.load();
    final device = _tokens.current.deviceToken;
    // The device token belongs to the auth-service. Other services do not accept it as a CORS header.
    if (_authClient == null && device != null && device.isNotEmpty) {
      options.headers['X-Device-Token'] = device;
    }
    if (!_isPublic(options.path)) {
      final s = _tokens.current;
      if (s.refreshToken != null && s.expiresWithin(const Duration(seconds: 45))) {
        await refresh();
      }
      final token = _tokens.current.accessToken;
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final req = err.requestOptions;

    if (status == 401 && !_isPublic(req.path)) {
      final hasRefresh = (_tokens.current.refreshToken ?? '').isNotEmpty;
      if (hasRefresh && req.extra['retried'] != true) {
        final ok = await refresh();
        // A multipart body is a one-shot stream and cannot be replayed.
        if (ok && req.data is! FormData) {
          req.extra['retried'] = true;
          req.headers['Authorization'] = 'Bearer ${_tokens.current.accessToken}';
          try {
            final response = await dio.fetch<dynamic>(req);
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          }
        }
      } else if (!hasRefresh) {
        // Older sessions without a refresh token have nothing left to try.
        await _tokens.clearSession();
        onSessionExpired?.call();
      }
    }
    handler.next(err);
  }

  /// Exchanges the stored refresh token for a new access and refresh token.
  /// Returns true when new tokens were saved. Concurrent callers share one call.
  Future<bool> refresh() {
    final delegate = _authClient;
    if (delegate != null) return delegate.refresh();
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<bool> _doRefresh() async {
    await _tokens.load();
    final refreshToken = _tokens.current.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final headers = <String, dynamic>{};
      final device = _tokens.current.deviceToken;
      if (device != null && device.isNotEmpty) headers['X-Device-Token'] = device;
      final res = await _bare.post<dynamic>(
        '/auth/refresh',
        data: <String, dynamic>{'refreshToken': refreshToken},
        options: Options(headers: headers),
      );
      final data = res.data;
      if (data is Map && data['token'] != null) {
        await _tokens.saveTokens(
          accessToken: data['token'].toString(),
          refreshToken: data['refreshToken']?.toString(),
          role: data['role']?.toString(),
          expiresInSeconds: (data['expiresIn'] as num?)?.toInt(),
          deviceToken: data['deviceToken']?.toString(),
        );
        return true;
      }
      return false;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // The server said the refresh token is no good (used, revoked or expired).
      // A network failure is different: keep the session and let the caller retry later.
      if (status == 400 || status == 401 || status == 403) {
        await _tokens.clearSession();
        onSessionExpired?.call();
      }
      return false;
    }
  }

  // ------------------------------------------------------------------- requests

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _run(() => dio.get<dynamic>(path, queryParameters: query));

  /// [headers] are added to this request only, for example an `Idempotency-Key`.
  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query, Map<String, dynamic>? headers}) => _run(
        () => dio.post<dynamic>(path, data: body, queryParameters: query, options: headers == null ? null : Options(headers: headers)),
      );

  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query}) =>
      _run(() => dio.put<dynamic>(path, data: body, queryParameters: query));

  Future<dynamic> patch(String path, {Object? body, Map<String, dynamic>? query}) =>
      _run(() => dio.patch<dynamic>(path, data: body, queryParameters: query));

  Future<dynamic> delete(String path, {Object? body, Map<String, dynamic>? query}) =>
      _run(() => dio.delete<dynamic>(path, data: body, queryParameters: query));

  /// For endpoints that answer with a plain sentence such as "Invite link revoked", sometimes labelled as JSON.
  /// The reply is not decoded, so a sentence cannot make a call that worked look like a failure.
  Future<void> postPlain(String path, {Object? body, Map<String, dynamic>? query}) => _run(
        () => dio.post<dynamic>(path, data: body, queryParameters: query, options: Options(responseType: ResponseType.plain)),
      );

  /// Same as [postPlain], for DELETE.
  Future<void> deletePlain(String path, {Map<String, dynamic>? query}) => _run(
        () => dio.delete<dynamic>(path, queryParameters: query, options: Options(responseType: ResponseType.plain)),
      );

  /// multipart/form-data upload. [onProgress] gets the bytes sent so far and the total.
  Future<dynamic> upload(String path, FormData form, {void Function(int sent, int total)? onProgress}) => _run(
        () => dio.post<dynamic>(
          path,
          data: form,
          options: Options(contentType: 'multipart/form-data'),
          onSendProgress: onProgress,
        ),
      );

  /// multipart/form-data with the verb the endpoint wants (an edit is a PUT).
  Future<dynamic> uploadWith(String method, String path, FormData form, {Map<String, dynamic>? query}) => _run(
        () => dio.request<dynamic>(
          path,
          data: form,
          queryParameters: query,
          options: Options(method: method, contentType: 'multipart/form-data'),
        ),
      );

  /// Raw bytes, for document downloads.
  Future<Uint8List> download(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await dio.get<List<int>>(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(res.data ?? const <int>[]);
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<dynamic> _run(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      return res.data;
    } on DioException catch (e) {
      throw ApiException.from(e);
    }
  }
}
