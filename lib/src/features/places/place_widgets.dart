import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';

/// Card that holds suggestion rows under a text field. Taps inside it do not take focus away from the field.
class SuggestionPanel extends StatelessWidget {
  const SuggestionPanel({super.key, required this.children, this.maxHeight = 300, this.margin = const EdgeInsets.only(top: 6)});

  final List<Widget> children;
  final double maxHeight;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return TextFieldTapRegion(
      child: Container(
        margin: margin,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(context.radius(Brand.radiusSmall + 2)),
          border: Border.all(color: context.pal.line2),
          boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.op(0.10), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// One tappable suggestion.
class SuggestionTile extends StatelessWidget {
  const SuggestionTile({super.key, required this.leading, required this.title, required this.onTap, this.subtitle});

  final Widget leading;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: <Widget>[
            SizedBox(width: 30, child: Center(child: leading)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A line of status text inside a suggestion panel, such as "Searching" or "No matches".
class SuggestionNote extends StatelessWidget {
  const SuggestionNote(this.text, {super.key, this.busy = false});

  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: <Widget>[
          if (busy) ...<Widget>[
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
          ],
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.35, color: context.mutedColor))),
        ],
      ),
    );
  }
}

/// The credit Google asks for when its place suggestions are listed outside a Google map.
class PoweredByGoogle extends StatelessWidget {
  const PoweredByGoogle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text('Powered by Google', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.mutedColor)),
      ),
    );
  }
}

/// OpenStreetMap tiles. On dark themes the map is inverted so it does not glare.
class MapTiles extends StatelessWidget {
  const MapTiles({super.key});

  static const ColorFilter _night = ColorFilter.matrix(<double>[
    -0.9, 0, 0, 0, 230,
    0, -0.9, 0, 0, 230,
    0, 0, -0.9, 0, 230,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final tiles = TileLayer(
      urlTemplate: AppConfig.mapTileUrl,
      userAgentPackageName: 'com.premisave.premisave_frontend',
      maxNativeZoom: 19,
    );
    return context.pal.dark ? ColorFiltered(colorFilter: _night, child: tiles) : tiles;
  }
}

/// The credit OpenStreetMap asks every map to show.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 6,
      bottom: 6,
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'), mode: LaunchMode.externalApplication),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(color: Colors.white.op(0.85), borderRadius: BorderRadius.circular(6)),
          child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10.5, color: Color(0xFF1B1B1B))),
        ),
      ),
    );
  }
}

/// A map pin whose tip sits at the centre of the widget.
class MapPin extends StatelessWidget {
  const MapPin({super.key, this.lifted = false});

  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return IgnorePointer(
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: <Widget>[
            Container(
              width: 12,
              height: 5,
              decoration: BoxDecoration(color: Colors.black.op(lifted ? 0.18 : 0.32), borderRadius: BorderRadius.circular(6)),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(0, lifted ? -34 : -22, 0),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  const Icon(Icons.location_on_rounded, size: 52, color: Colors.white),
                  Icon(Icons.location_on_rounded, size: 44, color: pal.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
