import 'json_utils.dart';

// Plain Dart objects for audio and video calls. Like the other models, every reader is forgiving.

/// The server sends times without a zone (LocalDateTime). They are read as local time.
DateTime? _when(Object? v) {
  if (v == null) return null;
  if (v is List && v.length >= 3) {
    int at(int i) => i < v.length && v[i] is num ? (v[i] as num).toInt() : 0;
    return DateTime(at(0), at(1), at(2), at(3), at(4), at(5));
  }
  return DateTime.tryParse(v.toString());
}

/// What a call was started as. Anyone can turn their camera on or off during the call either way.
enum CallMedia { audio, video }

CallMedia callMediaOf(Object? v) => strOr(v).toUpperCase() == 'AUDIO' ? CallMedia.audio : CallMedia.video;

String callMediaApi(CallMedia m) => m == CallMedia.audio ? 'AUDIO' : 'VIDEO';

enum CallStatus { ringing, active, waiting, ended, missed, declined, cancelled }

CallStatus callStatusOf(Object? v) {
  switch (strOr(v).toUpperCase()) {
    case 'RINGING':
      return CallStatus.ringing;
    case 'ACTIVE':
      return CallStatus.active;
    case 'WAITING':
      return CallStatus.waiting;
    case 'MISSED':
      return CallStatus.missed;
    case 'DECLINED':
      return CallStatus.declined;
    case 'CANCELLED':
      return CallStatus.cancelled;
    default:
      return CallStatus.ended;
  }
}

enum CallKind { private, group, link }

CallKind callKindOf(Object? v) {
  switch (strOr(v).toUpperCase()) {
    case 'GROUP':
      return CallKind.group;
    case 'LINK':
      return CallKind.link;
    default:
      return CallKind.private;
  }
}

enum PersonState { invited, joined, left, declined, missed, removed }

PersonState personStateOf(Object? v) {
  switch (strOr(v).toUpperCase()) {
    case 'INVITED':
      return PersonState.invited;
    case 'JOINED':
      return PersonState.joined;
    case 'DECLINED':
      return PersonState.declined;
    case 'MISSED':
      return PersonState.missed;
    case 'REMOVED':
      return PersonState.removed;
    default:
      return PersonState.left;
  }
}

enum CallRole { host, cohost, member }

CallRole callRoleOf(Object? v) {
  switch (strOr(v).toUpperCase()) {
    case 'HOST':
      return CallRole.host;
    case 'COHOST':
      return CallRole.cohost;
    default:
      return CallRole.member;
  }
}

String callRoleApi(CallRole r) {
  switch (r) {
    case CallRole.host:
      return 'HOST';
    case CallRole.cohost:
      return 'COHOST';
    case CallRole.member:
      return 'MEMBER';
  }
}

/// One person in a call, as the server lists them.
class CallPerson {
  const CallPerson({
    required this.userId,
    this.name = '',
    this.picture,
    this.state = PersonState.left,
    this.role = CallRole.member,
    this.joinedAt,
    this.leftAt,
  });

  final String userId;
  final String name;
  final String? picture;
  final PersonState state;
  final CallRole role;
  final DateTime? joinedAt;
  final DateTime? leftAt;

  bool get isHost => role == CallRole.host || role == CallRole.cohost;

  factory CallPerson.fromJson(Map<String, dynamic> j) => CallPerson(
        userId: strOr(j['userId']),
        name: strOr(j['displayName']),
        picture: str(j['profilePictureUrl']),
        state: personStateOf(j['state']),
        role: callRoleOf(j['role']),
        joinedAt: _when(j['joinedAt']),
        leftAt: _when(j['leftAt']),
      );

  String get initials {
    final bits = name.trim().split(RegExp(r'\s+')).where((b) => b.isNotEmpty).toList();
    if (bits.isEmpty) return 'P';
    if (bits.length == 1) return bits.first[0].toUpperCase();
    return (bits.first[0] + bits[1][0]).toUpperCase();
  }
}

/// A call: who is in it, how it stands and how it ended. The server sends the whole thing with every change.
class CallInfo {
  const CallInfo({
    required this.id,
    this.kind = CallKind.private,
    this.media = CallMedia.video,
    this.status = CallStatus.ended,
    this.chatId,
    this.groupId,
    this.title,
    this.initiatorId = '',
    this.initiatorName = '',
    this.locked = false,
    this.maxParticipants = 0,
    this.linkUrl,
    this.linkExpiresAt,
    this.createdAt,
    this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.endReason,
    this.recordingEnabled = false,
    this.recording = false,
    this.recordingCount = 0,
    this.people = const <CallPerson>[],
  });

