import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../core/network/messenger_socket.dart';
import '../../data/models/file_ref.dart';
import '../../data/models/messenger_models.dart';
import '../../data/repositories/messenger_repository.dart';
import '../../state/messenger_controller.dart';
import '../../state/messenger_providers.dart';
import 'emoji_panel.dart';
import 'file_actions.dart';
import 'message_bubble.dart';
import 'message_composer.dart';
import 'messenger_common.dart';

/// One open conversation: header, the messages and the message box.
class ConversationPane extends ConsumerStatefulWidget {
  const ConversationPane({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ConversationPane> createState() => _ConversationPaneState();
}

class _Row {
  const _Row.day(this.day)
      : message = null,
        gap = 0,
        showName = false;
  const _Row.message(this.message, {this.gap = 8, this.showName = false}) : day = null;

  final DateTime? day;
  final MMessage? message;
  final double gap;
  final bool showName;
}

class _ConversationPaneState extends ConsumerState<ConversationPane> with WidgetsBindingObserver {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  late final MessengerController _controller;
  MMessage? _replyTo;
  MMessage? _editing;
  bool _searching = false;
  bool _showJump = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ref.read(messengerProvider.notifier);
    _scroll.addListener(_onScroll);
    // Opening changes provider state, which is not allowed while the tree is being built.
    Future<void>.microtask(() {
      if (mounted) _controller.openChat(widget.chatId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final id = widget.chatId;
    final c = _controller;
    Future<void>.microtask(() => c.closeChat(id));
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.reconnect();
      _controller.markRead(widget.chatId);
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final far = p.pixels > 500;
    if (far != _showJump) setState(() => _showJump = far);
    if (p.pixels >= p.maxScrollExtent - 300) _controller.loadOlder(widget.chatId);
  }

  void _toLatest() {
    if (_scroll.hasClients) _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  // ----------------------------------------------------------------- sending

  void _send(String text, List<String> mentions) {
    _controller.sendText(widget.chatId, text, replyTo: _replyTo, mentions: mentions);
    setState(() => _replyTo = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _toLatest());
  }

  void _sendFiles(List<LocalFile> files, String caption) {
    var first = true;
    for (final f in files) {
      _controller.sendFile(widget.chatId, f, caption: first ? caption : '', replyTo: first ? _replyTo : null);
      first = false;
    }
    setState(() => _replyTo = null);
    WidgetsBinding.instance.addPostFrameCallback((_) => _toLatest());
  }

  Future<void> _saveEdit(String text, List<String> mentions) async {
    final m = _editing;
    if (m == null) return;
    setState(() => _editing = null);
    try {
      await _controller.edit(m, text, mentions: mentions);
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  // ----------------------------------------------------------------- actions

  bool _canEdit(MMessage m, String myId) {
    final until = m.editableUntil;
    return m.senderId == myId && !m.isPending && !(m.deleted || m.deletedForEveryone) && until != null && until.isAfter(DateTime.now());
  }

  Future<void> _showActions(MMessage m) async {
    final myId = _controller.meId;
    final mine = m.senderId == myId;
    final deleted = m.deleted || m.deletedForEveryone;
    final editable = _canEdit(m, myId);
    final editHours = ref.read(editWindowProvider).valueOrNull ?? 1;
    final fileUrl = resolveMedia(m.mediaUrl);

    if (m.status == MDelivery.failed && m.isPending) {
      final pick = await showModalBottomSheet<String>(
        context: context,
        useSafeArea: true,
        builder: (ctx) => SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            ListTile(leading: const Icon(Icons.refresh_rounded), title: const Text('Try again'), onTap: () => Navigator.of(ctx).pop('retry')),
            ListTile(leading: Icon(Icons.delete_outline_rounded, color: context.pal.bad), title: const Text('Discard'), onTap: () => Navigator.of(ctx).pop('discard')),
          ]),
        ),
      );
      if (pick == 'retry') _controller.retry(m);
      if (pick == 'discard') _controller.discard(m);
      return;
    }
    if (m.isPending) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (!deleted)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      for (final e in kQuickReactions)
                        InkWell(
                          borderRadius: BorderRadius.circular(99),
                          onTap: () => Navigator.of(ctx).pop('react:$e'),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: m.reactionOf(myId) == e ? BoxDecoration(color: ctx.pal.accentSoft, shape: BoxShape.circle) : null,
                            child: Text(e, style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                      IconButton(tooltip: 'More emoji', onPressed: () => Navigator.of(ctx).pop('react-more'), icon: const Icon(Icons.add_circle_outline_rounded)),
                    ],
                  ),
                ),
              if (!deleted) ListTile(leading: const Icon(Icons.reply_rounded), title: const Text('Reply'), onTap: () => Navigator.of(ctx).pop('reply')),
              if (!deleted && m.content.trim().isNotEmpty) ListTile(leading: const Icon(Icons.copy_rounded), title: const Text('Copy text'), onTap: () => Navigator.of(ctx).pop('copy')),
              if (!deleted && m.hasFile && fileUrl != null)
                ListTile(leading: const Icon(Icons.download_rounded), title: const Text('Download'), onTap: () => Navigator.of(ctx).pop('save')),
              if (mine && !deleted)
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: editable ? null : ctx.mutedColor),
                  title: Text(m.hasFile ? 'Edit caption' : 'Edit', style: editable ? null : TextStyle(color: ctx.mutedColor)),
                  subtitle: editable
                      ? null
                      : Text(editHours <= 0 ? 'Editing messages is turned off' : 'A message can be edited for $editHours ${editHours == 1 ? 'hour' : 'hours'} after it is sent'),
                  onTap: editable ? () => Navigator.of(ctx).pop('edit') : null,
                ),
              ListTile(leading: const Icon(Icons.visibility_off_outlined), title: const Text('Delete for me'), onTap: () => Navigator.of(ctx).pop('delete-me')),
              if (mine && !deleted)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded, color: ctx.pal.bad),
                  title: Text('Delete for everyone', style: TextStyle(color: ctx.pal.bad)),
                  onTap: () => Navigator.of(ctx).pop('delete-all'),
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
    if (action == null || !mounted) return;

    try {
      if (action.startsWith('react:')) {
        await _controller.react(m, action.substring(6));
      } else if (action == 'react-more') {
        final e = await pickEmoji(context);
        if (e != null) await _controller.react(m, e);
      } else if (action == 'reply') {
        setState(() {
          _editing = null;
          _replyTo = m;
        });
      } else if (action == 'copy') {
        await Clipboard.setData(ClipboardData(text: m.content));
        if (mounted) showToast(context, 'Copied');
      } else if (action == 'save') {
        await saveFile(context, ref, FileRef.fromMessage(m, fileUrl));
      } else if (action == 'edit') {
        setState(() {
          _replyTo = null;
          _editing = m;
        });
      } else if (action == 'delete-me') {
        await _controller.deleteForMe(m);
      } else if (action == 'delete-all') {
        final ok = await confirmDialog(context, title: 'Delete for everyone?', message: 'Everyone in this chat will see that the message was deleted.', confirmLabel: 'Delete', danger: true);
        if (ok) await _controller.deleteForEveryone(m);
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _quickReact(MMessage m, String emoji) async {
    try {
      await _controller.react(m, emoji);
    } catch (e) {
      if (!mounted) return;
      showApiError(context, e);
    }
  }

  Future<void> _chatMenu(MChat chat) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(chat.isGroup ? 'Group info' : 'View profile'),
            onTap: () => Navigator.of(ctx).pop('info'),
          ),
          ListTile(leading: const Icon(Icons.mark_chat_unread_outlined), title: const Text('Mark as unread'), onTap: () => Navigator.of(ctx).pop('unread')),
          if (!chat.isGroup)
            ListTile(leading: Icon(Icons.delete_outline_rounded, color: ctx.pal.bad), title: Text('Delete chat', style: TextStyle(color: ctx.pal.bad)), onTap: () => Navigator.of(ctx).pop('delete')),
        ]),
      ),
    );
    if (action == null || !mounted) return;
    try {
      if (action == 'info') {
        _openInfo(chat);
      } else if (action == 'unread') {
        await _controller.markUnread(chat.id);
        if (mounted && !context.isWide) context.go('/messages');
      } else if (action == 'delete') {
        final ok = await confirmDialog(context, title: 'Delete this chat?', message: 'It is removed from your list. The other person keeps their copy.', confirmLabel: 'Delete', danger: true);
        if (!ok) return;
        await _controller.deleteChat(chat.id);
        if (mounted) context.go('/messages');
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  void _openInfo(MChat chat) {
    if (chat.isGroup && chat.groupId != null) {
      context.push('/messages/group/${Uri.encodeComponent(chat.groupId ?? '')}');
    } else {
      final id = chat.otherId(_controller.meId);
      if (id != null) context.push('/people/${Uri.encodeComponent(id)}');
    }
  }

  // ------------------------------------------------------------------ layout

  List<_Row> _rows(List<MMessage> messages, bool group, String myId) {
    final rows = <_Row>[];
    MMessage? prev;
    for (final m in messages) {
      if (prev == null || !sameDay(prev.createdAt, m.createdAt)) rows.add(_Row.day(m.createdAt));
      final sameRun = prev != null && sameDay(prev.createdAt, m.createdAt) && prev.senderId == m.senderId && m.createdAt.difference(prev.createdAt).inMinutes < 5;
      rows.add(_Row.message(m, gap: sameRun ? 2 : 10, showName: group && m.senderId != myId && !sameRun));
      prev = m;
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(messengerProvider);
    ref.watch(editWindowProvider); // keeps the edit window loaded so the Edit item can explain itself
    final chat = s.chatById(widget.chatId);
    final pal = context.pal;

    if (chat == null) {
      if (!s.chatsLoaded) return const LoadingState();
      return EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'This chat is not available',
        message: 'It may have been deleted, or you may have left the group.',
        actionLabel: 'Back to messages',
        onAction: () => context.go('/messages'),
      );
    }

    final myId = s.me?.id ?? _controller.meId;
    final thread = s.threadOf(chat.id);
    final query = _searching ? _search.text.trim().toLowerCase() : '';
    final shown = query.isEmpty ? thread.messages : thread.messages.where((m) => m.content.toLowerCase().contains(query) || (m.fileName ?? '').toLowerCase().contains(query)).toList();
    final rows = _rows(shown, chat.isGroup, myId);

    final presence = s.presenceOf(chat);
    final typing = s.typing.contains(chat.id);
    final subtitle = typing
        ? 'typing...'
        : (chat.isGroup ? '${chat.memberCount} members' : presenceLabel(presence));

    List<MentionTarget> mentionTargets = const <MentionTarget>[];
    if (chat.isGroup && chat.groupId != null) {
      final g = ref.watch(groupDetailsProvider(chat.groupId ?? '')).valueOrNull;
      if (g != null) {
        mentionTargets = <MentionTarget>[
          for (final mem in g.members)
            if (mem.id != myId) MentionTarget(id: mem.id, name: mem.name, photo: mem.profilePictureUrl),
        ];
      }
    }

    return Column(
      children: <Widget>[
        _header(context, chat, subtitle, typing || presence.online),
        if (s.connection != SocketState.open && s.chatsLoaded)
          Container(
            width: double.infinity,
            color: pal.warn.op(0.16),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 14),
            child: Text(
              s.connection == SocketState.connecting ? 'Connecting...' : 'Offline. Messages will update when the connection returns.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: pal.ink2, fontWeight: FontWeight.w600),
            ),
          ),
        Expanded(
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: _messages(context, chat, thread, rows, myId, query)),
              if (_showJump)
                Positioned(
                  right: 14,
                  bottom: 12,
                  child: FloatingActionButton.small(heroTag: 'jump-${chat.id}', onPressed: _toLatest, child: const Icon(Icons.keyboard_arrow_down_rounded)),
                ),
            ],
          ),
        ),
        MessageComposer(
          onSend: _send,
          onSendFiles: _sendFiles,
          onTyping: () => _controller.typing(chat.id),
          replyTo: _replyTo,
          replyAuthor: _replyTo == null ? null : (_replyTo!.senderId == myId ? 'yourself' : _replyTo!.senderName),
          editing: _editing,
          onCancelContext: () => setState(() {
            _replyTo = null;
            _editing = null;
          }),
          onSaveEdit: _saveEdit,
          mentionTargets: mentionTargets,
        ),
      ],
    );
  }

  Widget _header(BuildContext context, MChat chat, String subtitle, bool highlight) {
    final pal = context.pal;
    if (_searching) {
      return Material(
        color: pal.panel,
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.borderColor))),
            child: Row(children: <Widget>[
              IconButton(tooltip: 'Close search', onPressed: () => setState(() {
                    _searching = false;
                    _search.clear();
                  }), icon: const Icon(Icons.arrow_back_rounded)),
              Expanded(
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(hintText: 'Search in this chat', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
                ),
              ),
              if (_search.text.isNotEmpty) IconButton(tooltip: 'Clear', onPressed: () => setState(_search.clear), icon: const Icon(Icons.close_rounded)),
            ]),
          ),
        ),
      );
    }
    return Material(
      color: pal.panel,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.borderColor))),
          child: Row(
            children: <Widget>[
              if (!context.isWide) IconButton(tooltip: 'Back', onPressed: () => context.go('/messages'), icon: const Icon(Icons.arrow_back_rounded)),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openInfo(chat),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(children: <Widget>[
                      MessengerAvatar(initials: chat.initials, imageUrl: chat.photo, size: 42, group: chat.isGroup),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(chat.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: highlight ? pal.good : context.mutedColor, fontWeight: highlight ? FontWeight.w700 : FontWeight.w500)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              IconButton(tooltip: 'Search', onPressed: () => setState(() => _searching = true), icon: const Icon(Icons.search_rounded)),
              IconButton(tooltip: 'More', onPressed: () => _chatMenu(chat), icon: const Icon(Icons.more_vert_rounded)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messages(BuildContext context, MChat chat, Thread thread, List<_Row> rows, String myId, String query) {
    if (thread.loading && thread.messages.isEmpty) return const LoadingState();
    if (thread.error != null && thread.messages.isEmpty) {
      return ErrorState(error: thread.error ?? 'Error', onRetry: () => _controller.loadThread(chat.id));
    }
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            query.isNotEmpty ? 'No messages match "$query".' : 'No messages yet. Say hello.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.mutedColor, fontSize: 15),
          ),
        ),
      );
    }
    final extra = thread.hasMore && query.isEmpty ? 1 : 0;
    return ListView.builder(
      controller: _scroll,
      reverse: true,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      itemCount: rows.length + extra,
      itemBuilder: (context, i) {
        if (i >= rows.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: thread.loadingOlder
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(onPressed: () => _controller.loadOlder(chat.id), child: const Text('Load earlier messages')),
            ),
          );
        }
        final row = rows[rows.length - 1 - i];
        if (row.day != null) return _DayChip(label: dayLabel(row.day ?? DateTime.now()));
        final m = row.message;
        if (m == null) return const SizedBox.shrink();
        final mine = m.senderId == myId;
        return Padding(
          padding: EdgeInsets.only(top: row.gap),
          child: Align(
            alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
            child: MessageBubble(
              message: m,
              mine: mine,
              myId: myId,
              showName: row.showName,
              highlight: query,
              onLongPress: () => _showActions(m),
              onReact: (e) => _quickReact(m, e),
              onRetry: () => _controller.retry(m),
              onOpenInvite: (code) => context.push('/messages/join/${Uri.encodeComponent(code)}'),
            ),
          ),
        );
      },
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: context.pal.panel2, borderRadius: BorderRadius.circular(99)),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.mutedColor)),
        ),
      ),
    );
  }
}
