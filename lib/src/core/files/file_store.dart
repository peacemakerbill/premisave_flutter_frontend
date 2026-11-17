// The part of saving files that differs between the browser and the other platforms.
// Phones and computers save into real folders. The browser can only hand the file to its own download list.
export 'file_store_web.dart' if (dart.library.io) 'file_store_io.dart';
