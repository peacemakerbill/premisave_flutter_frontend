import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerPhase;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/place.dart';
import '../../state/providers.dart';
import 'device_position.dart';
import 'place_map_view.dart';
import 'place_searcher.dart';
import 'place_widgets.dart';

/// Full screen map for choosing a spot. The pin stays in the middle while the map moves under it, and the address
/// under the pin updates when the map settles. Returns the chosen [Place], or null if the user backs out.
///
/// [initial] starts the map on a known place. Otherwise the map opens on [centerOn], which is looked up as text
/// such as a country name or what the user already typed.
Future<Place?> showMapPicker(
  BuildContext context, {
  String title = 'Choose location',
  Place? initial,
  String? centerOn,
  String? countryCode,
}) {
  return Navigator.of(context, rootNavigator: true).push<Place>(
    MaterialPageRoute<Place>(
      fullscreenDialog: true,
      builder: (_) => MapPickerScreen(title: title, initial: initial, centerOn: centerOn, countryCode: countryCode),
    ),
  );
}

class MapPickerScreen extends ConsumerStatefulWidget {
  const MapPickerScreen({super.key, required this.title, this.initial, this.centerOn, this.countryCode});

  final String title;
  final Place? initial;
  final String? centerOn;
  final String? countryCode;

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  static const LatLng _world = LatLng(15, 15);
  static const double _lookupZoom = 5;

  final PlaceMapController _map = PlaceMapController();
  final TextEditingController _query = TextEditingController();
  final FocusNode _queryFocus = FocusNode();
  final ValueNotifier<bool> _moving = ValueNotifier<bool>(false);
  late final PlaceSearcher _searcher;

  Timer? _settle;
  CancelToken? _cancel;
  int _turn = 0;
  bool _ready = false;
  LatLng? _pendingMove;
  double _pendingZoom = 2;

