import 'package:flutter/foundation.dart';

import 'country.dart';
import 'json_utils.dart';

/// A place on the map: a point plus the address parts the geocoder knows about it.
@immutable
class Place {
  const Place({
    required this.latitude,
    required this.longitude,
    this.name,
    this.houseNumber,
    this.street,
    this.district,
    this.city,
    this.state,
    this.postcode,
    this.country,
    this.countryCode,
  });

  final double latitude;
  final double longitude;

  /// Name of a building, shop, suburb or town when the result is one.
  final String? name;
  final String? houseNumber;
  final String? street;
  final String? district;
  final String? city;
  final String? state;
  final String? postcode;
  final String? country;
  final String? countryCode;

  /// A point on the map with no address known.
  const Place.point(this.latitude, this.longitude)
      : name = null,
        houseNumber = null,
        street = null,
        district = null,
        city = null,
        state = null,
        postcode = null,
        country = null,
        countryCode = null;

  /// Reads a place sent by the auth-service (/places/details and /places/reverse). Returns null without coordinates.
  static Place? fromJson(Map<String, dynamic> j) {
    final lat = doubleOrNull(j['latitude']);
    final lng = doubleOrNull(j['longitude']);
    if (lat == null || lng == null) return null;
    final code = str(j['countryCode'])?.toUpperCase();
    return Place(
      latitude: lat,
      longitude: lng,
      name: str(j['name']),
      houseNumber: str(j['houseNumber']),
      street: str(j['street']),
      district: str(j['district']),
      city: str(j['city']),
      state: str(j['state']),
      postcode: str(j['postcode']),
      country: Country.byCode(code)?.name ?? str(j['country']),
      countryCode: code,
    );
  }

  /// Reads one feature of a Photon (OpenStreetMap) response. Returns null without coordinates.
  static Place? fromPhoton(Object? feature) {
    if (feature is! Map) return null;
    final geometry = feature['geometry'];
    final props = feature['properties'];
    if (geometry is! Map || props is! Map) return null;
    final coords = geometry['coordinates'];
    if (coords is! List || coords.length < 2 || coords[0] is! num || coords[1] is! num) return null;

    String? s(Object? v) {
      final t = v is String ? v.trim() : '';
      return t.isEmpty ? null : t;
    }

    final code = s(props['countrycode'])?.toUpperCase();
    var name = s(props['name']);
    var street = s(props['street']);
    // A street result has its own name and no separate street field.
    if (street == null && props['osm_key'] == 'highway') {
      street = name;
      name = null;
    }
    return Place(
      latitude: (coords[1] as num).toDouble(),
      longitude: (coords[0] as num).toDouble(),
      name: name,
      houseNumber: s(props['housenumber']),
      street: street,
      district: s(props['district']) ?? s(props['locality']),
      city: s(props['city']) ?? s(props['county']),
      state: s(props['state']),
      postcode: s(props['postcode']),
      country: Country.byCode(code)?.name ?? s(props['country']),
      countryCode: code,
    );
  }

  Place withPoint(double lat, double lng) => Place(
        latitude: lat,
        longitude: lng,
        name: name,
        houseNumber: houseNumber,
        street: street,
        district: district,
        city: city,
        state: state,
        postcode: postcode,
        country: country,
        countryCode: countryCode,
      );

  static const Set<String> _numberFirst = <String>{'US', 'CA', 'GB', 'IE', 'AU', 'NZ', 'FR', 'ZA', 'IN', 'SG', 'MY', 'PH', 'NG', 'GH', 'KE', 'TZ', 'UG', 'RW'};

  /// House number and street, in the order people write them in that country.
  String get streetLine {
    final st = street;
    if (st == null) return '';
    final no = houseNumber;
    if (no == null) return st;
    return _numberFirst.contains(countryCode) ? '$no $st' : '$st $no';
  }

  /// Town, region and postcode on one line, for a second address line.
  String get localityLine => _join(<String?>[city ?? district, state == city ? null : state, postcode]);

  /// The best single line to show for this place.
  String get title {
    if (name != null) return name!;
    if (streetLine.isNotEmpty) return streetLine;
    return city ?? district ?? state ?? country ?? 'Pinned location';
  }

  /// The rest of the address, without repeating the title.
  String get subtitle {
    final parts = <String?>[
      if (name != null) streetLine,
      if (name != null || streetLine.isNotEmpty) (city ?? district) else null,
      state,
      country,
    ];
    return _join(parts, skip: title);
  }

  /// One line with everything, for a single "location" text box.
  String get summary => _join(<String?>[title, city ?? district, state, country]);

  /// True when the geocoder knew nothing but the point.
  bool get isBare => name == null && street == null && city == null && district == null && state == null && country == null;

  static String _join(List<String?> parts, {String? skip}) {
    final seen = <String>{if (skip != null) skip.toLowerCase()};
    final out = <String>[];
    for (final p in parts) {
      final t = p?.trim() ?? '';
      if (t.isEmpty || !seen.add(t.toLowerCase())) continue;
      out.add(t);
    }
    return out.join(', ');
  }
}

/// One line in the address search results. The free search returns the whole [place] at once. Google results only
/// carry an [id], and the place is fetched when the user chooses the suggestion.
@immutable
class PlaceSuggestion {
  const PlaceSuggestion({required this.title, this.subtitle = '', this.id, this.place});

  factory PlaceSuggestion.fromPlace(Place p) => PlaceSuggestion(title: p.title, subtitle: p.subtitle, place: p);

  final String title;
  final String subtitle;
  final String? id;
  final Place? place;
}
