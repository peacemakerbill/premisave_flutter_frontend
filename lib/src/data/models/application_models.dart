import 'json_utils.dart';

class Option {
  Option(Map<String, dynamic> j)
      : value = strOr(j['value'] ?? j['code']),
        label = strOr(j['label'] ?? j['name'] ?? j['value']),
        description = str(j['description']);

  final String value;
  final String label;
  final String? description;
}

class DocumentTypeOption {
  DocumentTypeOption(Map<String, dynamic> j)
      : value = strOr(j['value']),
        label = strOr(j['label']),
        description = strOr(j['description']),
        category = strOr(j['category']),
        allowsMultiple = boolOr(j['allowsMultiple']),
        maxFiles = intOr(j['maxFiles'], 1);

  final String value;
  final String label;
  final String description;
  final String category;
  final bool allowsMultiple;
  final int maxFiles;
}

class RequirementOption {
  RequirementOption(Map<String, dynamic> j)
      : key = strOr(j['key']),
        label = strOr(j['label']),
        description = strOr(j['description']),
        required = boolOr(j['required']),
        acceptedCombinations = _combos(j['acceptedCombinations']);

  final String key;
  final String label;
  final String description;
  final bool required;
  final List<List<String>> acceptedCombinations;
}

List<List<String>> _combos(Object? v) {
  if (v is List) return v.map<List<String>>((e) => stringList(e)).toList();
  return <List<String>>[];
}

class UploadLimits {
  UploadLimits(Map<String, dynamic> j)
      : maxFileSizeBytes = intOr(j['maxFileSizeBytes'], 10 * 1024 * 1024),
        maxFileSizeLabel = strOr(j['maxFileSizeLabel'], '10 MB'),
        allowedExtensions = stringList(j['allowedExtensions']),
        allowedMimeTypes = stringList(j['allowedMimeTypes']),
        maxDocuments = intOr(j['maxDocuments'], 20);

  final int maxFileSizeBytes;
  final String maxFileSizeLabel;
  final List<String> allowedExtensions;
  final List<String> allowedMimeTypes;
  final int maxDocuments;
}

/// GET /home-owner/applications/meta. Drives every dropdown in the application form.
class AppMeta {
  AppMeta(Map<String, dynamic> j)
      : ownerTypes = mapList(j['ownerTypes']).map(Option.new).toList(),
        idTypes = mapList(j['idTypes']).map(Option.new).toList(),
        propertyTypes = mapList(j['propertyTypes']).map(Option.new).toList(),
        managementPreferences = mapList(j['managementPreferences']).map(Option.new).toList(),
        payoutMethods = mapList(j['payoutMethods']).map(Option.new).toList(),
        referralSources = mapList(j['referralSources']).map(Option.new).toList(),
        statuses = mapList(j['statuses']).map(Option.new).toList(),
        documentTypes = mapList(j['documentTypes']).map(DocumentTypeOption.new).toList(),
        countries = mapList(j['countries']).map(Option.new).toList(),
        limits = UploadLimits(asMap(j['limits'])),
        reviewTimeHint = str(j['reviewTimeHint']),
        requirementsByOwnerType = asMap(j['requirementsByOwnerType']).map(
          (k, v) => MapEntry(k, mapList(v).map(RequirementOption.new).toList()),
        );

  final List<Option> ownerTypes;
  final List<Option> idTypes;
  final List<Option> propertyTypes;
  final List<Option> managementPreferences;
  final List<Option> payoutMethods;
  final List<Option> referralSources;
  final List<Option> statuses;
  final List<DocumentTypeOption> documentTypes;
  final List<Option> countries;
  final UploadLimits limits;
  final String? reviewTimeHint;
  final Map<String, List<RequirementOption>> requirementsByOwnerType;

  DocumentTypeOption? documentType(String value) {
    for (final d in documentTypes) {
      if (d.value == value) return d;
    }
    return null;
  }

  String labelFor(List<Option> options, String? value) {
    if (value == null) return '';
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return value;
  }
}

class Eligibility {
  Eligibility(Map<String, dynamic> j)
      : canApply = boolOr(j['canApply']),
        reason = str(j['reason']),
        openApplicationId = str(j['openApplicationId']),
        openApplicationStatus = str(j['openApplicationStatus']);

  final bool canApply;
  final String? reason;
  final String? openApplicationId;
  final String? openApplicationStatus;
}

class ReviewerRef {
  ReviewerRef(Map<String, dynamic> j)
      : id = strOr(j['id']),
        name = strOr(j['name']);

  final String id;
  final String name;
}

class StaffMember {
  StaffMember(Map<String, dynamic> j)
      : id = strOr(j['id']),
        name = strOr(j['name']),
        email = strOr(j['email']),
        role = strOr(j['role']);

