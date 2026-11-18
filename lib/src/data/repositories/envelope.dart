import '../models/json_utils.dart';

/// The wallet, developer and C2B services wrap every answer as {success, message, data, timestamp}.
/// This returns what is inside `data`, or the body itself when it is not wrapped.
Object? unwrap(Object? body) {
  if (body is Map && body.containsKey('data') && (body.containsKey('success') || body.containsKey('message'))) {
    return body['data'];
  }
  return body;
}

/// The wrapped answer as one object.
Map<String, dynamic> unwrapMap(Object? body) => asMap(unwrap(body));

/// The wrapped answer as a list of objects.
List<Map<String, dynamic>> unwrapList(Object? body) => mapList(unwrap(body));

/// The sentence a service sent along with its answer, or [fallback].
String messageOf(Object? body, String fallback) {
  if (body is Map) return str(body['message']) ?? fallback;
  return fallback;
}

/// 2026-11-18, the date format the wallet and listing services read.
String isoDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}
