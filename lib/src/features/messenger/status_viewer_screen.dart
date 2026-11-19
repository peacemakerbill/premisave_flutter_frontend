import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode, launchUrl;

import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../state/messenger_providers.dart';
import '../../state/providers.dart';
import 'emoji_panel.dart';
import 'messenger_common.dart';

/// Full screen status viewer. Tap the right side for the next update and the left side to go back.
/// Hold the screen to pause. Your own updates also show who saw them.
class StatusViewerScreen extends ConsumerWidget {
  const StatusViewerScreen({super.key, required this.userId, this.mine = false});

  final String userId;
  final bool mine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = mine ? ref.watch(myStatusesProvider) : ref.watch(userStatusesProvider(userId));

    void close() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/messages');
      }
    }

    return Scaffold(
      backgroundColor: context.pal.bg,
      body: value.when(
        loading: () => const LoadingState(),
        error: (e, _) => Column(children: <Widget>[
          SafeArea(child: Align(alignment: Alignment.centerLeft, child: IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: close))),
          Expanded(child: ErrorState(error: e, onRetry: () => mine ? ref.invalidate(myStatusesProvider) : ref.invalidate(userStatusesProvider(userId)))),
        ]),
        data: (posts) {
          final active = posts.where((p) => p.active).toList();
          if (active.isEmpty) {
            return Column(children: <Widget>[
              SafeArea(child: Align(alignment: Alignment.centerLeft, child: IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: close))),
              const Expanded(child: EmptyState(icon: Icons.auto_awesome_outlined, title: 'No status updates', message: 'Nothing to show right now.')),
            ]);
          }
          return _Story(posts: active, mine: mine, onClose: close);
        },
      ),
    );
  }
}

class _Story extends ConsumerStatefulWidget {
  const _Story({required this.posts, required this.mine, required this.onClose});

  final List<StatusPost> posts;
  final bool mine;
  final VoidCallback onClose;

  @override
  ConsumerState<_Story> createState() => _StoryState();
}

class _StoryState extends ConsumerState<_Story> with SingleTickerProviderStateMixin {
  late final AnimationController _bar = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  final Map<String, StatusPost> _local = <String, StatusPost>{};
  final Set<String> _seen = <String>{};
  int _index = 0;
  int _pauses = 0;

