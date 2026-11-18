import 'dart:convert';

import '../../core/network/service_client.dart';
import '../models/c2b_models.dart';
import '../models/json_utils.dart';
import 'envelope.dart';

/// The C2B Hakikisha service answers "who owns this M-Pesa account?" for Safaricom.
///
/// It does not use the Premisave sign in. It has its own client credentials (the Basic Auth user and password set in
/// the service), which are exchanged for a short lived access token. Signed in staff do not type them: the service reads
/// them from its own configuration and hands out a token for the staff member's Premisave sign in (see [consoleSession]).
class C2bRepository {
  C2bRepository(this._api);

  final ServiceClient _api;

  /// Exchanges the service credentials for an access token and its lifetime in seconds.
  Future<(String token, int expiresIn)> generateToken({required String username, required String password}) async {
    final basic = base64.encode(utf8.encode('$username:$password'));
    final res = await _api.post(
      '/oauth2/v1/generate',
      query: <String, dynamic>{'grant_type': 'client_credentials'},
      headers: <String, dynamic>{'Authorization': 'Basic $basic'},
    );
    final m = asMap(res);
    return (strOr(m['access_token']), intOr(m['expires_in'], 3600));
  }

  /// A lookup session for signed in Premisave staff. The service checks the person's own Premisave token, and answers with
  /// the paybill shortcode and an access token made from the username and password in its own application.yml, so
  /// nobody types or sees them. Fails with 403 for a role that is not staff.
  Future<({String shortcode, String token, int expiresIn})> consoleSession(String premisaveAccessToken) async {
    final res = asMap(await _api.get('/console/v1/session', headers: <String, dynamic>{'Authorization': 'Bearer $premisaveAccessToken'}));
    return (shortcode: strOr(res['shortcode']), token: strOr(res['access_token']), expiresIn: intOr(res['expires_in'], 3600));
  }

  /// Looks up the account name for an M-Pesa number.
  Future<NameLookupResult> lookup({required String accountNumber, required String shortcode}) async {
    final now = DateTime.now().toUtc();
    final res = await _api.post('/api/v1/c2b/hakikisha/name-lookup', body: <String, dynamic>{
      'requestId': 'app-${now.millisecondsSinceEpoch}',
      'timestamp': now.toIso8601String(),
      'accountNumber': accountNumber,
      'shortcode': shortcode,
    });
    return NameLookupResult.fromJson(asMap(res));
  }

  /// The wallet accounts the service holds for lookups.
  Future<List<SavedAccount>> savedAccounts({int page = 0, int size = 20}) async {
    final data = unwrapMap(await _api.get('/internal/accounts', query: <String, dynamic>{'page': page, 'size': size}));
    return mapList(data['content']).map(SavedAccount.fromJson).toList();
  }
}
