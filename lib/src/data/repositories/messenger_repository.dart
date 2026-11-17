import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/json_utils.dart';
import '../models/messenger_models.dart';

/// A file chosen on this device, ready to upload. Web gives bytes, mobile and desktop usually give a path.
class LocalFile {
  const LocalFile({required this.name, this.bytes, this.path, this.size = 0});

  final String name;
  final Uint8List? bytes;
  final String? path;
  final int size;

  Future<MultipartFile> toMultipart() async {
    final b = bytes;
    if (b != null) return MultipartFile.fromBytes(b, filename: name);
    final p = path;
    if (p == null) throw ApiException('That file could not be read.');
    return MultipartFile.fromFile(p, filename: name);
  }
}

/// Every messenger-service endpoint the app uses: chats, messages, files, groups, invite links and statuses.
/// It lives on its own address (MESSENGER_URL) and shares the saved sign-in with the auth-service.
class MessengerRepository {
  MessengerRepository(this._api);

  final ApiClient _api;

  String _id(String s) => Uri.encodeComponent(s);

  // ------------------------------------------------------------------ people

  Future<MUser> me() async => MUser.fromJson(asMap(await _api.get('/api/users/me')));

  Future<MUser> user(String userId) async => MUser.fromJson(asMap(await _api.get('/api/users/${_id(userId)}')));

  Future<List<MUser>> users({int page = 0, int size = 50}) async =>
      mapList(await _api.get('/api/users', query: <String, dynamic>{'page': page, 'size': size})).map(MUser.fromJson).toList();

  Future<List<MUser>> searchUsers(String query) async =>
      mapList(await _api.get('/api/users/search', query: <String, dynamic>{'query': query})).map(MUser.fromJson).toList();

  // ------------------------------------------------------------------- chats

  Future<List<MChat>> chats() async => mapList(await _api.get('/api/chats')).map(MChat.fromJson).toList();

  Future<MChat> createPrivateChat(String otherUserId) async =>
      MChat.fromJson(asMap(await _api.post('/api/chats/private', body: <String, dynamic>{'otherUserId': otherUserId})));

  Future<void> deleteChat(String chatId) => _api.delete('/api/chats/${_id(chatId)}');

  Future<void> markChatRead(String chatId) => _api.post('/api/chats/${_id(chatId)}/read');

  Future<void> markChatUnread(String chatId) => _api.post('/api/chats/${_id(chatId)}/unread');

  // ---------------------------------------------------------------- messages

  /// Page 0 is the newest messages. Each page comes newest first.
  Future<List<MMessage>> messages(String chatId, {int page = 0, int size = 40}) async => mapList(await _api.get(
        '/api/messages/chat/${_id(chatId)}',
        query: <String, dynamic>{'page': page, 'size': size},
      )).map(MMessage.fromJson).toList();

  Future<int> editWindowHours() async {
    final j = asMap(await _api.get('/api/messages/settings'));
    return intOr(j['editWindowHours'], 1);
  }

  Future<MMessage> send({
    required String chatId,
    String content = '',
    MType type = MType.text,
    String? attachmentId,
    String? replyToMessageId,
    List<String> mentionedUserIds = const <String>[],
  }) async {
    final body = <String, dynamic>{
      'chatId': chatId,
      'content': content,
      'messageType': mTypeApi(type),
      if (attachmentId != null) 'attachmentId': attachmentId,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (mentionedUserIds.isNotEmpty) 'mentionedUserIds': mentionedUserIds,
    };
    return MMessage.fromJson(asMap(await _api.post('/api/messages', body: body)));
  }

  /// Uploads a file into a chat. Send the result in a message with [send].
  Future<MAttachment> uploadAttachment(String chatId, LocalFile file, {void Function(int sent, int total)? onProgress}) async {
    final form = FormData.fromMap(<String, dynamic>{'chatId': chatId, 'file': await file.toMultipart()});
    return MAttachment.fromJson(asMap(await _api.upload('/api/attachments', form, onProgress: onProgress)));
  }

  Future<MMessage> edit(String messageId, String content, {List<String>? mentionedUserIds}) async => MMessage.fromJson(asMap(await _api.put(
        '/api/messages/${_id(messageId)}',
        body: <String, dynamic>{'content': content, if (mentionedUserIds != null) 'mentionedUserIds': mentionedUserIds},
      )));

