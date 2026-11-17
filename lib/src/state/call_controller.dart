import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc show Helper;
import 'package:livekit_client/livekit_client.dart' as lk;
import 'package:permission_handler/permission_handler.dart';

import '../core/network/api_exception.dart';
import '../data/models/call_models.dart';
import '../data/repositories/call_repository.dart';
import 'messenger_controller.dart';
import 'providers.dart';
import 'session_controller.dart';
import 'share_service.dart';
import 'sound_settings.dart';

// Audio and video calls. The messenger service decides who is in a call and hands out join tokens. The media itself
// (voice, camera, screen) flows between the app and a LiveKit server, so none of it goes through the messenger service.
//
// Two pieces live here:
//   CallController: the one per app object. It hears the server's live call events, rings, and owns the current session.
//   CallSession: one call the person is in. It holds the LiveKit room and everything the call screen shows.

final callProvider = NotifierProvider<CallController, CallState>(CallController.new);

enum CallPhase { connecting, live, reconnecting }

/// What the call controller shows the rest of the app.
class CallState {
  const CallState({
    this.incoming = const <CallInfo>[],
    this.session,
    this.expanded = true,
    this.busy = false,
    this.revision = 0,
    this.notice,
    this.noticeSeq = 0,
  });

  /// Calls ringing for this person, newest last.
  final List<CallInfo> incoming;

  /// The call this person is in, if any.
  final CallSession? session;

  /// True while the call fills the screen. False when it is shrunk to a bar so the app can be used.
  final bool expanded;

  /// True while a call is being started or joined, so buttons cannot be pressed twice.
  final bool busy;

  /// Goes up whenever the call list or a chat's call banner may be out of date.
  final int revision;

  final String? notice;
  final int noticeSeq;

  CallState copyWith({
    List<CallInfo>? incoming,
    CallSession? session,
    bool clearSession = false,
    bool? expanded,
    bool? busy,
    int? revision,
    String? notice,
    int? noticeSeq,
  }) =>
      CallState(
        incoming: incoming ?? this.incoming,
        session: clearSession ? null : (session ?? this.session),
        expanded: expanded ?? this.expanded,
        busy: busy ?? this.busy,
        revision: revision ?? this.revision,
        notice: notice ?? this.notice,
        noticeSeq: noticeSeq ?? this.noticeSeq,
      );
}

/// One tile on the call screen: a person's camera, their avatar when the camera is off, or a shared screen.
class CallTile {
  const CallTile({
    required this.id,
    required this.userId,
    required this.name,
    this.picture,
    this.video,
    this.isLocal = false,
    this.isScreen = false,
    this.speaking = false,
    this.level = 0,
    this.micOff = false,
    this.mutedSpeaking = false,
    this.handUp = false,
    this.status,
  });

  /// Unique on the screen. A person who shares their screen has two tiles: their camera and the screen.
  final String id;
  final String userId;
  final String name;
  final String? picture;
  final lk.VideoTrack? video;
  final bool isLocal;
  final bool isScreen;
  final bool speaking;

  /// How loud this person is, from 0 (silent) to 1 (loudest), as LiveKit measures it. It drives the speaking wave.
  final double level;
  final bool micOff;

  /// True only on this person's own tile, while they talk with the microphone muted. It is worked out on this device
  /// and never sent to anyone, so only they see the hint to unmute.
  final bool mutedSpeaking;
  final bool handUp;

  /// Set for people who were invited and have not joined, for example "Ringing".
  final String? status;

  bool get hasVideo => video != null;
}

/// An emoji floating up the screen.
class CallReaction {
  const CallReaction({required this.id, required this.name, required this.emoji});

  final int id;
  final String name;
  final String emoji;
}

class CallController extends Notifier<CallState> {
  StreamSubscription<Map<String, dynamic>>? _push;
  AudioPlayer? _loopPlayer;
  AudioPlayer? _beepPlayer;
  String? _loopPlaying;

  CallRepository get _repo => ref.read(callRepositoryProvider);

  String get _meId => ref.read(messengerProvider.notifier).meId;

  @override
  CallState build() {
    ref.onDispose(() {
      _push?.cancel();
      _loopPlayer?.dispose();
      _beepPlayer?.dispose();
      final s = state.session;
      if (s != null) unawaited(s._dispose());
    });
    _push = ref.read(messengerProvider.notifier).callEvents.listen(_onPush);
    // Load the chosen ringtone now, so it is ready before the first call comes in.
    ref.read(soundSettingsProvider);
    ref.listen<bool>(sessionProvider.select((s) => s.isSignedIn), (prev, next) {
      if (!next) unawaited(_signedOut());
    });
    return const CallState();
  }

  // ------------------------------------------------------------------ starting

