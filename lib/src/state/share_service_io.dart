import 'package:flutter_background/flutter_background.dart';

/// Starts the notification that lets Android keep sharing the screen while the app is in the background.
/// Call it after the capture permission is granted.
Future<bool> startShareService() async {
  await FlutterBackground.initialize(
    androidConfig: FlutterBackgroundAndroidConfig(
      notificationTitle: 'Premisave call',
      notificationText: 'You are sharing your screen',
    ),
  );
  return FlutterBackground.enableBackgroundExecution();
}

Future<void> stopShareService() => FlutterBackground.disableBackgroundExecution();
