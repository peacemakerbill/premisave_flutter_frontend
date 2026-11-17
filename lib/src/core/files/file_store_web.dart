import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'file_fetch.dart';
import 'file_kinds.dart';

/// A browser saves into its own Downloads folder and does not let a page pick subfolders.
const bool fileStoreCanChooseFolders = false;

/// What a saved file's "path" is in the browser, since there is no real one.
const String browserSavedMarker = 'browser';

Future<String?> fileStoreDownloadsRoot() async => null;

Future<String?> fileStorePickFolder() async => null;

/// Fetches the file and hands it to the browser as a download, so it saves instead of opening in a tab.
Future<String> fileStoreDownload({
  required String url,
  required String fileName,
  required String folder,
  String? mimeType,
  void Function(double progress)? onProgress,
}) async {
  final bytes = await fetchBytes(url, onProgress: onProgress);
  final blob = web.Blob(<JSAny>[bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType ?? 'application/octet-stream'));
  final objectUrl = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = safeFileName(fileName);
  web.document.body?.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(objectUrl);
  return browserSavedMarker;
}

Future<bool> fileStoreExists(String path) async => false;

Future<Uint8List?> fileStoreRead(String path, {int? maxBytes}) async => null;

Future<bool> fileStoreOpen(String path) async => false;

Future<void> fileStoreDelete(String path) async {}
