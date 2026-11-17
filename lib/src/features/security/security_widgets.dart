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
  if (t.contains('SIGN_UP') || t == 'USER_CREATED') return Icons.person_add_alt_1_rounded;
  if (t.contains('SIGN_IN')) return Icons.login_rounded;
  if (t == 'USER_DELETED') return Icons.person_remove_rounded;
  if (t.contains('ARCHIVED')) return Icons.inventory_2_outlined;
  if (t.contains('ACTIVATED') || t.contains('ACTIVATION')) return Icons.toggle_on_outlined;
  if (t.contains('VERIFIED')) return Icons.verified_outlined;
  if (t == 'PROFILE_UPDATED' || t == 'USER_UPDATED') return Icons.manage_accounts_outlined;
  if (t == 'HOME_OWNER_PROMOTED') return Icons.workspace_premium_outlined;
  if (t.contains('APPLICATION')) return Icons.assignment_outlined;
  if (t.contains('STORAGE')) return Icons.folder_open_rounded;
  if (t.contains('CONTACT')) return Icons.mark_email_unread_outlined;
  if (t.contains('NOTIFICATION')) return Icons.mail_outline_rounded;
  if (t.contains('SOCIAL')) return Icons.link_rounded;
  if (t.contains('ADMIN')) return Icons.admin_panel_settings_outlined;
  return Icons.security_rounded;
}

/// Failed outcomes in red, everything else in the severity colour of the event.
Color outcomeColor(String? outcome) =>
    (outcome ?? '').toUpperCase() == 'FAILURE' ? Brand.danger : Brand.success;
