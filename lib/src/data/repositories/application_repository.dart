import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/application_models.dart';
import '../models/json_utils.dart';

/// Home owner application workflow, for the applicant and for staff.
class ApplicationRepository {
  ApplicationRepository(this._api);

  final ApiClient _api;

  String _id(String s) => Uri.encodeComponent(s);

  // Applicant

  Future<AppMeta> meta() async => AppMeta(asMap(await _api.get('/home-owner/applications/meta')));

  Future<Eligibility> eligibility() async =>
      Eligibility(asMap(await _api.get('/home-owner/applications/eligibility')));

  Future<ApplicationDetail> start({String? ownerType, String? country}) async => ApplicationDetail(asMap(
        await _api.post('/home-owner/applications', body: compact({'ownerType': ownerType, 'country': country})),
      ));

  /// The applicant's current application, or null when there is none.
  Future<ApplicationDetail?> mine() async {
    try {
      final res = await _api.get('/home-owner/applications/mine');
      final m = asMap(res);
      return m.isEmpty ? null : ApplicationDetail(m);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  Future<List<ApplicationSummary>> myApplications() async =>
      mapList(await _api.get('/home-owner/applications')).map(ApplicationSummary.new).toList();

  Future<ApplicationDetail> get(String id) async =>
      ApplicationDetail(asMap(await _api.get('/home-owner/applications/${_id(id)}')));

  /// Saves any subset of the form fields.
  Future<ApplicationDetail> save(String id, Map<String, dynamic> fields) async =>
      ApplicationDetail(asMap(await _api.patch('/home-owner/applications/${_id(id)}', body: fields)));

  Future<ApplicationDetail> uploadDocument(
    String id, {
    required String type,
    required List<int> bytes,
    required String fileName,
    String? documentNumber,
    String? expiryDate,
  }) async {
    final form = FormData.fromMap({
      'type': type,
      'file': MultipartFile.fromBytes(bytes, filename: fileName),
      if (documentNumber != null && documentNumber.isNotEmpty) 'documentNumber': documentNumber,
      if (expiryDate != null && expiryDate.isNotEmpty) 'expiryDate': expiryDate,
    });
    return ApplicationDetail(asMap(await _api.upload('/home-owner/applications/${_id(id)}/documents', form)));
  }

  Future<ApplicationDetail> deleteDocument(String id, String documentId) async => ApplicationDetail(
        asMap(await _api.delete('/home-owner/applications/${_id(id)}/documents/${_id(documentId)}')),
      );

  Future<Uint8List> downloadDocument(String id, String documentId) =>
      _api.download('/home-owner/applications/${_id(id)}/documents/${_id(documentId)}/download');

  Future<ApplicationDetail> submit(String id) async =>
      ApplicationDetail(asMap(await _api.post('/home-owner/applications/${_id(id)}/submit')));

  Future<ApplicationDetail> reapply(String id) async =>
      ApplicationDetail(asMap(await _api.post('/home-owner/applications/${_id(id)}/reapply')));

  Future<ApplicationDetail> withdraw(String id, {String? reason}) async => ApplicationDetail(asMap(
        await _api.post('/home-owner/applications/${_id(id)}/withdraw', body: compact({'reason': reason})),
      ));

  Future<void> deleteDraft(String id) => _api.delete('/home-owner/applications/${_id(id)}');

  // Staff

  Future<StaffStats> staffStats() async => StaffStats(asMap(await _api.get('/staff/applications/stats')));

  Future<PagedApplications> staffSearch({
    String? q,
    List<String>? statuses,
    String? assignee,
    String sort = 'oldest',
    int page = 0,
    int size = 20,
  }) async {
    final res = await _api.get('/staff/applications', query: {
      if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      if (statuses != null && statuses.isNotEmpty) 'status': statuses.join(','),
      if (assignee != null && assignee.isNotEmpty) 'assignee': assignee,
      'sort': sort,
      'page': page,
      'size': size,
    });
    return PagedApplications(asMap(res));
  }

  Future<List<StaffMember>> reviewers() async =>
      mapList(await _api.get('/staff/applications/reviewers')).map(StaffMember.new).toList();

  Future<ApplicationDetail> staffGet(String id) async =>
      ApplicationDetail(asMap(await _api.get('/staff/applications/${_id(id)}')));

  Future<ApplicationDetail> claim(String id) async =>
      ApplicationDetail(asMap(await _api.post('/staff/applications/${_id(id)}/claim')));

  Future<ApplicationDetail> assign(String id, String reviewerId) async =>
      ApplicationDetail(asMap(await _api.put('/staff/applications/${_id(id)}/assign', body: {'reviewerId': reviewerId})));

  Future<ApplicationDetail> reviewDocument(
    String id,
    String documentId, {
    required bool verified,
    String? reason,
    bool requestReupload = false,
  }) async {
    final res = await _api.post(
      '/staff/applications/${_id(id)}/documents/${_id(documentId)}/review',
      body: compact({
        'status': verified ? 'VERIFIED' : 'REJECTED',
        'reason': reason,
        if (!verified) 'requestReupload': requestReupload,
      }),
    );
    return ApplicationDetail(asMap(res));
  }

  Future<ApplicationDetail> changeStatus(
    String id, {
    required String status,
    String? message,
    String? internalNote,
    bool? allowReapply,
  }) async {
    final res = await _api.post(
      '/staff/applications/${_id(id)}/status',
      body: compact({
        'status': status,
        'message': message,
        'internalNote': internalNote,
        'allowReapply': allowReapply,
      }),
    );
    return ApplicationDetail(asMap(res));
  }

  Future<ApplicationDetail> addNote(String id, String text) async =>
      ApplicationDetail(asMap(await _api.post('/staff/applications/${_id(id)}/notes', body: {'text': text})));

  Future<Uint8List> staffDownloadDocument(String id, String documentId) =>
      _api.download('/staff/applications/${_id(id)}/documents/${_id(documentId)}/download');

  /// Administrators only: approves a verified application and makes the applicant a home owner.
  Future<String> promote(String id, {String? message, String? internalNote}) async {
    final res = await _api.post(
      '/admin/applications/${_id(id)}/promote',
      body: compact({'message': message, 'internalNote': internalNote}),
    );
    return strOr(asMap(res)['message'], 'Application accepted.');
  }
}
