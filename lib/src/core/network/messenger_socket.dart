import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Where the live connection stands.
enum SocketState { connecting, open, down }

/// One message pushed by the server, already read from JSON.
class RealtimeEvent {
  const RealtimeEvent(this.destination, this.data);

  /// For example `/user/queue/messages` or `/topic/presence`.
  final String destination;
  final Map<String, dynamic> data;
}

/// Live updates from the messenger service: STOMP 1.2 over a plain WebSocket at /ws-messenger (no SockJS).
///
/// It connects with the access token, subscribes to everything the app listens to, answers server pings, and
/// reconnects with a growing pause whenever the line drops. Frames are read from a buffer, because one
/// WebSocket message can carry several STOMP frames or half of one.
class MessengerSocket {
  MessengerSocket({required this.url, required this.tokenProvider});

  final String url;

  /// Gives a fresh access token each time a connection is made.
  final Future<String?> Function() tokenProvider;

  static const List<String> destinations = <String>[
    '/user/queue/messages',
    '/user/queue/delivery-status',
    '/user/queue/read-receipts',
    '/user/queue/typing',
    '/user/queue/errors',
    '/user/queue/reactions',
    '/user/queue/status',
    '/user/queue/groups',
    '/topic/presence',
  ];

  final StreamController<RealtimeEvent> _events = StreamController<RealtimeEvent>.broadcast();
  final StreamController<SocketState> _states = StreamController<SocketState>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _heartbeat;
  Timer? _retry;
  int _attempt = 0;
  bool _wanted = false;
  bool _connected = false;
  int _generation = 0;
  String _buffer = '';
  final Map<String, String> _subscriptions = <String, String>{};

  SocketState _state = SocketState.down;
  SocketState get state => _state;

  Stream<RealtimeEvent> get events => _events.stream;
  Stream<SocketState> get states => _states.stream;
  bool get isOpen => _state == SocketState.open;

  void _set(SocketState s) {
    if (_state == s) return;
    _state = s;
    if (!_states.isClosed) _states.add(s);
  }

  /// Starts connecting, and keeps the connection up until [stop] is called.
  void start() {
    if (_wanted) return;
    _wanted = true;
    _attempt = 0;
    _open();
  }

  /// Closes the connection and stops reconnecting. Called when the person signs out.
  void stop() {
    _wanted = false;
    _retry?.cancel();
    _close();
    _set(SocketState.down);
  }

  /// Opens a fresh connection now, for example when the device comes back online.
  void reconnectNow() {
    if (!_wanted) return;
    _retry?.cancel();
    _attempt = 0;
    _close();
    _open();
  }

  void dispose() {
    stop();
    _events.close();
    _states.close();
  }

  // ------------------------------------------------------------------ sending

  /// Tells the other person in a private chat that you are typing.
  bool sendTyping(String chatId) => _send('/app/chat.typing', <String, dynamic>{'chatId': chatId});

  /// Tells the sender you read a message. Returns false when the line is down.
  bool sendRead(String messageId, String chatId) => _send('/app/chat.read', <String, dynamic>{'id': messageId, 'chatId': chatId});

  /// Returns false when the line is down, so the caller can use REST instead.
  bool _send(String destination, Map<String, dynamic> body) {
    if (!_connected) return false;
    _write(_frame('SEND', <String, String>{'destination': destination, 'content-type': 'application/json'}, jsonEncode(body)));
    return true;
  }

  // --------------------------------------------------------------- connection

  Future<void> _open() async {
    if (!_wanted) return;
    final generation = ++_generation;
    _set(SocketState.connecting);
    try {
      final token = await tokenProvider();
      if (!_wanted || generation != _generation) return;
      if (token == null || token.isEmpty) {
        _scheduleRetry();
        return;
      }
      final channel = WebSocketChannel.connect(Uri.parse(url));
      _channel = channel;
      await channel.ready;
      if (!_wanted || generation != _generation) {
        unawaited(channel.sink.close());
        return;
      }
      _buffer = '';
      _sub = channel.stream.listen(
        (dynamic data) => _onData(generation, data),
        onError: (Object e) => _onClosed(generation),
        onDone: () => _onClosed(generation),
        cancelOnError: true,
      );
      _write(_frame('CONNECT', <String, String>{
        'accept-version': '1.1,1.2',
        'heart-beat': '20000,0',
        'Authorization': 'Bearer $token',
      }));
    } catch (e) {
      debugPrint('Messenger socket could not connect: $e');
      if (generation == _generation) _onClosed(generation);
    }
  }