  final String id;
  final String name;
  final String email;
  final String role;
}

class ApplicationSummary {
  ApplicationSummary(Map<String, dynamic> j)
      : id = strOr(j['id']),
        applicationNumber = strOr(j['applicationNumber']),
        status = strOr(j['status']),
        statusLabel = strOr(j['statusLabel'], strOr(j['status'])),
        statusColor = str(j['statusColor']),
        applicantName = strOr(j['applicantName']),
        applicantEmail = strOr(j['applicantEmail']),
        phoneNumber = str(j['phoneNumber']),
        ownerType = str(j['ownerType']),
        country = str(j['country']),
        region = str(j['region']),
        numberOfProperties = intOrNull(j['numberOfProperties']),
        documentCount = intOr(j['documentCount']),
        verifiedDocumentCount = intOr(j['verifiedDocumentCount']),
        rejectedDocumentCount = intOr(j['rejectedDocumentCount']),
        completionPercent = intOr(j['completionPercent']),
        reviewer = j['reviewer'] is Map ? ReviewerRef(asMap(j['reviewer'])) : null,
        submissionCount = intOr(j['submissionCount']),
        submittedAt = dateOrNull(j['submittedAt']),
        waitingHours = intOr(j['waitingHours']),
        updatedAt = dateOrNull(j['updatedAt']);

  final String id;
  final String applicationNumber;
  final String status;
  final String statusLabel;
  final String? statusColor;
  final String applicantName;
  final String applicantEmail;
  final String? phoneNumber;
  final String? ownerType;
  final String? country;
  final String? region;
  final int? numberOfProperties;
  final int documentCount;
  final int verifiedDocumentCount;
  final int rejectedDocumentCount;
  final int completionPercent;
  final ReviewerRef? reviewer;
  final int submissionCount;
  final DateTime? submittedAt;
  final int waitingHours;
  final DateTime? updatedAt;
}

class PagedApplications {
  PagedApplications(Map<String, dynamic> j)
      : items = mapList(j['content']).map(ApplicationSummary.new).toList(),
        page = intOr(j['page']),
        size = intOr(j['size'], 20),
        totalElements = intOr(j['totalElements']),
        totalPages = intOr(j['totalPages'], 1);

  final List<ApplicationSummary> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  bool get hasMore => page + 1 < totalPages;
}

class StaffStats {
  StaffStats(Map<String, dynamic> j)
      : total = intOr(j['total']),
        byStatus = asMap(j['byStatus']).map((k, v) => MapEntry(k, intOr(v))),
        awaitingReview = intOr(j['awaitingReview']),
        unassigned = intOr(j['unassigned']),
        assignedToMe = intOr(j['assignedToMe']),
        needsInfoFromApplicant = intOr(j['needsInfoFromApplicant']),
        readyToPromote = intOr(j['readyToPromote']),
        averageDecisionHours = doubleOrNull(j['averageDecisionHours']),
        oldestWaitingSince = dateOrNull(j['oldestWaitingSince']),
        oldestWaitingApplicationId = str(j['oldestWaitingApplicationId']);

  final int total;
  final Map<String, int> byStatus;
  final int awaitingReview;
  final int unassigned;
  final int assignedToMe;
  final int needsInfoFromApplicant;
  final int readyToPromote;
  final double? averageDecisionHours;
  final DateTime? oldestWaitingSince;
  final String? oldestWaitingApplicationId;
}

class DocumentView {
  DocumentView(Map<String, dynamic> j)
      : id = strOr(j['id']),
        type = strOr(j['type']),
        typeLabel = strOr(j['typeLabel'], strOr(j['type'])),
        fileName = strOr(j['fileName']),
        mimeType = str(j['mimeType']),
        sizeBytes = intOr(j['sizeBytes']),
        documentNumber = str(j['documentNumber']),
        expiryDate = str(j['expiryDate']),
        status = strOr(j['status'], 'PENDING'),
        statusLabel = strOr(j['statusLabel'], strOr(j['status'])),
        reviewReason = str(j['reviewReason']),
        reviewedBy = str(j['reviewedBy']),
        uploadedAt = dateOrNull(j['uploadedAt']);

  final String id;
  final String type;
  final String typeLabel;
  final String fileName;
  final String? mimeType;
  final int sizeBytes;
  final String? documentNumber;
  final String? expiryDate;
  final String status;
  final String statusLabel;
  final String? reviewReason;
  final String? reviewedBy;
  final DateTime? uploadedAt;

  bool get verified => status == 'VERIFIED';
  bool get rejected => status == 'REJECTED';
  bool get isImage => (mimeType ?? '').startsWith('image/');
}

