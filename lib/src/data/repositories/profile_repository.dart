import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/location_model.dart';
import '../models/social_models.dart';
import '../models/user_model.dart';

/// /profile and /location endpoints.
class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  Future<UserModel> me() async => UserModel.fromJson(asMap(await _api.get('/profile/me')));

  Future<UserModel> user(String id) async =>
      UserModel.fromJson(asMap(await _api.get('/profile/user/${Uri.encodeComponent(id)}')));

  Future<String> update({
    required String username,
    required String firstName,
    String? middleName,
    required String lastName,
    required String phoneNumber,
    String? address1,
    String? address2,
    String? country,
    required String language,
  }) async {
    final res = await _api.put('/profile/update', body: {
      'username': username.trim(),
      'firstName': firstName.trim(),
      'middleName': (middleName ?? '').trim(),
      'lastName': lastName.trim(),
      'phoneNumber': phoneNumber.trim(),
      'address1': (address1 ?? '').trim(),
      'address2': (address2 ?? '').trim(),
      'country': (country ?? '').trim(),
      'language': language,
    });
    return strOr(asMap(res)['message'], 'Profile updated.');
  }

  /// Uploads a new avatar. Returns the new picture URL when the server reports one.
  Future<String?> uploadPicture({required List<int> bytes, required String fileName}) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
    });
    final res = asMap(await _api.upload('/profile/upload-profile-picture', form));
    return str(res['profilePictureUrl'] ?? res['url'] ?? res['imageUrl']);
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final res = await _api.post('/profile/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
    return strOr(asMap(res)['message'], 'Password changed successfully.');
  }

  Future<List<UserModel>> search(String query) async {
    final res = await _api.get('/profile/search', query: {'query': query});
    return mapList(res).map(UserModel.fromJson).toList();
  }

  Future<List<DirectoryEntry>> directory() async =>
      mapList(await _api.get('/profile/public/directory')).map(DirectoryEntry.new).toList();

  // Profile views

  Future<void> recordView(String targetId) async {
    await _api.post('/profile/views/${Uri.encodeComponent(targetId)}');
  }

  Future<List<ProfileViewEntry>> whoViewedMe() async =>
      mapList(await _api.get('/profile/views/who-viewed-me')).map(ProfileViewEntry.new).toList();

  Future<List<ProfileViewEntry>> whoIViewed() async =>
      mapList(await _api.get('/profile/views/who-i-viewed')).map(ProfileViewEntry.new).toList();

  Future<StatsModel> myViewStats() async => StatsModel(asMap(await _api.get('/profile/views/my-stats')));

  Future<StatsModel> viewStats() async => StatsModel(asMap(await _api.get('/profile/views/stats')));

  Future<StatsModel> viewStatsFor(String targetId) async =>
      StatsModel(asMap(await _api.get('/profile/views/stats/${Uri.encodeComponent(targetId)}')));

  // Location

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    String? locationName,
    String? address,
    String? country,
    String? city,
  }) async {
    await _api.put('/location', body: compact({
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'address': address,
      'country': country,
      'city': city,
    }));
  }

  Future<LocationModel?> currentLocation() async {
    final res = await _api.get('/location/current');
    final m = asMap(res);
    return m.isEmpty ? null : LocationModel(m);
  }

  Future<List<LocationModel>> locationHistory({int? limit}) async {
    final res = await _api.get('/location/history', query: limit == null ? null : {'limit': limit});
    return mapList(res).map(LocationModel.new).toList();
  }
}
