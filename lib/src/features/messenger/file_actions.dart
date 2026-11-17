import 'dart:typed_data';

import 'package:dio/dio.dart' show DioException;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/files/file_fetch.dart';
import '../../core/files/file_store.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/file_ref.dart';
import '../../state/file_downloads.dart';

// What the file tiles and the viewer do with a file: save it, open it, read it. Kept in one place so a download
// behaves the same wherever the button is.

/// The words for a failed download.
String downloadFailure(Object e) {
  if (e is StateError) return e.message;
  if (e is DioException) {
    final code = e.response?.statusCode;
    if (code == 404) return 'This file is no longer available.';
    if (code == 401 || code == 403) return 'This download link has expired. Reload the chat and try again.';
    return 'Could not download the file. Check your connection and try again.';
  }
  return 'Could not save the file. Check that the folder in the messenger settings can be written to.';
}

/// The folder part of a saved path.
String folderOf(String path) {
  final cut = path.lastIndexOf(RegExp(r'[\\/]'));
  return cut <= 0 ? path : path.substring(0, cut);
}

/// Downloads [file] into the folder for its kind and tells the person where it went. Null when it failed.
Future<DownloadedFile?> saveFile(BuildContext context, WidgetRef ref, FileRef file) async {
  try {
    final saved = await ref.read(downloadsProvider.notifier).download(file);
    if (context.mounted) {
      showToast(context, saved.inBrowser ? 'Saved to your browser\'s Downloads folder' : 'Saved to ${folderOf(saved.path)}');
    }
    return saved;
  } catch (e) {
    if (context.mounted) showToast(context, downloadFailure(e), error: true);
    return null;
  }
}

/// Opens a saved file in the app the system uses for that kind of file.
Future<void> openSavedFile(BuildContext context, WidgetRef ref, DownloadedFile saved) async {
  if (saved.inBrowser) {
    showToast(context, 'Your browser saved this file. Open it from the browser\'s downloads.');
    return;
  }
  final present = await ref.read(downloadsProvider.notifier).existing(saved.key);
  if (!context.mounted) return;
  if (present == null) {
    showToast(context, 'This file is no longer in its folder. Download it again.', error: true);
    return;
  }
  final opened = await fileStoreOpen(saved.path);
  if (!opened && context.mounted) {
    showToast(context, 'No app on this device could open the file.', error: true);
  }
}

/// The bytes of a file: the saved copy when there is one, otherwise a fresh read from the server. Kept in memory
/// for a short while so a preview and the viewer do not both download it.
Future<Uint8List> loadFileBytes(WidgetRef ref, FileRef file, {void Function(double progress)? onProgress, int? maxBytes}) async {
  final local = file.localPath ?? ref.read(downloadsProvider).files[file.key]?.path;
  if (local != null && local != 'browser') {
    final bytes = await fileStoreRead(local, maxBytes: maxBytes);
    if (bytes != null) return bytes;
  }
  final cached = PreviewCache.get(file.key);
  if (cached != null) return cached;
  final url = file.url;
  if (url == null) throw StateError('This file is not available.');
  final bytes = await fetchBytes(url, onProgress: onProgress, maxBytes: maxBytes);
  PreviewCache.put(file.key, bytes);
  return bytes;
}
