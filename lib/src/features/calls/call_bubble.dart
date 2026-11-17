import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/palette.dart';
import '../../data/models/call_models.dart';
import '../../state/call_controller.dart';
import 'call_format.dart';

/// The call line inside a chat: "Missed video call", "Voice call, 3 min", or "Join" while it is still running.
class CallLineBody extends ConsumerWidget {
  const CallLineBody({super.key, required this.line, required this.chatId, required this.mine, required this.myId, required this.fg, required this.soft});

  final CallLine line;
  final String chatId;
  final bool mine;
  final String myId;
  final Color fg;
  final Color soft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final outgoing = line.initiatorId == myId;
    final kind = line.media == CallMedia.video ? 'video call' : 'voice call';
    final cap = '${kind[0].toUpperCase()}${kind.substring(1)}';
    final inCallId = ref.watch(callProvider.select((s) => s.session?.callId));
    final here = inCallId == line.callId;

    String title;
    String? detail;
    IconData icon;
    var bad = false;
    if (line.isOpen) {
      title = '$cap in progress';
      detail = line.participantCount > 1 ? '${line.participantCount} in the call' : null;
      icon = line.media == CallMedia.video ? Icons.videocam_rounded : Icons.call_rounded;
    } else if (line.status == CallStatus.missed || line.status == CallStatus.cancelled) {
      bad = !outgoing;
      title = outgoing ? (line.status == CallStatus.cancelled ? 'Cancelled $kind' : 'No answer') : 'Missed $kind';
      icon = outgoing ? Icons.call_made_rounded : Icons.call_missed_rounded;
    } else if (line.status == CallStatus.declined) {
      title = outgoing ? 'Declined $kind' : 'Declined';
      icon = outgoing ? Icons.call_made_rounded : Icons.call_received_rounded;
    } else {
      title = cap;
      final d = durationText(line.durationSeconds);
      detail = d.isEmpty ? null : d;
      icon = outgoing ? Icons.call_made_rounded : Icons.call_received_rounded;
    }

    final accent = bad ? pal.bad : fg;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: (mine ? pal.accentInk : pal.accent).withValues(alpha: 0.14), shape: BoxShape.circle),
          child: Icon(icon, size: 19, color: bad ? pal.bad : (mine ? pal.accentInk : pal.accent)),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: accent)),
              if (detail != null) Text(detail, style: TextStyle(fontSize: 12.5, color: soft)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (line.isOpen)
          FilledButton.tonal(
            style: FilledButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 14)),
            onPressed: () {
              final ctl = ref.read(callProvider.notifier);
              here ? ctl.setExpanded(true) : ctl.joinCall(line.callId);
            },
            child: Text(here ? 'Open' : 'Join'),
          )
        else
          IconButton(
            tooltip: 'Call back',
            visualDensity: VisualDensity.compact,
            icon: Icon(line.media == CallMedia.video ? Icons.videocam_outlined : Icons.call_outlined, color: mine ? pal.accentInk : pal.accent),
            onPressed: () => ref.read(callProvider.notifier).startCall(chatId, line.media),
          ),
      ],
    );
  }
}
