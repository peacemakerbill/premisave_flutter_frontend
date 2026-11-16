import 'package:flutter/material.dart';

import '../../core/theme/brand.dart';

/// Icon for a device or session based on its label, OS or type.
IconData deviceIcon(String? label, [String? type]) {
  final s = '${label ?? ''} ${type ?? ''}'.toLowerCase();
  if (s.contains('iphone') || s.contains('android') || s.contains('mobile') || s.contains('phone')) {
    return Icons.smartphone_rounded;
  }
  if (s.contains('ipad') || s.contains('tablet')) return Icons.tablet_mac_rounded;
  if (s.contains('mac') || s.contains('windows') || s.contains('linux') || s.contains('desktop') || s.contains('laptop')) {
    return Icons.laptop_mac_rounded;
  }
  return Icons.devices_rounded;
}

Color severityColor(String severity) {
  switch (severity.toUpperCase()) {
    case 'CRITICAL':
    case 'ALERT':
    case 'HIGH':
      return Brand.danger;
    case 'WARNING':
    case 'WARN':
    case 'MEDIUM':
      return Brand.warning;
    default:
      return Brand.info;
  }
}

IconData eventIcon(String type) {
  final t = type.toUpperCase();
  if (t.contains('FAILED') || t.contains('LOCKED') || t.contains('THROTTLED')) return Icons.block_rounded;
  if (t.contains('SUSPICIOUS') || t.contains('REUSE') || t.contains('UNAUTHORIZED')) return Icons.gpp_maybe_outlined;
  if (t.contains('NEW_DEVICE')) return Icons.add_to_home_screen_rounded;
  if (t.contains('PASSWORD')) return Icons.password_rounded;
  if (t.contains('DEVICE')) return Icons.devices_rounded;
  if (t.contains('SESSION')) return Icons.logout_rounded;
  if (t.contains('SIGN_IN')) return Icons.login_rounded;
  if (t.contains('ADMIN')) return Icons.admin_panel_settings_outlined;
  return Icons.security_rounded;
}
