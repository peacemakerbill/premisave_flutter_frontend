import 'json_utils.dart';

// Plain Dart objects for the messenger service. Every reader is forgiving, so a missing field never crashes a screen.

/// The server sends times without a zone (LocalDateTime). They are read as local time, the same as the web test client.
DateTime? _when(Object? v) {
  if (v == null) return null;
  if (v is List && v.length >= 3) {
    int at(int i) => i < v.length && v[i] is num ? (v[i] as num).toInt() : 0;
    return DateTime(at(0), at(1), at(2), at(3), at(4), at(5));
  }
  return DateTime.tryParse(v.toString());
}

Map<String, List<String>> _reactions(Object? v) {
  final out = <String, List<String>>{};
  if (v is Map) {
    v.forEach((k, val) {
      final ids = stringList(val);
      if (ids.isNotEmpty) out[k.toString()] = ids;
    });
  }
  return out;
}

// ------------------------------------------------------------------ people

/// A person as the messenger service describes them.
class MUser {
  const MUser({
    required this.id,
    this.displayName = '',
    this.firstName = '',
    this.lastName = '',
    this.username = '',
    this.email = '',
    this.profilePictureUrl,
    this.online = false,
    this.lastSeen,
  });

  final String id;
  final String displayName;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? profilePictureUrl;
  final bool online;
  final DateTime? lastSeen;

  factory MUser.fromJson(Map<String, dynamic> j) => MUser(
        id: strOr(j['id'] ?? j['userId']),
        displayName: strOr(j['displayName']),
        firstName: strOr(j['firstName']),
        lastName: strOr(j['lastName']),
        username: strOr(j['username']),
        email: strOr(j['email']),
        profilePictureUrl: str(j['profilePictureUrl'] ?? j['profilePicture']),
        online: boolOr(j['online'] ?? j['isOnline']),
        lastSeen: _when(j['lastSeen']),
      );

  /// First and last name when the profile has them, then the display name, then the username.
  String get name {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) return full;
    if (displayName.isNotEmpty && displayName != 'Unknown User') return displayName;
    if (username.isNotEmpty && username != 'Unknown' && !username.contains('@')) return username;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Premisave member';
  }

  String get initials {
    final bits = name.trim().split(RegExp(r'\s+')).where((b) => b.isNotEmpty).toList();
    if (bits.isEmpty) return 'P';
    if (bits.length == 1) return bits.first[0].toUpperCase();
    return (bits.first[0] + bits[1][0]).toUpperCase();
  }
}

// ---------------------------------------------------------------- messages

enum MType { text, image, video, voice, document, other }

MType mTypeOf(Object? v) {
  switch (strOr(v).toUpperCase()) {
    case 'TEXT':
      return MType.text;
    case 'IMAGE':
      return MType.image;
    case 'VIDEO':
      return MType.video;
    case 'VOICE':
    case 'AUDIO':
      return MType.voice;
    case 'DOCUMENT':
    case 'FILE':
      return MType.document;
    default:
      return MType.other;
  }
}

String mTypeApi(MType t) {
  switch (t) {
    case MType.text:
      return 'TEXT';
    case MType.image:
      return 'IMAGE';
    case MType.video:
      return 'VIDEO';
    case MType.voice:
      return 'VOICE';
    case MType.document:
      return 'DOCUMENT';
    case MType.other:
      return 'TEXT';
  }
}

/// Delivery state of a message. [sending] and [failed] are local: the server only knows the rest.
enum MDelivery { sending, sent, delivered, read, failed }

MDelivery mStatusOf(Object? v) {
  switch (strOr(v).toUpperCase()) {
    case 'SENDING':
      return MDelivery.sending;
    case 'DELIVERED':
      return MDelivery.delivered;
    case 'READ':
      return MDelivery.read;
    case 'FAILED':
      return MDelivery.failed;
    default:
      return MDelivery.sent;
  }
}

