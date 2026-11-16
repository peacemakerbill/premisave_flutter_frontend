import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/config/app_config.dart';
import 'google_place_map.dart';
import 'osm_place_map.dart';

/// What a map implementation offers the screens that use it.
abstract interface class PlaceMapDelegate {
  void move(LatLng centre, double zoom);
}

/// Moves the map from outside. It does nothing until the map is ready, which [PlaceMapView.onReady] announces.
class PlaceMapController {
  PlaceMapDelegate? _delegate;

  bool get isReady => _delegate != null;

  /// Called by the map once it can be moved.
  void attach(PlaceMapDelegate delegate) => _delegate = delegate;

  void move(LatLng centre, double zoom) => _delegate?.move(centre, zoom);

  void dispose() => _delegate = null;
}

/// The map used for picking and showing places. It is Google Maps on Android, iOS and the web when a key is
/// configured for that platform (see AppConfig.googleMapsKey), and OpenStreetMap everywhere else.
///
/// [centre] and [zoom] only place the camera when the map first appears. After that, use [controller].
class PlaceMapView extends StatelessWidget {
  const PlaceMapView({
    super.key,
    required this.centre,
    required this.zoom,
    this.controller,
    this.interactive = true,
    this.minZoom = 2,
    this.maxZoom = 19,
    this.onReady,
    this.onMove,
    this.onTap,
  });

  final LatLng centre;
  final double zoom;
  final PlaceMapController? controller;
  final bool interactive;
  final double minZoom;
  final double maxZoom;
  final VoidCallback? onReady;

  /// Called while the camera moves, with the point under the middle of the map.
  final void Function(LatLng centre, double zoom)? onMove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (AppConfig.useGoogleMap) {
      return GooglePlaceMap(
        centre: centre,
        zoom: zoom,
        controller: controller,
        interactive: interactive,
        minZoom: minZoom,
        maxZoom: maxZoom,
        onReady: onReady,
        onMove: onMove,
        onTap: onTap,
      );
    }
    return OsmPlaceMap(
      centre: centre,
      zoom: zoom,
      controller: controller,
      interactive: interactive,
      minZoom: minZoom,
      maxZoom: maxZoom,
      onReady: onReady,
      onMove: onMove,
      onTap: onTap,
    );
  }
}
