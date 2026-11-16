/// Currency shown on the overview dashboards. The figures are sample data until the matching services exist,
/// so this is the one place to change when real amounts arrive with their own currency.
const String overviewCurrency = 'USD';

const List<String> _monthNames = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
];

/// Three letter month name for 1 to 12. Values outside that range wrap around.
String overviewMonth(int month) => _monthNames[((month - 1) % 12 + 12) % 12];

/// Month labels for the last [count] months ending with the current one, oldest first.
List<String> overviewMonthsBack(DateTime now, int count) => <String>[
      for (var i = count - 1; i >= 0; i--) overviewMonth(DateTime(now.year, now.month - i).month),
    ];

/// "USD 45,000"
String overviewMoney(num value) {
  final digits = value.round().toString();
  final grouped = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  return '$overviewCurrency $grouped';
}

String _trimZero(double v) {
  final s = v.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

/// "95K", "48.2M". Small numbers are left as they are.
String overviewShort(num value) {
  if (value >= 1000000) return '${_trimZero(value / 1000000)}M';
  if (value >= 1000) return '${_trimZero(value / 1000)}K';
  return value.round().toString();
}

/// "USD 95K"
String overviewShortMoney(num value) => '$overviewCurrency ${overviewShort(value)}';

/// "today", "tomorrow" or "in 5 days", counted in calendar days.
String overviewDueIn(DateTime now, DateTime due) {
  final days = DateTime(due.year, due.month, due.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'tomorrow';
  return 'in $days days';
}