  @override
  void initState() {
    super.initState();
    // Start on the first update you have not seen yet.
    if (!widget.mine) {
      final first = widget.posts.indexWhere((p) => !p.viewedByMe);
      if (first > 0) _index = first;
    }
    _bar.addStatusListener((s) {
      if (s == AnimationStatus.completed) _next();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  List<StatusPost> get _posts => widget.posts;

  StatusPost get _current {
    final i = _index.clamp(0, _posts.length - 1);
    final p = _posts[i];
    return _local[p.id] ?? p;
  }

  void _begin() {
    if (!mounted) return;
    final p = _current;
    _bar.duration = Duration(seconds: p.kind == StatusKind.text ? (4 + (p.text.length / 40).ceil()).clamp(5, 12) : (p.kind == StatusKind.image ? 6 : 10));
    _bar
      ..reset()
      ..forward();
    if (!widget.mine && !p.viewedByMe && _seen.add(p.id)) {
      ref.read(messengerRepositoryProvider).markStatusViewed(p.id).catchError((Object _) {});
    }
  }

  void _next() {
    if (!mounted) return;
    if (_index >= _posts.length - 1) {
      widget.onClose();
      return;
    }
    setState(() => _index++);
    _begin();
  }

  void _previous() {
    if (_index == 0) {
      _begin();
      return;
    }
    setState(() => _index--);
    _begin();
  }

  void _pause() {
    _pauses++;
    _bar.stop();
  }

  void _resume() {
    if (_pauses > 0) _pauses--;
    if (_pauses == 0 && mounted) _bar.forward();
  }

  Future<T?> _whilePaused<T>(Future<T?> Function() job) async {
    _pause();
    try {
      return await job();
    } finally {
      _resume();
    }
  }

  void _replace(StatusPost updated) {
    if (!mounted) return;
    setState(() => _local[updated.id] = updated);
  }

  Future<void> _like(StatusPost p) async {
    final repo = ref.read(messengerRepositoryProvider);
    try {
      _replace(p.likedByMe ? await repo.unlikeStatus(p.id) : await repo.likeStatus(p.id));
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _react(StatusPost p) async {
    final repo = ref.read(messengerRepositoryProvider);
    final pick = await _whilePaused<String>(() => showCenteredSheet<String>(
          context: context,
          useSafeArea: true,
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  for (final e in kQuickReactions)
                    InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: () => Navigator.of(ctx).pop(e),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: p.myReaction == e ? BoxDecoration(color: ctx.pal.accentSoft, shape: BoxShape.circle) : null,
                        child: Text(e, style: const TextStyle(fontSize: 28)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ));
    if (pick == null) return;
    try {
      _replace(p.myReaction == pick ? await repo.removeStatusReaction(p.id) : await repo.reactToStatus(p.id, pick));
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _comments(StatusPost p) async {
    await _whilePaused<void>(() => showCenteredSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (ctx) => _CommentsSheet(status: p),
        ));
    ref.invalidate(myStatusesProvider);
  }

  Future<void> _delete(StatusPost p) async {
    final ok = await _whilePaused<bool>(() => confirmDialog(context, title: 'Delete this status?', message: 'It disappears for everyone who could see it.', confirmLabel: 'Delete', danger: true));
    if (ok != true) return;
    try {
      await ref.read(messengerRepositoryProvider).deleteStatus(p.id);
      ref.invalidate(myStatusesProvider);
      ref.invalidate(statusFeedProvider);
      if (!mounted) return;
      showToast(context, 'Status deleted');
      if (_posts.length <= 1) widget.onClose();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _openMedia(StatusPost p) async {
    final url = resolveMedia(p.mediaUrl);
    if (url == null) return;
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) showToast(context, 'Could not open the file.', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final p = _current;
    final text = Theme.of(context).textTheme;
    final owner = widget.mine ? 'My status' : (p.owner?.name ?? 'Status');

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: _media(context, p)),
          Positioned.fill(
            child: Row(children: <Widget>[
              Expanded(flex: 2, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _previous, onLongPressStart: (_) => _pause(), onLongPressEnd: (_) => _resume())),
              Expanded(flex: 3, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _next, onLongPressStart: (_) => _pause(), onLongPressEnd: (_) => _resume())),
            ]),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Color(0xAA000000), Color(0x00000000)])),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 6, 14),
                  child: Column(children: <Widget>[
                    Row(children: <Widget>[
                      for (var i = 0; i < _posts.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: i == _index
                                  ? AnimatedBuilder(animation: _bar, builder: (_, __) => LinearProgressIndicator(value: _bar.value, minHeight: 3, backgroundColor: Colors.white30, color: Colors.white))
                                  : LinearProgressIndicator(value: i < _index ? 1 : 0, minHeight: 3, backgroundColor: Colors.white30, color: Colors.white),
                            ),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: <Widget>[
                      IconButton(tooltip: 'Close', icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: widget.onClose),
                      MessengerAvatar(initials: p.owner?.initials ?? 'P', imageUrl: p.owner?.profilePictureUrl, size: 38),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Text(owner, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                          Text(timeAgo(p.createdAt), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ]),
                      ),
                      if (widget.mine) IconButton(tooltip: 'Delete', icon: const Icon(Icons.delete_outline_rounded, color: Colors.white), onPressed: () => _delete(p)),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _bottom(context, p)),
        ],
      ),
    );
  }

  Widget _media(BuildContext context, StatusPost p) {
    switch (p.kind) {
      case StatusKind.text:
        return Container(
          color: parseHexColor(p.backgroundColor, const Color(0xFF0E3B2F)),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 120),
          child: SingleChildScrollView(
            child: Text(p.text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w700, height: 1.25)),
          ),
        );
      case StatusKind.image:
        final url = resolveMedia(p.mediaUrl);
        return Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: url == null
              ? const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 56)
              : Image.network(
                  url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 56),
                  loadingBuilder: (c, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
        );
      case StatusKind.video:
      case StatusKind.audio:
        final video = p.kind == StatusKind.video;
        return Container(
          color: const Color(0xFF111111),
          alignment: Alignment.center,
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Icon(video ? Icons.movie_outlined : Icons.graphic_eq_rounded, color: Colors.white70, size: 72),
            const SizedBox(height: 10),
            Text(p.fileName ?? (video ? 'Video status' : 'Audio status'), style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            PButton(label: video ? 'Play video' : 'Play audio', icon: Icons.play_arrow_rounded, kind: PButtonKind.accent, onPressed: () => _openMedia(p)),
          ]),
        );
    }
  }

  Widget _bottom(BuildContext context, StatusPost p) {
    final hasCaption = p.kind != StatusKind.text && p.caption.isNotEmpty;
    final stats = p.stats;
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: <Color>[Color(0xCC000000), Color(0x00000000)])),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 24, 14, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            if (hasCaption)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(p.caption, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.35)),
              ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
              _Action(icon: p.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: p.likedByMe ? const Color(0xFFFF5470) : Colors.white, label: widget.mine ? '${stats.likes}' : 'Like', onTap: () => _like(p)),
              _Action(icon: Icons.add_reaction_outlined, label: p.myReaction ?? (widget.mine ? '${stats.reactions}' : 'React'), onTap: () => _react(p)),
              _Action(icon: Icons.chat_bubble_outline_rounded, label: widget.mine ? '${stats.comments}' : 'Comment', onTap: () => _comments(p)),
              if (widget.mine)
                _Action(
                  icon: Icons.visibility_outlined,
                  label: '${stats.views}',
                  onTap: () async {
                    await _whilePaused<void>(() async {
                      await context.push<void>('/messages/status/${Uri.encodeComponent(p.id)}/insights');
                    });
                  },
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, this.color = Colors.white});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _CommentsSheet extends ConsumerStatefulWidget {
  const _CommentsSheet({required this.status});

  final StatusPost status;

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final TextEditingController _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(messengerRepositoryProvider).commentOnStatus(widget.status.id, t);
      _text.clear();
      ref.invalidate(statusCommentsProvider(widget.status.id));
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _remove(StatusComment c) async {
    try {
      await ref.read(messengerRepositoryProvider).deleteStatusComment(widget.status.id, c.id);
      ref.invalidate(statusCommentsProvider(widget.status.id));
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(statusCommentsProvider(widget.status.id));
    final max = ref.watch(statusSettingsProvider).valueOrNull?.commentMaxLength ?? 300;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 10),
            Container(width: 38, height: 4, decoration: BoxDecoration(color: context.pal.line2, borderRadius: BorderRadius.circular(9))),
            const Padding(padding: EdgeInsets.all(14), child: Text('Comments', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800))),
            Expanded(
              child: AsyncBody<List<StatusComment>>(
                value: comments,
                onRetry: () => ref.invalidate(statusCommentsProvider(widget.status.id)),
                builder: (list) {
                  if (list.isEmpty) return const EmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'No comments yet', message: 'Be the first to say something.');
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final c = list[i];
                      final a = c.author;
                      return ListTile(
                        leading: MessengerAvatar(initials: a?.initials ?? 'P', imageUrl: a?.profilePictureUrl, size: 38),
                        title: Text(c.mine ? 'You' : (a?.name ?? 'Member'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                        subtitle: Text(c.content, style: const TextStyle(height: 1.35)),
                        trailing: c.canDelete ? IconButton(tooltip: 'Delete comment', icon: const Icon(Icons.delete_outline_rounded), onPressed: () => _remove(c)) : null,
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 8, 10),
                child: Row(children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _text,
                      maxLength: max,
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(hintText: 'Write a comment', counterText: ''),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(onPressed: _sending ? null : _send, tooltip: 'Send', icon: const Icon(Icons.send_rounded)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
