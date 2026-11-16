import 'json_utils.dart';

class SessionView {
  SessionView(Map<String, dynamic> j)
      : id = strOr(j['id']),
        current = boolOr(j['current']),
        deviceId = str(j['deviceId']),
        deviceLabel = strOr(j['deviceLabel'], 'Unknown device'),
        method = str(j['method']),
        ipAddress = str(j['ipAddress']),
        country = str(j['country']),
        region = str(j['region']),
        city = str(j['city']),
        createdAt = dateOrNull(j['createdAt']),
        lastSeenAt = dateOrNull(j['lastSeenAt']),
        expiresAt = dateOrNull(j['expiresAt']);

  final String id;
  final bool current;
  final String? deviceId;
  final String deviceLabel;
  final String? method;
  final String? ipAddress;
  final String? country;
  final String? region;
  final String? city;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;
  final DateTime? expiresAt;

  String get place => placeLabel(city, region, country);
}

class DeviceView {
  DeviceView(Map<String, dynamic> j)
      : id = strOr(j['id']),
        current = boolOr(j['current']),
        label = strOr(j['label'], 'Unknown device'),
        deviceType = str(j['deviceType']),
        os = str(j['os']),
        browser = str(j['browser']),
        firstSeenAt = dateOrNull(j['firstSeenAt']),
        lastSeenAt = dateOrNull(j['lastSeenAt']),
        lastIp = str(j['lastIp']),
        country = str(j['country']),
        region = str(j['region']),
        city = str(j['city']),
        signInCount = intOr(j['signInCount']),
        trusted = boolOr(j['trusted']),
        trustedAt = dateOrNull(j['trustedAt']),
        trustRevokedAt = dateOrNull(j['trustRevokedAt']),
        activeSessions = intOr(j['activeSessions']);

  final String id;
  final bool current;
  final String label;
  final String? deviceType;
  final String? os;
  final String? browser;
  final DateTime? firstSeenAt;
  final DateTime? lastSeenAt;
  final String? lastIp;
  final String? country;
  final String? region;
  final String? city;
  final int signInCount;
  final bool trusted;
  final DateTime? trustedAt;
  final DateTime? trustRevokedAt;
  final int activeSessions;

  String get place => placeLabel(city, region, country);
}

class SignInView {
  SignInView(Map<String, dynamic> j)
      : sessionId = str(j['sessionId']),
        deviceId = str(j['deviceId']),
        deviceLabel = strOr(j['deviceLabel'], 'Unknown device'),
        at = dateOrNull(j['at']),
        ipAddress = str(j['ipAddress']),
        country = str(j['country']),
        region = str(j['region']),
        city = str(j['city']),
        method = str(j['method']),
        newDevice = boolOr(j['newDevice']),
        riskScore = intOr(j['riskScore']),
        riskReasons = stringList(j['riskReasons']);

  final String? sessionId;
  final String? deviceId;
  final String deviceLabel;
  final DateTime? at;
  final String? ipAddress;
  final String? country;
  final String? region;
  final String? city;
  final String? method;
  final bool newDevice;
  final int riskScore;
  final List<String> riskReasons;

  String get place => placeLabel(city, region, country);
  bool get risky => riskScore >= 40 || riskReasons.isNotEmpty;
}

class DeviceDetail {
  DeviceDetail(Map<String, dynamic> j)
      : device = DeviceView(asMap(j['device'])),
        recentSignIns = mapList(j['recentSignIns']).map(SignInView.new).toList();

  final DeviceView device;
  final List<SignInView> recentSignIns;
}

class SecurityEventView {
  SecurityEventView(Map<String, dynamic> j)
      : id = str(j['id']),
        type = strOr(j['type']),
        severity = strOr(j['severity'], 'INFO'),
        userId = str(j['userId']),
        actor = str(j['actor']),
        subject = str(j['subjectMasked']),
        ipAddress = str(j['ipAddress']),
        reason = str(j['reason']),
        details = asMap(j['details']).map((k, v) => MapEntry(k, v.toString())),
        createdAt = dateOrNull(j['createdAt']);

  final String? id;
  final String type;
  final String severity;
  final String? userId;
  final String? actor;
  final String? subject;
  final String? ipAddress;
  final String? reason;
  final Map<String, String> details;
  final DateTime? createdAt;

  /// SIGN_IN_FAILED becomes "Sign in failed".
  String get title {
    final t = type.toLowerCase().replaceAll('_', ' ');
    return t.isEmpty ? 'Event' : t[0].toUpperCase() + t.substring(1);
  }

  bool get isWarning => severity == 'WARNING' || severity == 'WARN';
  bool get isCritical => severity == 'CRITICAL' || severity == 'ALERT' || severity == 'HIGH';
}

class CountResult {
  CountResult(Map<String, dynamic> j)
      : count = intOr(j['count']),
        message = strOr(j['message']);

  final int count;
  final String message;
}

/// POST /auth/security-actions/inspect
class ReportPreview {
  ReportPreview(Map<String, dynamic> j)
      : signedInAt = dateOrNull(j['signedInAt']),
        device = str(j['device']),
        approximateLocation = str(j['approximateLocation']),
        maskedIp = str(j['maskedIp']),
        method = str(j['method']),
        sessionStillActive = boolOr(j['sessionStillActive']);

  final DateTime? signedInAt;
  final String? device;
  final String? approximateLocation;
  final String? maskedIp;
  final String? method;
  final bool sessionStillActive;
}

/// POST /auth/security-actions/confirm
class ReportResult {
  ReportResult(Map<String, dynamic> j)
      : sessionRevoked = boolOr(j['sessionRevoked']),
        deviceTrustRemoved = boolOr(j['deviceTrustRemoved']),
        passwordResetEmailSent = boolOr(j['passwordResetEmailSent']),
        message = strOr(j['message']);

  final bool sessionRevoked;
  final bool deviceTrustRemoved;
  final bool passwordResetEmailSent;
  final String message;
}

String placeLabel(String? city, String? region, String? country) {
  final parts = <String>[
    if (city != null && city.isNotEmpty) city,
    if (region != null && region.isNotEmpty && region != city) region,
    if (country != null && country.isNotEmpty) country,
  ];
  return parts.isEmpty ? 'Unknown location' : parts.join(', ');
}
