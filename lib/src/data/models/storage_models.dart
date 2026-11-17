import 'json_utils.dart';

/// The .env values that "Reset to .env" goes back to.
class StorageEnvValues {
  const StorageEnvValues({
    this.mode = 'LOCAL',
    this.root = '',
    this.networkMountPath = '',
    this.networkDirectory = '',
    this.networkRequireMount = true,
  });

  final String mode;
  final String root;
  final String networkMountPath;
  final String networkDirectory;
  final bool networkRequireMount;

  factory StorageEnvValues.fromJson(Map<String, dynamic> j) => StorageEnvValues(
        mode: strOr(j['mode'], 'LOCAL'),
        root: strOr(j['root']),
        networkMountPath: strOr(j['networkMountPath']),
        networkDirectory: strOr(j['networkDirectory']),
        networkRequireMount: boolOr(j['networkRequireMount'], true),
      );
}

/// Where chat attachments, group photos and status media are kept.
class AttachmentsStorage {
  const AttachmentsStorage({
    this.source = 'ENV',
    this.mode = 'LOCAL',
    this.root = '',
    this.networkMountPath = '',
    this.networkDirectory = '',
    this.networkRequireMount = true,
    this.location = '',
    this.ready = true,
    this.problem,
    this.freeMb,
    this.env = const StorageEnvValues(),
  });

  /// DASHBOARD when an administrator saved the values, ENV while the .env values apply.
  final String source;

  /// LOCAL (a folder on the server) or NETWORK (a share the operating system has mounted).
  final String mode;
  final String root;
  final String networkMountPath;
  final String networkDirectory;
  final bool networkRequireMount;

  /// The folder files are stored in right now, as the service sees it.
  final String location;
  final bool ready;
  final String? problem;
  final int? freeMb;
  final StorageEnvValues env;

  bool get fromDashboard => source == 'DASHBOARD';
  bool get isNetwork => mode == 'NETWORK';

  factory AttachmentsStorage.fromJson(Map<String, dynamic> j) => AttachmentsStorage(
        source: strOr(j['source'], 'ENV'),
        mode: strOr(j['mode'], 'LOCAL'),
        root: strOr(j['root']),
        networkMountPath: strOr(j['networkMountPath']),
        networkDirectory: strOr(j['networkDirectory']),
        networkRequireMount: boolOr(j['networkRequireMount'], true),
        location: strOr(j['location']),
        ready: boolOr(j['ready'], true),
        problem: str(j['problem']),
        freeMb: intOrNull(j['freeMb']),
        env: StorageEnvValues.fromJson(asMap(j['env'])),
      );
}

/// Where call recordings go. The recorder's shared folder is fixed by its Docker mount, so an administrator
/// picks a folder inside it, and the free space below which recording is refused.
class RecordingsStorage {
  const RecordingsStorage({
    this.source = 'ENV',
    this.mode = 'LOCAL',
    this.sharedFolder = '',
    this.subfolder = '',
    this.minFreeMb = 0,
    this.envMinFreeMb = 0,
    this.location = '',
    this.ready = true,
    this.problem,
    this.freeMb,
  });

  final String source;
  final String mode;

  bool get isNetwork => mode == 'NETWORK';
  final String sharedFolder;
  final String subfolder;
  final int minFreeMb;
  final int envMinFreeMb;
  final String location;
  final bool ready;
  final String? problem;
  final int? freeMb;

  bool get fromDashboard => source == 'DASHBOARD';

  factory RecordingsStorage.fromJson(Map<String, dynamic> j) => RecordingsStorage(
        source: strOr(j['source'], 'ENV'),
        mode: strOr(j['mode'], 'LOCAL'),
        sharedFolder: strOr(j['sharedFolder']),
        subfolder: strOr(j['subfolder']),
        minFreeMb: intOr(j['minFreeMb']),
        envMinFreeMb: intOr(j['envMinFreeMb']),
        location: strOr(j['location']),
        ready: boolOr(j['ready'], true),
        problem: str(j['problem']),
        freeMb: intOrNull(j['freeMb']),
      );
}

/// Everything the administrators' storage screen shows.
class StorageSettings {
  const StorageSettings({
    this.allowedRoots = const <String>[],
    this.attachments = const AttachmentsStorage(),
    this.recordings = const RecordingsStorage(),
  });

  /// The folders an administrator may choose from (STORAGE_ALLOWED_ROOTS in .env).
  final List<String> allowedRoots;
  final AttachmentsStorage attachments;
  final RecordingsStorage recordings;

  /// Changes whenever something an administrator can edit changes, so the form starts again from the saved values.
  String get fingerprint =>
      '${attachments.source}|${attachments.location}|${attachments.mode}|${recordings.source}|${recordings.location}|${recordings.minFreeMb}';

  factory StorageSettings.fromJson(Map<String, dynamic> j) => StorageSettings(
        allowedRoots: stringList(j['allowedRoots']),
        attachments: AttachmentsStorage.fromJson(asMap(j['attachments'])),
        recordings: RecordingsStorage.fromJson(asMap(j['recordings'])),
      );
}

/// The result of trying a storage setting without saving it.
class StorageCheck {
  const StorageCheck({required this.ok, this.problem, this.location, this.freeMb});

  final bool ok;
  final String? problem;
  final String? location;
  final int? freeMb;

  factory StorageCheck.fromJson(Map<String, dynamic> j) => StorageCheck(
        ok: boolOr(j['ok']),
        problem: str(j['problem']),
        location: str(j['location']),
        freeMb: intOrNull(j['freeMb']),
      );
}