  Future<Map<String, List<String>>> react(String messageId, String emoji) async {
    final j = asMap(await _api.put('/api/messages/${_id(messageId)}/reaction', body: <String, dynamic>{'emoji': emoji}));
    return _reactionMap(j['reactions']);
  }

  Future<Map<String, List<String>>> removeReaction(String messageId) async {
    final j = asMap(await _api.delete('/api/messages/${_id(messageId)}/reaction'));
    return _reactionMap(j['reactions']);
  }

  Map<String, List<String>> _reactionMap(Object? v) {
    final out = <String, List<String>>{};
    if (v is Map) {
      v.forEach((k, val) {
        final ids = stringList(val);
        if (ids.isNotEmpty) out[k.toString()] = ids;
      });
    }
    return out;
  }

  Future<void> deleteForEveryone(String messageId) => _api.delete('/api/messages/${_id(messageId)}');

  Future<void> deleteForMe(String messageId) => _api.delete('/api/messages/${_id(messageId)}/me');

  Future<void> markMessageRead(String messageId) => _api.post('/api/messages/read/${_id(messageId)}');

  // ------------------------------------------------------------------ groups

  Future<MGroup> createGroup({required String name, String? description, List<String> memberIds = const <String>[]}) async =>
      MGroup.fromJson(asMap(await _api.post('/api/groups', query: <String, dynamic>{
        'name': name,
        if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
        if (memberIds.isNotEmpty) 'memberIds': memberIds,
      })));

  Future<MGroup> group(String groupId) async => MGroup.fromJson(asMap(await _api.get('/api/groups/${_id(groupId)}')));

  Future<void> addMembers(String groupId, List<String> userIds) => _api.postPlain('/api/groups/${_id(groupId)}/members/bulk', body: userIds);

  Future<void> removeMember(String groupId, String userId) => _api.deletePlain('/api/groups/${_id(groupId)}/members/${_id(userId)}');

  Future<void> addAdmin(String groupId, String userId) =>
      _api.postPlain('/api/groups/${_id(groupId)}/admins', query: <String, dynamic>{'userId': userId});

  Future<void> removeAdmin(String groupId, String userId) => _api.deletePlain('/api/groups/${_id(groupId)}/admins/${_id(userId)}');

  /// Makes someone else the owner. The old owner stays on as an admin.
  Future<void> transferOwnership(String groupId, String newOwnerId) =>
      _api.post('/api/groups/${_id(groupId)}/transfer-admin', query: <String, dynamic>{'newAdminId': newOwnerId});

  /// An owner with other members must name [newOwnerId]: that member takes over as the owner leaves.
  Future<void> leaveGroup(String groupId, {String? newOwnerId}) => _api.postPlain(
        '/api/groups/${_id(groupId)}/leave',
        query: newOwnerId == null ? null : <String, dynamic>{'newOwnerId': newOwnerId},
      );

  Future<void> renameGroup(String groupId, String name) =>
      _api.put('/api/groups/${_id(groupId)}/name', query: <String, dynamic>{'name': name});

  Future<void> setGroupDescription(String groupId, String description) =>
      _api.put('/api/groups/${_id(groupId)}/description', query: <String, dynamic>{'description': description});

  Future<void> setGroupPhoto(String groupId, LocalFile file) async {
    final form = FormData.fromMap(<String, dynamic>{'file': await file.toMultipart()});
    await _api.upload('/api/groups/${_id(groupId)}/photo', form);
  }

  // ----------------------------------------------------------- notifications

  /// Made an admin or the owner, demoted, added to or removed from a group. Newest first.
  Future<List<MNotification>> notifications({int limit = 50}) async =>
      mapList(await _api.get('/api/notifications', query: <String, dynamic>{'limit': limit})).map(MNotification.fromJson).toList();

  Future<int> unreadNotificationCount() async => intOr(asMap(await _api.get('/api/notifications/unread-count'))['count']);

  Future<void> markNotificationRead(String id) => _api.post('/api/notifications/${_id(id)}/read');

  Future<void> markAllNotificationsRead() => _api.post('/api/notifications/read-all');

  Future<void> deleteNotification(String id) => _api.delete('/api/notifications/${_id(id)}');

  Future<void> clearNotifications() => _api.delete('/api/notifications');

  // ------------------------------------------------------------ invite links

