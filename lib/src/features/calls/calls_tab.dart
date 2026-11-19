import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/call_models.dart';
import '../../data/models/messenger_models.dart';
import '../../state/call_controller.dart';
import '../../state/call_providers.dart';
import '../../state/messenger_controller.dart';
import '../../state/providers.dart';
import '../messenger/member_picker.dart';
import '../messenger/messenger_common.dart';
import 'call_format.dart';

/// The Calls tab: start a call, make or join a call link, and the list of calls made and missed.
class CallsTab extends ConsumerWidget {
  const CallsTab({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(callHistoryProvider);
    await ref.read(callHistoryProvider.future);
  }

  Future<void> _joinWithLink(BuildContext context) async {
    final text = await promptDialog(
      context,
      title: 'Join with a call link',
      label: 'Paste the link or code',
      confirmLabel: 'Continue',
      required: true,
      multiline: false,
    );
    if (text == null || !context.mounted) return;
    final code = CallController.linkCodeOf(text);
    if (code.isEmpty) {
      showToast(context, 'That is not a call link.', error: true);
      return;
    }
    context.push('/messages/calls/join/${Uri.encodeComponent(code)}');
  }

  Future<void> _createLink(BuildContext context, WidgetRef ref) async {
    final media = await showCenteredSheet<CallMedia>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Align(alignment: Alignment.centerLeft, child: Text('Create a call link', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text('Anyone with the link can join while it is open. You join first and share the link from the call.', style: TextStyle(color: ctx.mutedColor, height: 1.35))),
          ),
          ListTile(leading: const Icon(Icons.videocam_rounded), title: const Text('Video call link'), onTap: () => Navigator.of(ctx).pop(CallMedia.video)),
          ListTile(leading: const Icon(Icons.call_rounded), title: const Text('Voice call link'), onTap: () => Navigator.of(ctx).pop(CallMedia.audio)),
        ]),
      ),
    );
    if (media == null) return;
    await ref.read(callProvider.notifier).createLinkAndJoin(media: media);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(callHistoryProvider);
    final me = ref.watch(messengerProvider.select((s) => s.me?.id)) ?? '';
    final chats = ref.watch(messengerProvider.select((s) => s.chats));
    final byChat = <String, MChat>{for (final c in chats) c.id: c};
    final busy = ref.watch(callProvider.select((s) => s.busy));

    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 100),
        children: <Widget>[
          _ActionTile(icon: Icons.add_link_rounded, title: 'Create call link', subtitle: 'Invite anyone, even people outside your chats', onTap: busy ? null : () => _createLink(context, ref)),
          _ActionTile(icon: Icons.link_rounded, title: 'Join with a link', subtitle: 'Paste a call link you were sent', onTap: () => _joinWithLink(context)),
          SectionHeader(
            'Recent calls',
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 6),
            action: (history.valueOrNull?.isNotEmpty ?? false) ? 'Clear' : null,
            onAction: () async {
              final ok = await confirmDialog(context, title: 'Clear call history?', message: 'This removes the list from your account. The people you called keep their own history.', confirmLabel: 'Clear', danger: true);
              if (!ok) return;
              try {
                await ref.read(callRepositoryProvider).clearHistory();
                ref.invalidate(callHistoryProvider);
              } catch (e) {
                if (context.mounted) showApiError(context, e);
              }
            },
          ),
          history.when(
            loading: () => const SkeletonList(kind: SkeletonKind.row, count: 5, shrink: true),
            error: (e, _) => SizedBox(height: 320, child: ErrorState(error: e, onRetry: () => ref.invalidate(callHistoryProvider))),
            data: (calls) {
              if (calls.isEmpty) {
                return const SizedBox(
                  height: 320,
                  child: EmptyState(
                    icon: Icons.call_outlined,
                    title: 'No calls yet',
                    message: 'Open a chat and tap the phone or camera icon to call. In a group, everyone is rung at once.',
                  ),
                );
              }
              return Column(children: <Widget>[for (final c in calls) _CallRow(call: c, me: me, chat: c.chatId == null ? null : byChat[c.chatId])]);
            },
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: CircleAvatar(radius: 24, backgroundColor: context.pal.accentSoft, child: Icon(icon, color: context.pal.accent)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle, style: TextStyle(color: context.mutedColor)),
      onTap: onTap,
    );
  }
}

