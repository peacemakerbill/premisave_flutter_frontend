import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/place.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import '../places/address_search_field.dart';
import '../places/country_field.dart';
import '../places/device_position.dart';
import '../places/map_picker_screen.dart';
import '../places/place_map_preview.dart';

/// Save where you are. Use the device position, search for an address, or pick a spot on the map.
/// The place name is optional.
class LocationScreen extends ConsumerStatefulWidget {
  const LocationScreen({super.key});

  @override
  ConsumerState<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends ConsumerState<LocationScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();

  double? _lat;
  double? _lng;
  Place? _place;
  String? _countryCode;
  bool _locating = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in <TextEditingController>[_name, _address, _city, _country]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Sets the point and the town and country boxes from a place. The address box is written only when asked,
  /// because the address search box writes its own text when a suggestion is chosen.
  void _applyPlace(Place p, {required bool writeAddress}) {
    // Texts first: changing them can call back into this screen, which must not happen inside setState.
    if (writeAddress) {
      final line = p.streetLine.isNotEmpty ? p.streetLine : (p.isBare ? '' : p.title);
      if (line.isNotEmpty) _address.text = line;
    }
    final town = p.city ?? p.district;
    if (town != null) _city.text = town;
    final country = p.country;
    if (country != null) _country.text = country;
    setState(() {
      _place = p;
      _lat = p.latitude;
      _lng = p.longitude;
      _countryCode = p.countryCode ?? _countryCode;
    });
  }

  Future<void> _detect() async {
    setState(() => _locating = true);
    try {
      final pos = await readDevicePosition();
      if (!mounted) return;
      _applyPlace(Place.point(pos.latitude, pos.longitude), writeAddress: false);
      try {
        final found = await ref.read(placeRepositoryProvider).reverse(pos.latitude, pos.longitude);
        if (mounted) _applyPlace(found, writeAddress: true);
      } catch (_) {
        // The point is enough. The address boxes stay empty for the user to fill in.
      }
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not read your position. Try again.', error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _chooseOnMap() async {
    final typedCountry = _country.text.trim();
    final place = await showMapPicker(
      context,
      title: 'Choose your location',
      initial: _place,
      centerOn: typedCountry.isEmpty ? null : typedCountry,
      countryCode: _countryCode,
    );
    if (place != null && mounted) _applyPlace(place, writeAddress: true);
  }

  Future<void> _save() async {
    if (_lat == null || _lng == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(profileRepositoryProvider).updateLocation(
            latitude: _lat!,
            longitude: _lng!,
            locationName: _name.text.trim(),
            address: _address.text.trim(),
            city: _city.text.trim(),
            country: _country.text.trim(),
          );
      ref.invalidate(currentLocationProvider);
      ref.invalidate(locationHistoryProvider);
      if (mounted) {
        showToast(context, 'Location saved');
        for (final c in <TextEditingController>[_name, _address, _city, _country]) {
          c.clear();
        }
        setState(() {
          _lat = null;
          _lng = null;
          _place = null;
          _countryCode = null;
        });
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentLocationProvider);
    final history = ref.watch(locationHistoryProvider);

    return SubPage(
      title: 'My location',
      fallbackRoute: '/account',
      body: PageBody(
        maxWidth: 640,
        onRefresh: () async {
          ref.invalidate(currentLocationProvider);
          ref.invalidate(locationHistoryProvider);
        },
        children: <Widget>[
          current.when(
            loading: () => const SizedBox(height: 90, child: LoadingState()),
            error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(currentLocationProvider)),
            data: (loc) => PCard(
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: Brand.info.op(0.12), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.place_rounded, color: Brand.info),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: loc == null
                        ? Text('No location saved yet.', style: TextStyle(color: context.mutedColor))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(loc.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              if (loc.subtitle.isNotEmpty) Text(loc.subtitle, style: TextStyle(fontSize: 13, color: context.mutedColor)),
                              if (loc.updatedAt != null)
                                Text('Updated ${timeAgo(loc.updatedAt)}', style: TextStyle(fontSize: 12, color: context.mutedColor)),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader('Update my location'),
          Text(
            'Use this device, search for an address, or place a pin on the map.',
            style: TextStyle(fontSize: 13, height: 1.4, color: context.mutedColor),
          ),
          const SizedBox(height: 12),
          PButton(
            label: _lat == null ? 'Use my current position' : 'Use my current position again',
            icon: Icons.my_location_rounded,
            kind: PButtonKind.outline,
            expand: true,
            loading: _locating,
            onPressed: _locating ? null : _detect,
          ),
          const SizedBox(height: 10),
          PButton(
            label: _lat == null ? 'Search or choose on the map' : 'Adjust on the map',
            icon: Icons.map_outlined,
            kind: PButtonKind.outline,
            expand: true,
            onPressed: _chooseOnMap,
          ),
          if (_lat != null && _lng != null) ...<Widget>[
            const SizedBox(height: 16),
            PlaceMapPreview(latitude: _lat!, longitude: _lng!, onTap: _chooseOnMap),
            const SizedBox(height: 8),
            Text(
              '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 12.5, color: context.mutedColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            PTextField(label: 'Place name', controller: _name, optional: true, hint: 'Home, Office, Downtown'),
            const SizedBox(height: 14),
            AddressSearchField(
              label: 'Address',
              controller: _address,
              optional: true,
              countryCode: _countryCode,
              mapTitle: 'Choose your location',
              onPlace: (p) => _applyPlace(p, writeAddress: false),
            ),
            const SizedBox(height: 14),
            PTextField(label: 'City', controller: _city, optional: true, textCapitalization: TextCapitalization.words),
            const SizedBox(height: 14),
            CountryField(
              controller: _country,
              optional: true,
              textInputAction: TextInputAction.done,
              onCountry: (c) => setState(() => _countryCode = c?.code),
            ),
            const SizedBox(height: 18),
            PButton(label: 'Save location', expand: true, loading: _saving, onPressed: _saving ? null : _save),
          ],
          const SectionHeader('History'),
          history.when(
            loading: () => const SizedBox(height: 90, child: LoadingState()),
            error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(locationHistoryProvider)),
            data: (items) => items.isEmpty
                ? Text('Nothing here yet.', style: TextStyle(color: context.mutedColor))
                : MenuGroup(
                    children: <Widget>[
                      for (final l in items.take(20))
                        MenuTile(
                          icon: Icons.history_rounded,
                          title: l.title,
                          subtitle: <String>[if (l.subtitle.isNotEmpty) l.subtitle, if (l.updatedAt != null) formatDateTime(l.updatedAt)].join(' · '),
                          trailing: const SizedBox.shrink(),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
