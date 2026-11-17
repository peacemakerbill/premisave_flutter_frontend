import '../../core/utils/audit_labels.dart';
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
        outcome = str(j['outcome']),
        userId = str(j['userId']),
        userName = str(j['userName']),
        userEmail = str(j['userEmail']),
        actor = str(j['actor']),
        actorName = str(j['actorName']),
        actorEmail = str(j['actorEmail']),
        actorRole = str(j['actorRole']),
        subject = str(j['subjectMasked']),
        ipAddress = str(j['ipAddress']),
        country = str(j['country']),
        region = str(j['region']),
        city = str(j['city']),
        userAgent = str(j['userAgent']),
        deviceLabel = str(j['deviceLabel']),
        deviceType = str(j['deviceType']),
        os = str(j['os']),
        browser = str(j['browser']),
        sessionId = str(j['sessionId']),
        deviceId = str(j['deviceId']),
        targetType = str(j['targetType']),
        targetId = str(j['targetId']),
        targetLabel = str(j['targetLabel']),
        requestMethod = str(j['requestMethod']),
        requestPath = str(j['requestPath']),
        reason = str(j['reason']),
        details = asMap(j['details']).map((k, v) => MapEntry(k, v.toString())),
        createdAt = dateOrNull(j['createdAt']);

  final String? id;
  final String type;
  final String severity;

  /// SUCCESS or FAILURE. Older events have none.
  final String? outcome;

  /// The person it happened to, and who did it. Names and emails come from the admin trail only.
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? actor;
  final String? actorName;
  final String? actorEmail;
  final String? actorRole;
  final String? subject;
  final String? ipAddress;
  final String? country;
  final String? region;
  final String? city;
  final String? userAgent;
  final String? deviceLabel;
  final String? deviceType;
  final String? os;
  final String? browser;
  final String? sessionId;
  final String? deviceId;
  final String? targetType;
  final String? targetId;
  final String? targetLabel;
  final String? requestMethod;
  final String? requestPath;
  final String? reason;
  final Map<String, String> details;
  final DateTime? createdAt;

  /// "Failed sign in" for SIGN_IN_FAILED. Kinds the app does not know are turned into a sentence.
  String get title => auditLabel(type).title;

  /// One sentence on what this kind of event means.
  String get description => auditLabel(type).description;

  String get category => auditLabel(type).category;

  bool get isWarning => severity == 'WARNING' || severity == 'WARN';
  bool get isCritical => severity == 'CRITICAL' || severity == 'ALERT' || severity == 'HIGH';
  bool get isFailure => (outcome ?? '').toUpperCase() == 'FAILURE';

  /// The person the event is about: their name, else their email, else the masked address kept with the event.
  String? get personLabel => userName ?? userEmail ?? subject;

  /// The person who did it. "System" and "Not signed in" stand in when no one was signed in.
  String? get actorLabel {
    if (actorName != null) return actorName;
    if (actorEmail != null) return actorEmail;
    final a = (actor ?? '').toUpperCase();
    if (a == 'SYSTEM') return 'The system';
    if (a == 'ANONYMOUS') return 'Not signed in';
    return actor;
  }

  /// "Chrome on Linux", from what the sign in reported.
  String get browserAndOs => browserAndSystem(browser, os);

  String get place => placeLabel(city, region, country);
}

/// One row of the summary: an event type and how many times it happened.
class EventCount {
  EventCount(Map<String, dynamic> j)
      : key = strOr(j['key']),
        count = intOr(j['count']);

  final String key;
  final int count;
}

/// GET /admin/security/summary
class AuditSummary {
  AuditSummary(Map<String, dynamic> j)
      : from = dateOrNull(j['from']),
        to = dateOrNull(j['to']),
        total = intOr(j['total']),
        info = intOr(j['info']),
        warning = intOr(j['warning']),
        critical = intOr(j['critical']),
        failures = intOr(j['failures']),
        signIns = intOr(j['signIns']),
        failedSignIns = intOr(j['failedSignIns']),
        lockouts = intOr(j['lockouts']),
        adminChanges = intOr(j['adminChanges']),
        people = intOr(j['people']),
        addresses = intOr(j['addresses']),
        topTypes = mapList(j['topTypes']).map(EventCount.new).toList();

  final DateTime? from;
  final DateTime? to;
  final int total;
  final int info;
  final int warning;
  final int critical;
  final int failures;
  final int signIns;
  final int failedSignIns;
  final int lockouts;
  final int adminChanges;
  final int people;
  final int addresses;
  final List<EventCount> topTypes;
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
