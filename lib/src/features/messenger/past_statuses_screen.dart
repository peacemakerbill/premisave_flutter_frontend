import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../state/providers.dart';
import 'messenger_common.dart';

/// Your expired statuses, newest first, with how many people saw and answered each.
class PastStatusesScreen extends ConsumerStatefulWidget {
  const PastStatusesScreen({super.key});

  @override
  ConsumerState<PastStatusesScreen> createState() => _PastStatusesScreenState();
}

class _PastStatusesScreenState extends ConsumerState<PastStatusesScreen> {
  final List<StatusPost> _items = <StatusPost>[];
  int _page = 0;
  bool _more = false;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(first: true);
  }

  Future<void> _load({bool first = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref.read(messengerRepositoryProvider).myPastStatuses(page: first ? 0 : _page + 1);
      if (!mounted) return;
      setState(() {
        if (first) _items.clear();
        _items.addAll(page.items);
        _page = page.page;
        _more = page.hasMore;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading && _items.isEmpty) {
      body = const SkeletonList(kind: SkeletonKind.row, count: 5);
    } else if (_error != null && _items.isEmpty) {
      body = ErrorState(error: _error ?? 'Error', onRetry: () => _load(first: true));
    } else if (_items.isEmpty) {
      body = const EmptyState(icon: Icons.history_rounded, title: 'No past statuses', message: 'Statuses you post appear here after they expire.');
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _items.length + (_more ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return Padding(
              padding: const EdgeInsets.all(14),
              child: Center(child: _loading ? const CircularProgressIndicator() : TextButton(onPressed: _load, child: const Text('Load more'))),
            );
          }
          return _PastTile(post: _items[i]);
        },
      );
    }
    return SubPage(title: 'Past statuses', fallbackRoute: '/messages', body: body);
  }
}

class _PastTile extends StatelessWidget {
  const _PastTile({required this.post});

  final StatusPost post;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final s = post.stats;
    final summary = post.kind == StatusKind.text ? post.text : (post.caption.isNotEmpty ? post.caption : (post.fileName ?? 'Media status'));
    final Widget thumb;
    if (post.kind == StatusKind.text) {
      thumb = Container(
        color: parseHexColor(post.backgroundColor, const Color(0xFF0E3B2F)),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(4),
        child: Text(post.text, maxLines: 3, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
      );
    } else if (post.kind == StatusKind.image && resolveMedia(post.mediaUrl) != null) {
      thumb = Image.network(resolveMedia(post.mediaUrl) ?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined));
    } else {
      thumb = Container(color: pal.panel2, child: Icon(post.kind == StatusKind.video ? Icons.movie_outlined : Icons.graphic_eq_rounded, color: pal.ink2));
    }
    return ListTile(
      leading: ClipRRect(borderRadius: BorderRadius.circular(context.radius(10)), child: SizedBox(width: 52, height: 52, child: thumb)),
      title: Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('${formatDateTime(post.createdAt)}\n${s.views} views, ${s.likes} likes, ${s.reactions} reactions, ${s.comments} comments'),
      isThreeLine: true,
      onTap: () => context.push('/messages/status/${Uri.encodeComponent(post.id)}/insights'),
    );
  }
}
