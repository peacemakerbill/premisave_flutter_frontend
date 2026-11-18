import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

/// A small HTTP client for a service that does not share the auth-service session: the developer service (its own
/// accounts) and the C2B Hakikisha service (its own client credentials).
///
/// [tokenProvider] returns the bearer token to send, or null for none. [onUnauthorized] runs when the server answers 401,
/// so the screen that owns the session can sign out. Only `Accept` and `Authorization` are sent, which every one of
/// these services lists in its CORS headers.
class ServiceClient {
  ServiceClient(String baseUrl, {this.tokenProvider, this.onUnauthorized})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: AppConfig.connectTimeout,
            receiveTimeout: AppConfig.receiveTimeout,
            headers: <String, dynamic>{'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final provider = tokenProvider;
          if (provider != null && options.headers['Authorization'] == null) {
            final token = await provider();
            if (token != null && token.isNotEmpty) options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (err, handler) {
          if (err.response?.statusCode == 401) onUnauthorized?.call();
          handler.next(err);
        },
      ),
    );
  }

  final Dio dio;
  final Future<String?> Function()? tokenProvider;
  final void Function()? onUnauthorized;

  Future<dynamic> get(String path, {Map<String, dynamic>? query, Map<String, dynamic>? headers}) => _run(
        () => dio.get<dynamic>(path, queryParameters: query, options: headers == null ? null : Options(headers: headers)),
      );

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query, Map<String, dynamic>? headers}) => _run(
        () => dio.post<dynamic>(path, data: body, queryParameters: query, options: Options(headers: headers)),
      );

  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query}) =>
      _run(() => dio.put<dynamic>(path, data: body, queryParameters: query));

  Future<dynamic> patch(String path, {Object? body, Map<String, dynamic>? query}) =>
      _run(() => dio.patch<dynamic>(path, data: body, queryParameters: query));

  Future<dynamic> delete(String path, {Object? body, Map<String, dynamic>? query}) =>
      _run(() => dio.delete<dynamic>(path, data: body, queryParameters: query));

  /// The body is the file itself, for an endpoint that takes an image as the whole request.
  Future<dynamic> putBytes(String path, Uint8List bytes, {required String contentType}) => _run(
        () => dio.put<dynamic>(path, data: Stream<List<int>>.fromIterable(<List<int>>[bytes]), options: Options(
          contentType: contentType,
          headers: <String, dynamic>{Headers.contentLengthHeader: bytes.length},
        )),
      );

  /// multipart/form-data with the verb the endpoint wants.
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