  final String id;
  final CallKind kind;
  final CallMedia media;
  final CallStatus status;
  final String? chatId;
  final String? groupId;
  final String? title;
  final String initiatorId;
  final String initiatorName;
  final bool locked;
  final int maxParticipants;

  /// The shareable link, for a call link that is still open.
  final String? linkUrl;
  final DateTime? linkExpiresAt;
  final DateTime? createdAt;

  /// When the second person joined. Null until then.
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String? endReason;

  /// Whether the administrators switched recording on. When false the app shows no recording controls at all.
  final bool recordingEnabled;

  /// A recording is starting or running in this call right now.
  final bool recording;

  /// How many finished recordings this call has.
  final int recordingCount;
  final List<CallPerson> people;

  factory CallInfo.fromJson(Map<String, dynamic> j) => CallInfo(
        id: strOr(j['id']),
        kind: callKindOf(j['kind']),
        media: callMediaOf(j['type']),
        status: callStatusOf(j['status']),
        chatId: str(j['chatId']),
        groupId: str(j['groupId']),
        title: str(j['title']),
        initiatorId: strOr(j['initiatorId']),
        initiatorName: strOr(j['initiatorName']),
        locked: boolOr(j['locked']),
        maxParticipants: intOr(j['maxParticipants']),
        linkUrl: str(j['linkUrl']),
        linkExpiresAt: _when(j['linkExpiresAt']),
        createdAt: _when(j['createdAt']),
        startedAt: _when(j['startedAt']),
        endedAt: _when(j['endedAt']),
        durationSeconds: intOr(j['durationSeconds']),
        endReason: str(j['endReason']),
        recordingEnabled: boolOr(j['recordingEnabled']),
        recording: boolOr(j['recording']),
        recordingCount: intOr(j['recordingCount']),
        people: mapList(j['participants']).map(CallPerson.fromJson).toList(),
      );

  bool get isOpen => status == CallStatus.ringing || status == CallStatus.active || status == CallStatus.waiting;
  bool get isVideo => media == CallMedia.video;
  bool get isGroupLike => kind != CallKind.private || people.length > 2;

  CallPerson? person(String? userId) {
    if (userId == null) return null;
    for (final p in people) {
      if (p.userId == userId) return p;
    }
    return null;
  }

  PersonState? stateOf(String? userId) => person(userId)?.state;
  CallRole roleOf(String? userId) => person(userId)?.role ?? CallRole.member;
  bool isManager(String? userId) => roleOf(userId) != CallRole.member && stateOf(userId) == PersonState.joined;

  List<CallPerson> get joined => people.where((p) => p.state == PersonState.joined).toList();
  List<CallPerson> get ringing => people.where((p) => p.state == PersonState.invited).toList();

  /// Everyone except this person who has been invited or is in the call: the people this person can see.
  List<CallPerson> others(String? me) => people.where((p) => p.userId != me && p.state != PersonState.removed).toList();

  /// The name to show for the call in a list: the other person, the group, or the link's title.
  String titleFor(String? me, {String? groupName}) {
    if (kind == CallKind.link) return (title ?? '').isNotEmpty ? title! : 'Call link';
    if (kind == CallKind.group) return (groupName ?? '').isNotEmpty ? groupName! : ((title ?? '').isNotEmpty ? title! : 'Group call');
    for (final p in people) {
      if (p.userId != me && p.name.isNotEmpty) return p.name;
    }
    return initiatorName.isNotEmpty ? initiatorName : 'Premisave member';
  }

  /// The person whose picture stands for the call in a list.
  CallPerson? headPerson(String? me) {
    for (final p in people) {
      if (p.userId != me) return p;
    }
    return people.isEmpty ? null : people.first;
  }
}

/// What starting or joining a call returns: the call, the media server address and this person's join token.
class CallJoinInfo {
  const CallJoinInfo({required this.call, this.url, this.token, this.identity = '', this.role = CallRole.member, this.reason});

  final CallInfo call;
  final String? url;
  final String? token;
  final String identity;
  final CallRole role;

  /// Set instead of a token when the call could not start, for example BUSY.
  final String? reason;

  bool get canConnect => (token ?? '').isNotEmpty && (url ?? '').isNotEmpty;

  factory CallJoinInfo.fromJson(Map<String, dynamic> j) => CallJoinInfo(
        call: CallInfo.fromJson(asMap(j['call'])),
        url: str(j['url']),
        token: str(j['token']),
        identity: strOr(j['identity']),
        role: callRoleOf(j['role']),
        reason: str(j['reason']),
      );
}

