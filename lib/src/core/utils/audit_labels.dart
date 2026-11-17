import 'formatters.dart';

/// How one kind of security event is shown to people: a short title, one sentence on what it means, and a group.
class AuditLabel {
  const AuditLabel(this.title, this.description, this.category);

  final String title;
  final String description;
  final String category;
}

const String catSignIn = 'Sign in';
const String catPassword = 'Passwords';
const String catSessions = 'Sessions and devices';
const String catAccount = 'Accounts';
const String catStaff = 'Staff actions';
const String catApplications = 'Applications';
const String catSettings = 'Settings';
const String catMessages = 'Messages and email';
const String catOther = 'Other';

/// Groups in the order the event picker lists them.
const List<String> auditCategories = <String>[
  catSignIn,
  catPassword,
  catSessions,
  catAccount,
  catStaff,
  catApplications,
  catSettings,
  catMessages,
];

/// Every event the auth service can write, matching its SecurityEventType enum.
const Map<String, AuditLabel> _labels = <String, AuditLabel>{
  'SIGN_IN_SUCCESS': AuditLabel('Signed in', 'Someone signed in to the account.', catSignIn),
  'SIGN_IN_FAILED': AuditLabel('Failed sign in', 'A sign in attempt was refused, for example because the password was wrong.', catSignIn),
  'SIGN_IN_THROTTLED': AuditLabel('Sign in paused', 'There were too many attempts, so new ones were paused for a short time.', catSignIn),
  'ACCOUNT_LOCKED': AuditLabel('Account locked', 'The account was locked after repeated failed sign ins.', catSignIn),
  'NEW_DEVICE_SIGN_IN': AuditLabel('Sign in from a new device', 'The account was used from a device it had not been used from before.', catSignIn),
  'SUSPICIOUS_SIGN_IN': AuditLabel('Suspicious sign in', 'A sign in looked unusual, for example a new place or device.', catSignIn),
  'UNAUTHORIZED_SIGN_IN_REPORTED': AuditLabel('Sign in reported as not me', 'The owner said a sign in was not theirs.', catSignIn),
  'REFRESH_TOKEN_REUSE': AuditLabel('Reused sign in token', 'An old sign in token was used again, so the session was ended as a precaution.', catSignIn),
  'SOCIAL_ACCOUNT_LINKED': AuditLabel('Social account linked', 'A Google or other social account was linked to this account.', catSignIn),
  'PASSWORD_CHANGED': AuditLabel('Password changed', 'The password was changed.', catPassword),
  'PASSWORD_RESET_REQUESTED': AuditLabel('Password reset requested', 'A reset link was requested for this account.', catPassword),
  'PASSWORD_RESET': AuditLabel('Password reset', 'The password was reset from an emailed link.', catPassword),
  'SESSION_REVOKED': AuditLabel('Session ended', 'A session ended, either by signing out or because it was ended on purpose.', catSessions),
  'ALL_SESSIONS_REVOKED': AuditLabel('All sessions ended', 'Every session of the account was ended.', catSessions),
  'DEVICE_TRUSTED': AuditLabel('Device trusted', 'A device was marked as trusted.', catSessions),
  'DEVICE_TRUST_REVOKED': AuditLabel('Device trust removed', 'A device is no longer marked as trusted.', catSessions),
  'DEVICE_CREDENTIAL_REVOKED': AuditLabel('Device reset', 'The saved sign in of a device was cleared, so it counts as new next time.', catSessions),
  'DEVICE_REMOVED': AuditLabel('Device removed', 'A device was removed and its sessions ended.', catSessions),
  'SIGN_UP': AuditLabel('Account created', 'A new account was created from the sign up page.', catAccount),
  'SIGN_UP_EXISTING_EMAIL': AuditLabel('Sign up with an existing email', 'Someone tried to sign up with an email that already has an account.', catAccount),
  'EMAIL_VERIFIED': AuditLabel('Email verified', 'The email address was confirmed from the emailed link.', catAccount),
  'ACTIVATION_RESENT': AuditLabel('Activation email sent again', 'A new activation email was requested.', catAccount),
  'ACTIVATION_RESEND_VERIFIED_ACCOUNT': AuditLabel('Activation requested for a verified account', 'An activation email was requested for an account that is already verified.', catAccount),
  'PROFILE_UPDATED': AuditLabel('Profile updated', 'The owner changed their profile details.', catAccount),
  'USER_CREATED': AuditLabel('Account created by staff', 'An administrator created the account.', catStaff),
  'USER_UPDATED': AuditLabel('Account edited by staff', 'An administrator changed the account details.', catStaff),
  'USER_DELETED': AuditLabel('Account deleted', 'An administrator deleted the account.', catStaff),
  'USER_ARCHIVED': AuditLabel('Account archived', 'An administrator archived the account.', catStaff),
  'USER_UNARCHIVED': AuditLabel('Account restored from archive', 'An administrator brought the account back from the archive.', catStaff),
  'USER_ACTIVATED': AuditLabel('Account activated', 'An administrator turned the account on.', catStaff),
  'USER_DEACTIVATED': AuditLabel('Account deactivated', 'An administrator turned the account off.', catStaff),
  'USER_VERIFIED_BY_ADMIN': AuditLabel('Account verified by staff', 'An administrator marked the account as verified.', catStaff),
  'USER_UNVERIFIED_BY_ADMIN': AuditLabel('Verification removed by staff', 'An administrator removed the verified mark from the account.', catStaff),
  'ADMIN_PROVISIONED': AuditLabel('Administrator created from settings', 'An administrator account was created from the server settings.', catStaff),
  'ADMIN_INVITATION_ACCEPTED': AuditLabel('Administrator invitation accepted', 'The invited person set up their administrator account.', catStaff),
  'ADMIN_ROLE_ASSIGNED': AuditLabel('Administrator role granted', 'An account was given the administrator role.', catStaff),
  'ADMIN_ROLE_CHANGED': AuditLabel('Role changed', 'An administrator changed the role of an account.', catStaff),
  'ADMIN_SUSPICIOUS_ACTIVITY': AuditLabel('Suspicious administrator activity', 'Something unusual happened on an administrator account.', catStaff),
  'APPLICATION_STATUS_CHANGED': AuditLabel('Application status changed', 'A reviewer moved a Home Owner application to a new status.', catApplications),
  'HOME_OWNER_PROMOTED': AuditLabel('Promoted to Home Owner', 'An administrator approved an application and made the applicant a Home Owner.', catApplications),
  'STORAGE_SETTINGS_CHANGED': AuditLabel('Storage settings changed', 'An administrator changed where documents are stored.', catSettings),
  'CONTACT_MESSAGE_RECEIVED': AuditLabel('Contact message received', 'A message came in from the contact form.', catMessages),
  'CONTACT_MESSAGE_FAILED': AuditLabel('Contact message failed', 'A message from the contact form could not be processed.', catMessages),
  'NOTIFICATION_FAILED': AuditLabel('Email could not be sent', 'An email to a person could not be delivered.', catMessages),
};