class MReply {
  const MReply({
    required this.messageId,
    this.senderId = '',
    this.senderName = '',
    this.content = '',
    this.type = MType.text,
    this.mediaUrl,
  });

  final String messageId;
  final String senderId;
  final String senderName;
  final String content;
  final MType type;
  final String? mediaUrl;

  factory MReply.fromJson(Map<String, dynamic> j) => MReply(
        messageId: strOr(j['messageId'] ?? j['id']),
        senderId: strOr(j['senderId']),
        senderName: strOr(j['senderName']),
        content: strOr(j['content']),
        type: mTypeOf(j['messageType']),
        mediaUrl: str(j['mediaUrl']),
      );
}

class MMessage {
  const MMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName = '',
    this.senderProfilePic,
    this.type = MType.text,
    this.content = '',
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.attachmentId,
    this.status = MDelivery.sent,
    this.readBy = const <String>[],
    required this.createdAt,
    this.editedAt,
    this.editableUntil,
    this.deleted = false,
    this.deletedForEveryone = false,
    this.mentionedUserIds = const <String>[],
    this.mentionAll = false,
    this.reactions = const <String, List<String>>{},
    this.replyToMessageId,
    this.reply,
    this.localId,
    this.progress,
  });

  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderProfilePic;
  final MType type;
  final String content;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final String? attachmentId;
  final MDelivery status;
  final List<String> readBy;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? editableUntil;
  final bool deleted;
  final bool deletedForEveryone;
  final List<String> mentionedUserIds;

  /// True when the text tags everyone with @all (groups only).
  final bool mentionAll;
  final Map<String, List<String>> reactions;
  final String? replyToMessageId;
  final MReply? reply;

  /// Set on messages still being sent from this device. The id changes when the server answers.
  final String? localId;

  /// Upload progress from 0 to 1 while a file is on its way.
  final double? progress;

  factory MMessage.fromJson(Map<String, dynamic> j) {
    final reply = j['replyPreview'];
    return MMessage(
      id: strOr(j['id']),
      chatId: strOr(j['chatId']),
      senderId: strOr(j['senderId']),
      senderName: strOr(j['senderName']),
      senderProfilePic: str(j['senderProfilePic']),
      type: mTypeOf(j['messageType']),
      content: strOr(j['content']),
      mediaUrl: str(j['mediaUrl']),
      fileName: str(j['fileName']),
      fileSize: intOrNull(j['fileSize']),
      mimeType: str(j['mimeType']),
      attachmentId: str(j['attachmentId']),
      status: mStatusOf(j['status']),
      readBy: stringList(j['readBy']),
      createdAt: _when(j['createdAt'] ?? j['timestamp']) ?? DateTime.now(),
      editedAt: _when(j['editedAt']),
      editableUntil: _when(j['editableUntil']),
      deleted: boolOr(j['deleted'] ?? j['isDeleted']),
      deletedForEveryone: boolOr(j['deletedForEveryone'] ?? j['isDeletedForEveryone']),
      mentionedUserIds: stringList(j['mentionedUserIds']),
      mentionAll: boolOr(j['mentionAll']),
      reactions: _reactions(j['reactions']),
      replyToMessageId: str(j['replyToMessageId']),
      reply: reply is Map ? MReply.fromJson(asMap(reply)) : null,
    );
  }

  MMessage copyWith({
    String? id,
    String? content,
    String? mediaUrl,
    MDelivery? status,
    List<String>? readBy,
    DateTime? editedAt,
    DateTime? editableUntil,
    bool? deleted,
    bool? deletedForEveryone,
    List<String>? mentionedUserIds,
    bool? mentionAll,
    Map<String, List<String>>? reactions,
    double? progress,
    bool clearProgress = false,
    String? attachmentId,
  }) =>
      MMessage(
        id: id ?? this.id,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        type: type,
        content: content ?? this.content,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        attachmentId: attachmentId ?? this.attachmentId,
        status: status ?? this.status,
        readBy: readBy ?? this.readBy,
        createdAt: createdAt,
        editedAt: editedAt ?? this.editedAt,
        editableUntil: editableUntil ?? this.editableUntil,
        deleted: deleted ?? this.deleted,
        deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
        mentionedUserIds: mentionedUserIds ?? this.mentionedUserIds,
        mentionAll: mentionAll ?? this.mentionAll,
        reactions: reactions ?? this.reactions,
        replyToMessageId: replyToMessageId,
        reply: reply,
        localId: localId,
        progress: clearProgress ? null : (progress ?? this.progress),
      );

  /// The same message with a local sending placeholder's identity, for the optimistic copy.
  MMessage asLocal(String localKey) => MMessage(
        id: localKey,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        senderProfilePic: senderProfilePic,
        type: type,
        content: content,
        mediaUrl: mediaUrl,
        fileName: fileName,
        fileSize: fileSize,
        mimeType: mimeType,
        attachmentId: attachmentId,
        status: MDelivery.sending,
        readBy: readBy,
        createdAt: createdAt,
        mentionedUserIds: mentionedUserIds,
        mentionAll: mentionAll,
        replyToMessageId: replyToMessageId,
        reply: reply,
        localId: localKey,
        progress: type == MType.text ? null : 0,
      );

  bool get hasFile => type != MType.text && type != MType.other;
  bool get isPending => localId != null && (status == MDelivery.sending || status == MDelivery.failed);

  /// Everyone's reaction count for one emoji.
  int reactionCount(String emoji) => reactions[emoji]?.length ?? 0;

  /// The emoji this person reacted with, or null.
  String? reactionOf(String userId) {
    for (final e in reactions.entries) {
      if (e.value.contains(userId)) return e.key;
    }
    return null;
  }
}