  void _close() {
    final wasConnected = _connected;
    _generation++;
    _connected = false;
    _heartbeat?.cancel();
    _heartbeat = null;
    _sub?.cancel();
    _sub = null;
    final c = _channel;
    _channel = null;
    if (c != null) {
      try {
        if (wasConnected) c.sink.add(_frame('DISCONNECT', const <String, String>{}));
      } catch (_) {
        // already closed
      }
      unawaited(c.sink.close().catchError((Object _) {}));
    }
    _subscriptions.clear();
  }

  void _onClosed(int generation) {
    if (generation != _generation) return;
    _connected = false;
    _heartbeat?.cancel();
    _sub?.cancel();
    _sub = null;
    _channel = null;
    _subscriptions.clear();
    _set(SocketState.down);
    if (_wanted) _scheduleRetry();
  }

  void _scheduleRetry() {
    _retry?.cancel();
    _attempt++;
    final pause = math.min(15000, 800 * math.pow(1.7, _attempt - 1)).toInt() + math.Random().nextInt(400);
    _retry = Timer(Duration(milliseconds: pause), _open);
  }

  void _write(String frame) {
    try {
      _channel?.sink.add(frame);
    } catch (e) {
      debugPrint('Messenger socket write failed: $e');
    }
  }

  // ------------------------------------------------------------------- frames

  static String _frame(String command, Map<String, String> headers, [String body = '']) {
    final b = StringBuffer(command)..write('\n');
    headers.forEach((k, v) => b.write('$k:$v\n'));
    b..write('\n')..write(body)..write('\u0000');
    return b.toString();
  }

  void _onData(int generation, dynamic data) {
    if (generation != _generation) return;
    final text = data is String ? data : utf8.decode(data as List<int>);
    _buffer += text;
    while (true) {
      // Blank lines between frames are the server's heart beat.
      var start = 0;
      while (start < _buffer.length && (_buffer[start] == '\n' || _buffer[start] == '\r')) {
        start++;
      }
      if (start > 0) _buffer = _buffer.substring(start);
      final end = _buffer.indexOf('\u0000');
      if (end < 0) return;
      final raw = _buffer.substring(0, end);
      _buffer = _buffer.substring(end + 1);
      _handleFrame(generation, raw);
    }
  }

  void _handleFrame(int generation, String raw) {
    final split = raw.indexOf('\n\n');
    final head = split < 0 ? raw : raw.substring(0, split);
    final body = split < 0 ? '' : raw.substring(split + 2);
    final lines = head.split('\n');
    if (lines.isEmpty) return;
    final command = lines.first.trim();
    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      final i = line.indexOf(':');
      if (i > 0) headers.putIfAbsent(line.substring(0, i).trim(), () => line.substring(i + 1).trim());
    }

    switch (command) {
      case 'CONNECTED':
        _connected = true;
        _attempt = 0;
        _set(SocketState.open);
        _startHeartbeat();
        _subscribeAll();
        break;
      case 'MESSAGE':
        final sub = headers['subscription'];
        final destination = headers['destination'] ?? (sub == null ? null : _subscriptions[sub]);
        if (destination == null) return;
        try {
          final decoded = jsonDecode(body);
          if (decoded is Map) {
            _events.add(RealtimeEvent(destination, decoded.map((k, v) => MapEntry(k.toString(), v))));
          }
        } catch (_) {
          // not JSON, nothing the app can use
        }
        break;
      case 'ERROR':
        debugPrint('Messenger socket error: ${headers['message'] ?? body}');
        _onClosed(generation);
        break;
      default:
        break;
    }
  }

  void _subscribeAll() {
    _subscriptions.clear();
    for (var i = 0; i < destinations.length; i++) {
      final id = 'sub-$i';
      _subscriptions[id] = destinations[i];
      _write(_frame('SUBSCRIBE', <String, String>{'id': id, 'destination': destinations[i]}));
    }
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    // A lone line feed tells the server the line is alive. We promised one every 20 seconds.
    _heartbeat = Timer.periodic(const Duration(seconds: 18), (_) => _write('\n'));
  }
}