/// The label for [type], or a readable fallback when the server adds a kind this app does not know yet.
AuditLabel auditLabel(String type) {
  final known = _labels[type.toUpperCase()];
  if (known != null) return known;
  return AuditLabel(type.isEmpty ? 'Event' : sentence(type), 'Recorded by the system.', catOther);
}

/// All known event types, sorted by their title, for pickers.
List<String> auditTypesIn(String category) {
  final types = _labels.entries.where((e) => e.value.category == category).map((e) => e.key).toList();
  types.sort((a, b) => _labels[a]!.title.compareTo(_labels[b]!.title));
  return types;
}

String severityLabel(String? severity) {
  switch ((severity ?? '').toUpperCase()) {
    case 'CRITICAL':
    case 'ALERT':
    case 'HIGH':
      return 'Critical';
    case 'WARNING':
    case 'WARN':
    case 'MEDIUM':
      return 'Warning';
    default:
      return 'Information';
  }
}

String outcomeLabel(String? outcome) {
  switch ((outcome ?? '').toUpperCase()) {
    case 'FAILURE':
      return 'Failed';
    case 'SUCCESS':
      return 'Succeeded';
    default:
      return '';
  }
}

/// HOME_OWNER becomes "Home owner".
String roleLabel(String? role) => sentence(role);

