import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/network/api_exception.dart';
import '../core/network/messenger_socket.dart';
import '../data/models/messenger_models.dart';
import '../data/repositories/messenger_repository.dart';
import 'providers.dart';
import 'session_controller.dart';

const Object _keep = Object();

/// Whether someone is online, and when they were last seen.
class Presence {
  const Presence({this.online = false, this.lastSeen});

  final bool online;
  final DateTime? lastSeen;
}

/// The messages of one chat, oldest first, plus where the loading stands.
class Thread {
  const Thread({this.messages = const <MMessage>[], this.loading = false, this.loadingOlder = false, this.hasMore = true, this.page = 0, this.error});

  final List<MMessage> messages;
  final bool loading;
  final bool loadingOlder;
  final bool hasMore;
  final int page;
  final Object? error;

  Thread copyWith({List<MMessage>? messages, bool? loading, bool? loadingOlder, bool? hasMore, int? page, Object? error = _keep}) => Thread(
        messages: messages ?? this.messages,
        loading: loading ?? this.loading,
        loadingOlder: loadingOlder ?? this.loadingOlder,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: identical(error, _keep) ? this.error : error,
      );
}

class MessengerState {
  const MessengerState({
    this.me,
    this.chats = const <MChat>[],
    this.chatsLoading = false,
    this.chatsLoaded = false,
    this.chatsError,
    this.threads = const <String, Thread>{},
    this.connection = SocketState.down,
    this.typing = const <String>{},
    this.presence = const <String, Presence>{},
    this.activeChatId,
    this.statusRevision = 0,
    this.groupRevision = 0,
    this.notificationRevision = 0,
    this.notice,
    this.noticeSeq = 0,
  });

  final MUser? me;
  final List<MChat> chats;
  final bool chatsLoading;
  final bool chatsLoaded;
  final Object? chatsError;
  final Map<String, Thread> threads;
  final SocketState connection;

  /// Chat ids where the other person is typing right now.
  final Set<String> typing;
  final Map<String, Presence> presence;
  final String? activeChatId;

  /// Goes up when a status changes, so status screens reload.
  final int statusRevision;

  /// Goes up when a group changes, so group screens reload.
  final int groupRevision;

  /// Goes up when a notification arrives, so the notification list and the bell reload.
  final int notificationRevision;

  /// A short message the screens show once, for example a send that the server refused.
  final String? notice;
  final int noticeSeq;

  MessengerState copyWith({
    Object? me = _keep,
    List<MChat>? chats,
    bool? chatsLoading,
    bool? chatsLoaded,
    Object? chatsError = _keep,
    Map<String, Thread>? threads,
    SocketState? connection,
    Set<String>? typing,
    Map<String, Presence>? presence,
    Object? activeChatId = _keep,
    int? statusRevision,
    int? groupRevision,
    int? notificationRevision,
    Object? notice = _keep,
    int? noticeSeq,
  }) =>
      MessengerState(
        me: identical(me, _keep) ? this.me : me as MUser?,
        chats: chats ?? this.chats,
        chatsLoading: chatsLoading ?? this.chatsLoading,
        chatsLoaded: chatsLoaded ?? this.chatsLoaded,
        chatsError: identical(chatsError, _keep) ? this.chatsError : chatsError,
        threads: threads ?? this.threads,
        connection: connection ?? this.connection,
        typing: typing ?? this.typing,
        presence: presence ?? this.presence,
        activeChatId: identical(activeChatId, _keep) ? this.activeChatId : activeChatId as String?,
        statusRevision: statusRevision ?? this.statusRevision,
        groupRevision: groupRevision ?? this.groupRevision,
        notificationRevision: notificationRevision ?? this.notificationRevision,
        notice: identical(notice, _keep) ? this.notice : notice as String?,
        noticeSeq: noticeSeq ?? this.noticeSeq,
      );

  MChat? chatById(String? id) {
    if (id == null) return null;
    for (final c in chats) {
      if (c.id == id) return c;
    }
    return null;
  }

  Thread threadOf(String chatId) => threads[chatId] ?? const Thread();

