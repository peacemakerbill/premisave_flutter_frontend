import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import 'place_widgets.dart';

/// A small map with a pin on a saved point. Tap it to adjust the point.
class PlaceMapPreview extends StatelessWidget {
  const PlaceMapPreview({super.key, required this.latitude, required this.longitude, this.onTap, this.height = 170});

  final double latitude;
  final double longitude;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return ClipRRect(
      borderRadius: BorderRadius.circular(context.radius(Brand.radius)),
      child: SizedBox(
        height: height,
        child: Stack(
          children: <Widget>[
            IgnorePointer(
              child: FlutterMap(
                key: ValueKey<String>('$latitude,$longitude'),
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: const <Widget>[MapTiles()],
              ),
            ),
            const MapPin(),
            const MapAttribution(),
            if (onTap != null)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: pal.line2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.edit_location_alt_outlined, size: 15, color: pal.accent),
                      const SizedBox(width: 6),
                      const Text('Adjust on map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(onTap: onTap),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
