import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'place_map_view.dart';
import 'place_widgets.dart';

/// The OpenStreetMap implementation of [PlaceMapView]. It is used on desktop and whenever no Google Maps key is set.
class OsmPlaceMap extends StatefulWidget {
  const OsmPlaceMap({
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
  State<OsmPlaceMap> createState() => _OsmPlaceMapState();
}

class _OsmPlaceMapState extends State<OsmPlaceMap> implements PlaceMapDelegate {
  final MapController _map = MapController();

  @override
  void move(LatLng centre, double zoom) => _map.move(centre, zoom);

  void _ready() {
    widget.controller?.attach(this);
    widget.onReady?.call();
  }

  @override
  void dispose() {
    widget.controller?.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: widget.centre,
            initialZoom: widget.zoom,
            minZoom: widget.minZoom,
            maxZoom: widget.maxZoom,
            interactionOptions: InteractionOptions(flags: widget.interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none),
            onMapReady: _ready,
            onTap: (_, __) => widget.onTap?.call(),
            onPositionChanged: (camera, _) => widget.onMove?.call(camera.center, camera.zoom),
          ),
          children: const <Widget>[MapTiles()],
        ),
        const MapAttribution(),
      ],
    );
  }
}