/// The .env values of the sign-up service's document storage, which "Reset to .env" goes back to.
class DocumentStorageEnv {
  const DocumentStorageEnv({
    this.type = 'LOCAL',
    this.localPath = '',
    this.networkProtocol = 'SMB',
    this.networkHost = '',
    this.networkShare = '',
    this.networkMountPath = '',
    this.networkDirectory = '',
    this.networkRequireMount = true,
    this.minFreeMb = 0,
  });

  final String type;
  final String localPath;
  final String networkProtocol;
  final String networkHost;
  final String networkShare;
  final String networkMountPath;
  final String networkDirectory;
  final bool networkRequireMount;
  final int minFreeMb;

  factory DocumentStorageEnv.fromJson(Map<String, dynamic> j) => DocumentStorageEnv(
        type: strOr(j['type'], 'LOCAL'),
        localPath: strOr(j['localPath']),
        networkProtocol: strOr(j['networkProtocol'], 'SMB'),
        networkHost: strOr(j['networkHost']),
        networkShare: strOr(j['networkShare']),
        networkMountPath: strOr(j['networkMountPath']),
        networkDirectory: strOr(j['networkDirectory']),
        networkRequireMount: boolOr(j['networkRequireMount'], true),
        minFreeMb: intOr(j['minFreeMb']),
      );
}

/// Where the auth service keeps the documents people upload with a Home Owner application.
class DocumentStorage {
  const DocumentStorage({
    this.source = 'ENV',
    this.type = 'LOCAL',
    this.localPath = '',
    this.networkProtocol = 'SMB',
    this.networkHost = '',
    this.networkShare = '',
    this.networkMountPath = '',
    this.networkDirectory = '',
    this.networkRequireMount = true,
    this.minFreeMb = 0,
    this.location = '',
    this.ready = true,
    this.problem,
    this.freeMb,
    this.env = const DocumentStorageEnv(),
  });

  /// DASHBOARD when an administrator saved the values, ENV while the .env values apply.
  final String source;
  final String type;
  final String localPath;
  final String networkProtocol;
  final String networkHost;
  final String networkShare;
  final String networkMountPath;
  final String networkDirectory;
  final bool networkRequireMount;
  final int minFreeMb;

  /// The folder files are stored in right now, as the service sees it.
  final String location;
  final bool ready;
  final String? problem;
  final int? freeMb;
  final DocumentStorageEnv env;

  bool get fromDashboard => source == 'DASHBOARD';

  factory DocumentStorage.fromJson(Map<String, dynamic> j) => DocumentStorage(
        source: strOr(j['source'], 'ENV'),
        type: strOr(j['type'], 'LOCAL'),
        localPath: strOr(j['localPath']),
        networkProtocol: strOr(j['networkProtocol'], 'SMB'),
        networkHost: strOr(j['networkHost']),
        networkShare: strOr(j['networkShare']),
        networkMountPath: strOr(j['networkMountPath']),
        networkDirectory: strOr(j['networkDirectory']),
        networkRequireMount: boolOr(j['networkRequireMount'], true),
        minFreeMb: intOr(j['minFreeMb']),
        location: strOr(j['location']),
        ready: boolOr(j['ready'], true),
        problem: str(j['problem']),
        freeMb: intOrNull(j['freeMb']),
        env: DocumentStorageEnv.fromJson(asMap(j['env'])),
      );
}

/// What the administrators' storage screen shows for the auth service.
class DocumentStorageSettings {
  const DocumentStorageSettings({this.allowedRoots = const <String>[], this.documents = const DocumentStorage()});

  final List<String> allowedRoots;
  final DocumentStorage documents;

  /// Changes whenever something an administrator can edit changes, so the form starts again from the saved values.
  String get fingerprint => '${documents.source}|${documents.location}|${documents.type}|${documents.minFreeMb}';

  factory DocumentStorageSettings.fromJson(Map<String, dynamic> j) => DocumentStorageSettings(
        allowedRoots: stringList(j['allowedRoots']),
        documents: DocumentStorage.fromJson(asMap(j['documents'])),
      );
}

/// One folder in the folder picker.
class FolderEntry {
  const FolderEntry({required this.name, required this.path});

  final String name;

  /// The full path on the server.
  final String path;

  factory FolderEntry.fromJson(Map<String, dynamic> j) => FolderEntry(name: strOr(j['name']), path: strOr(j['path']));
}

/// What the server answered when asked for the folders inside a folder. [top] is the list of folders an administrator
/// may choose from, shown before any folder is opened.
class FolderListing {
  const FolderListing({
    this.path = '',
    this.parent,
    this.top = false,
    this.exists = true,
    this.canCreate = false,
    this.writable = false,
    this.freeMb,
    this.truncated = false,
    this.folders = const <FolderEntry>[],
  });

  final String path;

  /// The folder above. Empty when the parent is the list of allowed folders, null in that list.
  final String? parent;
  final bool top;

  /// False for a folder that is allowed but has not been created yet. Choosing it creates it.
  final bool exists;
  final bool canCreate;
  final bool writable;
  final int? freeMb;
  final bool truncated;
  final List<FolderEntry> folders;

  factory FolderListing.fromJson(Map<String, dynamic> j) => FolderListing(
        path: strOr(j['path']),
        parent: j['parent'] == null ? null : strOr(j['parent']),
        top: boolOr(j['top']),
        exists: boolOr(j['exists'], true),
        canCreate: boolOr(j['canCreate']),
        writable: boolOr(j['writable']),
        freeMb: intOrNull(j['freeMb']),
        truncated: boolOr(j['truncated']),
        folders: mapList(j['folders']).map(FolderEntry.fromJson).toList(),
      );
}