// ------------------------------------------------------------------- chats

class MChat {
  const MChat({
    required this.id,
    this.isGroup = false,
    this.participantIds = const <String>[],
    this.groupId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.markedUnread = false,
    this.online = false,
    this.groupName = '',
    this.groupPhotoUrl,
    this.adminId,
    this.memberCount = 0,
    this.lastSeen,
    this.otherUser,
    this.newlyCreated = false,
  });

  final String id;
  final bool isGroup;
  final List<String> participantIds;
  final String? groupId;
  final MMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool markedUnread;
  final bool online;
  final String groupName;
  final String? groupPhotoUrl;
  final String? adminId;
  final int memberCount;
  final DateTime? lastSeen;
  final MUser? otherUser;
  final bool newlyCreated;

  factory MChat.fromJson(Map<String, dynamic> j) {
    final last = j['lastMessage'];
    final other = j['otherUser'];
    return MChat(
      id: strOr(j['id'] ?? j['chatId']),
      isGroup: strOr(j['chatType']).toUpperCase() == 'GROUP',
      participantIds: stringList(j['participantIds']),
      groupId: str(j['groupId']),
      lastMessage: last is Map ? MMessage.fromJson(asMap(last)) : null,
      lastMessageAt: _when(j['lastMessageAt']),
      unreadCount: intOr(j['unreadCount']),
      markedUnread: boolOr(j['markedUnread']),
      online: boolOr(j['online'] ?? j['isOnline']),
      groupName: strOr(j['groupName']),
      groupPhotoUrl: str(j['groupPhotoUrl']),
      adminId: str(j['adminId']),
      memberCount: intOr(j['memberCount']),
      lastSeen: _when(j['lastSeen']),
      otherUser: other is Map ? MUser.fromJson(asMap(other)) : null,
      newlyCreated: boolOr(j['newlyCreated']),
    );
  }

