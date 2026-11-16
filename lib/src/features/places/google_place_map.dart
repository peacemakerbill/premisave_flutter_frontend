import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/palette.dart';
import 'google_maps_loader.dart';
import 'osm_place_map.dart';
import 'place_map_view.dart';

/// The Google Maps implementation of [PlaceMapView]. On the web it first loads Google's script with the public web
/// key. If that cannot be done, the OpenStreetMap map is shown instead, so the screen always works.
class GooglePlaceMap extends StatefulWidget {
  const GooglePlaceMap({
    super.key,
    required this.centre,
    required this.zoom,
    required this.controller,
    required this.interactive,
    required this.minZoom,
    required this.maxZoom,
    required this.onReady,
    required this.onMove,
    required this.onTap,
  });

  final LatLng centre;
  final double zoom;
  final PlaceMapController? controller;
  final bool interactive;
  final double minZoom;
  final double maxZoom;
  final VoidCallback? onReady;
  final void Function(LatLng centre, double zoom)? onMove;
  final VoidCallback? onTap;

  @override
  State<GooglePlaceMap> createState() => _GooglePlaceMapState();
}

class _GooglePlaceMapState extends State<GooglePlaceMap> implements PlaceMapDelegate {
  late final Future<bool> _loaded = loadGoogleMaps(AppConfig.googleMapsKey);
  gm.GoogleMapController? _map;

  @override
  void move(LatLng centre, double zoom) {
    _map?.animateCamera(gm.CameraUpdate.newLatLngZoom(gm.LatLng(centre.latitude, centre.longitude), zoom));
  }

  void _created(gm.GoogleMapController controller) {
    _map = controller;
    widget.controller?.attach(this);
    widget.onReady?.call();
  }

  void _moved(gm.CameraPosition p) {
    widget.onMove?.call(LatLng(p.target.latitude, p.target.longitude), p.zoom);
  }

  @override
  void dispose() {
    widget.controller?.dispose();
    _map?.dispose();
    _map = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _loaded,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ColoredBox(color: context.pal.panel2, child: const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))));
        }
        if (snapshot.data != true) {
          return OsmPlaceMap(
            centre: widget.centre,
            zoom: widget.zoom,
            controller: widget.controller,
            interactive: widget.interactive,
            minZoom: widget.minZoom,
            maxZoom: widget.maxZoom,
            onReady: widget.onReady,
            onMove: widget.onMove,
            onTap: widget.onTap,
          );
        }
        final touch = widget.interactive;
        return gm.GoogleMap(
          initialCameraPosition: gm.CameraPosition(target: gm.LatLng(widget.centre.latitude, widget.centre.longitude), zoom: widget.zoom),
          onMapCreated: _created,
          onCameraMove: _moved,
          onTap: widget.onTap == null ? null : (_) => widget.onTap!(),
          minMaxZoomPreference: gm.MinMaxZoomPreference(widget.minZoom, widget.maxZoom),
          style: context.pal.dark ? _darkStyle : null,
          zoomControlsEnabled: false,
          zoomGesturesEnabled: touch,
          scrollGesturesEnabled: touch,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
        );
      },
    );
  }
}

/// Google's own night map style, used on dark themes.
const String _darkStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#746855"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#17263c"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}
]
''';
