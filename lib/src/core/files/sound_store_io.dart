import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart' show getApplicationSupportDirectory;

/// Phones and computers keep a copy of the chosen file, so it still plays if the original is moved or deleted.
const bool soundStoreKeepsFiles = true;

/// The biggest sound file the app accepts, in bytes.
const int soundStoreMaxBytes = 15 * 1024 * 1024;

/// Copies a chosen sound into the app's own folder and returns where the copy is. Null if it could not be kept.
Future<String?> soundStoreSave({required String slot, required String name, String? sourcePath, Uint8List? bytes}) async {
  try {
    final sep = Platform.pathSeparator;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${sep}sounds');
    await dir.create(recursive: true);
    final dot = name.lastIndexOf('.');
    final ext = dot < 0 || dot == name.length - 1 ? 'audio' : name.substring(dot + 1).toLowerCase();
    final dest = '${dir.path}$sep${slot}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    if (sourcePath != null) {
      await File(sourcePath).copy(dest);
    } else if (bytes != null) {
      await File(dest).writeAsBytes(bytes, flush: true);
    } else {
      return null;
    }
    return dest;
  } catch (_) {
    return null;
  }
}

Future<bool> soundStoreExists(String path) async {
  try {
    return await File(path).exists();
  } catch (_) {
    return false;
  }
}

Future<void> soundStoreDelete(String path) async {
  try {
    await File(path).delete();
  } catch (_) {
    // Already gone.
  }
}
