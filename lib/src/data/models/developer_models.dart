import 'json_utils.dart';

/// A developer account on the developer service. These accounts are separate from the auth-service accounts.
class DeveloperAccount {
  DeveloperAccount.fromJson(Map<String, dynamic> j)
      : developerId = strOr(j['developerId']),
        email = strOr(j['email']),
        username = str(j['username']),
        fullName = strOr(j['fullName'], strOr(j['email'])),
        companyName = str(j['companyName']),
        country = str(j['country']),
        emailVerified = boolOr(j['emailVerified']),
        status = strOr(j['status'], 'ACTIVE'),
        role = strOr(j['role'], 'DEVELOPER');

  final String developerId;
  final String email;
  final String? username;
  final String fullName;
  final String? companyName;
  final String? country;
  final bool emailVerified;
  final String status;
  final String role;
}

/// Google, Facebook or GitHub as a person would write it, from the key the service uses.
String providerLabel(String key) {
  switch (key) {
    case 'google':
      return 'Google';
    case 'facebook':
      return 'Facebook';
    case 'github':
      return 'GitHub';
    default:
      return key.isEmpty ? 'The provider' : key;
  }
}

/// One provider account (Google, Facebook or GitHub) joined to a developer account.
class DeveloperConnection {
  DeveloperConnection.fromJson(Map<String, dynamic> j)
      : provider = strOr(j['provider']),
        email = str(j['email']),
        linkedAt = dateOrNull(j['linkedAt']);

  final String provider;
  final String? email;
  final DateTime? linkedAt;
}

/// What a developer account has joined, and whether it still has a password to fall back on.
class DeveloperConnections {
  DeveloperConnections.fromJson(Map<String, dynamic> j)
      : connections = mapList(j['connections']).map(DeveloperConnection.fromJson).toList(),
        hasPassword = boolOr(j['hasPassword']),
        available = stringList(j['available']);

  final List<DeveloperConnection> connections;
  final bool hasPassword;

  /// The providers the service has switched on.
  final List<String> available;

  DeveloperConnection? of(String provider) {
    for (final c in connections) {
      if (c.provider == provider) return c;
    }
    return null;
  }
}

class DeveloperApp {
  DeveloperApp.fromJson(Map<String, dynamic> j)
      : appId = strOr(j['appId']),
        name = strOr(j['name'], 'App'),
        description = str(j['description']),
        environment = strOr(j['environment'], 'sandbox'),
        status = strOr(j['status'], 'ACTIVE'),
        merchantNumber = str(j['merchantNumber']),
        callbackUrl = str(j['callbackUrl']),
        enabledMethods = stringList(j['enabledMethods']),
        createdAt = dateOrNull(j['createdAt']);

  final String appId;
  final String name;
  final String? description;

  /// "sandbox" or "production".
  final String environment;
  final String status;
  final String? merchantNumber;
  final String? callbackUrl;
  final List<String> enabledMethods;
  final DateTime? createdAt;

  bool get isSandbox => environment.toLowerCase() == 'sandbox';
  bool get suspended => status == 'SUSPENDED';
}

class ApiKeyModel {
  ApiKeyModel.fromJson(Map<String, dynamic> j)
      : key = strOr(j['key']),
        label = str(j['label']),
        status = strOr(j['status'], 'ACTIVE'),
        secretEndsWith = str(j['secretEndsWith']),
        secret = str(j['secret']),
        createdAt = dateOrNull(j['createdAt']),
        lastUsedAt = dateOrNull(j['lastUsedAt']);

  final String key;
  final String? label;
  final String status;
  final String? secretEndsWith;

  /// Present only in the reply that creates or rotates a key. It cannot be read again.
  final String? secret;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;

  bool get revoked => status != 'ACTIVE';
}