/// Fields an administrator can change on an account, as the user update event lists them.
const Map<String, String> _changedFields = <String, String>{
  'details': 'name and contact details',
  'email': 'email address',
  'role': 'role',
  'active': 'active status',
  'archived': 'archived status',
  'verified': 'verified status',
  'password': 'password',
};

const Map<String, String> _detailKeys = <String, String>{
  'from': 'Changed from',
  'to': 'Changed to',
  'previousRole': 'Previous role',
  'newRole': 'New role',
  'changed': 'What changed',
  'source': 'Source',
  'device': 'Device',
  'score': 'Risk score',
  'reasons': 'Why it looked unusual',
  'reference': 'Reference',
  'sessionsEnded': 'Sessions ended',
  'sessionRevoked': 'Session ended',
  'sessionWasRevoked': 'Session was already ended',
  'trustRemoved': 'Trust removed',
  'passwordResetRequested': 'Password reset requested',
  'newDevice': 'New device',
  'template': 'Email template',
  'error': 'Error',
  'provider': 'Sign in provider',
  'method': 'Sign in method',
  'type': 'Type',
  'topic': 'Topic',
  'slot': 'Settings slot',
  'minutes': 'Minutes',
  'state': 'New state',
};

/// "previousRole" becomes "Previous role", "sessions_ended" becomes "Sessions ended".
String detailKeyLabel(String key) {
  final known = _detailKeys[key];
  if (known != null) return known;
  final spaced = key
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll(RegExp(r'[_.-]+'), ' ')
      .trim();
  return sentence(spaced.isEmpty ? key : spaced);
}

/// Values the server stores as codes, shown in words.
String detailValueLabel(String key, String value) {
  switch (key) {
    case 'changed':
      return value
          .split(',')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .map((p) => _changedFields[p] ?? p)
          .join(', ');
    case 'previousRole':
    case 'newRole':
    case 'role':
      return roleLabel(value);
    case 'trustRemoved':
    case 'sessionRevoked':
    case 'sessionWasRevoked':
    case 'newDevice':
    case 'passwordResetRequested':
      if (value == 'true') return 'Yes';
      if (value == 'false') return 'No';
      return value;
    default:
      return value;
  }
}

/// "Chrome on Linux", "Chrome", or "Linux", whichever parts are known.
String browserAndSystem(String? browser, String? os) {
  final b = (browser ?? '').trim();
  final o = (os ?? '').trim();
  if (b.isNotEmpty && o.isNotEmpty) return '$b on $o';
  return b.isNotEmpty ? b : o;
}

/// "Nairobi, Nairobi County, Kenya", skipping parts that are missing.
String placeLabel(String? city, String? region, String? country) {
  final parts = <String>[
    for (final p in <String?>[city, region, country])
      if (p != null && p.trim().isNotEmpty) p.trim(),
  ];
  return parts.join(', ');
}

/// The request that caused an event, for example "PUT /admin/users/update/{id}".
String requestLabel(String? method, String? path) {
  final m = (method ?? '').trim();
  final p = (path ?? '').trim();
  if (m.isEmpty && p.isEmpty) return '';
  return '$m $p'.trim();
}

/// "USER" becomes "Account", "APPLICATION" becomes "Home Owner application".
String targetTypeLabel(String? type) {
  switch ((type ?? '').toUpperCase()) {
    case 'USER':
      return 'Account';
    case 'APPLICATION':
      return 'Home Owner application';
    case 'SETTINGS':
      return 'Settings';
    default:
      return sentence(type);
  }
}