class _CallRow extends ConsumerWidget {
  const _CallRow({required this.call, required this.me, this.chat});

  final CallInfo call;
  final String me;
  final MChat? chat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final out = outcomeOf(call, me);
    final head = call.headPerson(me);
    final title = chat?.title ?? call.titleFor(me);
    final group = call.kind != CallKind.private || (chat?.isGroup ?? false);
    final picture = chat?.photo ?? head?.picture;
    final canCallBack = call.chatId != null && !call.isOpen;
    final extra = group && call.joined.isNotEmpty ? ', ${call.joined.length} joined' : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: MessengerAvatar(initials: (head?.initials ?? 'P'), imageUrl: picture, size: 48, group: group),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, color: out.bad ? pal.bad : null)),
      subtitle: Row(children: <Widget>[
        Icon(out.icon, size: 15, color: out.bad ? pal.bad : context.mutedColor),
        const SizedBox(width: 5),
        Flexible(child: Text('${out.text}$extra, ${callWhen(call.createdAt)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.mutedColor))),
        if (call.recordingEnabled && call.recordingCount > 0) ...<Widget>[
          const SizedBox(width: 8),
          Icon(Icons.videocam_rounded, size: 15, color: pal.accent),
          const SizedBox(width: 3),
          Text(call.recordingCount == 1 ? 'Recording' : '${call.recordingCount} recordings', style: TextStyle(color: pal.accent, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ]),
      trailing: call.isOpen
          ? PButton(label: 'Join', small: true, onPressed: () => ref.read(callProvider.notifier).joinCall(call.id))
          : (canCallBack
              ? IconButton(
                  tooltip: call.isVideo ? 'Video call' : 'Voice call',
                  icon: Icon(call.isVideo ? Icons.videocam_outlined : Icons.call_outlined, color: pal.accent),
                  onPressed: () => ref.read(callProvider.notifier).startCall(call.chatId!, call.media),
                )
              : null),
      onTap: () => context.push('/messages/calls/details/${Uri.encodeComponent(call.id)}'),
    );
  }
}

/// The "New call" sheet: pick one person and ring them. Groups are called from the group's own chat.
Future<void> showNewCallSheet(BuildContext context, WidgetRef ref) async {
  var media = CallMedia.video;
  await showCenteredSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.pal.bg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => FractionallySizedBox(
        heightFactor: 0.86,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(children: <Widget>[
                Expanded(child: Text('New call', style: ctx.display(size: 18, weight: FontWeight.w800))),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(ctx).pop()),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: SegmentedButton<CallMedia>(
                segments: const <ButtonSegment<CallMedia>>[
                  ButtonSegment<CallMedia>(value: CallMedia.video, icon: Icon(Icons.videocam_rounded), label: Text('Video')),
                  ButtonSegment<CallMedia>(value: CallMedia.audio, icon: Icon(Icons.call_rounded), label: Text('Voice')),
                ],
                selected: <CallMedia>{media},
                onSelectionChanged: (v) => setState(() => media = v.first),
              ),
            ),
            Expanded(
              child: MemberPicker(
                emptyMessage: 'No members match that search.',
                onPick: (user) async {
                  Navigator.of(ctx).pop();
                  try {
                    final chatId = await ref.read(messengerProvider.notifier).startPrivateChat(user.id);
                    await ref.read(callProvider.notifier).startCall(chatId, media);
                  } catch (e) {
                    if (context.mounted) showApiError(context, e);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