  /// Calls the people in a chat. When a call is already running there, joins it.
  Future<bool> startCall(String chatId, CallMedia media) async {
    if (!_canStart()) return false;
    state = state.copyWith(busy: true);
    try {
      await _ensurePermissions(media);
      final join = await _repo.start(chatId, media);
      return await _enter(join);
    } catch (e) {
      _notice(ApiException.from(e).message);
      return false;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// Answers a ringing call, or joins one that is running.
  Future<bool> answer(String callId) async {
    if (state.busy) return false;
    final open = state.session;
    if (open != null && open.callId == callId) {
      setExpanded(true);
      return true;
    }
    state = state.copyWith(busy: true);
    try {
      // Taking a second call leaves the first.
      if (open != null) await leave();
      _removeIncoming(callId);
      await _stopLoop();
      final media = _incomingMedia(callId);
      await _ensurePermissions(media);
      final join = await _repo.join(callId);
      return await _enter(join);
    } catch (e) {
      _notice(ApiException.from(e).message);
      return false;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<bool> joinCall(String callId) => answer(callId);

  /// Joins a call from its link or the code at the end of it.
  Future<bool> joinLink(String codeOrUrl) async {
    if (!_canStart()) return false;
    final code = linkCodeOf(codeOrUrl);
    if (code.isEmpty) {
      _notice('That is not a call link.');
      return false;
    }
    state = state.copyWith(busy: true);
    try {
      await _ensurePermissions(CallMedia.video);
      final join = await _repo.joinLink(code);
      return await _enter(join);
    } catch (e) {
      _notice(ApiException.from(e).message);
      return false;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// Makes a call link, joins it as the host and returns the call so its link can be shared.
  Future<CallInfo?> createLinkAndJoin({CallMedia media = CallMedia.video, String? title}) async {
    if (!_canStart()) return null;
    state = state.copyWith(busy: true);
    try {
      final info = await _repo.createLink(media: media, title: title);
      await _ensurePermissions(media);
      final join = await _repo.join(info.id);
      final entered = await _enter(join);
      return entered ? info : null;
    } catch (e) {
      _notice(ApiException.from(e).message);
      return null;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// The code at the end of a pasted call link, or the text itself when it is already just a code.
  static String linkCodeOf(String text) {
    final t = text.trim();
    if (t.isEmpty) return '';
    final uri = Uri.tryParse(t);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final last = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (last.isNotEmpty) return last.last;
    }
    return t.replaceAll('/', '');
  }

  bool _canStart() {
    if (state.busy) return false;
    if (state.session != null) {
      _notice('You are already in a call.');
      setExpanded(true);
      return false;
    }
    return true;
  }

  Future<bool> _enter(CallJoinInfo join) async {
    if (!join.canConnect) {
      _notice(_reasonText(join));
      return false;
    }
    _removeIncoming(join.call.id);
    await _stopLoop();
    final session = CallSession._(this, join.call, _mediaUrl(join.url!), join.token!, join.identity);
    state = state.copyWith(session: session, expanded: true, revision: state.revision + 1);
    _updateSounds();
    unawaited(session._connect());
    return true;
  }

  String _reasonText(CallJoinInfo join) {
    switch ((join.reason ?? '').toUpperCase()) {
      case 'BUSY':
        return 'They are on another call.';
      case 'NOT_CONFIGURED':
        return 'Calls are not set up on the server yet.';
      case 'LOCKED':
        return 'The host has locked this call.';
      case 'FULL':
        return 'This call is full.';
      case 'ENDED':
        return 'This call has ended.';
      default:
        return 'The call could not be started.';
    }
  }

  /// The media server address as the server knows it, adjusted for the Android emulator where localhost is the phone.
  static String _mediaUrl(String url) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return url;
    return url.replaceFirst('//localhost', '//10.0.2.2').replaceFirst('//127.0.0.1', '//10.0.2.2');
  }

  CallMedia _incomingMedia(String callId) {
    for (final c in state.incoming) {
      if (c.id == callId) return c.media;
    }
    return CallMedia.video;
  }

  Future<void> _ensurePermissions(CallMedia media) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) _notice('Allow the microphone in Settings so people can hear you.');
      if (media == CallMedia.video) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) _notice('Allow the camera in Settings so people can see you.');
      }
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Lets Bluetooth headsets work. Nothing breaks when it is refused.
        await Permission.bluetoothConnect.request();
      }
    } catch (e) {
      debugPrint('Calls: permission request failed: $e');
    }
  }

  // ------------------------------------------------------------------- ringing

  Future<void> decline(String callId) async {
    _removeIncoming(callId);
    _updateSounds();
    await _quiet(_repo.decline(callId));
    state = state.copyWith(revision: state.revision + 1);
  }

  // -------------------------------------------------------------------- ending

  /// Leaves the call. Everyone else carries on, unless it was a one to one call.
  Future<void> leave() async {
    final s = state.session;
    if (s == null) return;
    unawaited(_beep('leave.wav'));
    final id = s.callId;
    await _close(s);
    await _quiet(_repo.leave(id));
  }

  /// A host ends the call for everyone.
  Future<void> endForAll() async {
    final s = state.session;
    if (s == null) return;
    final id = s.callId;
    await _close(s);
    await _quiet(_repo.end(id));
  }

  void setExpanded(bool value) {
    if (state.expanded == value) return;
    state = state.copyWith(expanded: value);
  }

  Future<void> _close(CallSession s, {String? notice}) async {
    if (state.session == s) {
      state = state.copyWith(clearSession: true, expanded: true, revision: state.revision + 1);
    }
    _updateSounds();
    if (notice != null) _notice(notice);
    await s._dispose();
  }

