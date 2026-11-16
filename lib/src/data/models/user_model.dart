import 'json_utils.dart';

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

  bool get isStaff =>
      this == Role.operations || this == Role.finance || this == Role.support || this == Role.admin;

  static Role parse(Object? value) {
    final v = (value ?? '').toString().toUpperCase().replaceAll('ROLE_', '').replaceAll('_', '');
    for (final r in Role.values) {
      if (r.api.replaceAll('_', '') == v) return r;
    }
    return Role.client;
  }
}

class UserModel {
  const UserModel({
    required this.id,
    this.username = '',
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.email = '',
    this.phoneNumber = '',
    this.address1 = '',
    this.address2 = '',
    this.country = '',
    this.language = 'ENGLISH',
    this.profilePictureUrl,
    this.role = Role.client,
    this.verified = false,
    this.active = true,
    this.archived = false,
    this.usernameGenerated = false,
  });

  final String id;
  final String username;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String address1;
  final String address2;
  final String country;
  final String language;
  final String? profilePictureUrl;
  final Role role;
  final bool verified;
  final bool active;
  final bool archived;
  final bool usernameGenerated;

  factory UserModel.fromJson(Map<String, dynamic> j) {
    return UserModel(
      id: strOr(j['id'] ?? j['userId']),
      username: strOr(j['username']),
      firstName: strOr(j['firstName']),
      middleName: strOr(j['middleName']),
      lastName: strOr(j['lastName']),
      email: strOr(j['email']),
      phoneNumber: strOr(j['phoneNumber']),
      address1: strOr(j['address1']),
      address2: strOr(j['address2']),
      country: strOr(j['country']),
      language: strOr(j['language'], 'ENGLISH'),
      profilePictureUrl: str(j['profilePictureUrl']),
      role: Role.parse(j['role']),
      verified: boolOr(j['verified']),
      active: boolOr(j['active'], true),
      archived: boolOr(j['archived']),
      usernameGenerated: boolOr(j['usernameGenerated']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'username': username,
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'address1': address1,
        'address2': address2,
        'country': country,
        'language': language,
        'profilePictureUrl': profilePictureUrl,
        'role': role.api,
        'verified': verified,
        'active': active,
        'archived': archived,
        'usernameGenerated': usernameGenerated,
      };

  /// Best available name for display.
  String get displayName {
    final n = '$firstName $lastName'.trim();
    if (n.isNotEmpty) return n;
    if (username.isNotEmpty && !username.contains('@')) return username;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Premisave member';
  }

  String get fullName {
    final parts = <String>[firstName, middleName, lastName].where((p) => p.trim().isNotEmpty);
    final n = parts.join(' ').trim();
    return n.isEmpty ? displayName : n;
  }

  String get initials {
    final f = firstName.trim();
    final l = lastName.trim();
    if (f.isNotEmpty && l.isNotEmpty) return (f[0] + l[0]).toUpperCase();
    final d = displayName.trim();
    if (d.isEmpty) return 'P';
    final bits = d.split(RegExp(r'\s+'));
    if (bits.length > 1) return (bits[0][0] + bits[1][0]).toUpperCase();
    return d[0].toUpperCase();
  }

  UserModel copyWith({String? profilePictureUrl}) => UserModel(
        id: id,
        username: username,
        firstName: firstName,
        middleName: middleName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        address1: address1,
        address2: address2,
        country: country,
        language: language,
        profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
        role: role,
        verified: verified,
        active: active,
        archived: archived,
        usernameGenerated: usernameGenerated,
      );
}
