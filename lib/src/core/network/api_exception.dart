import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// A readable error from the backend (or from the network).
///
/// The auth-service answers errors in three shapes:
///   {"status":400,"message":"..."}                      most errors
///   {"status":400,"errors":{"field":"message"}}         bean validation
///   {"status":..., "message":..., "details":...}        ApiException with details
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const <String, String>{},
    this.isNetwork = false,
  });

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;
  final bool isNetwork;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isRateLimited => statusCode == 429;

  String? fieldError(String field) => fieldErrors[field];

  @override
  String toString() => message;

  /// Converts anything thrown by Dio (or elsewhere) into an [ApiException].
  static ApiException from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) return _fromDio(error);
    return ApiException(_clean(error.toString()));
  }

  static ApiException _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'The server took too long to respond. Check your connection and try again.',
          isNetwork: true,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          'Cannot reach the server. Check your internet connection and the server address.',
          isNetwork: true,
        );
      case DioExceptionType.cancel:
        return ApiException('The request was cancelled.');
      default:
        break;
    }

    final status = e.response?.statusCode;
    final data = e.response?.data;
    String? message;
    var fields = <String, String>{};

    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        fields = errors.map((k, v) => MapEntry(k.toString(), v.toString()));
        if (fields.isNotEmpty) message = fields.values.first;
      }
      final m = data['message'] ?? data['error'] ?? data['detail'];
      if (m != null && m.toString().trim().isNotEmpty) message = m.toString();
    } else if (data is String && data.trim().isNotEmpty && !data.trimLeft().startsWith('<')) {
      message = data.trim();
    }

    // A server fault carries internals (class names, stack text) that mean nothing to a person.
    // Keep them in the debug console and show a plain sentence instead.
    // A 503 is the one exception: the backend uses it for "try again shortly" with a message written for people.
    if (status != null && status >= 500 && status != 503) {
      if (message != null) debugPrint('Server error $status: $message');
      message = _fallbackFor(status);
    }
    message ??= _fallbackFor(status);
    return ApiException(message, statusCode: status, fieldErrors: fields);
  }

  static String _fallbackFor(int? status) {
    switch (status) {
      case 400:
        return 'The request was not accepted. Please check the details and try again.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return 'You do not have permission to do that.';
      case 404:
        return 'We could not find what you were looking for.';
      case 409:
        return 'That conflicts with something that already exists.';
      case 413:
        return 'That file is too large.';
      case 429:
        return 'Too many attempts. Please wait a moment and try again.';
      case 503:
        return 'The service is temporarily unavailable. Please try again shortly.';
      default:
        if (status != null && status >= 500) {
          return 'The server ran into a problem. Please try again shortly.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  static String _clean(String s) =>
      s.startsWith('Exception: ') ? s.substring('Exception: '.length) : s;
}