class RequirementView {
  RequirementView(Map<String, dynamic> j)
      : key = strOr(j['key']),
        label = strOr(j['label']),
        description = strOr(j['description']),
        required = boolOr(j['required']),
        stillNeeded = stringList(j['stillNeeded']),
        uploaded = boolOr(j['uploaded']),
        verified = boolOr(j['verified']),
        needsAttention = boolOr(j['needsAttention']);

  final String key;
  final String label;
  final String description;
  final bool required;
  final List<String> stillNeeded;
  final bool uploaded;
  final bool verified;
  final bool needsAttention;
}

class FieldIssue {
  FieldIssue(Map<String, dynamic> j)
      : field = strOr(j['field']),
        message = strOr(j['message']);

  final String field;
  final String message;
}

class Readiness {
  Readiness(Map<String, dynamic> j)
      : percent = intOr(j['percent']),
        canSubmit = boolOr(j['canSubmit']),
        allRequiredVerified = boolOr(j['allRequiredVerified']),
        issues = mapList(j['issues']).map(FieldIssue.new).toList(),
        requirements = mapList(j['requirements']).map(RequirementView.new).toList();

  final int percent;
  final bool canSubmit;
  final bool allRequiredVerified;
  final List<FieldIssue> issues;
  final List<RequirementView> requirements;

  String? issueFor(String field) {
    for (final i in issues) {
      if (i.field == field) return i.message;
    }
    return null;
  }
}

class TimelineEvent {
  TimelineEvent(Map<String, dynamic> j)
      : type = strOr(j['type']),
        fromStatus = str(j['fromStatus']),
        toStatus = str(j['toStatus']),
        actor = str(j['actor']),
        message = str(j['message']),
        at = dateOrNull(j['at']);

  final String type;
  final String? fromStatus;
  final String? toStatus;
  final String? actor;
  final String? message;
  final DateTime? at;
}

class InternalNote {
  InternalNote(Map<String, dynamic> j)
      : id = strOr(j['id']),
        author = strOr(j['author']),
        authorRole = str(j['authorRole']),
        text = strOr(j['text']),
        at = dateOrNull(j['at']);

  final String id;
  final String author;
  final String? authorRole;
  final String text;
  final DateTime? at;
}

/// Full application. The raw map stays available so form fields can be filled by key
/// without a typed getter for each of the 50 or so fields.
class ApplicationDetail {
  ApplicationDetail(this.raw)
      : documents = mapList(raw['documents']).map(DocumentView.new).toList(),
        readiness = Readiness(asMap(raw['readiness'])),
        timeline = mapList(raw['timeline']).map(TimelineEvent.new).toList(),
        internalNotes = mapList(raw['internalNotes']).map(InternalNote.new).toList(),
        reviewer = raw['reviewer'] is Map ? ReviewerRef(asMap(raw['reviewer'])) : null;

  final Map<String, dynamic> raw;
  final List<DocumentView> documents;
  final Readiness readiness;
  final List<TimelineEvent> timeline;
  final List<InternalNote> internalNotes;
  final ReviewerRef? reviewer;

  String get id => strOr(raw['id']);
  String get applicationNumber => strOr(raw['applicationNumber']);
  String get status => strOr(raw['status'], 'DRAFT');
  String get statusLabel => strOr(raw['statusLabel'], status);
  String? get statusDescription => str(raw['statusDescription']);
  String? get statusColor => str(raw['statusColor']);
  String? get nextStep => str(raw['nextStep']);
  String? get reviewTimeHint => str(raw['reviewTimeHint']);
  String? get latestMessage => str(raw['latestMessage']);
  String? get decisionReason => str(raw['decisionReason']);
  bool get editable => boolOr(raw['editable']);
  bool get canReapply => boolOr(raw['canReapply']);
  String get applicantName => strOr(raw['applicantName']);
  String get applicantEmail => strOr(raw['applicantEmail']);
  String? get ownerType => str(raw['ownerType']);
  int get submissionCount => intOr(raw['submissionCount']);
  DateTime? get submittedAt => dateOrNull(raw['submittedAt']);
  DateTime? get decidedAt => dateOrNull(raw['decidedAt']);
  DateTime? get updatedAt => dateOrNull(raw['updatedAt']);

  String? text(String key) => str(raw[key]);
  int? number(String key) => intOrNull(raw[key]);
  bool flag(String key) => boolOr(raw[key]);
  List<String> list(String key) => stringList(raw[key]);

  bool get isFinal => status == 'ACCEPTED' || status == 'REJECTED' || status == 'WITHDRAWN';
  bool get isDraft => status == 'DRAFT';
}