  /// Online status of the other person in a private chat: live updates first, then what the chat list said.
  Presence presenceOf(MChat c) {
    final id = c.otherId(me?.id);
    if (id == null) return const Presence();
    final live = presence[id];
    if (live != null) return live;
    return Presence(online: c.otherUser?.online ?? c.online, lastSeen: c.otherUser?.lastSeen ?? c.lastSeen);
  }
}

final messengerProvider = NotifierProvider<MessengerController, MessengerState>(MessengerController.new);

/// Unread chats for the badge on the Messages tab: the unread messages, or one for a chat marked unread.
final messengerUnreadProvider = Provider<int>((ref) {
  return ref.watch(messengerProvider.select((s) {
    var n = 0;
    for (final c in s.chats) {
      if (c.unreadCount > 0) {
        n += c.unreadCount;
      } else if (c.markedUnread) {
        n += 1;
      }
    }
    return n;
  }));
});

/// Holds the chat list, every opened conversation and the live connection. It starts when someone signs in
/// and stops when they sign out, so nothing outlives the session.
class MessengerController extends Notifier<MessengerState> {
  MessengerSocket? _socket;
  StreamSubscription<RealtimeEvent>? _events;
  StreamSubscription<SocketState>? _states;
  Timer? _poll;
  bool _started = false;
  bool _wasDown = false;
  DateTime _lastTypingSent = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<String, Timer> _typingTimers = <String, Timer>{};
  final Map<String, Future<MMessage> Function(MMessage local)> _jobs = <String, Future<MMessage> Function(MMessage local)>{};

  MessengerRepository get _repo => ref.read(messengerRepositoryProvider);

  /// The signed-in person's id as the messenger service knows it.
  String get meId => state.me?.id ?? ref.read(sessionProvider).user?.id ?? '';

  @override
  MessengerState build() {
    ref.onDispose(_stop);
    ref.listen<bool>(sessionProvider.select((s) => s.isSignedIn), (prev, next) {
      if (next) {
        _begin();
      } else {
        _end();
      }
    });
    if (ref.read(sessionProvider).isSignedIn) Future<void>.microtask(_begin);
    return const MessengerState();
  }

  // ---------------------------------------------------------------- lifecycle