  Future<void> _roomLost(CallSession s) async {
    if (state.session != s || s._closing) return;
    final id = s.callId;
    await _close(s, notice: 'The call connection was lost.');
    await _quiet(_repo.leave(id));
  }

  Future<void> _signedOut() async {
    final s = state.session;
    if (s != null) await _close(s);
    await _stopLoop();
    state = const CallState();
  }

  // ------------------------------------------------------------- live events

  void _onPush(Map<String, dynamic> raw) {
    // Not a server event: the messenger saw a call line arrive in a chat and asks whether that call is ringing for us.
    if (raw['type'] == 'CHECK') {
      unawaited(_checkRinging((raw['callId'] ?? '').toString()));
      return;
    }
    final CallPush p;
    try {
      p = CallPush.fromJson(raw);
    } catch (e) {
      debugPrint('Calls: unreadable event: $e');
      return;
    }
    final me = _meId;
    final call = p.call;
    final s = state.session;
    final mine = s != null && s.callId == p.callId ? s : null;

    switch (p.type) {
      case CallPushType.incoming:
        if (call == null || !call.isOpen || call.stateOf(me) != PersonState.invited) {
          debugPrint('Calls: incoming call ignored. call=${call != null} open=${call?.isOpen} myState=${call?.stateOf(me)} me=$me people=${call?.people.map((x) => x.userId).toList()}');
          return;
        }
        if (mine != null) return;
        _addIncoming(call);
        if (s != null) unawaited(_beep('join.wav'));
        _ringBack(call.id);
        state = state.copyWith(revision: state.revision + 1);
        break;

      case CallPushType.chat:
        if (mine != null && p.message != null) mine._addChat(p.message!);
        break;

      case CallPushType.mutedByHost:
        if (mine != null) {
          mine._ping();
          _notice('A host muted you.');
        }
        break;

      case CallPushType.removed:
        if (call != null) _applyCall(call);
        if (p.userId == me) {
          _removeIncoming(p.callId);
          if (mine != null) {
            unawaited(_close(mine, notice: 'A host removed you from the call.'));
          }
        }
        break;

      case CallPushType.ended:
        _removeIncoming(p.callId);
        if (mine != null) {
          unawaited(_close(mine, notice: 'The call has ended.'));
        } else {
          state = state.copyWith(revision: state.revision + 1);
        }
        break;

      case CallPushType.roleChanged:
        if (call != null) {
          final before = mine?.call.roleOf(me);
          _applyCall(call);
          if (mine != null && p.userId == me && before != call.roleOf(me)) {
            _notice(call.roleOf(me) == CallRole.member
                ? 'You are no longer a host.'
                : (call.roleOf(me) == CallRole.host ? 'You are now the host.' : 'You are now a co-host.'));
          }
        }
        break;

      case CallPushType.lockChanged:
        if (call != null) {
          _applyCall(call);
          if (mine != null && !call.isManager(me)) _notice(call.locked ? 'The host locked the call.' : 'The host unlocked the call.');
        }
        break;

      case CallPushType.declined:
      case CallPushType.missed:
      case CallPushType.joined:
      case CallPushType.left:
      case CallPushType.invited:
      case CallPushType.ringing:
        if (call != null) _applyCall(call);
        if (p.userId == me) {
          // This person answered, declined or timed out, possibly on another device. Stop ringing here.
          if (p.type != CallPushType.invited && p.type != CallPushType.ringing && mine == null) _removeIncoming(p.callId);
        }
        if (p.type == CallPushType.missed || p.type == CallPushType.declined || p.type == CallPushType.joined) {
          state = state.copyWith(revision: state.revision + 1);
        }
        break;

      case CallPushType.recordingStarted:
        if (call != null) {
          final wasRecording = mine?.call.recording ?? false;
          _applyCall(call);
          if (mine != null && !wasRecording && call.recording) _notice('This call is being recorded.');
        }
        state = state.copyWith(revision: state.revision + 1);
        break;

      case CallPushType.recordingStopped:
        if (call != null) {
          final wasRecording = mine?.call.recording ?? false;
          _applyCall(call);
          if (mine != null && wasRecording && !call.recording) _notice('Recording stopped. It will be in the call details soon.');
        }
        state = state.copyWith(revision: state.revision + 1);
        break;

      case CallPushType.recordingSetting:
        if (call != null) {
          final could = mine?.call.recordingEnabled ?? false;
          _applyCall(call);
          if (mine != null && could && !call.recordingEnabled) _notice('Call recording was switched off by an administrator.');
        }
        state = state.copyWith(revision: state.revision + 1);
        break;

      case CallPushType.unknown:
        break;
    }
    _updateSounds();
  }

  /// A call line arrived in a chat. If that call is ringing for this person and the live "incoming" event did not
  /// bring up the ringing screen, ask the server and bring it up now.
  Future<void> _checkRinging(String callId) async {
    if (callId.isEmpty || state.session != null || state.incoming.any((c) => c.id == callId)) return;
    try {
      final call = await _repo.get(callId);
      final me = _meId;
      if (state.session != null || state.incoming.any((c) => c.id == call.id)) return;
      if (!call.isOpen || call.stateOf(me) != PersonState.invited) {
        debugPrint('Calls: call line checked, not ringing for me. open=${call.isOpen} myState=${call.stateOf(me)} me=$me');
        return;
      }
      _addIncoming(call);
      _ringBack(call.id);
      state = state.copyWith(revision: state.revision + 1);
      _updateSounds();
    } catch (e) {
      debugPrint('Calls: could not check call $callId: $e');
    }
  }