/// A message written in a call's own chat.
class CallChatMsg {
  const CallChatMsg({required this.id, required this.callId, required this.senderId, this.senderName = '', this.text = '', required this.createdAt});

  final String id;
  final String callId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  factory CallChatMsg.fromJson(Map<String, dynamic> j) => CallChatMsg(
        id: strOr(j['id']),
        callId: strOr(j['callId']),
        senderId: strOr(j['senderId']),
        senderName: strOr(j['senderName']),
        text: strOr(j['text']),
        createdAt: _when(j['createdAt']) ?? DateTime.now(),
      );
}

/// The call line inside a chat message.
class CallLine {
  const CallLine({
    required this.callId,
    this.media = CallMedia.video,
    this.status = CallStatus.ended,
    this.initiatorId = '',
    this.initiatorName = '',
    this.durationSeconds = 0,
    this.participantCount = 0,
  });

  final String callId;
  final CallMedia media;
  final CallStatus status;
  final String initiatorId;
  final String initiatorName;
  final int durationSeconds;
  final int participantCount;

  bool get isOpen => status == CallStatus.ringing || status == CallStatus.active || status == CallStatus.waiting;
  bool get isMissed => status == CallStatus.missed || status == CallStatus.cancelled;

  factory CallLine.fromJson(Map<String, dynamic> j) => CallLine(
        callId: strOr(j['callId']),
        media: callMediaOf(j['type']),
        status: callStatusOf(j['status']),
        initiatorId: strOr(j['initiatorId']),
        initiatorName: strOr(j['initiatorName']),
        durationSeconds: intOr(j['durationSeconds']),
        participantCount: intOr(j['participantCount']),
      );
}

/// The kinds of live event the server sends on /user/queue/calls.
enum CallPushType {
  incoming,
  ringing,
  invited,
  joined,
  left,
  declined,
  missed,
  ended,
  removed,
  mutedByHost,
  roleChanged,
  lockChanged,
  chat,
  recordingStarted,
  recordingStopped,
  recordingSetting,
  unknown,
}

CallPushType callPushTypeOf(Object? v) {
  switch (strOr(v).toUpperCase()) {
    case 'INCOMING':
      return CallPushType.incoming;
    case 'RINGING':
      return CallPushType.ringing;
    case 'PARTICIPANT_INVITED':
      return CallPushType.invited;
    case 'PARTICIPANT_JOINED':
      return CallPushType.joined;
    case 'PARTICIPANT_LEFT':
      return CallPushType.left;
    case 'PARTICIPANT_DECLINED':
      return CallPushType.declined;
    case 'PARTICIPANT_MISSED':
      return CallPushType.missed;
    case 'ENDED':
      return CallPushType.ended;
    case 'PARTICIPANT_REMOVED':
      return CallPushType.removed;
    case 'MUTED_BY_HOST':
      return CallPushType.mutedByHost;
    case 'ROLE_CHANGED':
      return CallPushType.roleChanged;
    case 'LOCK_CHANGED':
      return CallPushType.lockChanged;
    case 'CHAT':
      return CallPushType.chat;
    case 'RECORDING_STARTED':
      return CallPushType.recordingStarted;
    case 'RECORDING_STOPPED':
      return CallPushType.recordingStopped;
    case 'RECORDING_SETTING':
      return CallPushType.recordingSetting;
    default:
      return CallPushType.unknown;
  }
}

/// One live event about a call.
class CallPush {
  const CallPush({required this.type, required this.callId, this.actorId, this.userId, this.call, this.message});

  final CallPushType type;
  final String callId;

  /// Who did it.
  final String? actorId;

  /// Who it is about, when that is somebody other than the actor.
  final String? userId;

  /// The call as it is now. Null for chat messages.
  final CallInfo? call;
  final CallChatMsg? message;

  factory CallPush.fromJson(Map<String, dynamic> j) {
    final call = j['call'];
    final message = j['message'];
    return CallPush(
      type: callPushTypeOf(j['type']),
      callId: strOr(j['callId']),
      actorId: str(j['actorId']),
      userId: str(j['userId']),
      call: call is Map ? CallInfo.fromJson(asMap(call)) : null,
      message: message is Map ? CallChatMsg.fromJson(asMap(message)) : null,
    );
  }
}

/// The answer to adding people to a call.
class CallInviteOutcome {
  const CallInviteOutcome({required this.call, this.invited = const <String>[], this.skipped = const <String, String>{}});

  final CallInfo call;
  final List<String> invited;

  /// userId to the reason: ALREADY_IN_CALL, NOT_REACHABLE, REMOVED or FULL.
  final Map<String, String> skipped;

