// Small helpers for reading JSON that may be missing fields or have unexpected types.

Map<String, dynamic> asMap(Object? v) {
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return <String, dynamic>{};
}

List<Map<String, dynamic>> mapList(Object? v) {
  if (v is List) {
    return v.whereType<Map>().map(asMap).toList();
  }
  return <Map<String, dynamic>>[];
}

List<String> stringList(Object? v) {
  if (v is List) return v.where((e) => e != null).map((e) => e.toString()).toList();
  return <String>[];
}

String? str(Object? v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

String strOr(Object? v, [String fallback = '']) => str(v) ?? fallback;

int intOr(Object? v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

int? intOrNull(Object? v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? doubleOrNull(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool boolOr(Object? v, [bool fallback = false]) {
  if (v is bool) return v;
  if (v is String) return v.toLowerCase() == 'true';
  return fallback;
}

DateTime? dateOrNull(Object? v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

/// Removes null and empty-string entries so a PATCH body only carries real values.
Map<String, dynamic> compact(Map<String, dynamic> m) {
  final out = <String, dynamic>{};
  m.forEach((k, v) {
    if (v == null) return;
    if (v is String && v.trim().isEmpty) return;
    out[k] = v;
  });
  return out;
}