  /// Takes a fresh copy of a call from the server into the session and the ringing list.
  void _applyCall(CallInfo call) {
    final s = state.session;
    if (s != null && s.callId == call.id) s._updateCall(call);
    final idx = state.incoming.indexWhere((c) => c.id == call.id);
    if (idx < 0) return;
    if (!call.isOpen || call.stateOf(_meId) != PersonState.invited) {
      _removeIncoming(call.id);
    } else {
      final list = List<CallInfo>.of(state.incoming);
      list[idx] = call;
      state = state.copyWith(incoming: list);
    }
  }

  void _addIncoming(CallInfo call) {
    final list = state.incoming.where((c) => c.id != call.id).toList()..add(call);
    state = state.copyWith(incoming: list);
  }

  void _removeIncoming(String callId) {
    if (!state.incoming.any((c) => c.id == callId)) return;
    state = state.copyWith(incoming: state.incoming.where((c) => c.id != callId).toList());
  }

  void _ringBack(String callId) {
    ref.read(messengerProvider.notifier).sendCallRinging(callId);
  }

  void _notice(String message) {
    state = state.copyWith(notice: message, noticeSeq: state.noticeSeq + 1);
  }

  Future<void> _quiet(Future<void> f) async {
    try {
      await f;
    } catch (e) {
      debugPrint('Calls: request failed: $e');
    }
  }

  // ------------------------------------------------------------------- sounds

  /// The ringtone for an incoming call, or the ringback tone while the people we called are ringing.
  void _updateSounds() {
    final s = state.session;
    String? want;
    if (s == null && state.incoming.isNotEmpty) {
      want = 'ringtone.wav';
    } else if (s != null && s.ringingOut) {
      want = 'ringback.wav';
    }
    if (want == _loopPlaying) return;
    _loopPlaying = want;
    if (want == null) {
      unawaited(_stopLoop());
    } else {
      unawaited(_startLoop(want));
    }
  }

  Future<void> _startLoop(String asset) async {
    try {
      final p = _loopPlayer ??= AudioPlayer();
      await p.setReleaseMode(ReleaseMode.loop);
      Source source = AssetSource('sounds/$asset');
      if (asset == 'ringtone.wav') {
        // The incoming call uses the ringtone the person chose in Sounds. The ringback tone stays as it is.
        final chosen = await ref.read(soundServiceProvider).sourceFor(ref.read(soundSettingsProvider).ringtone, fallback: defaultRingtone);
        if (chosen != null) source = chosen;
      }
      if (_loopPlaying != asset) return;
      await p.play(source);
    } catch (e) {
      // Browsers refuse sound before the first tap. The screen still shows the call.
      debugPrint('Calls: could not play $asset: $e');
    }
  }

  Future<void> _stopLoop() async {
    _loopPlaying = null;
    try {
      await _loopPlayer?.stop();
    } catch (_) {}
  }

  Future<void> _beep(String asset) async {
    try {
      final p = _beepPlayer ??= AudioPlayer();
      await p.setReleaseMode(ReleaseMode.release);
      await p.play(AssetSource('sounds/$asset'), volume: 0.6);
    } catch (_) {}
  }
}

/// One call this person is in. The call screen listens to it and redraws whenever anything changes.
class CallSession extends ChangeNotifier {
  CallSession._(this._owner, this._call, this.url, this._token, this.identity);

  final CallController _owner;
  final String url;
  final String? _token;
  final String identity;

  CallInfo _call;
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _listener;
  Timer? _reactionTimer;

  bool _disposed = false;
  bool _closing = false;
  bool _queued = false;
  int _reactionSeq = 0;
  bool _backgroundOn = false;

  CallPhase phase = CallPhase.connecting;
  DateTime? connectedAt;

  bool micOn = false;
  bool camOn = false;
  bool sharing = false;
  bool handUp = false;
  bool speakerOn = false;
  bool frontCamera = true;

  /// True while this person talks with their microphone muted. The call screen then tells them, and only them, to
  /// unmute. It is measured on this device and nothing about it is sent over the network.
  bool mutedSpeaking = false;

  /// The tile id someone chose to look at in large. Null lets the app follow whoever is speaking.
  String? pinnedId;

  final List<CallChatMsg> chat = <CallChatMsg>[];
  int unreadChat = 0;
  bool chatOpen = false;
  bool _chatLoaded = false;

  final Set<String> _hands = <String>{};
  final List<CallReaction> reactions = <CallReaction>[];

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  CallInfo get call => _call;
  String get callId => _call.id;
  lk.Room? get room => _room;
  String get meId => identity;

  bool get isConnected => phase != CallPhase.connecting;
  bool get isManager => _call.roleOf(identity) != CallRole.member;

  /// True while we wait for the people we rang: nobody else has joined yet.
  bool get ringingOut => phase == CallPhase.live && _call.status == CallStatus.ringing && _call.initiatorId == identity && _call.joined.length <= 1;

  String get title => _call.titleFor(identity);

