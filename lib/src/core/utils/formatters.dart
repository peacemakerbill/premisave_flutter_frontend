const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

String _two(int n) => n.toString().padLeft(2, '0');

/// 14 Nov 2026
String formatDate(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  return '${l.day} ${_months[l.month - 1]} ${l.year}';
}

/// 14 Nov 2026, 09:30
String formatDateTime(DateTime? d) {
  if (d == null) return '';
  final l = d.toLocal();
  return '${formatDate(l)}, ${_two(l.hour)}:${_two(l.minute)}';
}

/// "just now", "5 min ago", "3 h ago", "2 days ago", then a date.
String timeAgo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d.toLocal());
  if (diff.isNegative || diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return diff.inDays == 1 ? 'yesterday' : '${diff.inDays} days ago';
  return formatDate(d);
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Time-of-day greeting.
String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 5) return 'Good evening';
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// SIGN_IN_FAILED or "sign in failed" becomes "Sign in failed".
String sentence(String? s) {
  if (s == null || s.isEmpty) return '';
  final t = s.replaceAll('_', ' ').toLowerCase();
  return t[0].toUpperCase() + t.substring(1);
}

/// "12 hours" or "3 days" for a waiting time given in hours.
String waitingLabel(int hours) {
  if (hours < 1) return 'under an hour';
  if (hours < 48) return '$hours h';
  return '${(hours / 24).round()} days';
}

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';
