/// 1234567.5 becomes "1,234,567.50". Whole numbers drop the decimals: 1500 becomes "1,500".
String groupDigits(num value, {int decimals = 2}) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  var out = buffer.toString();
  if (parts.length > 1) {
    final fraction = parts[1].replaceFirst(RegExp(r'0+$'), '');
    if (fraction.isNotEmpty) out = '$out.${fraction.length == 1 ? '${fraction}0' : fraction}';
  }
  return negative ? '-$out' : out;
}

/// The currency the Premisave services keep money in. The wallet holds one currency per user and the property service
/// uses the same one, so an amount that arrives with no currency of its own is in this one.
const String platformCurrency = 'USD';

/// "USD 12,500" or "KES 49.99". A missing amount shows as a dash.
String formatMoney(num? value, [String currency = platformCurrency]) {
  if (value == null) return '-';
  return '$currency ${groupDigits(value)}';
}