  factory CallInviteOutcome.fromJson(Map<String, dynamic> j) {
    final skipped = <String, String>{};
    for (final s in mapList(j['skipped'])) {
      skipped[strOr(s['userId'])] = strOr(s['reason']);
    }
    return CallInviteOutcome(call: CallInfo.fromJson(asMap(j['call'])), invited: stringList(j['invited']), skipped: skipped);
  }
}

/// What someone sees before joining from a call link.
class CallLinkPreview {
  const CallLinkPreview({
    required this.callId,
    this.title,
    this.media = CallMedia.video,
    this.hostName = '',
    this.participantCount = 0,
    this.locked = false,
    this.full = false,
    this.joinable = false,
  });

  final String callId;
  final String? title;
  final CallMedia media;
  final String hostName;
  final int participantCount;
  final bool locked;
  final bool full;
  final bool joinable;

  factory CallLinkPreview.fromJson(Map<String, dynamic> j) => CallLinkPreview(
        callId: strOr(j['callId']),
        title: str(j['title']),
        media: callMediaOf(j['type']),
        hostName: strOr(j['hostName']),
        participantCount: intOr(j['participantCount']),
        locked: boolOr(j['locked']),
        full: boolOr(j['full']),
        joinable: boolOr(j['joinable']),
      );
}

// ---------------------------------------------------------------------------- recordings

enum RecState { starting, recording, stopping, ready, failed }

RecState recStateOf(Object? v) {
  switch (strOr(v).toUpperCase()) {
    case 'STARTING':
      return RecState.starting;
    case 'RECORDING':
      return RecState.recording;
    case 'STOPPING':
      return RecState.stopping;
    case 'READY':
      return RecState.ready;
    default:
      return RecState.failed;
  }
}

/// One recording of a call. Watchable once [state] is ready: [playUrl] then plays or downloads the video.
class CallRecording {
  const CallRecording({
    required this.id,
    required this.callId,
    this.state = RecState.starting,
    this.startedBy = '',
    this.startedByName = '',
    this.createdAt,
    this.durationSeconds = 0,
    this.sizeBytes = 0,
    this.playUrl,
    this.error,
    this.canDelete = false,
  });

  final String id;
  final String callId;
  final RecState state;
  final String startedBy;
  final String startedByName;
  final DateTime? createdAt;
  final int durationSeconds;
  final int sizeBytes;
  final String? playUrl;
  final String? error;
  final bool canDelete;

  bool get isReady => state == RecState.ready && (playUrl ?? '').isNotEmpty;
  bool get isBusy => state == RecState.starting || state == RecState.recording || state == RecState.stopping;

  factory CallRecording.fromJson(Map<String, dynamic> j) => CallRecording(
        id: strOr(j['id']),
        callId: strOr(j['callId']),
        state: recStateOf(j['status']),
        startedBy: strOr(j['startedBy']),
        startedByName: strOr(j['startedByName']),
        createdAt: _when(j['createdAt']),
        durationSeconds: intOr(j['durationSeconds']),
        sizeBytes: intOr(j['sizeBytes']),
        playUrl: str(j['playUrl']),
        error: str(j['error']),
        canDelete: boolOr(j['canDelete']),
      );
}

/// The call switches the administrators control.
class CallSettings {
  const CallSettings({
    this.recordingEnabled = false,
    this.canManage = false,
    this.storageMode = 'LOCAL',
    this.storageReady = true,
    this.storageLocation,
    this.storageProblem,
    this.storageFreeMb,
  });

  final bool recordingEnabled;

  /// True for an administrator, who may change the switches.
  final bool canManage;

  /// Where recordings are kept: LOCAL (a folder on the server) or NETWORK (a mounted share).
  final String storageMode;

  /// False when a new recording cannot be saved right now (share not mounted, disk full).
  final bool storageReady;

  /// Administrators only: the folder the videos are in, and why the storage is not ready.
  final String? storageLocation;
  final String? storageProblem;
  final int? storageFreeMb;

  bool get storageIsNetwork => storageMode == 'NETWORK';

  factory CallSettings.fromJson(Map<String, dynamic> j) => CallSettings(
        recordingEnabled: boolOr(j['recordingEnabled']),
        canManage: boolOr(j['canManage']),
        storageMode: str(j['storageMode']) ?? 'LOCAL',
        storageReady: boolOr(j['storageReady'], true),
        storageLocation: str(j['storageLocation']),
        storageProblem: str(j['storageProblem']),
        storageFreeMb: intOrNull(j['storageFreeMb']),
      );
}