  late LatLng _centre;
  late double _zoom;
  Place? _place;
  Place? _pinned;
  bool _resolving = false;
  bool _lookupFailed = false;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _searcher = PlaceSearcher(ref.read(placeRepositoryProvider), countryCode: widget.countryCode);
    _queryFocus.addListener(_onQueryFocus);
    final start = widget.initial;
    if (start != null) {
      _centre = LatLng(start.latitude, start.longitude);
      _zoom = 16;
      _place = start;
      _pinned = start;
    } else {
      _centre = _world;
      _zoom = 2;
      _findStart();
    }
  }

  void _onQueryFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _queryFocus.removeListener(_onQueryFocus);
    _settle?.cancel();
    _cancel?.cancel();
    _searcher.dispose();
    _query.dispose();
    _queryFocus.dispose();
    _moving.dispose();
    _map.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------------- moving the map

  void _moveTo(LatLng point, double zoom) {
    if (!_ready) {
      _pendingMove = point;
      _pendingZoom = zoom;
      return;
    }
    _map.move(point, zoom);
  }

  Future<void> _findStart() async {
    final text = widget.centerOn?.trim() ?? '';
    if (text.length < 2) return;
    try {
      final p = await ref.read(placeRepositoryProvider).locate(text);
      if (!mounted || p == null || _place != null) return;
      _moveTo(LatLng(p.latitude, p.longitude), _zoomFor(p));
    } catch (_) {
      // The map still opens on the world view and the user can search or move it.
    }
  }

  /// How close to zoom for a search result: a street or building closely, a town less, a country far out.
  double _zoomFor(Place p) {
    if (p.houseNumber != null) return 17;
    if (p.street != null) return 16;
    final n = p.name;
    if (n == null) return p.state != null ? 9 : 5;
    if (n == p.country) return 5;
    if (n == p.state) return 8;
    return 14;
  }

  void _onReady() {
    _ready = true;
    final target = _pendingMove;
    if (target != null) {
      _pendingMove = null;
      _map.move(target, _pendingZoom);
    }
  }

  void _onMove(LatLng centre, double zoom) {
    _centre = centre;
    _zoom = zoom;
    _setMoving(true);
    _settle?.cancel();
    _settle = Timer(const Duration(milliseconds: 450), _resolve);
  }

  /// The map can report its position while the screen is still being built, where notifying listeners is not allowed.
  void _setMoving(bool value) {
    if (_moving.value == value) return;
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _moving.value = value;
      });
    } else {
      _moving.value = value;
    }
  }

  bool _isNear(Place p, LatLng c) => (p.latitude - c.latitude).abs() < 0.0003 && (p.longitude - c.longitude).abs() < 0.0003;

  Future<void> _resolve() async {
    if (!mounted) return;
    _setMoving(false);
    final keep = _pinned;
    if (keep != null && _isNear(keep, _centre)) {
      setState(() {
        _place = keep;
        _resolving = false;
        _lookupFailed = false;
      });
      return;
    }
    _pinned = null;
    if (_zoom < _lookupZoom) {
      _cancel?.cancel();
      _turn++;
      setState(() {
        _place = null;
        _resolving = false;
        _lookupFailed = false;
      });
      return;
    }
    final turn = ++_turn;
    _cancel?.cancel();
    final token = CancelToken();
    _cancel = token;
    final point = _centre;
    setState(() {
      _resolving = true;
      _lookupFailed = false;
    });
    try {
      final found = await ref.read(placeRepositoryProvider).reverse(point.latitude, point.longitude, cancelToken: token);
      if (!mounted || turn != _turn) return;
      setState(() {
        _place = found;
        _resolving = false;
      });
    } catch (e) {
      if (!mounted || turn != _turn) return;
      setState(() {
        _place = Place.point(point.latitude, point.longitude);
        _resolving = false;
        _lookupFailed = true;
      });
    }
  }

  void _zoomBy(double delta) {
    if (!_ready) return;
    _map.move(_centre, (_zoom + delta).clamp(2.0, 19.0));
  }

  Future<void> _useMyPosition() async {
    setState(() => _locating = true);
    try {
      final pos = await readDevicePosition();
      if (mounted) _moveTo(LatLng(pos.latitude, pos.longitude), 17);
    } catch (e) {
      if (mounted) showToast(context, e is ApiException ? e.message : 'Could not read your position. Try again.', error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<Place?> _loadPlace(PlaceSuggestion s, String session) async {
    try {
      return await ref.read(placeRepositoryProvider).resolve(s, sessionToken: session);
    } catch (e) {
      if (mounted) showApiError(context, e);
      return null;
    }
  }

  Future<void> _choose(PlaceSuggestion s) async {
    final session = _searcher.session;
    _query.text = s.title;
    _searcher.clear();
    _queryFocus.unfocus();
    final p = await _loadPlace(s, session);
    if (p == null || !mounted) return;
    _searcher.endSession();
    _pinned = p;
    setState(() {
      _place = p;
      _resolving = false;
      _lookupFailed = false;
    });
    _moveTo(LatLng(p.latitude, p.longitude), _zoomFor(p));
  }

  void _confirm() {
    Navigator.of(context).pop(_place ?? Place.point(_centre.latitude, _centre.longitude));
  }

  // ----------------------------------------------------------------- screen

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                PlaceMapView(
                  centre: _centre,
                  zoom: _zoom,
                  controller: _map,
                  onReady: _onReady,
                  onMove: _onMove,
                  onTap: _queryFocus.unfocus,
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _moving,
                  builder: (context, moving, _) => MapPin(lifted: moving),
                ),
                Positioned(top: 12, left: 12, right: 12, child: _searchBar(context)),
                Positioned(right: 12, bottom: 40, child: PointerInterceptor(child: _controls(context))),
              ],
            ),
          ),
          _footer(context),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    final pal = context.pal;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: PointerInterceptor(
          child: ListenableBuilder(
            listenable: _searcher,
            builder: (context, _) {
              final text = _query.text.trim();
              final results = _searcher.results;
              final open = _queryFocus.hasFocus && text.length >= 3 && (_searcher.loading || _searcher.searched || results.isNotEmpty);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Material(
                    color: context.surfaceColor,
                    elevation: 4,
                    shadowColor: Colors.black.op(0.4),
                    borderRadius: BorderRadius.circular(context.radius(Brand.radiusSmall + 2)),
                    child: TextField(
                      controller: _query,
                      focusNode: _queryFocus,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) {
                        _searcher.search(v);
                        setState(() {});
                      },
                      onTap: () => setState(() {}),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'Search for a place or address',
                        hintStyle: TextStyle(color: context.mutedColor),
                        prefixIcon: Icon(Icons.search_rounded, color: pal.ink3),
                        suffixIcon: _searcher.loading
                            ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                            : (_query.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear',
                                    icon: const Icon(Icons.close_rounded, size: 20),
                                    onPressed: () {
                                      _query.clear();
                                      _searcher.clear();
                                      setState(() {});
                                    },
                                  )),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  if (open)
                    SuggestionPanel(
                      maxHeight: 280,
                      children: <Widget>[
                        if (results.isEmpty && _searcher.loading) const SuggestionNote('Searching', busy: true),
                        if (results.isEmpty && !_searcher.loading && _searcher.failed)
                          const SuggestionNote('Search is not available right now. You can still move the map to place the pin.'),
                        if (results.isEmpty && !_searcher.loading && !_searcher.failed) const SuggestionNote('No matching places. Try another spelling or move the map.'),
                        for (final s in results)
                          SuggestionTile(
                            leading: Icon(Icons.place_outlined, size: 22, color: pal.accent),
                            title: s.title,
                            subtitle: s.subtitle,
                            onTap: () => _choose(s),
                          ),
                        if (results.any((r) => r.id != null)) const PoweredByGoogle(),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    Widget button(IconData icon, String tip, VoidCallback? onTap, {bool busy = false}) {
      return Material(
        color: context.surfaceColor,
        elevation: 3,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tip,
          onPressed: onTap,
          icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(icon, size: 22),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        button(Icons.my_location_rounded, 'Use my position', _locating ? null : _useMyPosition, busy: _locating),
        const SizedBox(height: 10),
        button(Icons.add_rounded, 'Zoom in', () => _zoomBy(1)),
        const SizedBox(height: 6),
        button(Icons.remove_rounded, 'Zoom out', () => _zoomBy(-1)),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    final pal = context.pal;
    final place = _place;
    final far = _zoom < _lookupZoom && place == null;

    String title;
    String? detail;
    if (far) {
      title = 'Move the map to place the pin';
      detail = 'Zoom in on the spot you mean. The address appears here.';
    } else if (_resolving) {
      title = 'Finding the address';
      detail = null;
    } else if (place != null) {
      title = place.title;
      detail = place.subtitle.isNotEmpty ? place.subtitle : (_lookupFailed ? 'The address could not be looked up. The point can still be used.' : 'No street address here. The point can still be used.');
    } else {
      title = 'Pinned location';
      detail = null;
    }

    return Material(
      color: context.surfaceColor,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const IconBadge(Icons.place_rounded, size: 42),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                            if (detail != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.3, color: context.mutedColor)),
                              ),
                          ],
                        ),
                      ),
                      if (_resolving) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  if (!far)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 54),
                      child: Text(
                        '${_centre.latitude.toStringAsFixed(5)}, ${_centre.longitude.toStringAsFixed(5)}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: pal.ink3),
                      ),
                    ),
                  const SizedBox(height: 14),
                  PButton(label: 'Use this location', icon: Icons.check_rounded, expand: true, onPressed: far ? null : _confirm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
