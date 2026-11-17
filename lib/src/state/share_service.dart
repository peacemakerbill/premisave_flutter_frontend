// Android keeps screen sharing alive with a foreground service. The package that does that has no web version,
// so the web build gets an empty stand-in and never loads it.
export 'share_service_stub.dart' if (dart.library.io) 'share_service_io.dart';
