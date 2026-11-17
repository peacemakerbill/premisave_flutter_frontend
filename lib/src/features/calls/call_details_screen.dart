import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/call_models.dart';
import '../../data/models/file_ref.dart';
import '../../state/call_controller.dart';
import '../../state/call_providers.dart';
import '../../state/messenger_controller.dart';
import '../../state/providers.dart';
import '../messenger/file_viewer_screen.dart';
import 'call_format.dart';

/// One call after it happened (or while it runs): who was in it, the recordings to watch again, and the chat that was
/// written during the call. Everyone who was in the call can open all of it.
class CallDetailsScreen extends ConsumerStatefulWidget {
  const CallDetailsScreen({super.key, required this.callId});

  final String callId;

  @override
  ConsumerState<CallDetailsScreen> createState() => _CallDetailsScreenState();
}

class _CallDetailsScreenState extends ConsumerState<CallDetailsScreen> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // A finished recording is announced live, but a missed event should not leave the page stuck on "Saving the video".
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      final data = ref.read(callDetailsProvider(widget.callId)).valueOrNull;
      if (data != null && data.recordings.any((r) => r.isBusy) && !data.call.isOpen) {
        ref.invalidate(callDetailsProvider(widget.callId));
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _play(CallRecording r) async {
    final url = r.playUrl;
    if (url == null) return;
    final when = r.createdAt == null ? '' : ' ${formatDateTime(r.createdAt)}';
    await openFileViewer(
      context,
      FileRef(key: 'call-recording-${r.id}', name: 'Call recording$when.mp4', mime: 'video/mp4', size: r.sizeBytes > 0 ? r.sizeBytes : null, url: url, hint: 'VIDEO'),
    );
  }

  Future<void> _delete(CallRecording r) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this recording?',
      message: 'The video is deleted for everyone who was in the call. This cannot be undone.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(callRepositoryProvider).deleteRecording(widget.callId, r.id);
      ref.invalidate(callDetailsProvider(widget.callId));
      if (mounted) showToast(context, 'Recording deleted');
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _removeFromHistory() async {
    try {
      await ref.read(callRepositoryProvider).removeFromHistory(widget.callId);
      ref.invalidate(callHistoryProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(callDetailsProvider(widget.callId));
    final me = ref.watch(messengerProvider.select((s) => s.me?.id)) ?? '';
    final chats = ref.watch(messengerProvider.select((s) => s.chats));

    return SubPage(
      title: 'Call details',
      fallbackRoute: '/messages',
      body: value.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(callDetailsProvider(widget.callId))),
        data: (d) {
          final call = d.call;
          final chat = chats.where((c) => c.id == call.chatId).firstOrNull;
          final title = chat?.title ?? call.titleFor(me);
          final out = outcomeOf(call, me);
          return PageBody(
            maxWidth: 720,
            onRefresh: () async {
              ref.invalidate(callDetailsProvider(widget.callId));
              await ref.read(callDetailsProvider(widget.callId).future);
            },
            children: <Widget>[
              Text(title, style: context.display(size: 22, weight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                '${call.isVideo ? 'Video' : 'Voice'} call, ${out.text}, ${callWhen(call.createdAt)}',
                style: TextStyle(color: context.mutedColor),
              ),
              const SizedBox(height: 14),
              if (call.isOpen)
                Align(
                  alignment: Alignment.centerLeft,
                  child: PButton(label: 'Join the call', small: true, onPressed: () => ref.read(callProvider.notifier).joinCall(call.id)),
                ),
              if (call.recordingEnabled) ...<Widget>[
                const SectionHeader('Recordings'),
                if (d.recordings.isEmpty)
                  _Note(
                    call.isOpen
                        ? 'Nothing recorded yet. A host or co-host can start a recording from the More menu in the call.'
                        : 'This call was not recorded.',
                  )
                else
                  for (final r in d.recordings) _RecordingTile(recording: r, onPlay: () => _play(r), onDelete: () => _delete(r)),
              ],
              const SectionHeader('People'),
              _Card(
                children: <Widget>[
                  for (final p in call.people)
                    ListTile(
                      dense: true,
                      leading: UserAvatar(initials: p.initials, imageUrl: p.picture, size: 34),
                      title: Text(p.userId == me ? 'You' : p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(_stateText(p)),
                    ),
                ],
              ),
              const SectionHeader('Call chat'),
              if (!d.chatAllowed)
                const _Note('The chat of a call can be read only by people who were in the call.')
              else if (d.messages.isEmpty)
                const _Note('Nobody wrote in the chat during this call.')
              else
                _Card(
                  children: <Widget>[
                    for (final m in d.messages) _ChatLine(message: m, mine: m.senderId == me),
                  ],
                ),
              const SizedBox(height: 18),
              if (call.linkUrl != null && call.isOpen)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.link_rounded),
                  title: const Text('Copy call link'),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: call.linkUrl!));
                    if (context.mounted) showToast(context, 'Call link copied');
                  },
                ),
              if (!call.isOpen)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline_rounded, color: context.pal.bad),
                  title: Text('Remove from my call history', style: TextStyle(color: context.pal.bad)),
                  subtitle: Text('Recordings and the chat stay available to the other people in the call.', style: TextStyle(color: context.mutedColor)),
                  onTap: _removeFromHistory,
                ),
            ],
          );
        },
      ),
    );
  }

  static String _stateText(CallPerson p) {
    switch (p.state) {
      case PersonState.joined:
        return 'In the call';
      case PersonState.left:
        return p.joinedAt == null ? 'Did not join' : 'Joined and left';
      case PersonState.declined:
        return 'Declined';
      case PersonState.missed:
        return 'Did not answer';
      case PersonState.removed:
        return 'Removed';
      case PersonState.invited:
        return 'Ringing';
    }
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(context.radius(Brand.radiusLarge)),
        border: Border.all(color: context.borderColor),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(color: context.mutedColor, height: 1.45)),
    );
  }
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({required this.recording, required this.onPlay, required this.onDelete});

  final CallRecording recording;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  String get _subtitle {
    final r = recording;
    switch (r.state) {
      case RecState.ready:
        final bits = <String>[
          if (r.durationSeconds > 0) durationText(r.durationSeconds),
          if (r.sizeBytes > 0) formatBytes(r.sizeBytes),
          if (r.startedByName.isNotEmpty) 'recorded by ${r.startedByName}',
        ];
        return bits.join(', ');
      case RecState.starting:
      case RecState.recording:
        return 'Recording now';
      case RecState.stopping:
        return 'Saving the video, this takes a moment';
      case RecState.failed:
        return (r.error ?? '').isNotEmpty ? r.error! : 'This recording could not be saved';
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = recording;
    final pal = context.pal;
    final failed = r.state == RecState.failed;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(context.radius(Brand.radiusLarge)),
        border: Border.all(color: context.borderColor),
      ),
      child: ListTile(
        onTap: r.isReady ? onPlay : null,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: failed ? pal.bad.withValues(alpha: 0.12) : pal.accentSoft,
          child: r.isBusy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4))
              : Icon(failed ? Icons.error_outline_rounded : Icons.play_arrow_rounded, color: failed ? pal.bad : pal.accent),
        ),
        title: Text(callWhen(r.createdAt).isEmpty ? 'Recording' : 'Recording, ${callWhen(r.createdAt)}', style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(_subtitle, style: TextStyle(color: failed ? pal.bad : context.mutedColor)),
        trailing: r.canDelete && !r.isBusy
            ? IconButton(tooltip: 'Delete recording', icon: Icon(Icons.delete_outline_rounded, color: pal.bad), onPressed: onDelete)
            : null,
      ),
    );
  }
}

class _ChatLine extends StatelessWidget {
  const _ChatLine({required this.message, required this.mine});

  final CallChatMsg message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  mine ? 'You' : (message.senderName.isEmpty ? 'Someone' : message.senderName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(callWhen(message.createdAt), style: TextStyle(fontSize: 12, color: context.mutedColor)),
            ],
          ),
          const SizedBox(height: 2),
          SelectableText(message.text, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}
