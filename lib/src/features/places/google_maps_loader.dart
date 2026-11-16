// Makes sure Google Maps can draw before a map is built. Only the web needs real work, see the web file.
export 'google_maps_loader_stub.dart' if (dart.library.js_interop) 'google_maps_loader_web.dart';
