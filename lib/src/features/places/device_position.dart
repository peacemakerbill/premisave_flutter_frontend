import 'package:geolocator/geolocator.dart';

import '../../core/network/api_exception.dart';

/// The device's current position, or an [ApiException] with a message the user can act on.
Future<Position> readDevicePosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw ApiException('Location is turned off on this device.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
    throw ApiException('Location permission was not granted. You can allow it in the device settings.');
  }
  return Geolocator.getCurrentPosition().timeout(const Duration(seconds: 20));
}