  Future<void> _begin() async {
    if (_started) return;
    _started = true;
    state = state.copyWith(chatsLoading: true);
    try {
      final me = await _repo.me();
      if (me.id.isNotEmpty) state = state.copyWith(me: me);
    } catch (e) {
      debugPrint('Messenger: could not read the profile: $e');
    }
    await refreshChats();
    if (!_started) return;
    final socket = MessengerSocket(url: AppConfig.messengerSocketUrl, tokenProvider: _token);
    _socket = socket;
    _events = socket.events.listen(_onEvent);
    _states = socket.states.listen(_onSocketState);
    socket.start();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_socket?.isOpen != true) _resync();
    });
  }

  void _end() {
    _stop();
    state = const MessengerState();
  }

  void _stop() {
    _started = false;
    _poll?.cancel();
    _poll = null;
    _events?.cancel();
    _states?.cancel();
    _events = null;
    _states = null;
    _socket?.dispose();
    _socket = null;
    for (final t in _typingTimers.values) {
      t.cancel();
    }
    _typingTimers.clear();
    _jobs.clear();
    _wasDown = false;
  }

  Future<String?> _token() async {
    final store = ref.read(tokenStoreProvider);
    await store.load();
    final s = store.current;
    if ((s.refreshToken ?? '').isNotEmpty && s.expiresWithin(const Duration(seconds: 60))) {
      await ref.read(apiClientProvider).refresh();
    }
    return store.current.accessToken;
  }

  /// Opens the live connection again straight away, for example when the app returns to the foreground.
  void reconnect() {
    if (_socket?.isOpen == true) return;
    _socket?.reconnectNow();
    _resync();
  }

  void _onSocketState(SocketState s) {
    state = state.copyWith(connection: s);
    if (s == SocketState.down) _wasDown = true;
    if (s == SocketState.open && _wasDown) {
      _wasDown = false;
      _resync();
    }
  }

  /// Catches up after a gap: the chat list, and the newest messages of the open chat.
  Future<void> _resync() async {
    await refreshChats();
    final id = state.activeChatId;
    if (id != null) await loadThread(id, silent: true);
  }

  void _notice(String message) {
    state = state.copyWith(notice: message, noticeSeq: state.noticeSeq + 1);
  }

  // ------------------------------------------------------------------- chats

  List<MChat> _sorted(List<MChat> list) {
    final out = List<MChat>.of(list);
    out.sort((a, b) {
      final x = a.sortTime;
      final y = b.sortTime;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return y.compareTo(x);
    });
    return out;
  }

  Future<void> refreshChats() async {
    try {
      final list = await _repo.chats();
      final active = state.activeChatId;
      final fixed = <MChat>[
        for (final c in list) (c.id == active && c.hasUnread) ? c.copyWith(unreadCount: 0, markedUnread: false) : c,
      ];
      state = state.copyWith(chats: _sorted(fixed), chatsLoading: false, chatsLoaded: true, chatsError: null);
    } catch (e) {
      state = state.copyWith(chatsLoading: false, chatsLoaded: true, chatsError: state.chats.isEmpty ? e : null);
    }
  }

  void _patchChat(String chatId, MChat Function(MChat c) change) {
    final list = <MChat>[for (final c in state.chats) c.id == chatId ? change(c) : c];
    state = state.copyWith(chats: _sorted(list));
  }

  /// Opens (or creates) the private chat with a person and returns its id.
  Future<String> startPrivateChat(String userId) async {
    final chat = await _repo.createPrivateChat(userId);
    await refreshChats();
    return chat.id;
  }

  Future<MGroup> createGroup({required String name, String? description, List<String> memberIds = const <String>[]}) async {
    final g = await _repo.createGroup(name: name, description: description, memberIds: memberIds);
    await refreshChats();
    return g;
  }

  Future<void> deleteChat(String chatId) async {
    await _repo.deleteChat(chatId);
    _dropChat(chatId);
  }

  void _dropChat(String chatId) {
    final threads = Map<String, Thread>.of(state.threads)..remove(chatId);
    state = state.copyWith(
      chats: state.chats.where((c) => c.id != chatId).toList(),
      threads: threads,
      activeChatId: state.activeChatId == chatId ? null : state.activeChatId,
    );
  }

  /// Removes a group chat from the list after the person left it.
  void forgetChat(String chatId) => _dropChat(chatId);

  Future<void> markUnread(String chatId) async {
    await _repo.markChatUnread(chatId);
    _patchChat(chatId, (c) => c.copyWith(markedUnread: true));
  }

  Future<void> markRead(String chatId) async {
    final c = state.chatById(chatId);
    if (c != null && c.hasUnread) _patchChat(chatId, (c) => c.copyWith(unreadCount: 0, markedUnread: false));
    try {
      await _repo.markChatRead(chatId);
    } catch (e) {
      debugPrint('Messenger: mark read failed: $e');
    }
  }

  // ----------------------------------------------------------------- threads

  void _setThread(String chatId, Thread t) {
    state = state.copyWith(threads: <String, Thread>{...state.threads, chatId: t});
  }

  /// Marks a chat as the one on screen. Its unread count clears and new messages arrive already read.
  void openChat(String chatId) {
    if (state.activeChatId == chatId) return;
    state = state.copyWith(activeChatId: chatId);
    loadThread(chatId);
    markRead(chatId);
  }

  void closeChat(String chatId) {
    if (state.activeChatId == chatId) state = state.copyWith(activeChatId: null);
  }

  /// Loads the newest messages. A [silent] load keeps what is on screen while it runs.
  Future<void> loadThread(String chatId, {bool silent = false}) async {
    final existing = state.threads[chatId];
    if (existing != null && existing.loading) return;
    final base = existing ?? const Thread();
    if (!silent) _setThread(chatId, base.copyWith(loading: base.messages.isEmpty, error: null));
    try {
      final rows = await _repo.messages(chatId, page: 0);
      final fresh = rows.reversed.toList();
      final current = state.threadOf(chatId);
      _setThread(
        chatId,
        current.copyWith(
          messages: _merge(current.messages, fresh),
          loading: false,
          hasMore: existing == null ? rows.length >= 40 : current.hasMore,
          page: existing == null ? 0 : current.page,
          error: null,
        ),
      );
    } catch (e) {
      final current = state.threadOf(chatId);
      _setThread(chatId, current.copyWith(loading: false, error: current.messages.isEmpty ? e : null));
    }
  }

  Future<void> loadOlder(String chatId) async {
    final t = state.threadOf(chatId);
    if (t.loadingOlder || !t.hasMore || t.loading) return;
    _setThread(chatId, t.copyWith(loadingOlder: true));
    try {
      final next = t.page + 1;
      final rows = await _repo.messages(chatId, page: next);
      final current = state.threadOf(chatId);
      _setThread(
        chatId,
        current.copyWith(messages: _merge(current.messages, rows.reversed.toList()), loadingOlder: false, hasMore: rows.length >= 40, page: next),
      );
    } catch (e) {
      _setThread(chatId, state.threadOf(chatId).copyWith(loadingOlder: false));
      _notice(ApiException.from(e).message);
    }
  }

  /// Puts [fresh] over [old] by id. Messages still being sent stay. A message the server no longer lists
  /// inside the fetched window (deleted for me) goes.
  List<MMessage> _merge(List<MMessage> old, List<MMessage> fresh) {
    if (fresh.isEmpty) return old;
    final byId = <String, MMessage>{};
    final oldest = fresh.first.createdAt;
    final freshIds = <String>{for (final m in fresh) m.id};
    for (final m in old) {
      if (m.isPending) {
        byId[m.id] = m;
      } else if (freshIds.contains(m.id) || m.createdAt.isBefore(oldest)) {
        byId[m.id] = m;
      }
    }
    for (final m in fresh) {
      final had = byId[m.id];
      byId[m.id] = had == null ? m : m.copyWith(mediaUrl: m.mediaUrl ?? had.mediaUrl);
    }
    final list = byId.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  void _upsert(MMessage m) {
    final t = state.threads[m.chatId];
    if (t == null) return;
    final list = List<MMessage>.of(t.messages);
    final i = list.indexWhere((x) => x.id == m.id);
    if (i >= 0) {
      list[i] = m;
    } else {
      list.add(m);
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    _setThread(m.chatId, t.copyWith(messages: list));
  }

  void _updateMessage(String chatId, String messageId, MMessage Function(MMessage m) change) {
    final t = state.threads[chatId];
    if (t == null) return;
    final list = <MMessage>[for (final m in t.messages) m.id == messageId ? change(m) : m];
    _setThread(chatId, t.copyWith(messages: list));
    final c = state.chatById(chatId);
    if (c != null && c.lastMessage?.id == messageId) {
      final updated = list.firstWhere((m) => m.id == messageId);
      _patchChat(chatId, (c) => c.copyWith(lastMessage: updated));
    }
  }

  void _noteLast(MMessage m, {bool unread = false}) {
    final c = state.chatById(m.chatId);
    if (c == null) {
      refreshChats();
      return;
    }
    _patchChat(
      m.chatId,
      (c) => c.copyWith(lastMessage: m, lastMessageAt: m.createdAt, unreadCount: unread ? c.unreadCount + 1 : null),
    );
  }

  // ----------------------------------------------------------------- sending

  MMessage _local(String chatId, {required MType type, String content = '', String? fileName, int? fileSize, MMessage? replyTo, List<String> mentions = const <String>[]}) {
    final me = state.me;
    final key = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final base = MMessage(
      id: key,
      chatId: chatId,
      senderId: meId,
      senderName: me?.name ?? ref.read(sessionProvider).user?.displayName ?? '',
      type: type,
      content: content,
      fileName: fileName,
      fileSize: fileSize,
      createdAt: DateTime.now(),
      mentionedUserIds: mentions,
      replyToMessageId: replyTo?.id,
      reply: replyTo == null
          ? null
          : MReply(
              messageId: replyTo.id,
              senderId: replyTo.senderId,
              senderName: replyTo.senderName,
              content: replyTo.deletedForEveryone ? '' : replyTo.content,
              type: replyTo.type,
              mediaUrl: replyTo.mediaUrl,
            ),
    );
    return base.asLocal(key);
  }

  /// Sends text. The message shows at once and turns into the saved one when the server answers.
  Future<void> sendText(String chatId, String text, {MMessage? replyTo, List<String> mentions = const <String>[]}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final local = _local(chatId, type: MType.text, content: trimmed, replyTo: replyTo, mentions: mentions);
    await _deliver(
      local,
      (l) => _repo.send(chatId: chatId, content: trimmed, replyToMessageId: replyTo?.id, mentionedUserIds: mentions),
    );
  }

  /// Uploads a file and sends it, with an optional caption.
  Future<void> sendFile(String chatId, LocalFile file, {String caption = '', MMessage? replyTo, List<String> mentions = const <String>[]}) async {
    final local = _local(
      chatId,
      type: guessType(file.name),
      content: caption.trim(),
      fileName: file.name,
      fileSize: file.size,
      replyTo: replyTo,
      mentions: mentions,
    );
    await _deliver(local, (l) async {
      final attachment = await _repo.uploadAttachment(chatId, file, onProgress: (sent, total) {
        if (total <= 0) return;
        _updateMessage(chatId, l.id, (m) => m.copyWith(progress: sent / total));
      });
      return _repo.send(
        chatId: chatId,
        content: caption.trim(),
        type: attachment.type == MType.other ? l.type : attachment.type,
        attachmentId: attachment.id,
        replyToMessageId: replyTo?.id,
        mentionedUserIds: mentions,
      );
    });
  }

  Future<void> _deliver(MMessage local, Future<MMessage> Function(MMessage local) job) async {
    _jobs[local.id] = job;
    _ensureThread(local.chatId);
    _upsert(local);
    _noteLast(local);
    await _run(local, job);
  }

  Future<void> _run(MMessage local, Future<MMessage> Function(MMessage local) job) async {
    try {
      final saved = await job(local);
      _jobs.remove(local.id);
      _replaceLocal(local, saved);
    } catch (e) {
      final message = ApiException.from(e).message;
      _updateMessage(local.chatId, local.id, (m) => m.copyWith(status: MDelivery.failed, clearProgress: true));
      _notice(message);
    }
  }

  void _ensureThread(String chatId) {
    if (!state.threads.containsKey(chatId)) _setThread(chatId, const Thread(hasMore: true));
  }

  void _replaceLocal(MMessage local, MMessage saved) {
    final t = state.threads[local.chatId];
    if (t == null) return;
    final list = t.messages.where((m) => m.id != local.id && m.id != saved.id).toList();
    final fixed = saved.copyWith(status: saved.status == MDelivery.sending ? MDelivery.sent : saved.status);
    list.add(fixed);
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _setThread(local.chatId, t.copyWith(messages: list));
    _noteLast(fixed);
  }

  /// Sends a failed message again.
  Future<void> retry(MMessage failed) async {
    final job = _jobs[failed.id];
    if (job == null) {
      discard(failed);
      return;
    }
    _updateMessage(failed.chatId, failed.id, (m) => m.copyWith(status: MDelivery.sending, progress: m.type == MType.text ? null : 0));
    final current = state.threadOf(failed.chatId).messages.firstWhere((m) => m.id == failed.id, orElse: () => failed);
    await _run(current, job);
  }

  /// Drops a message that never left this device.
  void discard(MMessage m) {
    _jobs.remove(m.id);
    final t = state.threads[m.chatId];
    if (t == null) return;
    _setThread(m.chatId, t.copyWith(messages: t.messages.where((x) => x.id != m.id).toList()));
  }

  // ------------------------------------------------------- message actions

  Future<void> edit(MMessage m, String text, {List<String>? mentions}) async {
    final saved = await _repo.edit(m.id, text.trim(), mentionedUserIds: mentions);
    _updateMessage(m.chatId, m.id, (old) => old.copyWith(
          content: saved.content,
          editedAt: saved.editedAt ?? DateTime.now(),
          editableUntil: saved.editableUntil,
          mentionedUserIds: saved.mentionedUserIds,
        ));
  }

  /// Reacts with [emoji], or takes the reaction back when it is the one already chosen.
  Future<void> react(MMessage m, String emoji) async {
    final mine = m.reactionOf(meId);
    final reactions = mine == emoji ? await _repo.removeReaction(m.id) : await _repo.react(m.id, emoji);
    _updateMessage(m.chatId, m.id, (old) => old.copyWith(reactions: reactions));
  }

  Future<void> deleteForMe(MMessage m) async {
    await _repo.deleteForMe(m.id);
    discard(m);
    final c = state.chatById(m.chatId);
    if (c != null && c.lastMessage?.id == m.id) refreshChats();
  }

  Future<void> deleteForEveryone(MMessage m) async {
    await _repo.deleteForEveryone(m.id);
    _updateMessage(m.chatId, m.id, (old) => old.copyWith(deleted: true, deletedForEveryone: true, content: ''));
  }

  /// Tells the other person you are typing. Sent at most every few seconds, private chats only.
  void typing(String chatId) {
    final c = state.chatById(chatId);
    if (c == null || c.isGroup) return;
    final now = DateTime.now();
    if (now.difference(_lastTypingSent) < const Duration(milliseconds: 2500)) return;
    _lastTypingSent = now;
    _socket?.sendTyping(chatId);
  }

  // ----------------------------------------------------------- live events

  void _onEvent(RealtimeEvent e) {
    final d = e.data;
    switch (e.destination) {
      case '/user/queue/messages':
        _onIncoming(MMessage.fromJson(d));
        break;
      case '/user/queue/delivery-status':
        _onDelivery(d);
        break;
      case '/user/queue/read-receipts':
        _onReceipt(d);
        break;
      case '/user/queue/typing':
        _onTyping(d);
        break;
      case '/user/queue/errors':
        _notice(strOrMessage(d['message'], 'Something went wrong'));
        break;
      case '/user/queue/reactions':
        _onReaction(d);
        break;
      case '/user/queue/status':
        state = state.copyWith(statusRevision: state.statusRevision + 1);
        break;
      case '/user/queue/groups':
        _onGroup(d);
        break;
      case '/user/queue/notifications':
        _onNotification(d);
        break;
      case '/topic/presence':
        _onPresence(d);
        break;
      default:
        break;
    }
  }

  String strOrMessage(Object? v, String fallback) {
    final s = v?.toString() ?? '';
    return s.trim().isEmpty ? fallback : s;
  }

  Future<void> _onIncoming(MMessage incoming) async {
    if (incoming.chatId.isEmpty || incoming.id.isEmpty) return;
    var m = incoming;
    if (m.hasFile && m.mediaUrl == null && !m.deleted) {
      // The push carries no signed link, so take the stored copy.
      try {
        final rows = await _repo.messages(m.chatId, size: 10);
        for (final r in rows) {
          if (r.id == m.id) m = r;
        }
      } catch (_) {
        // fall through with what the push had
      }
    }

    final mine = m.senderId == meId;
    final t = state.threads[m.chatId];
    final known = t != null && t.messages.any((x) => x.id == m.id);
    if (known) {
      _updateMessage(m.chatId, m.id, (old) => m.copyWith(mediaUrl: m.mediaUrl ?? old.mediaUrl));
      return;
    }
    // The server echoes your own message back. If it is still being sent from here, the answer to that request replaces it.
    final pendingTwin = mine &&
        t != null &&
        t.messages.any((x) => x.isPending && x.content == m.content && x.type == m.type && x.status != MDelivery.failed);
    if (pendingTwin) return;

    final active = state.activeChatId == m.chatId;
    _upsert(m);
    _noteLast(m, unread: !mine && !active);
    if (!mine && active) {
      final sent = _socket?.sendRead(m.id, m.chatId) ?? false;
      if (!sent) unawaited(_repo.markMessageRead(m.id).catchError((Object _) {}));
    }
  }

  void _onDelivery(Map<String, dynamic> d) {
    final id = d['messageId']?.toString();
    final chatId = d['chatId']?.toString();
    if (id == null || chatId == null) return;
    final stateName = (d['deliveryState'] ?? '').toString().toUpperCase();
    _updateMessage(chatId, id, (m) {
      if (stateName == 'FAILED') return m.copyWith(status: MDelivery.failed);
      if (m.status == MDelivery.sent || m.status == MDelivery.sending) return m.copyWith(status: MDelivery.delivered);
      return m;
    });
  }

  void _onReceipt(Map<String, dynamic> d) {
    final id = d['messageId']?.toString();
    final chatId = d['chatId']?.toString();
    if (id == null || chatId == null) return;
    final by = d['readBy'] is List ? (d['readBy'] as List).map((e) => e.toString()).toList() : <String>[if (d['readBy'] != null) d['readBy'].toString()];
    _updateMessage(chatId, id, (m) => m.copyWith(readBy: <String>{...m.readBy, ...by}.toList(), status: MDelivery.read));
  }

  void _onTyping(Map<String, dynamic> d) {
    final chatId = d['chatId']?.toString();
    if (chatId == null) return;
    _typingTimers[chatId]?.cancel();
    state = state.copyWith(typing: <String>{...state.typing, chatId});
    _typingTimers[chatId] = Timer(const Duration(seconds: 4), () {
      _typingTimers.remove(chatId);
      state = state.copyWith(typing: state.typing.where((c) => c != chatId).toSet());
    });
  }

  void _onReaction(Map<String, dynamic> d) {
    final id = d['messageId']?.toString();
    final chatId = d['chatId']?.toString();
    if (id == null || chatId == null) return;
    final raw = d['reactions'];
    final reactions = <String, List<String>>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is List && v.isNotEmpty) reactions[k.toString()] = v.map((e) => e.toString()).toList();
      });
    }
    _updateMessage(chatId, id, (m) => m.copyWith(reactions: reactions));
  }

  /// A notification arrived: reload the list and the bell, and say it once on screen.
  void _onNotification(Map<String, dynamic> d) {
    final n = MNotification.fromJson(d);
    state = state.copyWith(notificationRevision: state.notificationRevision + 1);
    final text = n.body.isNotEmpty ? n.body : n.title;
    if (text.isNotEmpty) _notice(text);
  }

  void _onGroup(Map<String, dynamic> d) {
    final event = (d['event'] ?? '').toString().toUpperCase();
    final chatId = d['chatId']?.toString();
    if (event == 'REMOVED' && chatId != null) {
      _dropChat(chatId);
    } else {
      refreshChats();
    }
    state = state.copyWith(groupRevision: state.groupRevision + 1);
  }

  void _onPresence(Map<String, dynamic> d) {
    final id = d['userId']?.toString();
    if (id == null) return;
    final online = (d['status'] ?? '').toString().toUpperCase() == 'ONLINE';
    state = state.copyWith(presence: <String, Presence>{...state.presence, id: Presence(online: online, lastSeen: online ? null : DateTime.now())});
  }
}

/// Picks the message type from a file name, the same way the server sorts uploads.
MType guessType(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final ext = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();
  const images = <String>{'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif', 'bmp'};
  const videos = <String>{'mp4', 'mov', 'mkv', 'webm', 'avi', '3gp', 'm4v'};
  const audio = <String>{'mp3', 'm4a', 'wav', 'ogg', 'aac', 'opus', 'amr', 'flac'};
  if (images.contains(ext)) return MType.image;
  if (videos.contains(ext)) return MType.video;
  if (audio.contains(ext)) return MType.voice;
  return MType.document;
}
