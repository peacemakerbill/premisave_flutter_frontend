import 'dart:typed_data';

/// The browser has no folders for the app, so a chosen sound is kept in the saved settings.
const bool soundStoreKeepsFiles = false;

/// The biggest sound file the browser keeps, in bytes. Browsers allow only a few megabytes of saved settings.
const int soundStoreMaxBytes = 1024 * 1024;

Future<String?> soundStoreSave({required String slot, required String name, String? sourcePath, Uint8List? bytes}) async => null;

Future<bool> soundStoreExists(String path) async => true;

Future<void> soundStoreDelete(String path) async {}
