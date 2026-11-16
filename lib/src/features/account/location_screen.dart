import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';

/// Save where you are. Position comes from the device; the place name is optional.
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
  bool _locating = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in <TextEditingController>[_name, _address, _city, _country]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _detect() async {
    setState(() => _locating = true);
    try {
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
      final pos = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 20));
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not read your position. Try again.', error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
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
        setState(() {
          _lat = null;
          _lng = null;
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
          PButton(
            label: _lat == null ? 'Use my current position' : 'Position found',
            icon: _lat == null ? Icons.my_location_rounded : Icons.check_circle_outline_rounded,
            kind: PButtonKind.outline,
            expand: true,
            loading: _locating,
            onPressed: _locating ? null : _detect,
          ),
          if (_lat != null && _lng != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 12.5, color: context.mutedColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            PTextField(label: 'Place name', controller: _name, optional: true, hint: 'Home, Office, Downtown'),
            const SizedBox(height: 14),
            PTextField(label: 'Address', controller: _address, optional: true),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: PTextField(label: 'City', controller: _city, optional: true)),
                const SizedBox(width: 12),
                Expanded(child: PTextField(label: 'Country', controller: _country, optional: true)),
              ],
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
