import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/user_model.dart';

/// /admin/users endpoints (administrators only).
class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  String _id(String s) => Uri.encodeComponent(s);

  Future<List<UserModel>> all() async => mapList(await _api.get('/admin/users')).map(UserModel.fromJson).toList();

  Future<List<UserModel>> active() async =>
      mapList(await _api.get('/admin/users/active')).map(UserModel.fromJson).toList();

  Future<List<UserModel>> archived() async =>
      mapList(await _api.get('/admin/users/archived')).map(UserModel.fromJson).toList();

  Future<List<UserModel>> search(String query) async =>
      mapList(await _api.post('/admin/users/search', body: {'query': query})).map(UserModel.fromJson).toList();

  Future<UserModel> byId(String id) async =>
      UserModel.fromJson(asMap(await _api.get('/admin/users/${_id(id)}')));

  Future<UserModel> create({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required Role role,
    bool active = true,
    bool verified = true,
  }) async {
    final res = await _api.post('/admin/users/create', body: {
      'username': username.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'phoneNumber': phoneNumber.trim(),
      'role': role.api,
      'active': active,
      'verified': verified,
    });
    return UserModel.fromJson(asMap(res));
  }

  Future<bool> emailExists(String email) async =>
      boolOr(await _api.get('/admin/users/exists/email/${_id(email)}'));

  Future<bool> usernameExists(String username) async =>
      boolOr(await _api.get('/admin/users/exists/username/${_id(username)}'));

  Future<String> archive(String id) => _put('/admin/users/archive/${_id(id)}');
  Future<String> unarchive(String id) => _put('/admin/users/unarchive/${_id(id)}');
  Future<String> activate(String id) => _put('/admin/users/activate/${_id(id)}');
  Future<String> deactivate(String id) => _put('/admin/users/deactivate/${_id(id)}');
  Future<String> verify(String id) => _put('/admin/users/verify/${_id(id)}');
  Future<String> unverify(String id) => _put('/admin/users/unverify/${_id(id)}');

  /// Starts a password reset: the user receives an email link to pick a new password.
  Future<String> resetPassword(String id) => _put('/admin/users/reset-password/${_id(id)}');

  Future<String> changeRole(String id, Role role) =>
      _put('/admin/users/change-role/${_id(id)}', body: {'role': role.api});

  Future<String> delete(String id) async {
    final res = await _api.delete('/admin/users/delete/${_id(id)}');
    return strOr(asMap(res)['message'], 'User deleted.');
  }

  Future<String> _put(String path, {Object? body}) async {
    final res = await _api.put(path, body: body);
    return strOr(asMap(res)['message'], 'Done.');
  }
}
