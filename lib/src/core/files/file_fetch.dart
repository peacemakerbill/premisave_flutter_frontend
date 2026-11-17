import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Reads a whole file from a link into memory. Used for previews and for the in-app viewers. The link is a signed
/// messenger link, so no sign-in header is sent (extra headers would make the browser ask permission first).
Future<Uint8List> fetchBytes(String url, {void Function(double progress)? onProgress, int? maxBytes}) async {
  final res = await Dio().get<List<int>>(
    url,
    options: Options(responseType: ResponseType.bytes, receiveTimeout: const Duration(minutes: 5)),
    onReceiveProgress: (received, total) {
      if (maxBytes != null && received > maxBytes) throw StateError('File is too large to preview');
      if (total > 0) onProgress?.call(received / total);
    },
  );
  final data = res.data;
  if (data == null) throw StateError('The file was empty');
  return data is Uint8List ? data : Uint8List.fromList(data);
}

/// Keeps a few recently fetched previews so scrolling a chat does not download the same file again.
class PreviewCache {
  PreviewCache._();

  static final Map<String, Uint8List> _items = <String, Uint8List>{};
  static const int _maxItems = 12;
  static const int _maxBytes = 48 * 1024 * 1024;

  static Uint8List? get(String key) {
    final v = _items.remove(key);
    if (v != null) _items[key] = v; // most recent last
    return v;
  }

  static void put(String key, Uint8List data) {
    _items.remove(key);
    _items[key] = data;
    var total = _items.values.fold<int>(0, (a, b) => a + b.length);
    while (_items.length > _maxItems || total > _maxBytes) {
      final oldest = _items.keys.first;
      total -= _items.remove(oldest)!.length;
      if (_items.isEmpty) break;
    }
  }
}
