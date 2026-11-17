import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../state/messenger_providers.dart';
import '../../state/providers.dart';

/// What happened to you in groups: made an admin or the owner, demoted, added, removed. Newest first.
/// Tap one to read it and open the group's chat. The same events are also emailed.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _busy = false;

  void _reload() {
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadNotificationsProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _reload();
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open(MNotification n) async {
    final repo = ref.read(messengerRepositoryProvider);
    if (n.unread) {
      try {
        await repo.markNotificationRead(n.id);
        _reload();
      } catch (_) {
        // Opening the chat matters more than the read mark.
      }
    }
    if (!mounted) return;
    if (n.canOpenChat) context.go('/messages/chat/${Uri.encodeComponent(n.chatId!)}');
  }

  Future<void> _markAll() => _run(() => ref.read(messengerRepositoryProvider).markAllNotificationsRead());

  Future<void> _delete(MNotification n) => _run(() => ref.read(messengerRepositoryProvider).deleteNotification(n.id));

  Future<void> _clear() async {
    final ok = await confirmDialog(
      context,
      title: 'Clear all notifications?',
      message: 'Every notification in this list will be deleted.',
      confirmLabel: 'Clear all',
      danger: true,
    );
    if (!ok) return;
    await _run(() => ref.read(messengerRepositoryProvider).clearNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(notificationsProvider);
    return SubPage(
      title: 'Notifications',
      fallbackRoute: '/messages',
      actions: <Widget>[
        IconButton(tooltip: 'Mark all as read', icon: const Icon(Icons.done_all_rounded), onPressed: _busy ? null : _markAll),
        IconButton(tooltip: 'Clear all', icon: const Icon(Icons.delete_sweep_outlined), onPressed: _busy ? null : _clear),
      ],
      body: AsyncBody<List<MNotification>>(
        value: value,
        onRetry: _reload,
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications',
              message: 'You will see it here when someone makes you an admin or the owner of a group, or adds or removes you.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await ref.read(notificationsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: items.length,
              itemBuilder: (context, i) => _NotificationTile(
                item: items[i],
                onTap: () => _open(items[i]),
                onDelete: () => _delete(items[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap, required this.onDelete});

  final MNotification item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  (IconData, Color) _look(BuildContext context) {
    final pal = context.pal;
    switch (item.type) {
      case 'MADE_ADMIN':
        return (Icons.admin_panel_settings_outlined, pal.accent);
      case 'REMOVED_ADMIN':
        return (Icons.shield_outlined, pal.warn);
      case 'BECAME_OWNER':
        return (Icons.workspace_premium_outlined, pal.good);
      case 'ADDED_TO_GROUP':
        return (Icons.group_add_outlined, pal.accent);
      case 'REMOVED_FROM_GROUP':
        return (Icons.person_remove_outlined, pal.bad);
      default:
        return (Icons.notifications_none_rounded, pal.accent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final (icon, tint) = _look(context);
    final unread = item.unread;
    return ListTile(
      onTap: onTap,
      tileColor: unread ? pal.accent.op(0.06) : null,
      leading: CircleAvatar(backgroundColor: tint.op(0.14), foregroundColor: tint, child: Icon(icon)),
      title: Text(item.title, style: TextStyle(fontWeight: unread ? FontWeight.w800 : FontWeight.w600)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text('${item.body}\n${timeAgo(item.createdAt)}', style: TextStyle(color: context.mutedColor, height: 1.35)),
      ),
      isThreeLine: true,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        if (unread) Container(width: 10, height: 10, decoration: BoxDecoration(color: pal.accent, shape: BoxShape.circle)),
        PopupMenuButton<String>(
          tooltip: 'More',
          onSelected: (v) {
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
          ],
        ),
      ]),
    );
  }
}
