import '../../core/network/service_client.dart';
import '../models/developer_models.dart';
import '../models/json_utils.dart';
import 'envelope.dart';

/// The developer service. Its accounts are separate from the auth-service accounts, so this repository has its own
/// sign in and its own token (see state/developer_session.dart).
class DeveloperRepository {
  DeveloperRepository(this._api);

  final ServiceClient _api;

  String _id(String s) => Uri.encodeComponent(s);

  /// Signs in and returns the access token. The account is read with [me].
  Future<String> login({required String email, required String password}) async {
    final res = await _api.post('/api/v1/auth/login', body: <String, dynamic>{'email': email, 'password': password});
    return strOr(unwrapMap(res)['accessToken']);
  }

  /// Creates a developer account. The person has to confirm the email address before signing in.
  Future<String> signup({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required String country,
    String? companyName,
  }) async {
    final res = await _api.post('/api/v1/auth/signup', body: compact(<String, dynamic>{
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'password': password,
      'country': country,
      'companyName': companyName,
      'acceptTerms': true,
    }));
    return messageOf(res, 'Account created. Check your email to confirm the address.');
  }

  Future<void> forgotPassword(String email) => _api.post('/api/v1/auth/forgot-password', body: <String, dynamic>{'email': email});

  Future<DeveloperAccount> me() async => DeveloperAccount.fromJson(unwrapMap(await _api.get('/api/v1/me')));

  Future<void> logout() => _api.post('/api/v1/me/logout');

  Future<List<DeveloperApp>> apps() async {
    final data = unwrapMap(await _api.get('/api/v1/apps', query: <String, dynamic>{'size': 50}));
    return mapList(data['content']).map(DeveloperApp.fromJson).toList();
  }

  /// Creates an app. A sandbox app comes with a first key, returned here with its secret.
  Future<DeveloperApp> createApp({
    required String name,
    required String environment,
    String? description,
    String? callbackUrl,
    String? merchantNumber,
  }) async {
    final res = await _api.post('/api/v1/apps', body: compact(<String, dynamic>{
      'name': name,
      'environment': environment,
      'description': description,
      'callbackUrl': callbackUrl,
      'merchantNumber': merchantNumber,
    }));
    return DeveloperApp.fromJson(unwrapMap(res));
  }

  Future<void> suspendApp(String appId) => _api.post('/api/v1/apps/${_id(appId)}/suspend');

  Future<void> reactivateApp(String appId) => _api.post('/api/v1/apps/${_id(appId)}/reactivate');

  Future<List<ApiKeyModel>> keys(String appId) async {
    final data = unwrapMap(await _api.get('/api/v1/apps/${_id(appId)}/keys'));
    return mapList(data['keys']).map(ApiKeyModel.fromJson).toList();
  }

  /// A new key. The secret is in the answer once and is never shown again.
  Future<ApiKeyModel> createKey(String appId, {String? label}) async {
    final res = await _api.post('/api/v1/apps/${_id(appId)}/keys', body: compact(<String, dynamic>{'label': label}));
    return ApiKeyModel.fromJson(unwrapMap(res));
  }

  Future<ApiKeyModel> rotateKey(String appId, String key) async {
    final res = await _api.post('/api/v1/apps/${_id(appId)}/keys/${_id(key)}/rotate');
    return ApiKeyModel.fromJson(unwrapMap(res));
  }

  Future<void> revokeKey(String appId, String key) => _api.delete('/api/v1/apps/${_id(appId)}/keys/${_id(key)}');
}