  Future<MInvite> createInvite(String groupId, {int? expiresInHours, int? maxUses}) async => MInvite.fromJson(asMap(await _api.post(
        '/api/groups/${_id(groupId)}/invite',
        query: <String, dynamic>{
          if (expiresInHours != null) 'expiresInHours': expiresInHours,
          if (maxUses != null) 'maxUses': maxUses,
        },
      )));

  /// The group's working link, or null when it has none (never made, revoked, expired or used up).
  Future<MInvite?> currentInvite(String groupId) async {
    try {
      return MInvite.fromJson(asMap(await _api.get('/api/groups/${_id(groupId)}/invite')));
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  Future<void> revokeInvite(String groupId) => _api.deletePlain('/api/groups/${_id(groupId)}/invite');

  Future<MInvitePreview> previewInvite(String code) async =>
      MInvitePreview.fromJson(asMap(await _api.get('/api/group-invites/${_id(code)}')));

  Future<MJoinResult> joinWithInvite(String code) async =>
      MJoinResult.fromJson(asMap(await _api.post('/api/group-invites/${_id(code)}/join')));

  // ---------------------------------------------------------------- statuses

  Future<StatusSettings> statusSettings() async => StatusSettings.fromJson(asMap(await _api.get('/api/status/settings')));

  Future<List<StatusGroup>> statusFeed() async => mapList(await _api.get('/api/status/feed')).map(StatusGroup.fromJson).toList();

  Future<List<StatusPost>> myStatuses() async => mapList(await _api.get('/api/status/mine')).map(StatusPost.fromJson).toList();

  Future<StatusPage> myPastStatuses({int page = 0, int size = 20}) async =>
      StatusPage.fromJson(asMap(await _api.get('/api/status/mine/past', query: <String, dynamic>{'page': page, 'size': size})));

  Future<List<StatusPost>> statusesOf(String userId) async =>
      mapList(await _api.get('/api/status/user/${_id(userId)}')).map(StatusPost.fromJson).toList();

  Future<StatusPost> postTextStatus({required String text, String? backgroundColor, int? durationHours}) async =>
      StatusPost.fromJson(asMap(await _api.post('/api/status', body: <String, dynamic>{
        'text': text,
        if (backgroundColor != null) 'backgroundColor': backgroundColor,
        if (durationHours != null) 'durationHours': durationHours,
      })));

  Future<StatusPost> postFileStatus({required LocalFile file, String? caption, int? durationHours, void Function(int sent, int total)? onProgress}) async {
    final form = FormData.fromMap(<String, dynamic>{
      'file': await file.toMultipart(),
      if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
      if (durationHours != null) 'durationHours': durationHours,
    });
    return StatusPost.fromJson(asMap(await _api.upload('/api/status', form, onProgress: onProgress)));
  }

  Future<void> markStatusViewed(String statusId) => _api.post('/api/status/${_id(statusId)}/view');

  Future<StatusPost> likeStatus(String statusId) async => StatusPost.fromJson(asMap(await _api.put('/api/status/${_id(statusId)}/like')));

  Future<StatusPost> unlikeStatus(String statusId) async => StatusPost.fromJson(asMap(await _api.delete('/api/status/${_id(statusId)}/like')));

  Future<StatusPost> reactToStatus(String statusId, String emoji) async =>
      StatusPost.fromJson(asMap(await _api.put('/api/status/${_id(statusId)}/reaction', body: <String, dynamic>{'emoji': emoji})));

  Future<StatusPost> removeStatusReaction(String statusId) async =>
      StatusPost.fromJson(asMap(await _api.delete('/api/status/${_id(statusId)}/reaction')));

  Future<List<StatusComment>> statusComments(String statusId) async =>
      mapList(await _api.get('/api/status/${_id(statusId)}/comments')).map(StatusComment.fromJson).toList();

  Future<StatusComment> commentOnStatus(String statusId, String content) async => StatusComment.fromJson(
      asMap(await _api.post('/api/status/${_id(statusId)}/comments', body: <String, dynamic>{'content': content})));

  Future<void> deleteStatusComment(String statusId, String commentId) =>
      _api.delete('/api/status/${_id(statusId)}/comments/${_id(commentId)}');

  Future<StatusInsights> statusInsights(String statusId) async =>
      StatusInsights.fromJson(asMap(await _api.get('/api/status/${_id(statusId)}/insights')));

  Future<void> deleteStatus(String statusId) => _api.delete('/api/status/${_id(statusId)}');
}