  MChat copyWith({
    MMessage? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? markedUnread,
    String? groupName,
    String? groupPhotoUrl,
    int? memberCount,
    String? adminId,
  }) =>
      MChat(
        id: id,
        isGroup: isGroup,
        participantIds: participantIds,
        groupId: groupId,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageAt: lastMessageAt ?? this.lastMessageAt,
        unreadCount: unreadCount ?? this.unreadCount,
        markedUnread: markedUnread ?? this.markedUnread,
        online: online,
        groupName: groupName ?? this.groupName,
        groupPhotoUrl: groupPhotoUrl ?? this.groupPhotoUrl,
        adminId: adminId ?? this.adminId,
        memberCount: memberCount ?? this.memberCount,
        lastSeen: lastSeen,
        otherUser: otherUser,
        newlyCreated: newlyCreated,
      );

  String get title => isGroup ? (groupName.isEmpty ? 'Group' : groupName) : (otherUser?.name ?? 'Premisave member');
  String? get photo => isGroup ? groupPhotoUrl : otherUser?.profilePictureUrl;
  String get initials {
    if (!isGroup) return otherUser?.initials ?? 'P';
    final t = title.trim();
    return t.isEmpty ? 'G' : t[0].toUpperCase();
  }

  /// The other person in a private chat.
  String? otherId(String? myId) {
    if (isGroup) return null;
    final o = otherUser?.id;
    if (o != null && o.isNotEmpty) return o;
    for (final id in participantIds) {
      if (id != myId) return id;
    }
    return null;
  }

  bool get hasUnread => unreadCount > 0 || markedUnread;
  DateTime? get sortTime => lastMessage?.createdAt ?? lastMessageAt;
}

// ------------------------------------------------------------------ groups

class MGroupMember {
  const MGroupMember({
    required this.id,
    this.displayName = '',
    this.username = '',
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.profilePictureUrl,
    this.role = 'MEMBER',
  });

  final String id;
  final String displayName;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;

  /// OWNER, ADMIN or MEMBER.
  final String role;

  factory MGroupMember.fromJson(Map<String, dynamic> j) => MGroupMember(
        id: strOr(j['id']),
        displayName: strOr(j['displayName']),
        username: strOr(j['username']),
        email: strOr(j['email']),
        firstName: strOr(j['firstName']),
        lastName: strOr(j['lastName']),
        profilePictureUrl: str(j['profilePictureUrl']),
        role: strOr(j['role'], 'MEMBER').toUpperCase(),
      );

  MUser get user => MUser(
        id: id,
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        profilePictureUrl: profilePictureUrl,
      );

  String get name => user.name;
  bool get isOwner => role == 'OWNER';
  bool get isAdmin => role == 'ADMIN';
}

class MGroup {
  const MGroup({
    required this.id,
    this.chatId,
    this.name = '',
    this.description = '',
    this.groupPhotoUrl,
    this.adminId = '',
    this.moderators = const <String>[],
    this.memberIds = const <String>[],
    this.createdAt,
    this.members = const <MGroupMember>[],
  });

  final String id;
  final String? chatId;
  final String name;
  final String description;
  final String? groupPhotoUrl;
  final String adminId;
  final List<String> moderators;
  final List<String> memberIds;
  final DateTime? createdAt;
  final List<MGroupMember> members;

  factory MGroup.fromJson(Map<String, dynamic> j) => MGroup(
        id: strOr(j['id']),
        chatId: str(j['chatId']),
        name: strOr(j['name']),
        description: strOr(j['description']),
        groupPhotoUrl: str(j['groupPhotoUrl']),
        adminId: strOr(j['adminId']),
        moderators: stringList(j['moderators']),
        memberIds: stringList(j['memberIds']),
        createdAt: _when(j['createdAt']),
        members: mapList(j['members']).map(MGroupMember.fromJson).toList(),
      );

  bool isOwner(String? userId) => userId != null && userId == adminId;
  bool isAdmin(String? userId) => userId != null && (userId == adminId || moderators.contains(userId));

  /// Owner first, then admins, then members, each sorted by name.
  List<MGroupMember> get sortedMembers {
    int rank(MGroupMember m) => m.isOwner ? 0 : (m.isAdmin ? 1 : 2);
    final list = List<MGroupMember>.of(members);
    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }
}

