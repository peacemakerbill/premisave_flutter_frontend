import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../state/messenger_providers.dart';
import '../../state/providers.dart';
import 'messenger_common.dart';

/// Who viewed, liked, reacted to and commented on one of your statuses.
class StatusInsightsScreen extends ConsumerWidget {
  const StatusInsightsScreen({super.key, required this.statusId});

  final String statusId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(statusInsightsProvider(statusId));
    return SubPage(
      title: 'Status activity',
      fallbackRoute: '/messages',
      body: AsyncBody<StatusInsights>(
        value: value,
        onRetry: () => ref.invalidate(statusInsightsProvider(statusId)),
        builder: (i) => DefaultTabController(
          length: 4,
          child: Column(
            children: <Widget>[
              TabBar(
                tabs: <Widget>[
                  Tab(text: 'Views ${i.viewers.length}'),
                  Tab(text: 'Likes ${i.likers.length}'),
                  Tab(text: 'Reactions ${i.reactors.length}'),
                  Tab(text: 'Comments ${i.comments.length}'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _people(context, i.viewers, 'Nobody has viewed this yet.'),
                    _people(context, i.likers, 'No likes yet.'),
                    _people(context, i.reactors, 'No reactions yet.'),
                    _comments(context, ref, i),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _people(BuildContext context, List<StatusPerson> list, String empty) {
    if (list.isEmpty) return EmptyState(icon: Icons.visibility_off_outlined, title: empty);
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, i) {
        final p = list[i];
        return ListTile(
          leading: MessengerAvatar(initials: p.user.initials, imageUrl: p.user.profilePictureUrl, size: 42),
          title: Text(p.user.name, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: p.at == null ? null : Text(timeAgo(p.at)),
          trailing: p.emoji == null ? null : Text(p.emoji ?? '', style: const TextStyle(fontSize: 24)),
        );
      },
    );
  }

  Widget _comments(BuildContext context, WidgetRef ref, StatusInsights i) {
    if (i.comments.isEmpty) return const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'No comments yet.');
    return ListView.builder(
      itemCount: i.comments.length,
      itemBuilder: (context, n) {
        final c = i.comments[n];
        final a = c.author;
        return ListTile(
          leading: MessengerAvatar(initials: a?.initials ?? 'P', imageUrl: a?.profilePictureUrl, size: 42),
          title: Text(a?.name ?? 'Member', style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text('${c.content}\n${timeAgo(c.createdAt)}', style: TextStyle(height: 1.35, color: context.pal.ink2)),
          isThreeLine: true,
          trailing: c.canDelete
              ? IconButton(
                  tooltip: 'Delete comment',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: () async {
                    try {
                      await ref.read(messengerRepositoryProvider).deleteStatusComment(statusId, c.id);
                      ref.invalidate(statusInsightsProvider(statusId));
                    } catch (e) {
                      if (context.mounted) showApiError(context, e);
                    }
                  },
                )
              : null,
        );
      },
    );
  }
}