  /// Everyone who is in the call right now, including this person.
  int get peopleCount => _room == null ? 1 : _room!.remoteParticipants.length + 1;

  // --------------------------------------------------------------- connecting

  Future<void> _connect() async {
    try {
      final room = lk.Room(
        roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true),
      );
      _room = room;
      _listener = room.createListener();
      _listener!.listen(_onRoomEvent);
      room.addListener(_ping);
      await room.connect(url, _token ?? '');
      if (_disposed) return;
      phase = CallPhase.live;
      connectedAt = DateTime.now();
      _ping();
      _owner._updateSounds();
      await _openDevices(room);
      unawaited(_loadChat());
      unawaited(_refreshCall());
    } catch (e) {
      debugPrint('Calls: could not connect: $e');
      if (_disposed) return;
      final id = callId;
      await _owner._close(this, notice: 'Could not connect to the call. Check your connection and try again.');
      await _owner._quiet(_owner._repo.leave(id));
    }
  }

  Future<void> _openDevices(lk.Room room) async {
    final lp = room.localParticipant;
    if (lp == null) return;
    try {
      await lp.setMicrophoneEnabled(true);
    } catch (e) {
      debugPrint('Calls: microphone unavailable: $e');
      _owner._notice('The microphone could not be turned on.');
    }
    if (_call.isVideo) {
      try {
        await lp.setCameraEnabled(true);
      } catch (e) {
        debugPrint('Calls: camera unavailable: $e');
        _owner._notice('The camera could not be turned on.');
      }
    }
    if (_isMobile) {
      speakerOn = _call.isVideo;
      try {
        await lk.Hardware.instance.setSpeakerphoneOn(speakerOn);
      } catch (e) {
        debugPrint('Calls: speaker route failed: $e');
      }
    }
    _devicesOpened = true;
    _ping();
  }

  Future<void> _refreshCall() async {
    try {
      _updateCall(await _owner._repo.get(callId));
    } catch (_) {}
  }

  bool get _isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS);

  /// True on desktop, where the person picks which screen or window to share.
  bool get needsScreenPicker => _isDesktop;

  /// False where sharing the screen is not possible from the app (iPhone and iPad need a broadcast extension).
  bool get canShareScreen => kIsWeb || defaultTargetPlatform != TargetPlatform.iOS;

  bool get canFlipCamera => _isMobile;
  bool get canPickSpeaker => _isMobile;

  // ------------------------------------------------------------- room events

  void _onRoomEvent(lk.RoomEvent e) {
    if (_disposed) return;
    if (e is lk.RoomDisconnectedEvent) {
      if (!_closing) unawaited(_owner._roomLost(this));
      return;
    }
    if (e is lk.RoomReconnectingEvent) {
      phase = CallPhase.reconnecting;
    } else if (e is lk.RoomReconnectedEvent) {
      phase = CallPhase.live;
    } else if (e is lk.DataReceivedEvent) {
      _onData(e);
    } else if (e is lk.ParticipantConnectedEvent) {
      unawaited(_owner._beep('join.wav'));
      // The newcomer has not seen our raised hand.
      if (handUp) unawaited(_publish('hand', <String, dynamic>{'up': true}));
    } else if (e is lk.ParticipantDisconnectedEvent) {
      _hands.remove(e.participant.identity);
      if (pinnedId != null && pinnedId!.startsWith(e.participant.identity)) pinnedId = null;
      unawaited(_owner._beep('leave.wav'));
    }
    _ping();
  }

  void _onData(lk.DataReceivedEvent e) {
    final from = e.participant?.identity;
    if (from == null) return;
    try {
      final body = jsonDecode(utf8.decode(e.data));
      if (body is! Map) return;
      if (e.topic == 'hand') {
        if (body['up'] == true) {
          _hands.add(from);
        } else {
          _hands.remove(from);
        }
      } else if (e.topic == 'reaction') {
        final emoji = (body['e'] ?? '').toString();
        if (emoji.isNotEmpty && emoji.length <= 8) _showReaction(_nameOf(from, e.participant), emoji);
      }
    } catch (_) {}
  }

  /// Redraws once for any burst of room events.
  void _ping() {
    if (_queued || _disposed) return;
    _queued = true;
    scheduleMicrotask(() {
      _queued = false;
      if (_disposed) return;
      _syncLocal();
      _notify();
      _owner._updateSounds();
    });
  }

  void _syncLocal() {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    micOn = _audioOn(lp);
    camOn = _cameraTrack(lp) != null;
    sharing = _screenTrack(lp) != null;
    handUp = _hands.contains(identity);
    _syncWatcher();
  }

  void _updateCall(CallInfo call) {
    if (_disposed) return;
    _call = call;
    _ping();
  }

  // -------------------------------------------------------- reading tracks

  static bool _audioOn(lk.Participant p) {
    for (final pub in p.audioTrackPublications) {
      if (pub.source == lk.TrackSource.microphone && !pub.muted && pub.track != null) return true;
    }
    return false;
  }

  static lk.VideoTrack? _trackOf(lk.Participant p, lk.TrackSource source) {
    for (final pub in p.videoTrackPublications) {
      if (pub.source != source || pub.muted) continue;
      final t = pub.track;
      if (t is lk.VideoTrack) return t;
    }
    return null;
  }

  static lk.VideoTrack? _cameraTrack(lk.Participant p) => _trackOf(p, lk.TrackSource.camera);
  static lk.VideoTrack? _screenTrack(lk.Participant p) => _trackOf(p, lk.TrackSource.screenShareVideo);

  String _nameOf(String userId, lk.Participant? p) {
    final known = _call.person(userId)?.name ?? '';
    if (known.isNotEmpty) return known;
    final n = p?.name ?? '';
    return n.isNotEmpty ? n : 'Someone';
  }

  /// Everything the call screen draws: shared screens first, then people.
  List<CallTile> tiles() {
    final room = _room;
    if (room == null) return const <CallTile>[];
    final out = <CallTile>[];
    final screens = <CallTile>[];
    final seen = <String>{};

    void add(lk.Participant p, bool local) {
      final uid = p.identity;
      seen.add(uid);
      final name = local ? 'You' : _nameOf(uid, p);
      final picture = _call.person(uid)?.picture;
      final screen = _screenTrack(p);
      if (screen != null) {
        screens.add(CallTile(
          id: '$uid:screen',
          userId: uid,
          name: local ? 'Your screen' : '$name\'s screen',
          picture: picture,
          video: screen,
          isLocal: local,
          isScreen: true,
        ));
      }
      out.add(CallTile(
        id: '$uid:cam',
        userId: uid,
        name: name,
        picture: picture,
        video: _cameraTrack(p),
        isLocal: local,
        speaking: p.isSpeaking,
        level: p.audioLevel,
        micOff: !_audioOn(p),
        mutedSpeaking: local && mutedSpeaking,
        handUp: _hands.contains(uid),
      ));
    }

    final lp = room.localParticipant;
    if (lp != null) add(lp, true);
    for (final p in room.remoteParticipants.values) {
      add(p, false);
    }
    // People who were invited and have not joined yet.
    for (final person in _call.people) {
      if (seen.contains(person.userId) || person.userId == identity) continue;
      if (person.state != PersonState.invited) continue;
      out.add(CallTile(id: '${person.userId}:cam', userId: person.userId, name: person.name, picture: person.picture, status: 'Ringing'));
    }
    return <CallTile>[...screens, ...out];
  }

  // ----------------------------------------------------------------- controls

  Future<void> toggleMic() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final turningOn = !micOn;
    if (turningOn) {
      // Let go of the private listening capture first, so the real microphone has the device to itself.
      _watchPaused = true;
      await _stopWatcher();
    }
    try {
      await lp.setMicrophoneEnabled(turningOn);
    } catch (e) {
      _owner._notice('The microphone could not be changed.');
    } finally {
      _watchPaused = false;
    }
    _ping();
  }

  // ------------------------------------------------- talking while muted

  // While the microphone is muted the app keeps a second capture that never leaves this device and is never published.
  // It only measures loudness, so a person who starts talking while muted can be told to unmute, and nobody else is.
  // The operating system shows its "microphone in use" indicator for as long as it runs. Set this to false to release
  // the microphone completely while muted; the hint is then not shown.
  static const bool _listenWhileMuted = true;

  // Loudness is on the visualizer's 0 to 1 scale. Speech has to rise this far above the room's background level, and
  // be at least [_speechFloor] in absolute terms, to count. The margin grows while someone else is talking, because
  // their voice from the speakers can leak into the microphone.
  static const double _speechMargin = 0.2;
  static const double _speechFloor = 0.45;
  static const Duration _speechHold = Duration(milliseconds: 400);
  static const Duration _speechGap = Duration(milliseconds: 250);
  static const Duration _hintLinger = Duration(milliseconds: 2500);

  lk.LocalAudioTrack? _watchTrack;
  lk.AudioVisualizer? _watchViz;
  lk.EventsListener<lk.AudioVisualizerEvent>? _watchListener;
  bool _devicesOpened = false;
  bool _watchStarting = false;
  bool _watchFailed = false;
  bool _watchPaused = false;
  double _floor = 1;
  DateTime? _floorAt;
  DateTime? _activeSince;
  DateTime? _lastActive;

  bool get _wantWatch =>
      _listenWhileMuted && _devicesOpened && !micOn && !_watchPaused && !_watchFailed && !_closing && !_disposed && phase == CallPhase.live;

  void _syncWatcher() {
    if (_wantWatch) {
      if (_watchTrack == null && !_watchStarting) unawaited(_startWatcher());
    } else if (_watchTrack != null) {
      unawaited(_stopWatcher());
    }
  }

  Future<void> _startWatcher() async {
    if (_watchStarting) return;
    _watchStarting = true;
    lk.LocalAudioTrack? track;
    lk.AudioVisualizer? viz;
    lk.EventsListener<lk.AudioVisualizerEvent>? listener;
    try {
      track = await lk.LocalAudioTrack.create();
      if (!_wantWatch) {
        await _releaseWatcher(track, null, null);
        return;
      }
      viz = lk.createVisualizer(track, options: const lk.AudioVisualizerOptions(centeredBands: false, barCount: 7, smoothTransition: true));
      listener = viz.createListener();
      listener.on<lk.AudioVisualizerEvent>(_onWatchLevel);
      await viz.start();
      if (!_wantWatch) {
        await _releaseWatcher(track, viz, listener);
        return;
      }
      _watchTrack = track;
      _watchViz = viz;
      _watchListener = listener;
    } catch (e) {
      // No microphone, no permission, or a platform without the visualizer. The call carries on without the hint.
      debugPrint('Calls: cannot listen for speech while muted: $e');
      _watchFailed = true;
      await _releaseWatcher(track, viz, listener);
    } finally {
      _watchStarting = false;
      // The mute button may have been pressed again while this was starting.
      if (!_disposed) _syncWatcher();
    }
  }

  Future<void> _stopWatcher() async {
    // A start that is still in flight ends quickly, because it checks again once the capture exists.
    for (var i = 0; i < 60 && _watchStarting; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
    final track = _watchTrack;
    final viz = _watchViz;
    final listener = _watchListener;
    _watchTrack = null;
    _watchViz = null;
    _watchListener = null;
    _floor = 1;
    _floorAt = null;
    _activeSince = null;
    _lastActive = null;
    if (mutedSpeaking) {
      mutedSpeaking = false;
      _notify();
    }
    await _releaseWatcher(track, viz, listener);
  }

  Future<void> _releaseWatcher(lk.LocalAudioTrack? track, lk.AudioVisualizer? viz, lk.EventsListener<lk.AudioVisualizerEvent>? listener) async {
    try {
      await viz?.stop();
    } catch (_) {}
    try {
      await viz?.dispose();
    } catch (_) {}
    try {
      await listener?.dispose();
    } catch (_) {}
    try {
      await track?.stop();
    } catch (_) {}
    try {
      await track?.dispose();
    } catch (_) {}
  }

  void _onWatchLevel(lk.AudioVisualizerEvent e) {
    if (_disposed || micOn || _watchTrack == null) return;
    var level = 0.0;
    for (final v in e.event) {
      if (v is num && v > level) level = v.toDouble();
    }
    final now = DateTime.now();

    // The room's background level: it drops at once and creeps up slowly, so a few seconds of talking do not raise it.
    final before = _floorAt;
    _floorAt = now;
    if (level <= _floor) {
      _floor = level;
    } else if (before != null) {
      _floor = math.min(level, _floor + 0.05 * now.difference(before).inMilliseconds / 1000);
    }

    var margin = _speechMargin;
    final room = _room;
    if (room != null && room.remoteParticipants.values.any((p) => p.isSpeaking)) margin *= 1.6;

    if (level >= _speechFloor && level - _floor > margin) {
      _lastActive = now;
      _activeSince ??= now;
    } else if (_lastActive != null && now.difference(_lastActive!) > _speechGap) {
      _activeSince = null;
    }

    final talking = _activeSince != null && now.difference(_activeSince!) >= _speechHold;
    if (talking && !mutedSpeaking) {
      mutedSpeaking = true;
      _notify();
    } else if (!talking && mutedSpeaking && _lastActive != null && now.difference(_lastActive!) > _hintLinger) {
      mutedSpeaking = false;
      _notify();
    }
  }

  Future<void> toggleCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    try {
      await lp.setCameraEnabled(!camOn);
    } catch (e) {
      _owner._notice('The camera could not be turned on.');
    }
    _ping();
  }

  Future<void> flipCamera() async {
    final lp = _room?.localParticipant;
    if (lp == null || !camOn) return;
    for (final pub in lp.videoTrackPublications) {
      final t = pub.track;
      if (pub.source == lk.TrackSource.camera && t is lk.LocalVideoTrack) {
        try {
          final next = frontCamera ? lk.CameraPosition.back : lk.CameraPosition.front;
          await t.setCameraPosition(next);
          frontCamera = !frontCamera;
        } catch (e) {
          _owner._notice('This device could not switch cameras.');
        }
        break;
      }
    }
    _ping();
  }

  Future<void> toggleSpeaker() async {
    if (!_isMobile) return;
    speakerOn = !speakerOn;
    try {
      await lk.Hardware.instance.setSpeakerphoneOn(speakerOn);
    } catch (e) {
      debugPrint('Calls: speaker route failed: $e');
    }
    _ping();
  }

  /// Starts sharing. On desktop [sourceId] is the screen or window the person picked.
  Future<void> startScreenShare({String? sourceId}) async {
    final lp = _room?.localParticipant;
    if (lp == null || sharing) return;
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        if (!await rtc.Helper.requestCapturePermission()) return;
        _backgroundOn = await startShareService();
        await lp.setScreenShareEnabled(true);
      } else if (_isDesktop && sourceId != null) {
        final track = await lk.LocalVideoTrack.createScreenShareTrack(
          lk.ScreenShareCaptureOptions(sourceId: sourceId, maxFrameRate: 15),
        );
        await lp.publishVideoTrack(track);
      } else if (kIsWeb) {
        // Keep this app's own tab out of the browser's list, so nobody shares the call by accident.
        await lp.setScreenShareEnabled(
          true,
          screenShareCaptureOptions: const lk.ScreenShareCaptureOptions(selfBrowserSurface: 'exclude'),
        );
      } else {
        await lp.setScreenShareEnabled(true);
      }
    } catch (e) {
      debugPrint('Calls: screen share failed: $e');
      _owner._notice('Screen sharing could not start.');
      await _stopBackground();
    }
    _ping();
  }

  Future<void> stopScreenShare() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    try {
      await lp.setScreenShareEnabled(false);
    } catch (e) {
      debugPrint('Calls: stopping screen share failed: $e');
    }
    await _stopBackground();
    _ping();
  }

  Future<void> _stopBackground() async {
    if (!_backgroundOn) return;
    _backgroundOn = false;
    try {
      await stopShareService();
    } catch (_) {}
  }

  Future<void> toggleHand() async {
    handUp = !handUp;
    if (handUp) {
      _hands.add(identity);
    } else {
      _hands.remove(identity);
    }
    await _publish('hand', <String, dynamic>{'up': handUp});
    _ping();
  }

  Future<void> react(String emoji) async {
    _showReaction('You', emoji);
    await _publish('reaction', <String, dynamic>{'e': emoji});
  }

  void _showReaction(String name, String emoji) {
    final r = CallReaction(id: ++_reactionSeq, name: name, emoji: emoji);
    reactions.add(r);
    if (reactions.length > 14) reactions.removeAt(0);
    _reactionTimer?.cancel();
    _reactionTimer = Timer(const Duration(milliseconds: 3400), () {
      reactions.clear();
      if (!_disposed) _notify();
    });
    _notify();
  }

  Future<void> _publish(String topic, Map<String, dynamic> body) async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    try {
      await lp.publishData(utf8.encode(jsonEncode(body)), reliable: true, topic: topic);
    } catch (e) {
      debugPrint('Calls: could not send $topic: $e');
    }
  }

  void pin(String? tileId) {
    pinnedId = pinnedId == tileId ? null : tileId;
    _notify();
  }

  // --------------------------------------------------------------------- chat

  Future<void> _loadChat() async {
    try {
      final list = await _owner._repo.messages(callId);
      if (_disposed) return;
      _chatLoaded = true;
      for (final m in list) {
        _addChat(m, quiet: true);
      }
      _notify();
    } catch (_) {}
  }

  void _addChat(CallChatMsg m, {bool quiet = false}) {
    if (_disposed || chat.any((c) => c.id == m.id)) return;
    chat.add(m);
    chat.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (!quiet && !chatOpen && m.senderId != identity) unreadChat++;
    if (!quiet) _notify();
  }

  void setChatOpen(bool open) {
    chatOpen = open;
    if (open) unreadChat = 0;
    _notify();
  }

  bool get chatLoaded => _chatLoaded;

  Future<void> sendChat(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final sent = await _owner._repo.sendMessage(callId, t);
    _addChat(sent, quiet: true);
    _notify();
  }

  // ------------------------------------------------------------- host actions

  Future<void> invite(List<String> userIds) async {
    if (userIds.isEmpty) return;
    final outcome = await _owner._repo.invite(callId, userIds);
    _updateCall(outcome.call);
    if (outcome.skipped.isNotEmpty) {
      final busy = outcome.skipped.values.where((r) => r == 'ALREADY_IN_CALL').length;
      final full = outcome.skipped.values.any((r) => r == 'FULL');
      if (full) {
        _owner._notice('The call is full.');
      } else if (busy > 0) {
        _owner._notice(busy == 1 ? 'One person is already in a call.' : '$busy people are already in a call.');
      }
    }
  }

  Future<void> muteOther(String userId) => _owner._repo.mute(callId, userId);
  Future<void> muteAll() => _owner._repo.muteAll(callId);
  Future<void> removeOther(String userId) => _owner._repo.remove(callId, userId);
  Future<void> setRole(String userId, CallRole role) => _owner._repo.setRole(callId, userId, role);
  Future<void> setLocked(bool locked) => _owner._repo.setLocked(callId, locked);

  // --------------------------------------------------------------- recording

  bool recordBusy = false;

  /// Whether this person may start or stop recording: a host or co-host, in a call that can be recorded.
  bool get canRecord => isManager && _call.recordingEnabled && _call.isOpen;

  /// Whether a recording is running. Everyone in the call sees the red "Recording" sign.
  bool get recording => _call.recordingEnabled && _call.recording;

  Future<void> startRecording() => _recordJob(() => _owner._repo.startRecording(callId));
  Future<void> stopRecording() async {
    await _recordJob(() => _owner._repo.stopRecording(callId));
    _owner._notice('Recording stopped. It will be in the call details soon.');
  }

  Future<void> _recordJob(Future<CallRecording> Function() job) async {
    if (recordBusy) return;
    recordBusy = true;
    _notify();
    try {
      await job();
      await _refreshCall();
    } finally {
      recordBusy = false;
      _notify();
    }
  }

  // --------------------------------------------------------------- shutting down

  Future<void> _dispose() async {
    if (_disposed) return;
    _closing = true;
    _disposed = true;
    _reactionTimer?.cancel();
    final room = _room;
    final listener = _listener;
    _room = null;
    _listener = null;
    try {
      room?.removeListener(_ping);
    } catch (_) {}
    try {
      await listener?.dispose();
    } catch (_) {}
    await _stopBackground();
    await _stopWatcher();
    try {
      await room?.disconnect();
    } catch (_) {}
    try {
      await room?.dispose();
    } catch (_) {}
    super.dispose();
  }
}