class MInvite {
  const MInvite({
    required this.groupId,
    required this.code,
    required this.link,
    this.expiresAt,
    this.maxUses,
    this.uses = 0,
  });

  final String groupId;
  final String code;
  final String link;
  final DateTime? expiresAt;
  final int? maxUses;
  final int uses;

  factory MInvite.fromJson(Map<String, dynamic> j) => MInvite(
        groupId: strOr(j['groupId']),
        code: strOr(j['code']),
        link: strOr(j['link']),
        expiresAt: _when(j['expiresAt']),
        maxUses: intOrNull(j['maxUses']),
        uses: intOr(j['uses']),
      );
}

class MInvitePreview {
  const MInvitePreview({
    required this.groupId,
    this.name = '',
    this.description = '',
    this.groupPhotoUrl,
    this.memberCount = 0,
    this.alreadyMember = false,
    this.chatId,
    this.expiresAt,
  });

  final String groupId;
  final String name;
  final String description;
  final String? groupPhotoUrl;
  final int memberCount;
  final bool alreadyMember;
  final String? chatId;
  final DateTime? expiresAt;

  factory MInvitePreview.fromJson(Map<String, dynamic> j) => MInvitePreview(
        groupId: strOr(j['groupId']),
        name: strOr(j['name'], 'Group'),
        description: strOr(j['description']),
        groupPhotoUrl: str(j['groupPhotoUrl']),
        memberCount: intOr(j['memberCount']),
        alreadyMember: boolOr(j['alreadyMember']),
        chatId: str(j['chatId']),
        expiresAt: _when(j['expiresAt']),
      );
}

class MJoinResult {
  const MJoinResult({required this.groupId, required this.chatId, this.name = '', this.alreadyMember = false});

  final String groupId;
  final String chatId;
  final String name;
  final bool alreadyMember;

  factory MJoinResult.fromJson(Map<String, dynamic> j) => MJoinResult(
        groupId: strOr(j['groupId']),
        chatId: strOr(j['chatId']),
        name: strOr(j['name']),
        alreadyMember: boolOr(j['alreadyMember']),
      );
}

class MAttachment {
  const MAttachment({required this.id, this.fileName = '', this.mimeType = '', this.size = 0, this.type = MType.document});

  final String id;
  final String fileName;
  final String mimeType;
  final int size;
  final MType type;

  factory MAttachment.fromJson(Map<String, dynamic> j) => MAttachment(
        id: strOr(j['attachmentId'] ?? j['id']),
        fileName: strOr(j['fileName']),
        mimeType: strOr(j['mimeType']),
        size: intOr(j['size']),
        type: mTypeOf(j['messageType']),
      );
}

// ---------------------------------------------------------------- statuses

enum StatusKind { text, image, video, audio }

StatusKind statusKindOf(Object? v) {
  switch (strOr(v).toUpperCase()) {
    case 'IMAGE':
      return StatusKind.image;
    case 'VIDEO':
      return StatusKind.video;
    case 'AUDIO':
      return StatusKind.audio;
    default:
      return StatusKind.text;
  }
}

class StatusStats {
  const StatusStats({this.views = 0, this.likes = 0, this.reactions = 0, this.comments = 0});

  final int views;
  final int likes;
  final int reactions;
  final int comments;

  factory StatusStats.fromJson(Map<String, dynamic> j) => StatusStats(
        views: intOr(j['views']),
        likes: intOr(j['likes']),
        reactions: intOr(j['reactions']),
        comments: intOr(j['comments']),
      );
}

class StatusPost {
  const StatusPost({
    required this.id,
    required this.ownerId,
    this.owner,
    this.kind = StatusKind.text,
    this.text = '',
    this.backgroundColor,
    this.caption = '',
    this.mediaUrl,
    this.fileName,
    this.mimeType,
    this.durationHours = 24,
    this.createdAt,
    this.expiresAt,
    this.active = true,
    this.mine = false,
    this.viewedByMe = false,
    this.likedByMe = false,
    this.myReaction,
    this.stats = const StatusStats(),
  });

