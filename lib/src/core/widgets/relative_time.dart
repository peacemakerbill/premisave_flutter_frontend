import 'package:flutter/material.dart';

import '../theme/brand.dart';
import '../utils/formatters.dart';

/// "2 hours ago" for a moment in time. Hover or long press shows the exact date and time.
/// Renders nothing when [time] is null, so callers do not need their own check.
class RelativeTime extends StatelessWidget {
  const RelativeTime(this.time, {super.key, this.prefix = '', this.style});

  final DateTime? time;

  /// Text placed before the time, for example "Updated ".
  final String prefix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = time;
    if (t == null) return const SizedBox.shrink();
    return Tooltip(
      message: formatDateTime(t),
      child: Text(
        '$prefix${timeAgo(t)}',
        style: style ?? TextStyle(fontSize: 12.5, color: context.mutedColor),
      ),
    );
  }
}
