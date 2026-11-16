import 'json_utils.dart';

class LocationModel {
  LocationModel(Map<String, dynamic> j)
      : latitude = doubleOrNull(j['latitude']),
        longitude = doubleOrNull(j['longitude']),
        locationName = str(j['locationName']),
        address = str(j['address']),
        country = str(j['country']),
        city = str(j['city']),
        updatedAt = dateOrNull(j['updatedAt'] ?? j['createdAt'] ?? j['timestamp']);

  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? address;
  final String? country;
  final String? city;
  final DateTime? updatedAt;

  String get title => locationName ?? city ?? address ?? 'Saved location';

  String get subtitle {
    final parts = <String>[
      if (address != null) address!,
      if (city != null && city != locationName) city!,
      if (country != null) country!,
    ];
    return parts.join(', ');
  }
}
