import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../state/call_controller.dart';
import '../../state/call_providers.dart';

/// A strip above a chat's messages while a call is running in it: "Call in progress, Join".
class ActiveCallBanner extends ConsumerWidget {
  const ActiveCallBanner({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeCallInChatProvider(chatId)).valueOrNull;
    final inCallId = ref.watch(callProvider.select((s) => s.session?.callId));
    if (active == null || !active.isOpen) return const SizedBox.shrink();
    final mine = inCallId == active.id;
    final n = active.joined.length;
    final pal = context.pal;
    return Material(
      color: pal.good.withValues(alpha: 0.14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
        child: Row(
          children: <Widget>[
            Icon(active.isVideo ? Icons.videocam_rounded : Icons.call_rounded, size: 18, color: pal.good),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                mine
                    ? 'You are in this call'
                    : '${active.isVideo ? 'Video' : 'Voice'} call in progress${n > 0 ? ', ${plural(n)}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700, color: pal.ink, fontSize: 13.5),
              ),
            ),
            PButton(
              label: mine ? 'Open' : 'Join',
              small: true,
              onPressed: () {
                final ctl = ref.read(callProvider.notifier);
                if (mine) {
                  ctl.setExpanded(true);
                } else {
                  ctl.joinCall(active.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String plural(int n) => n == 1 ? '1 in the call' : '$n in the call';
}