  final String id;
  final String ownerId;
  final MUser? owner;
  final StatusKind kind;
  final String text;
  final String? backgroundColor;
  final String caption;
  final String? mediaUrl;
  final String? fileName;
  final String? mimeType;
  final int durationHours;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final bool active;
  final bool mine;
  final bool viewedByMe;
  final bool likedByMe;
  final String? myReaction;
  final StatusStats stats;

  factory StatusPost.fromJson(Map<String, dynamic> j) {
    final owner = j['owner'];
    final stats = j['stats'];
    return StatusPost(
      id: strOr(j['id']),
      ownerId: strOr(j['ownerId']),
      owner: owner is Map ? MUser.fromJson(asMap(owner)) : null,
      kind: statusKindOf(j['type']),
      text: strOr(j['text']),
      backgroundColor: str(j['backgroundColor']),
      caption: strOr(j['caption']),
      mediaUrl: str(j['mediaUrl']),
      fileName: str(j['fileName']),
      mimeType: str(j['mimeType']),
      durationHours: intOr(j['durationHours'], 24),
      createdAt: _when(j['createdAt']),
      expiresAt: _when(j['expiresAt']),
      active: boolOr(j['active'], true),
      mine: boolOr(j['mine']),
      viewedByMe: boolOr(j['viewedByMe']),
      likedByMe: boolOr(j['likedByMe']),
      myReaction: str(j['myReaction']),
      stats: stats is Map ? StatusStats.fromJson(asMap(stats)) : const StatusStats(),
    );
  }

  StatusPost copyWith({bool? viewedByMe, bool? likedByMe, String? myReaction, bool clearReaction = false, StatusStats? stats}) => StatusPost(
        id: id,
        ownerId: ownerId,
        owner: owner,
        kind: kind,
        text: text,
        backgroundColor: backgroundColor,
        caption: caption,
        mediaUrl: mediaUrl,
        fileName: fileName,
        mimeType: mimeType,
        durationHours: durationHours,
        createdAt: createdAt,
        expiresAt: expiresAt,
        active: active,
        mine: mine,
        viewedByMe: viewedByMe ?? this.viewedByMe,
        likedByMe: likedByMe ?? this.likedByMe,
        myReaction: clearReaction ? null : (myReaction ?? this.myReaction),
        stats: stats ?? this.stats,
      );
}

/// One person's current statuses, as the feed groups them.
class StatusGroup {
  const StatusGroup({required this.user, required this.statuses, this.unseenCount = 0, this.latestAt});

  final MUser user;
  final List<StatusPost> statuses;
  final int unseenCount;
  final DateTime? latestAt;

  factory StatusGroup.fromJson(Map<String, dynamic> j) => StatusGroup(
        user: MUser.fromJson(asMap(j['user'])),
        statuses: mapList(j['statuses']).map(StatusPost.fromJson).toList(),
        unseenCount: intOr(j['unseenCount']),
        latestAt: _when(j['latestAt']),
      );
}

class StatusPage {
  const StatusPage({this.items = const <StatusPost>[], this.page = 0, this.hasMore = false});

  final List<StatusPost> items;
  final int page;
  final bool hasMore;

  factory StatusPage.fromJson(Map<String, dynamic> j) => StatusPage(
        items: mapList(j['items']).map(StatusPost.fromJson).toList(),
        page: intOr(j['page']),
        hasMore: boolOr(j['hasMore']),
      );
}

class StatusComment {
  const StatusComment({required this.id, required this.statusId, this.author, this.content = '', this.createdAt, this.mine = false, this.canDelete = false});

  final String id;
  final String statusId;
  final MUser? author;
  final String content;
  final DateTime? createdAt;
  final bool mine;
  final bool canDelete;

