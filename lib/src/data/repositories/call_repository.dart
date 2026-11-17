import '../../core/network/api_client.dart';
import '../models/call_models.dart';
import '../models/json_utils.dart';

/// Every call endpoint of the messenger service. The media itself never goes through here: starting or joining
/// a call returns an address and a token, and the app connects to the media server directly.
class CallRepository {
  CallRepository(this._api);

  final ApiClient _api;

  String _id(String s) => Uri.encodeComponent(s);

  /// Calls the people in a chat. When a call is already running in that chat, joins it instead.
  Future<CallJoinInfo> start(String chatId, CallMedia media) async => CallJoinInfo.fromJson(
        asMap(await _api.post('/api/calls', body: <String, dynamic>{'chatId': chatId, 'type': callMediaApi(media)})),
      );

  /// Answers a ringing call, or joins a running one.
  Future<CallJoinInfo> join(String callId) async => CallJoinInfo.fromJson(asMap(await _api.post('/api/calls/${_id(callId)}/join')));

  Future<void> decline(String callId) => _api.post('/api/calls/${_id(callId)}/decline');

  Future<void> leave(String callId) => _api.post('/api/calls/${_id(callId)}/leave');

  /// A host ends the call for everyone.
  Future<void> end(String callId) => _api.post('/api/calls/${_id(callId)}/end');

  Future<CallInviteOutcome> invite(String callId, List<String> userIds) async => CallInviteOutcome.fromJson(
        asMap(await _api.post('/api/calls/${_id(callId)}/invite', body: <String, dynamic>{'userIds': userIds})),
      );

  Future<void> mute(String callId, String userId) => _api.post('/api/calls/${_id(callId)}/participants/${_id(userId)}/mute');

  Future<void> muteAll(String callId) => _api.post('/api/calls/${_id(callId)}/mute-all');

  Future<void> remove(String callId, String userId) => _api.post('/api/calls/${_id(callId)}/participants/${_id(userId)}/remove');

  Future<void> setRole(String callId, String userId, CallRole role) =>
      _api.post('/api/calls/${_id(callId)}/participants/${_id(userId)}/role', body: <String, dynamic>{'role': callRoleApi(role)});

  Future<void> setLocked(String callId, bool locked) => _api.post('/api/calls/${_id(callId)}/lock', body: <String, dynamic>{'locked': locked});

  // ---------------------------------------------------------------- call chat

  /// The call's chat, oldest first. It is kept after the call, so anyone who was in the call can read it later.
  Future<List<CallChatMsg>> messages(String callId, {int limit = 100}) async => mapList(
        await _api.get('/api/calls/${_id(callId)}/messages', query: <String, dynamic>{'limit': limit}),
      ).map(CallChatMsg.fromJson).toList();

  Future<CallChatMsg> sendMessage(String callId, String text) async =>
      CallChatMsg.fromJson(asMap(await _api.post('/api/calls/${_id(callId)}/messages', body: <String, dynamic>{'text': text})));

  // --------------------------------------------------------------- recording

  /// A host or co-host starts recording the call.
  Future<CallRecording> startRecording(String callId) async =>
      CallRecording.fromJson(asMap(await _api.post('/api/calls/${_id(callId)}/recording/start')));

  Future<CallRecording> stopRecording(String callId) async =>
      CallRecording.fromJson(asMap(await _api.post('/api/calls/${_id(callId)}/recording/stop')));

  /// The recordings of a call, newest first. Empty when recording is switched off.
  Future<List<CallRecording>> recordings(String callId) async =>
      mapList(await _api.get('/api/calls/${_id(callId)}/recordings')).map(CallRecording.fromJson).toList();

  Future<void> deleteRecording(String callId, String recordingId) =>
      _api.delete('/api/calls/${_id(callId)}/recordings/${_id(recordingId)}');

  /// The switches the administrators control (recording on or off).
  Future<CallSettings> settings() async => CallSettings.fromJson(asMap(await _api.get('/api/call-settings')));

  /// Administrators only.
  Future<CallSettings> setRecordingEnabled(bool enabled) async =>
      CallSettings.fromJson(asMap(await _api.put('/api/call-settings/recording', body: <String, dynamic>{'enabled': enabled})));

  // ------------------------------------------------------------------ history

  /// The signed-in person's calls, newest first. [before] is the start time of the last call already shown.
  Future<List<CallInfo>> history({int limit = 40, DateTime? before}) async => mapList(await _api.get(
        '/api/calls',
        query: <String, dynamic>{'limit': limit, if (before != null) 'before': before.toIso8601String()},
      )).map(CallInfo.fromJson).toList();

  /// The call running in a chat right now, or null when there is none.
  Future<CallInfo?> activeInChat(String chatId) async {
    final j = asMap(await _api.get('/api/calls/active', query: <String, dynamic>{'chatId': chatId}));
    if (j['id'] == null) return null;
    return CallInfo.fromJson(j);
  }

  Future<CallInfo> get(String callId) async => CallInfo.fromJson(asMap(await _api.get('/api/calls/${_id(callId)}')));

  Future<void> removeFromHistory(String callId) => _api.delete('/api/calls/${_id(callId)}');

  Future<void> clearHistory() => _api.delete('/api/calls');

  // -------------------------------------------------------------- call links

  /// Makes a call link. Nobody rings. Join it yourself, then share [CallInfo.linkUrl].
  Future<CallInfo> createLink({CallMedia media = CallMedia.video, String? title, int? expiresInHours}) async => CallInfo.fromJson(asMap(await _api.post(
        '/api/calls/links',
        body: <String, dynamic>{
          'type': callMediaApi(media),
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
          if (expiresInHours != null) 'expiresInHours': expiresInHours,
        },
      )));

  Future<CallLinkPreview> previewLink(String code) async => CallLinkPreview.fromJson(asMap(await _api.get('/api/calls/links/${_id(code)}')));

  Future<CallJoinInfo> joinLink(String code) async => CallJoinInfo.fromJson(asMap(await _api.post('/api/calls/links/${_id(code)}/join')));
}
