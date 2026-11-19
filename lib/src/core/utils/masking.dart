/// Shortens a phone number to its start and end, for example 2547...45, so a screen can show which number is saved
/// without writing it out in full.
String maskPhone(String? phone) {
  final p = (phone ?? '').replaceAll(RegExp(r'\s'), '');
  if (p.length < 7) return p.isEmpty ? '' : '...';
  return '${p.substring(0, 4)}...${p.substring(p.length - 2)}';
}

/// Shortens an email address to its first letter and its domain, for example b...@gmail.com.
String maskEmail(String? email) {
  final e = (email ?? '').trim();
  final at = e.indexOf('@');
  if (at < 1) return e.isEmpty ? '' : '...';
  return '${e.substring(0, 1)}...${e.substring(at)}';
}
