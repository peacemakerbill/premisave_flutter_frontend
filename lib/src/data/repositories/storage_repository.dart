import '../../core/network/api_client.dart';
import '../models/json_utils.dart';
import '../models/storage_models.dart';

/// The administrators' storage endpoints of the messenger service: where attachments and call recordings are kept.
/// The .env values apply until something is saved here, and a delete goes back to them.
class StorageRepository {
  StorageRepository(this._api);

  final ApiClient _api;

  static const String _base = '/api/storage-settings';

  Future<StorageSettings> settings() async => StorageSettings.fromJson(asMap(await _api.get(_base)));

  Map<String, dynamic> _attachmentsBody({
    required String mode,
    required String root,
    required String networkMountPath,
    required String networkDirectory,
    required bool networkRequireMount,
  }) =>
      <String, dynamic>{
        'mode': mode,
        'root': root,
        'networkMountPath': networkMountPath,
        'networkDirectory': networkDirectory,
        'networkRequireMount': networkRequireMount,
      };

  /// Tries the values (the folder is created and written to) without saving them.
  Future<StorageCheck> checkAttachments({
    required String mode,
    required String root,
    required String networkMountPath,
    required String networkDirectory,
    required bool networkRequireMount,
  }) async =>
      StorageCheck.fromJson(asMap(await _api.post(
        '$_base/attachments/check',
        body: _attachmentsBody(
          mode: mode,
          root: root,
          networkMountPath: networkMountPath,
          networkDirectory: networkDirectory,
          networkRequireMount: networkRequireMount,
        ),
      )));

  Future<StorageSettings> saveAttachments({
    required String mode,
    required String root,
    required String networkMountPath,
    required String networkDirectory,
    required bool networkRequireMount,
  }) async =>
      StorageSettings.fromJson(asMap(await _api.put(
        '$_base/attachments',
        body: _attachmentsBody(
          mode: mode,
          root: root,
          networkMountPath: networkMountPath,
          networkDirectory: networkDirectory,
          networkRequireMount: networkRequireMount,
        ),
      )));

  Future<StorageSettings> resetAttachments() async => StorageSettings.fromJson(asMap(await _api.delete('$_base/attachments')));

  Future<StorageCheck> checkRecordings({required String subfolder, required int minFreeMb}) async =>
      StorageCheck.fromJson(asMap(await _api.post(
        '$_base/recordings/check',
        body: <String, dynamic>{'subfolder': subfolder, 'minFreeMb': minFreeMb},
      )));

  Future<StorageSettings> saveRecordings({required String subfolder, required int minFreeMb}) async =>
      StorageSettings.fromJson(asMap(await _api.put(
        '$_base/recordings',
        body: <String, dynamic>{'subfolder': subfolder, 'minFreeMb': minFreeMb},
      )));

  Future<StorageSettings> resetRecordings() async => StorageSettings.fromJson(asMap(await _api.delete('$_base/recordings')));
}

/// The administrators' storage endpoints of the auth service: where Home Owner application documents are kept.
class DocumentStorageRepository {
  DocumentStorageRepository(this._api);

  final ApiClient _api;

  static const String _base = '/admin/storage-settings';

  Future<DocumentStorageSettings> settings() async => DocumentStorageSettings.fromJson(asMap(await _api.get(_base)));

  Map<String, dynamic> _body({
    required String type,
    required String localPath,
    required String networkProtocol,
    required String networkHost,
    required String networkShare,
    required String networkMountPath,
    required String networkDirectory,
    required bool networkRequireMount,
    required int minFreeMb,
  }) =>
      <String, dynamic>{
        'type': type,
        'localPath': localPath,
        'networkProtocol': networkProtocol,
        'networkHost': networkHost,
        'networkShare': networkShare,
        'networkMountPath': networkMountPath,
        'networkDirectory': networkDirectory,
        'networkRequireMount': networkRequireMount,
        'minFreeMb': minFreeMb,
      };

  /// Tries the values (the folder is created and written to) without saving them.
  Future<StorageCheck> check({
    required String type,
    required String localPath,
    required String networkProtocol,
    required String networkHost,
    required String networkShare,
    required String networkMountPath,
    required String networkDirectory,
    required bool networkRequireMount,
    required int minFreeMb,
  }) async =>
      StorageCheck.fromJson(asMap(await _api.post(
        '$_base/check',
        body: _body(
          type: type,
          localPath: localPath,
          networkProtocol: networkProtocol,
          networkHost: networkHost,
          networkShare: networkShare,
          networkMountPath: networkMountPath,
          networkDirectory: networkDirectory,
          networkRequireMount: networkRequireMount,
          minFreeMb: minFreeMb,
        ),
      )));

  Future<DocumentStorageSettings> save({
    required String type,
    required String localPath,
    required String networkProtocol,
    required String networkHost,
    required String networkShare,
    required String networkMountPath,
    required String networkDirectory,
    required bool networkRequireMount,
    required int minFreeMb,
  }) async =>
      DocumentStorageSettings.fromJson(asMap(await _api.put(
        _base,
        body: _body(
          type: type,
          localPath: localPath,
          networkProtocol: networkProtocol,
          networkHost: networkHost,
          networkShare: networkShare,
          networkMountPath: networkMountPath,
          networkDirectory: networkDirectory,
          networkRequireMount: networkRequireMount,
          minFreeMb: minFreeMb,
        ),
      )));

  Future<DocumentStorageSettings> reset() async => DocumentStorageSettings.fromJson(asMap(await _api.delete(_base)));
}
