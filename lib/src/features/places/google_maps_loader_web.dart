import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool>? _loading;

/// Loads the Google Maps JavaScript API once, using the public web key from the app's own configuration, so the key
/// does not have to be written into index.html. Completes with false when the script cannot be loaded.
Future<bool> loadGoogleMaps(String key) {
  final running = _loading;
  if (running != null) return running;
  final started = _inject(key).then((ok) {
    if (!ok) _loading = null;
    return ok;
  });
  return _loading = started;
}

Future<bool> _inject(String key) {
  final done = Completer<bool>();
  final script = web.HTMLScriptElement()..src = 'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeQueryComponent(key)}';
  script.onload = ((web.Event _) {
    if (!done.isCompleted) done.complete(true);
  }).toJS;
  script.onerror = ((web.Event _) {
    if (!done.isCompleted) done.complete(false);
  }).toJS;
  web.document.head!.append(script);
  return done.future;
}