  factory StatusComment.fromJson(Map<String, dynamic> j) {
    final a = j['author'];
    return StatusComment(
      id: strOr(j['id']),
      statusId: strOr(j['statusId']),
      author: a is Map ? MUser.fromJson(asMap(a)) : null,
      content: strOr(j['content']),
      createdAt: _when(j['createdAt']),
      mine: boolOr(j['mine']),
      canDelete: boolOr(j['canDelete']),
    );
  }
}

class StatusPerson {
  const StatusPerson({required this.user, this.emoji, this.at});

  final MUser user;
  final String? emoji;
  final DateTime? at;

  factory StatusPerson.fromJson(Map<String, dynamic> j) =>
      StatusPerson(user: MUser.fromJson(asMap(j['user'])), emoji: str(j['emoji']), at: _when(j['at']));
}

class StatusInsights {
  const StatusInsights({
    required this.status,
    this.viewers = const <StatusPerson>[],
    this.likers = const <StatusPerson>[],
    this.reactors = const <StatusPerson>[],
    this.comments = const <StatusComment>[],
  });

  final StatusPost status;
  final List<StatusPerson> viewers;
  final List<StatusPerson> likers;
  final List<StatusPerson> reactors;
  final List<StatusComment> comments;

  factory StatusInsights.fromJson(Map<String, dynamic> j) => StatusInsights(
        status: StatusPost.fromJson(asMap(j['status'])),
        viewers: mapList(j['viewers']).map(StatusPerson.fromJson).toList(),
        likers: mapList(j['likers']).map(StatusPerson.fromJson).toList(),
        reactors: mapList(j['reactors']).map(StatusPerson.fromJson).toList(),
        comments: mapList(j['comments']).map(StatusComment.fromJson).toList(),
      );
}

class StatusSettings {
  const StatusSettings({this.maxHours = 24, this.defaultHours = 24, this.textMaxLength = 700, this.commentMaxLength = 300});

  final int maxHours;
  final int defaultHours;
  final int textMaxLength;
  final int commentMaxLength;

  factory StatusSettings.fromJson(Map<String, dynamic> j) => StatusSettings(
        maxHours: intOr(j['maxHours'], 24),
        defaultHours: intOr(j['defaultHours'], 24),
        textMaxLength: intOr(j['textMaxLength'], 700),
        commentMaxLength: intOr(j['commentMaxLength'], 300),
      );
}


/// Something that happened to the signed-in person in a group: made an admin or the owner, demoted, added, removed.
class MNotification {
  const MNotification({
    required this.id,
    this.type = '',
    this.title = '',
    this.body = '',
    this.groupId,
    this.chatId,
    this.actorId,
    this.actorName = '',
    this.createdAt,
    this.read = false,
  });

  final String id;

  /// MADE_ADMIN, REMOVED_ADMIN, BECAME_OWNER, ADDED_TO_GROUP, REMOVED_FROM_GROUP, MENTIONED or MENTIONED_ALL.
  final String type;
  final String title;
  final String body;
  final String? groupId;

  /// The group's chat. Null when the person can no longer open it.
  final String? chatId;
  final String? actorId;
  final String actorName;
  final DateTime? createdAt;
  final bool read;

  bool get unread => !read;

  /// True when there is a group chat the person can still open from this notification.
  bool get canOpenChat => chatId != null && chatId!.isNotEmpty && type != 'REMOVED_FROM_GROUP';

  MNotification copyWith({bool? read}) => MNotification(
        id: id,
        type: type,
        title: title,
        body: body,
        groupId: groupId,
        chatId: chatId,
        actorId: actorId,
        actorName: actorName,
        createdAt: createdAt,
        read: read ?? this.read,
      );

  factory MNotification.fromJson(Map<String, dynamic> j) => MNotification(
        id: strOr(j['id']),
        type: strOr(j['type']).toUpperCase(),
        title: strOr(j['title']),
        body: strOr(j['body']),
        groupId: str(j['groupId']),
        chatId: str(j['chatId']),
        actorId: str(j['actorId']),
        actorName: strOr(j['actorName']),
        createdAt: _when(j['createdAt']),
        read: boolOr(j['read']),
      );
}
