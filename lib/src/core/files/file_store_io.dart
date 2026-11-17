import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart' show FilePicker;
import 'package:open_filex/open_filex.dart' show OpenFilex, ResultType;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory, getDownloadsDirectory, getExternalStorageDirectory;
import 'package:permission_handler/permission_handler.dart';

import 'file_kinds.dart';

/// Phones and computers can save into real folders.
const bool fileStoreCanChooseFolders = true;

/// The person's Downloads folder, or the closest place the app is allowed to write.
Future<String?> fileStoreDownloadsRoot() async {
  try {
    if (Platform.isAndroid) {
      final shared = Directory('/storage/emulated/0/Download');
      if (await shared.exists()) return shared.path;
      final own = await getExternalStorageDirectory();
      if (own != null) return own.path;
    } else {
      final d = await getDownloadsDirectory();
      if (d != null) return d.path;
    }
  } catch (_) {
    // Fall through to the app's own folder.
  }
  try {
    return (await getApplicationDocumentsDirectory()).path;
  } catch (_) {
    return null;
  }
}

/// Lets the person choose a folder. Null when they cancel or the system has no folder picker.
Future<String?> fileStorePickFolder() async {
  try {
    return await FilePicker.platform.getDirectoryPath(dialogTitle: 'Choose a folder');
  } catch (_) {
    return null;
  }
}

Future<String> _uniquePath(String folder, String fileName) async {
  var candidate = joinPath(folder, fileName);
  if (!await File(candidate).exists()) return candidate;
  final ext = extensionOf(fileName);
  final stem = ext.isEmpty ? fileName : fileName.substring(0, fileName.length - ext.length - 1);
  for (var i = 1; i < 500; i++) {
    candidate = joinPath(folder, ext.isEmpty ? '$stem ($i)' : '$stem ($i).$ext');
    if (!await File(candidate).exists()) return candidate;
  }
  return joinPath(folder, '${DateTime.now().millisecondsSinceEpoch}_$fileName');
}

Future<void> _askStorageAccess() async {
  // Only old Android versions ask. On newer ones the request is refused at once and writing to Downloads still works.
  try {
    if (Platform.isAndroid && !await Permission.storage.isGranted) {
      await Permission.storage.request();
    }
  } catch (_) {}
}

/// Saves the file at [url] into [folder] and returns where it ended up. When the folder cannot be written, for
/// example because the system does not allow it, the file goes into the app's own folder instead so it is never lost.
Future<String> fileStoreDownload({
  required String url,
  required String fileName,
  required String folder,
  String? mimeType,
  void Function(double progress)? onProgress,
}) async {
  final name = safeFileName(fileName);
  await _askStorageAccess();

  Future<String> saveInto(String dir) async {
    await Directory(dir).create(recursive: true);
    final target = await _uniquePath(dir, name);
    final partial = '$target.part';
    try {
      await Dio().download(
        url,
        partial,
        options: Options(receiveTimeout: const Duration(minutes: 10)),
        onReceiveProgress: (received, total) {
          if (total > 0) onProgress?.call(received / total);
        },
      );
      await File(partial).rename(target);
      return target;
    } catch (_) {
      try {
        final p = File(partial);
        if (await p.exists()) await p.delete();
      } catch (_) {}
      rethrow;
    }
  }

  try {
    return await saveInto(folder);
  } on FileSystemException {
    final docs = await getApplicationDocumentsDirectory();
    final last = folder.split(RegExp(r'[\\/]')).where((s) => s.isNotEmpty).toList();
    final leaf = last.isEmpty ? 'Premisave' : last.last;
    return saveInto(joinPath(joinPath(docs.path, 'Premisave'), leaf));
  }
}

Future<bool> fileStoreExists(String path) async {
  try {
    return await File(path).exists();
  } catch (_) {
    return false;
  }
}

Future<Uint8List?> fileStoreRead(String path, {int? maxBytes}) async {
  try {
    final f = File(path);
    if (maxBytes != null && await f.length() > maxBytes) return null;
    return await f.readAsBytes();
  } catch (_) {
    return null;
  }
}

/// Opens the file in whatever app the system uses for it. False when nothing could open it.
Future<bool> fileStoreOpen(String path) async {
  try {
    final r = await OpenFilex.open(path);
    return r.type == ResultType.done;
  } catch (_) {
    return false;
  }
}

Future<void> fileStoreDelete(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } catch (_) {}
}
