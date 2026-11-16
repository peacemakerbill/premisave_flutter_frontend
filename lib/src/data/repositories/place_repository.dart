import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../models/place.dart';

/// Address search and "what is here" lookups, backed by Photon, a free geocoder built on OpenStreetMap data.
///
/// This uses its own HTTP client on purpose: the app's API client carries the sign in token, which must never
/// be sent to a third party. Point [AppConfig.geocoderUrl] at your own Photon server or a compatible provider
/// before launching at scale, because the public server is meant for modest traffic.
class PlaceRepository {
  PlaceRepository({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.geocoderUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 8),
              responseType: ResponseType.json,
            ));

  final Dio _dio;
  final Map<String, List<Place>> _cache = <String, List<Place>>{};

  /// Places matching [query]. Results in [countryCode] come first when it is given.
  Future<List<Place>> search(
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
    var places = _parse(res.data);
    if (countryCode != null) {
      final code = countryCode.toUpperCase();
      final inside = places.where((p) => p.countryCode == code).toList();
      final outside = places.where((p) => p.countryCode != code).toList();
      places = <Place>[...inside, ...outside].take(limit).toList();
    }
    if (_cache.length > 60) _cache.remove(_cache.keys.first);
    return _cache[key] = places;
  }

  /// The address at a point on the map. The point itself is kept, not moved to the nearest feature.
  Future<Place> reverse(double latitude, double longitude, {CancelToken? cancelToken}) async {
    final res = await _dio.get<dynamic>(
      '/reverse',
      queryParameters: <String, dynamic>{'lat': latitude, 'lon': longitude, 'lang': 'en'},
      cancelToken: cancelToken,
    );
    final found = _parse(res.data);
    if (found.isEmpty) return Place.point(latitude, longitude);
    return found.first.withPoint(latitude, longitude);
  }

  List<Place> _parse(dynamic data) {
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
