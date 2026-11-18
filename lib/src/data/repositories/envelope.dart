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

/// The records inside an answer: a bare list, a Spring page ({content: []}), or the first list under [key].
List<Map<String, dynamic>> rows(Object? body, {String? key}) {
  final data = unwrap(body);
  if (data is List) return mapList(data);
  if (data is Map) {
    final m = asMap(data);
    if (key != null && m[key] is List) return mapList(m[key]);
    for (final k in const <String>['content', 'items', 'results']) {
      if (m[k] is List) return mapList(m[k]);
    }
    for (final v in m.values) {
      if (v is List && v.isNotEmpty && v.first is Map) return mapList(v);
    }
  }
  return <Map<String, dynamic>>[];
}
