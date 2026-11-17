import 'package:flutter/material.dart';

import '../../data/models/call_models.dart';

String durationText(int seconds) {
  if (seconds < 1) return '';
  if (seconds < 60) return '$seconds sec';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m < 60) return s == 0 ? '$m min' : '$m min $s sec';
  final h = m ~/ 60;
  final rm = m % 60;
  return rm == 0 ? '$h h' : '$h h $rm min';
}

const List<String> _months = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String _two(int n) => n.toString().padLeft(2, '0');

/// "14:20", "Yesterday 14:20" or "12 Nov, 14:20".
String callWhen(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(l.year, l.month, l.day);
  final diff = today.difference(day).inDays;
  final time = '${_two(l.hour)}:${_two(l.minute)}';
  if (diff == 0) return time;
  if (diff == 1) return 'Yesterday $time';
  return '${l.day} ${_months[l.month - 1]}, $time';
}

/// How a call ended, from one person's point of view.
class CallOutcome {
  const CallOutcome({required this.icon, required this.text, this.bad = false});

  final IconData icon;
  final String text;

  /// True for calls this person missed, so the row can be drawn in the warning colour.
  final bool bad;
}

CallOutcome outcomeOf(CallInfo c, String me) {
  final outgoing = c.initiatorId == me;
  final mine = c.stateOf(me);
  final talk = durationText(c.durationSeconds);
  if (c.isOpen) {
    return CallOutcome(icon: c.isVideo ? Icons.videocam_rounded : Icons.call_rounded, text: c.status == CallStatus.ringing ? 'Ringing' : 'In progress');
  }
  if (!outgoing && (c.status == CallStatus.missed || mine == PersonState.missed)) {
    return const CallOutcome(icon: Icons.call_missed_rounded, text: 'Missed', bad: true);
  }
  if (!outgoing && mine == PersonState.declined) {
    return const CallOutcome(icon: Icons.call_received_rounded, text: 'Declined');
  }
  final icon = outgoing ? Icons.call_made_rounded : Icons.call_received_rounded;
  if (outgoing) {
    switch (c.status) {
      case CallStatus.missed:
        return CallOutcome(icon: icon, text: 'No answer');
      case CallStatus.declined:
        return CallOutcome(icon: icon, text: 'Declined');
      case CallStatus.cancelled:
        return CallOutcome(icon: icon, text: 'Cancelled');
      default:
        break;
    }
  }
  return CallOutcome(icon: icon, text: talk.isEmpty ? 'Ended' : talk);
}
