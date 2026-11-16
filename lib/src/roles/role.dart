/// The kinds of account on the platform. What each role can see and do is decided in `role_registry.dart`,
/// never by comparing against a role in screen code.
enum Role {
  client,
  homeOwner,
  operations,
  finance,
  support,
  admin;

  /// Value used by the backend.
  String get api {
    switch (this) {
      case Role.client:
        return 'CLIENT';
      case Role.homeOwner:
        return 'HOME_OWNER';
      case Role.operations:
        return 'OPERATIONS';
      case Role.finance:
        return 'FINANCE';
      case Role.support:
        return 'SUPPORT';
      case Role.admin:
        return 'ADMIN';
    }
  }

  String get label {
    switch (this) {
      case Role.client:
        return 'Client';
      case Role.homeOwner:
        return 'Home owner';
      case Role.operations:
        return 'Operations';
      case Role.finance:
        return 'Finance';
      case Role.support:
        return 'Support';
      case Role.admin:
        return 'Administrator';
    }
  }

  static Role parse(Object? value) {
    final v = (value ?? '').toString().toUpperCase().replaceAll('ROLE_', '').replaceAll('_', '');
    for (final r in Role.values) {
      if (r.api.replaceAll('_', '') == v) return r;
    }
    return Role.client;
  }
}
