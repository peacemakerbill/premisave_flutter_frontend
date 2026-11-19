import 'dart:typed_data';


import 'package:dio/dio.dart';

import '../../core/network/service_client.dart';
import '../models/developer_models.dart';
import '../models/json_utils.dart';
import 'envelope.dart';
import 'messenger_repository.dart' show LocalFile;

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

  /// The keys of an app as the service sent them.
  Future<List<Map<String, dynamic>>> keysRaw(String appId) async => rows(await _api.get('/api/v1/apps/${_id(appId)}/keys'), key: 'keys');

  /// A new key as the service sent it, with the secret that is shown once.
  Future<Map<String, dynamic>> createKeyRaw(String appId, {String? label}) async =>
      unwrapMap(await _api.post('/api/v1/apps/${_id(appId)}/keys', body: compact(<String, dynamic>{'label': label})));

  Future<Map<String, dynamic>> rotateKeyRaw(String appId, String key) async =>
      unwrapMap(await _api.post('/api/v1/apps/${_id(appId)}/keys/${_id(key)}/rotate'));

  // ------------------------------------------------------------- sign in help

  /// Confirms an email address with the code from the link in the email.
  Future<String> verifyEmail(String token) async =>
      messageOf(await _api.post('/api/v1/auth/verify-email', body: <String, dynamic>{'token': token}), 'Email confirmed');

  /// Sends the confirmation email again.
  Future<String> resendVerification(String email) async => messageOf(
        await _api.post('/api/v1/auth/resend-verification', body: <String, dynamic>{'email': email}),
        'If the account exists and is waiting for confirmation, a new email is on its way.',
      );

  Future<String> resetPassword({required String token, required String newPassword}) async => messageOf(
        await _api.post('/api/v1/auth/reset-password', body: <String, dynamic>{'token': token, 'newPassword': newPassword}),
        'Your password was changed',
      );

  /// Which social sign ins are switched on, with the public client id of each. Providers are google, facebook and github.
  Future<({List<String> providers, Map<String, String> clientIds})> socialProviders() async {
    final data = unwrapMap(await _api.get('/api/v1/auth/social/providers'));
    final ids = <String, String>{};
    asMap(data['clientIds']).forEach((k, v) => ids[k] = '$v');
    return (providers: stringList(data['providers']), clientIds: ids);
  }

  /// Signs in or up with what the provider gave the app: Google's ID token, Facebook's access token or GitHub's code
  /// ([token]), or, on Linux and Windows, an authorization code and the redirect address it was issued for ([code] and
  /// [redirectUri]), which the service trades with the provider.
  Future<String> socialLogin(String provider, {String? token, String? code, String? redirectUri}) async {
    final res = await _api.post('/api/v1/auth/social/${_id(provider)}', body: <String, dynamic>{
      if (token != null) 'token': token,
      if (code != null) 'code': code,
      if (redirectUri != null) 'redirectUri': redirectUri,
    });
    return strOr(unwrapMap(res)['accessToken']);
  }

  /// Opens the link from the "join Facebook to your account" email. Joins the provider account and signs nobody in.
  /// Returns the provider's key, such as facebook.
  Future<String> confirmProviderLink(String token) async {
    final res = await _api.post('/api/v1/auth/social/link/confirm', body: <String, dynamic>{'token': token});
    return strOr(unwrapMap(res)['provider']);
  }

  /// The providers joined to the signed in account.
  Future<DeveloperConnections> connections() async =>
      DeveloperConnections.fromJson(unwrapMap(await _api.get('/api/v1/me/connections')));

  /// Joins a provider account to the signed in account with what the provider gave the app (see [socialLogin]).
  Future<DeveloperConnections> connect(String provider, {String? token, String? code, String? redirectUri}) async {
    final res = await _api.post('/api/v1/me/connections/${_id(provider)}', body: <String, dynamic>{
      if (token != null) 'token': token,
      if (code != null) 'code': code,
      if (redirectUri != null) 'redirectUri': redirectUri,
    });
    return DeveloperConnections.fromJson(unwrapMap(res));
  }

  Future<DeveloperConnections> disconnect(String provider) async =>
      DeveloperConnections.fromJson(unwrapMap(await _api.delete('/api/v1/me/connections/${_id(provider)}')));

  // ------------------------------------------------------------------ profile

  Future<Map<String, dynamic>> profile() async => unwrapMap(await _api.get('/api/v1/me'));

  Future<DeveloperAccount> updateProfile(Map<String, dynamic> changes) async =>
      DeveloperAccount.fromJson(unwrapMap(await _api.put('/api/v1/me', body: changes)));

  Future<void> changePassword({String? currentPassword, required String newPassword}) => _api.put(
        '/api/v1/me/password',
        body: compact(<String, dynamic>{'currentPassword': currentPassword, 'newPassword': newPassword}),
      );

  /// Ends every session of this account on every device.
  Future<void> logoutAll() => _api.post('/api/v1/me/logout-all');

  /// Sends the confirmation email to the signed in account.
  Future<void> resendMyVerification() => _api.post('/api/v1/me/resend-verification');

  Future<bool> usernameAvailable(String username) async {
    final data = unwrapMap(await _api.get('/api/v1/me/username-available', query: <String, dynamic>{'username': username}));
    return boolOr(data['available']);
  }

  /// The image is sent as the whole request body.
  Future<void> uploadPicture(Uint8List bytes, {required String contentType}) =>
      _api.putBytes('/api/v1/me/profile-picture', bytes, contentType: contentType);

  Future<void> removePicture() => _api.delete('/api/v1/me/profile-picture');

  /// Merchant numbers that behave in a known way in the sandbox, for testing payments.
  Future<Map<String, dynamic>> testMerchantNumbers() async => unwrapMap(await _api.get('/api/v1/meta/test-merchant-numbers'));

  // --------------------------------------------------------------------- apps

  Future<List<Map<String, dynamic>>> appsRaw({String? environment, String? status, String? businessId}) async =>
      rows(await _api.get('/api/v1/apps', query: compact(<String, dynamic>{
        'environment': environment,
        'status': status,
        'businessId': businessId,
        'size': 100,
      })));

  Future<Map<String, dynamic>> app(String appId) async => unwrapMap(await _api.get('/api/v1/apps/${_id(appId)}'));

  /// Changes name, description, callback address, enabled methods or limits. Only the fields sent are changed.
  Future<Map<String, dynamic>> updateApp(String appId, Map<String, dynamic> changes) async =>
      unwrapMap(await _api.put('/api/v1/apps/${_id(appId)}', body: changes));

  /// Creates an app from a full request. A sandbox app needs no business. A live app needs a business with an approved application.
  Future<Map<String, dynamic>> createAppRaw(Map<String, dynamic> request) async =>
      unwrapMap(await _api.post('/api/v1/apps', body: compact(request)));

  // --------------------------------------------------------------- businesses

  Future<List<Map<String, dynamic>>> businesses() async => rows(await _api.get('/api/v1/businesses'), key: 'businesses');

  Future<Map<String, dynamic>> business(String businessId) async => unwrapMap(await _api.get('/api/v1/businesses/${_id(businessId)}'));

  Future<Map<String, dynamic>> applyForBusiness(Map<String, dynamic> request) async =>
      unwrapMap(await _api.post('/api/v1/businesses', body: compact(request)));

  String _app(String businessId) => '/api/v1/businesses/${_id(businessId)}/application';

  /// The onboarding application of a business: form, documents and status.
  Future<Map<String, dynamic>> application(String businessId) async => unwrapMap(await _api.get(_app(businessId)));

  /// Starts the application when the business has none yet.
  Future<Map<String, dynamic>> startApplication(String businessId) async => unwrapMap(await _api.post(_app(businessId)));

  /// Saves the form. Fields left out keep their value. Directors, when sent, replace the whole list.
  Future<Map<String, dynamic>> saveApplication(String businessId, Map<String, dynamic> form) async =>
      unwrapMap(await _api.put(_app(businessId), body: form));

  /// Attaches a PDF, PNG or JPEG. [type] says what it is, for example BUSINESS_REGISTRATION.
  Future<Map<String, dynamic>> uploadApplicationDocument(String businessId, LocalFile file, {required String type}) async {
    final form = FormData();
    form.fields.add(MapEntry<String, String>('type', type));
    form.files.add(MapEntry<String, MultipartFile>('file', await file.toMultipart()));
    return unwrapMap(await _api.uploadWith('POST', '${_app(businessId)}/documents', form));
  }

  Future<void> removeApplicationDocument(String businessId, String documentId) =>
      _api.delete('${_app(businessId)}/documents/${_id(documentId)}');

  Future<Uint8List> downloadApplicationDocument(String businessId, String documentId) =>
      _api.download('${_app(businessId)}/documents/${_id(documentId)}/content');

  Future<Map<String, dynamic>> submitApplication(String businessId, {String? message, List<Map<String, dynamic>>? responses}) async =>
      unwrapMap(await _api.post('${_app(businessId)}/submit', body: compact(<String, dynamic>{'message': message, 'responses': responses})));

  Future<List<Map<String, dynamic>>> applicationTimeline(String businessId) async =>
      rows(await _api.get('${_app(businessId)}/timeline'), key: 'events');

  // ---------------------------------------------------------------- transfers

  /// Starts handing an app over to another developer by email. A 6 digit code is emailed to confirm it.
  Future<Map<String, dynamic>> transferApp(String appId, String toEmail) async =>
      unwrapMap(await _api.post('/api/v1/apps/${_id(appId)}/transfer', body: <String, dynamic>{'toEmail': toEmail}));

  Future<List<Map<String, dynamic>>> transfers() async => rows(await _api.get('/api/v1/transfers'), key: 'transfers');

  Future<Map<String, dynamic>> transfer(String id) async => unwrapMap(await _api.get('/api/v1/transfers/${_id(id)}'));

  Future<Map<String, dynamic>> confirmTransfer(String id, String otp) async =>
      unwrapMap(await _api.post('/api/v1/transfers/${_id(id)}/confirm', body: <String, dynamic>{'otp': otp}));

  Future<Map<String, dynamic>> resendTransferCode(String id) async => unwrapMap(await _api.post('/api/v1/transfers/${_id(id)}/resend'));

  Future<Map<String, dynamic>> cancelTransfer(String id) async => unwrapMap(await _api.delete('/api/v1/transfers/${_id(id)}'));

  /// Takes over a business by the merchant number it was created under.
  Future<Map<String, dynamic>> claimBusiness(String merchantNumber) async =>
      unwrapMap(await _api.post('/api/v1/transfers/claim', body: <String, dynamic>{'merchantNumber': merchantNumber}));

  // -------------------------------------------------------------------- admin
  // Everything below needs a developer account with the ADMIN role.

  static const String _admin = '/api/v1/admin';

  Future<Map<String, dynamic>> adminStats() async => unwrapMap(await _api.get('$_admin/stats'));

  Future<List<Map<String, dynamic>>> adminAudit({String? actorId, String? targetId, String? action}) async =>
      rows(await _api.get('$_admin/audit', query: compact(<String, dynamic>{'actorId': actorId, 'targetId': targetId, 'action': action, 'size': 100})));

  Future<List<Map<String, dynamic>>> adminDevelopers({String? q, String? status}) async =>
      rows(await _api.get('$_admin/developers', query: compact(<String, dynamic>{'q': q, 'status': status, 'size': 100})));

  Future<List<Map<String, dynamic>>> adminAdministrators() async =>
      rows(await _api.get('$_admin/administrators', query: <String, dynamic>{'size': 100}));

  Future<Map<String, dynamic>> adminCreateDeveloper(Map<String, dynamic> request) async =>
      unwrapMap(await _api.post('$_admin/developers', body: compact(request)));

  Future<Map<String, dynamic>> adminDeveloper(String id) async => unwrapMap(await _api.get('$_admin/developers/${_id(id)}'));

  Future<Map<String, dynamic>> adminUpdateDeveloper(String id, Map<String, dynamic> changes) async =>
      unwrapMap(await _api.put('$_admin/developers/${_id(id)}', body: changes));

  Future<void> adminDeleteDeveloper(String id) => _api.delete('$_admin/developers/${_id(id)}');

  /// [status] is ACTIVE or DISABLED.
  Future<void> adminSetDeveloperStatus(String id, String status, {String? reason}) =>
      _api.put('$_admin/developers/${_id(id)}/status', body: compact(<String, dynamic>{'status': status, 'reason': reason}));

  Future<void> adminSetDeveloperRole(String id, String role) =>
      _api.put('$_admin/developers/${_id(id)}/role', body: <String, dynamic>{'role': role});

  Future<void> adminSetDeveloperEmail(String id, String email, {bool? verified}) =>
      _api.put('$_admin/developers/${_id(id)}/email', body: compact(<String, dynamic>{'email': email, 'verified': verified}));

  Future<void> adminVerifyDeveloperEmail(String id) => _api.post('$_admin/developers/${_id(id)}/verify-email');

  Future<void> adminUnlockDeveloper(String id) => _api.post('$_admin/developers/${_id(id)}/unlock');

  Future<void> adminSignOutDeveloper(String id) => _api.post('$_admin/developers/${_id(id)}/sign-out');

  Future<void> adminSendPasswordReset(String id) => _api.post('$_admin/developers/${_id(id)}/password-reset');

  Future<List<Map<String, dynamic>>> adminDeveloperApps(String id, {String? environment}) async =>
      rows(await _api.get('$_admin/developers/${_id(id)}/apps', query: compact(<String, dynamic>{'environment': environment, 'size': 100})));

  Future<List<Map<String, dynamic>>> adminDeveloperBusinesses(String id) async =>
      rows(await _api.get('$_admin/developers/${_id(id)}/businesses'), key: 'businesses');

  Future<void> adminShareBusiness(String developerId, String businessId) =>
      _api.post('$_admin/developers/${_id(developerId)}/businesses/${_id(businessId)}');

  Future<void> adminUnshareBusiness(String developerId, String businessId) =>
      _api.delete('$_admin/developers/${_id(developerId)}/businesses/${_id(businessId)}');

  Future<List<Map<String, dynamic>>> adminApps({String? developerId, String? businessId, String? environment, String? status, String? name}) async =>
      rows(await _api.get('$_admin/apps', query: compact(<String, dynamic>{
        'developerId': developerId,
        'businessId': businessId,
        'environment': environment,
        'status': status,
        'name': name,
        'size': 100,
      })));

  Future<Map<String, dynamic>> adminApp(String appId) async => unwrapMap(await _api.get('$_admin/apps/${_id(appId)}'));

  Future<Map<String, dynamic>> adminUpdateApp(String appId, Map<String, dynamic> changes) async =>
      unwrapMap(await _api.put('$_admin/apps/${_id(appId)}', body: changes));

  Future<void> adminDeleteApp(String appId) => _api.delete('$_admin/apps/${_id(appId)}');

  Future<void> adminSetAppStatus(String appId, String status, {String? reason}) =>
      _api.put('$_admin/apps/${_id(appId)}/status', body: compact(<String, dynamic>{'status': status, 'reason': reason}));

  Future<void> adminSetAppOwner(String appId, String developerId) =>
      _api.put('$_admin/apps/${_id(appId)}/owner', body: <String, dynamic>{'developerId': developerId});

  Future<List<Map<String, dynamic>>> adminKeys(String appId) async =>
      rows(await _api.get('$_admin/apps/${_id(appId)}/keys'), key: 'keys');

  Future<Map<String, dynamic>> adminIssueKey(String appId, {String? label}) async =>
      unwrapMap(await _api.post('$_admin/apps/${_id(appId)}/keys', body: compact(<String, dynamic>{'label': label})));

  Future<void> adminRevokeAllKeys(String appId) => _api.delete('$_admin/apps/${_id(appId)}/keys');

  Future<Map<String, dynamic>> adminRotateKey(String appId, String key) async =>
      unwrapMap(await _api.post('$_admin/apps/${_id(appId)}/keys/${_id(key)}/rotate'));

  Future<void> adminRevokeKey(String appId, String key) => _api.delete('$_admin/apps/${_id(appId)}/keys/${_id(key)}');

  Future<List<Map<String, dynamic>>> adminTransfers({String? status, String? type, String? developerId}) async =>
      rows(await _api.get('$_admin/transfers', query: compact(<String, dynamic>{'status': status, 'type': type, 'developerId': developerId, 'size': 100})));

  Future<Map<String, dynamic>> adminTransfer(String id) async => unwrapMap(await _api.get('$_admin/transfers/${_id(id)}'));

  Future<void> adminCancelTransfer(String id) => _api.delete('$_admin/transfers/${_id(id)}');
}
