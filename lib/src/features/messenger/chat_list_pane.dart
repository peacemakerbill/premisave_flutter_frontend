import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../core/network/messenger_socket.dart';
import '../../data/models/messenger_models.dart';
import '../../state/messenger_controller.dart';
import '../../state/messenger_providers.dart';
import 'messenger_common.dart';
import 'status_tab.dart';

enum _Section { chats, status }

/// The list of chats with a Status tab beside it. On a wide screen it sits to the left of the open chat.
class ChatListPane extends ConsumerStatefulWidget {
  const ChatListPane({super.key, this.selectedChatId});

  final String? selectedChatId;

  @override
  ConsumerState<ChatListPane> createState() => _ChatListPaneState();
}

class _ChatListPaneState extends ConsumerState<ChatListPane> {
  final TextEditingController _search = TextEditingController();
  _Section _section = _Section.chats;
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openChat(MChat chat) => context.go('/messages/chat/${Uri.encodeComponent(chat.id)}');

  Future<void> _chatMenu(MChat chat) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          ListTile(
            leading: Icon(chat.hasUnread ? Icons.mark_chat_read_outlined : Icons.mark_chat_unread_outlined),
            title: Text(chat.hasUnread ? 'Mark as read' : 'Mark as unread'),
            onTap: () => Navigator.of(ctx).pop('toggle'),
          ),
          if (!chat.isGroup)
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: ctx.pal.bad),
              title: Text('Delete chat', style: TextStyle(color: ctx.pal.bad)),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
        ]),
      ),
    );
    if (action == null || !mounted) return;
    final controller = ref.read(messengerProvider.notifier);
    try {
      if (action == 'toggle') {
        if (chat.hasUnread) {
          await controller.markRead(chat.id);
        } else {
          await controller.markUnread(chat.id);
        }
      } else if (action == 'delete') {
        final ok = await confirmDialog(context, title: 'Delete this chat?', message: 'It is removed from your list. The other person keeps their copy.', confirmLabel: 'Delete', danger: true);
        if (!ok) return;
        await controller.deleteChat(chat.id);
        if (mounted && widget.selectedChatId == chat.id) context.go('/messages');
      }
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _newMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          ListTile(leading: const Icon(Icons.person_add_alt_1_outlined), title: const Text('New chat'), onTap: () => Navigator.of(ctx).pop('chat')),
          ListTile(leading: const Icon(Icons.group_add_outlined), title: const Text('New group'), onTap: () => Navigator.of(ctx).pop('group')),
          ListTile(leading: const Icon(Icons.qr_code_scanner_rounded), title: const Text('Join with a link or QR code'), onTap: () => Navigator.of(ctx).pop('join')),
        ]),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 'chat') context.push('/messages/new');
    if (action == 'group') context.push('/messages/new-group');
    if (action == 'join') context.push('/messages/join');
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final s = ref.watch(messengerProvider);
    final unread = ref.watch(messengerUnreadProvider);
    final query = _search.text.trim().toLowerCase();

    final chats = query.isEmpty
        ? s.chats
        : s.chats.where((c) => c.title.toLowerCase().contains(query) || (c.lastMessage?.content.toLowerCase().contains(query) ?? false)).toList();

    return Material(
      color: pal.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: _section == _Section.chats
            ? FloatingActionButton(heroTag: 'new-chat', tooltip: 'New chat or group', onPressed: _newMenu, child: const Icon(Icons.edit_outlined))
            : FloatingActionButton(heroTag: 'new-status', tooltip: 'Add status', onPressed: () => context.push('/messages/status/new'), child: const Icon(Icons.add_a_photo_outlined)),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: <Widget>[
              _header(context, s, unread),
              _sectionTabs(context, unread),
              Expanded(
                child: _section == _Section.status
                    ? const StatusTab()
                    : _chats(context, s, chats, query),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, MessengerState s, int unread) {
    final pal = context.pal;
    if (_searching) {
      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(children: <Widget>[
          IconButton(
            tooltip: 'Close search',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => setState(() {
              _searching = false;
              _search.clear();
            }),
          ),
          Expanded(
            child: TextField(
              controller: _search,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Search chats', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
            ),
          ),
          if (_search.text.isNotEmpty) IconButton(tooltip: 'Clear', icon: const Icon(Icons.close_rounded), onPressed: () => setState(_search.clear)),
        ]),
      );
    }
    final dotColor = s.connection == SocketState.open ? pal.good : (s.connection == SocketState.connecting ? pal.warn : pal.bad);
    final dotLabel = s.connection == SocketState.open ? 'Live' : (s.connection == SocketState.connecting ? 'Connecting' : 'Offline');
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 6, 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Row(children: <Widget>[
              Text('Messages', style: context.display(size: 24, weight: FontWeight.w800, spacing: -0.5)),
              const SizedBox(width: 10),
              Tooltip(
                message: dotLabel,
                child: GestureDetector(
                  onTap: s.connection == SocketState.open ? null : () => ref.read(messengerProvider.notifier).reconnect(),
                  child: Container(width: 10, height: 10, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
                ),
              ),
            ]),
          ),
          const _NotificationsBell(),
          IconButton(tooltip: 'Search', icon: const Icon(Icons.search_rounded), onPressed: () => setState(() => _searching = true)),
          IconButton(tooltip: 'Join a group', icon: const Icon(Icons.qr_code_scanner_rounded), onPressed: () => context.push('/messages/join')),
          IconButton(tooltip: 'Messenger settings', icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/messages/settings')),
        ],
      ),
    );
  }

  Widget _sectionTabs(BuildContext context, int unread) {
    final pal = context.pal;
    Widget tab(_Section section, String label, {int badge = 0}) {
      final on = _section == section;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(context.radius(12)),
          onTap: () => setState(() => _section = section),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? pal.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(context.radius(12)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: on ? pal.ink : context.mutedColor)),
              if (badge > 0) ...<Widget>[const SizedBox(width: 8), CountBadge(badge)],
            ]),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(children: <Widget>[
        tab(_Section.chats, 'Chats', badge: unread),
        const SizedBox(width: 6),
        tab(_Section.status, 'Status'),
      ]),
    );
  }

  Widget _chats(BuildContext context, MessengerState s, List<MChat> chats, String query) {
    final controller = ref.read(messengerProvider.notifier);
    if (s.chatsLoading && !s.chatsLoaded) return const SkeletonList(kind: SkeletonKind.row, count: 7);
    if (s.chatsError != null && !s.chatsLoaded) {
      return ErrorState(error: s.chatsError ?? 'Error', onRetry: controller.refreshChats);
    }
    if (chats.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.refreshChats,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(
              height: 420,
              child: query.isNotEmpty
                  ? const EmptyState(icon: Icons.search_off_rounded, title: 'No chats match your search')
                  : EmptyState(
                      icon: Icons.forum_outlined,
                      title: 'No conversations yet',
                      message: 'Start a chat with another member, create a group, or join one with a link.',
                      actionLabel: 'Start a chat',
                      onAction: () => context.push('/messages/new'),
                    ),
            ),
          ],
        ),
      );
    }
    final myId = s.me?.id ?? controller.meId;
    return RefreshIndicator(
      onRefresh: controller.refreshChats,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: chats.length,
        itemBuilder: (context, i) {
          final chat = chats[i];
          return _ChatTile(
            chat: chat,
            myId: myId,
            selected: chat.id == widget.selectedChatId,
            typing: s.typing.contains(chat.id),
            online: !chat.isGroup && s.presenceOf(chat).online,
            onTap: () => _openChat(chat),
            onLongPress: () => _chatMenu(chat),
          );
        },
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.chat,
    required this.myId,
    required this.selected,
    required this.typing,
    required this.online,
    required this.onTap,
    required this.onLongPress,
  });

  final MChat chat;
  final String myId;
  final bool selected;
  final bool typing;
  final bool online;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final last = chat.lastMessage;
    final unread = chat.hasUnread;
    final mine = last != null && last.senderId == myId;

    Widget preview;
    if (typing) {
      preview = Text('typing...', maxLines: 1, style: TextStyle(color: pal.good, fontWeight: FontWeight.w700, fontSize: 13.5));
    } else if (last == null) {
      preview = Text(chat.isGroup ? '${chat.memberCount} members' : 'No messages yet', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.mutedColor, fontSize: 13.5));
    } else {
      final text = previewOf(last);
      final prefix = chat.isGroup && !mine && last.senderName.isNotEmpty ? '${last.senderName.split(' ').first}: ' : '';
      preview = Row(children: <Widget>[
        if (mine && last.status != MDelivery.sending) ...<Widget>[
          DeliveryTicks(status: last.status, size: 16),
          const SizedBox(width: 4),
        ],
        if (last.hasFile && !(last.deleted || last.deletedForEveryone)) ...<Widget>[
          Icon(typeIcon(last.type), size: 15, color: context.mutedColor),
          const SizedBox(width: 3),
        ],
        Expanded(
          child: Text(
            '$prefix$text',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: unread ? pal.ink : context.mutedColor, fontSize: 13.5, fontWeight: unread ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
      ]);
    }

    return Material(
      color: selected ? pal.accentSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: <Widget>[
              MessengerAvatar(initials: chat.initials, imageUrl: chat.photo, size: 52, online: online, group: chat.isGroup),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(children: <Widget>[
                      if (chat.isGroup) ...<Widget>[Icon(Icons.groups_rounded, size: 16, color: context.mutedColor), const SizedBox(width: 4)],
                      Expanded(child: Text(chat.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15.5, fontWeight: unread ? FontWeight.w800 : FontWeight.w700))),
                      const SizedBox(width: 8),
                      Text(chatStamp(chat.sortTime), style: TextStyle(fontSize: 12, color: unread ? pal.accent : context.mutedColor, fontWeight: unread ? FontWeight.w800 : FontWeight.w500)),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: <Widget>[
                      Expanded(child: preview),
                      if (unread) ...<Widget>[const SizedBox(width: 8), CountBadge(chat.unreadCount, dot: chat.unreadCount == 0)],
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// The bell in the header: opens the notifications and shows how many are unread.
class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsProvider).valueOrNull ?? 0;
    return IconButton(
      tooltip: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
      onPressed: () => context.push('/messages/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: Icon(unread > 0 ? Icons.notifications_rounded : Icons.notifications_none_rounded),
      ),
    );
  }
}
