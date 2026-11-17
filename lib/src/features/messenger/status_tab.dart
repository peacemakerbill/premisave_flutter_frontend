import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../state/messenger_controller.dart';
import '../../state/messenger_providers.dart';
import 'messenger_common.dart';

/// The Status tab: your own updates on top, then the people who posted recently.
class StatusTab extends ConsumerWidget {
  const StatusTab({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(statusFeedProvider);
    ref.invalidate(myStatusesProvider);
    await Future.wait<Object?>(<Future<Object?>>[ref.read(statusFeedProvider.future), ref.read(myStatusesProvider.future)]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(myStatusesProvider);
    final feed = ref.watch(statusFeedProvider);
    final me = ref.watch(messengerProvider.select((s) => s.me));

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        children: <Widget>[
          _MyStatusTile(me: me, posts: mine.valueOrNull ?? const <StatusPost>[]),
          const SectionHeader('Recent updates', padding: EdgeInsets.fromLTRB(18, 14, 18, 6)),
          feed.when(
            loading: () => const SkeletonList(kind: SkeletonKind.row, count: 4, shrink: true),
            error: (e, _) => SizedBox(height: 360, child: ErrorState(error: e, onRetry: () => ref.invalidate(statusFeedProvider))),
            data: (groups) {
              if (groups.isEmpty) {
                return const SizedBox(
                  height: 300,
                  child: EmptyState(icon: Icons.auto_awesome_outlined, title: 'No updates yet', message: 'Statuses from other members show up here for a day.'),
                );
              }
              final sorted = List<StatusGroup>.of(groups)
                ..sort((a, b) {
                  if ((a.unseenCount > 0) != (b.unseenCount > 0)) return a.unseenCount > 0 ? -1 : 1;
                  final at = a.latestAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  final bt = b.latestAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return bt.compareTo(at);
                });
              return Column(children: <Widget>[for (final g in sorted) _FeedTile(group: g)]);
            },
          ),
          const SizedBox(height: 6),
          ListTile(
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: context.pal.panel2, shape: BoxShape.circle),
              child: Icon(Icons.history_rounded, color: context.pal.ink2),
            ),
            title: const Text('Past statuses', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Your expired updates and how they did'),
            onTap: () => context.push('/messages/status/past'),
          ),
        ],
      ),
    );
  }
}

/// A coloured ring that says whether there is something new to watch.
class StatusRing extends StatelessWidget {
  const StatusRing({super.key, required this.child, this.unseen = false, this.size = 54, this.segments = 1});

  final Widget child;
  final bool unseen;
  final double size;
  final int segments;

  @override
  Widget build(BuildContext context) {
    final color = unseen ? context.pal.accent : context.pal.line2;
    return Container(
      width: size + 8,
      height: size + 8,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: unseen ? 2.5 : 1.5)),
      child: ClipOval(child: SizedBox(width: size, height: size, child: child)),
    );
  }
}

class _MyStatusTile extends StatelessWidget {
  const _MyStatusTile({required this.me, required this.posts});

  final MUser? me;
  final List<StatusPost> posts;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final has = posts.isNotEmpty;
    final avatar = MessengerAvatar(initials: me?.initials ?? 'P', imageUrl: me?.profilePictureUrl, size: 54);
    final latest = has ? posts.map((p) => p.createdAt).whereType<DateTime>().fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a) : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          has ? StatusRing(unseen: true, child: avatar) : Padding(padding: const EdgeInsets.all(4), child: avatar),
          Positioned(
            right: has ? 2 : 0,
            bottom: has ? 2 : 0,
            child: Container(
              decoration: BoxDecoration(color: pal.accent, shape: BoxShape.circle, border: Border.all(color: pal.bg, width: 2)),
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.add_rounded, size: 16, color: pal.accentInk),
            ),
          ),
        ],
      ),
      title: const Text('My status', style: TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(has ? '${posts.length} ${posts.length == 1 ? 'update' : 'updates'}, ${timeAgo(latest)}' : 'Tap to add a status update'),
      trailing: has ? IconButton(tooltip: 'Add status', icon: const Icon(Icons.add_circle_outline_rounded), onPressed: () => context.push('/messages/status/new')) : null,
      onTap: () => has ? context.push('/messages/status/mine') : context.push('/messages/status/new'),
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({required this.group});

  final StatusGroup group;

  @override
  Widget build(BuildContext context) {
    final u = group.user;
    final unseen = group.unseenCount > 0;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: StatusRing(unseen: unseen, child: MessengerAvatar(initials: u.initials, imageUrl: u.profilePictureUrl, size: 54)),
      title: Text(u.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: unseen ? FontWeight.w800 : FontWeight.w600)),
      subtitle: Text('${group.statuses.length} ${group.statuses.length == 1 ? 'update' : 'updates'}, ${timeAgo(group.latestAt)}'),
      onTap: () => context.push('/messages/status/user/${Uri.encodeComponent(u.id)}'),
    );
  }
}
