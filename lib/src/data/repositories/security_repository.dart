import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/security_models.dart';

/// /security endpoints: sessions, devices, sign-in history and events.
class SecurityRepository {
  SecurityRepository(this._api);

  final ApiClient _api;

  String _id(String s) => Uri.encodeComponent(s);

  Future<List<SessionView>> sessions() async =>
      mapList(await _api.get('/security/sessions')).map(SessionView.new).toList();

  Future<CountResult> endSession(String id) async =>
      CountResult(asMap(await _api.delete('/security/sessions/${_id(id)}')));

  Future<CountResult> endOtherSessions() async =>
      CountResult(asMap(await _api.post('/security/sessions/revoke-others')));

  Future<List<DeviceView>> devices() async =>
      mapList(await _api.get('/security/devices')).map(DeviceView.new).toList();

  Future<DeviceDetail> device(String id) async =>
      DeviceDetail(asMap(await _api.get('/security/devices/${_id(id)}')));

  /// Trusting a device needs the account password again.
  Future<DeviceView> trustDevice(String id, String currentPassword) async => DeviceView(
        asMap(await _api.post('/security/devices/${_id(id)}/trust', body: {'currentPassword': currentPassword})),
      );

  Future<DeviceView> revokeTrust(String id) async =>
      DeviceView(asMap(await _api.delete('/security/devices/${_id(id)}/trust')));

  Future<DeviceView> revokeCredential(String id) async =>
      DeviceView(asMap(await _api.post('/security/devices/${_id(id)}/revoke-credential')));

  Future<CountResult> removeDevice(String id) async =>
      CountResult(asMap(await _api.delete('/security/devices/${_id(id)}')));

  Future<List<SignInView>> signIns() async =>
      mapList(await _api.get('/security/sign-ins')).map(SignInView.new).toList();

  Future<List<SecurityEventView>> events() async =>
      mapList(await _api.get('/security/events')).map(SecurityEventView.new).toList();

  /// Administrator audit trail, newest first. Every filter is optional.
  Future<List<SecurityEventView>> adminEvents({
    String? q,
    String? userId,
    String? actor,
    String? type,
    String? severity,
    String? outcome,
    String? ip,
    DateTime? from,
    DateTime? to,
    int page = 0,
    int size = 50,
  }) async {
    String? text(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    final res = await _api.get('/admin/security/events', query: {
      if (text(q) != null) 'q': text(q),
      if (text(userId) != null) 'userId': text(userId),
      if (text(actor) != null) 'actor': text(actor),
      if (text(type) != null) 'type': text(type),
      if (text(severity) != null) 'severity': text(severity),
      if (text(outcome) != null) 'outcome': text(outcome),
      if (text(ip) != null) 'ip': text(ip),
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
      'page': page,
      'size': size,
    });
    return mapList(res).map(SecurityEventView.new).toList();
  }

  /// One audit event with everything recorded about it.
  Future<SecurityEventView> adminEvent(String id) async =>
      SecurityEventView(asMap(await _api.get('/admin/security/events/${_id(id)}')));

  /// Counts for the last [hours] hours.
  Future<AuditSummary> adminSummary({int hours = 24}) async =>
      AuditSummary(asMap(await _api.get('/admin/security/summary', query: {'hours': hours})));
}
