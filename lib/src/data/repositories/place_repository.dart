import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/json_utils.dart';
import '../models/place.dart';

/// Address search and "what is here" lookups.
///
/// When the auth-service has a Google key (GOOGLE_MAPS_API_KEY), suggestions and addresses come from Google Places
/// through the service, which knows places like Donholm or Outer Ring Road far better than free map data. The key
/// never reaches the app. Without a key, or if the service cannot be reached, this falls back to Photon, a free
/// geocoder built on OpenStreetMap data. The fallback uses its own HTTP client, because the app's API client
/// carries the sign in token, which must never be sent to a third party.
class PlaceRepository {
  PlaceRepository(this._api, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.geocoderUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              responseType: ResponseType.json,
              // The free geocoder asks apps to say who they are. A browser sets its own and does not allow this header.
              headers: kIsWeb ? null : <String, dynamic>{'User-Agent': 'Premisave-App/1.0'},
            ));

  final ApiClient _api;
  final Dio _dio;
  final Map<String, List<Place>> _cache = <String, List<Place>>{};
  bool? _googleOn;

  /// A fresh token for one search. Google bills a typed search and the choice that ends it as a single session.
  String newSession() {
    final r = Random.secure();
    return List<String>.generate(24, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  Future<bool> _useGoogle() async {
    // Google's terms keep its place data off other companies' maps, and Linux, Windows and macOS have no Google map.
    if (!AppConfig.googleMapsSupported) return false;
    final known = _googleOn;
    if (known != null) return known;
    try {
      final res = asMap(await _api.get('/places/status'));
      return _googleOn = boolOr(res['enabled']);
    } catch (e) {
      // An older service without /places has nothing to ask again. Any other failure, such as being offline or
      // signed out, uses the free search now and asks again next time.
      if (e is ApiException && e.isNotFound) _googleOn = false;
      return false;
    }
  }

  // ------------------------------------------------------------------ suggestions

  /// Suggestions for [query]. Results in [countryCode] come first.
  Future<List<PlaceSuggestion>> search(
    String query, {
    String? countryCode,
    String? sessionToken,
    int limit = 6,
    CancelToken? cancelToken,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const <PlaceSuggestion>[];
    if (await _useGoogle()) {
      try {
        final res = await _api.get('/places/suggest', query: <String, dynamic>{
          'q': q,
          if (countryCode != null) 'country': countryCode,
          if (sessionToken != null) 'session': sessionToken,
        });
        return <PlaceSuggestion>[
          for (final m in mapList(res))
            if (str(m['id']) != null && str(m['title']) != null)
              PlaceSuggestion(id: str(m['id']), title: str(m['title'])!, subtitle: strOr(m['subtitle'])),
        ].take(limit).toList();
      } catch (e) {
        if (e is ApiException && e.isRateLimited) rethrow;
        // Google could not answer. The free search still can.
      }
    }
    final found = await _photonSearch(q, countryCode: countryCode, limit: limit, cancelToken: cancelToken);
    return <PlaceSuggestion>[for (final p in found) PlaceSuggestion.fromPlace(p)];
  }

  /// The full place for a chosen suggestion, with coordinates and address parts.
  Future<Place> resolve(PlaceSuggestion suggestion, {String? sessionToken}) async {
    final ready = suggestion.place;
    if (ready != null) return ready;
    final id = suggestion.id;
    if (id == null) throw ApiException('That place could not be loaded.');
    final res = await _api.get('/places/details', query: <String, dynamic>{
      'id': id,
      if (sessionToken != null) 'session': sessionToken,
    });
    final place = Place.fromJson(asMap(res));
    if (place == null) throw ApiException('That place could not be loaded.');
    return place;
  }

  // ------------------------------------------------------------------ the map

  /// The address at a point on the map. The point itself is kept, not moved to the nearest feature.
  Future<Place> reverse(double latitude, double longitude, {CancelToken? cancelToken}) async {
    if (await _useGoogle()) {
      try {
        final res = await _api.get('/places/reverse', query: <String, dynamic>{'lat': latitude, 'lng': longitude});
        final place = Place.fromJson(asMap(res));
        if (place != null) return place.withPoint(latitude, longitude);
      } catch (_) {
        // No address known to Google here, or it is unavailable. Try the free lookup.
      }
    }
    final res = await _dio.get<dynamic>(
      '/reverse',
      queryParameters: <String, dynamic>{'lat': latitude, 'lon': longitude, 'lang': 'en'},
      cancelToken: cancelToken,
    );
    final found = _parsePhoton(res.data);
    if (found.isEmpty) return Place.point(latitude, longitude);
    return found.first.withPoint(latitude, longitude);
  }

  /// A rough position for a country, region or town name, used only to start the map in the right area.
  /// It always uses the free search, so it never costs anything.
  Future<Place?> locate(String text) async {
    final found = await _photonSearch(text, limit: 1);
    return found.isEmpty ? null : found.first;
  }

  // ------------------------------------------------------------------ free search (Photon)

  Future<List<Place>> _photonSearch(
    String query, {
    String? countryCode,
    int limit = 6,
    CancelToken? cancelToken,
  }) async {
    final q = query.trim();
    if (q.length < 2) return const <Place>[];
    final key = '${countryCode ?? ''}|$limit|${q.toLowerCase()}';
    final cached = _cache[key];
    if (cached != null) return cached;

    final res = await _dio.get<dynamic>(
      '/api/',
      queryParameters: <String, dynamic>{'q': q, 'limit': countryCode == null ? limit : limit + 4, 'lang': 'en'},
      cancelToken: cancelToken,
    );
    var places = _parsePhoton(res.data);
    if (countryCode != null) {
      final code = countryCode.toUpperCase();
      final inside = places.where((p) => p.countryCode == code).toList();
      final outside = places.where((p) => p.countryCode != code).toList();
      places = <Place>[...inside, ...outside].take(limit).toList();
    }
    if (_cache.length > 60) _cache.remove(_cache.keys.first);
    return _cache[key] = places;
  }

  List<Place> _parsePhoton(dynamic data) {
    if (data is! Map || data['features'] is! List) return const <Place>[];
    final seen = <String>{};
    final out = <Place>[];
    for (final f in data['features'] as List) {
      final p = Place.fromPhoton(f);
      if (p == null) continue;
      // The geocoder can return the same address twice, for example as a building and as a house.
      if (seen.add('${p.title}|${p.subtitle}')) out.add(p);
    }
    return out;
  }
}
