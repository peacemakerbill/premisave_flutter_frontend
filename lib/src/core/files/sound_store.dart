// The part of keeping a chosen ringtone that differs between the browser and the other platforms.
// Phones and computers copy the file into the app's own folder. The browser has no folders, so the sound is kept
// inside the app's saved settings instead.
export 'sound_store_web.dart' if (dart.library.io) 'sound_store_io.dart';
