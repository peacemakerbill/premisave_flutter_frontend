import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/files/file_kinds.dart';
import '../core/files/file_store.dart';
import '../data/models/file_ref.dart';

// Where downloaded files go, and which files have been downloaded.
//
// By default everything goes to Downloads/Premisave, in a subfolder for each kind of file:
// "Premisave Images", "Premisave Video", "Premisave Audio", "Premisave Documents" and "Premisave Other".
// The person can move the main folder or any single subfolder from the messenger settings.

// ------------------------------------------------------------------ settings

class FileSettings {
  const FileSettings({this.root, this.folders = const <FileCategory, String>{}});

  /// A chosen main folder. Null means Downloads/Premisave.
  final String? root;

  /// A folder chosen for one kind of file. Missing means a default subfolder.
  final Map<FileCategory, String> folders;

  FileSettings copyWith({String? root, bool clearRoot = false, Map<FileCategory, String>? folders}) =>
      FileSettings(root: clearRoot ? null : (root ?? this.root), folders: folders ?? this.folders);
}

class FileSettingsController extends Notifier<FileSettings> {
  static const String _kRoot = 'msgr_dl_root';
  static String _kFolder(FileCategory c) => 'msgr_dl_${c.name}';

  bool _loaded = false;

  @override
  FileSettings build() {
    _load();
    return const FileSettings();
  }

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final folders = <FileCategory, String>{};
      for (final c in FileCategory.values) {
        final v = prefs.getString(_kFolder(c));
        if (v != null && v.isNotEmpty) folders[c] = v;
      }
      state = FileSettings(root: prefs.getString(_kRoot), folders: folders);
    } catch (_) {
      // Unreadable storage: keep the defaults.
    }
  }

  /// The main folder files go under when no folder is chosen for their kind.
  Future<String> rootFolder() async {
    final chosen = state.root;
    if (chosen != null && chosen.isNotEmpty) return chosen;
    final downloads = await fileStoreDownloadsRoot();
    return joinPath(downloads ?? '', 'Premisave');
  }

  /// The folder a file of this kind is saved into.
  Future<String> folderFor(FileCategory c) async {
    final own = state.folders[c];
    if (own != null && own.isNotEmpty) return own;
    return joinPath(await rootFolder(), c.folderName);
  }

  Future<void> setRoot(String path) async {
    state = state.copyWith(root: path);
    await _save(_kRoot, path);
  }

  Future<void> setFolder(FileCategory c, String path) async {
    state = state.copyWith(folders: <FileCategory, String>{...state.folders, c: path});
    await _save(_kFolder(c), path);
  }

  /// Goes back to Downloads/Premisave for the main folder. Folders chosen for a single kind stay as they are.
  Future<void> resetRoot() async {
    state = state.copyWith(clearRoot: true);
    await _save(_kRoot, null);
  }

  /// Puts one kind of file back to its default subfolder.
  Future<void> resetFolder(FileCategory c) async {
    final next = Map<FileCategory, String>.from(state.folders)..remove(c);
    state = state.copyWith(folders: next);
    await _save(_kFolder(c), null);
  }

  /// Back to Downloads/Premisave with every default subfolder.
  Future<void> resetAll() async {
    state = const FileSettings();
    await _save(_kRoot, null);
    for (final c in FileCategory.values) {
      await _save(_kFolder(c), null);
    }
  }

  Future<void> _save(String key, String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    } catch (_) {}
  }
}

final fileSettingsProvider = NotifierProvider<FileSettingsController, FileSettings>(FileSettingsController.new);

// ----------------------------------------------------------------- downloads

/// A file saved on this device.
class DownloadedFile {
  const DownloadedFile({required this.key, required this.name, required this.path, required this.category, this.mime, this.size, required this.savedAt});

  final String key;
  final String name;
  final String path;
  final FileCategory category;
  final String? mime;
  final int? size;
  final DateTime savedAt;

  /// True for a file the browser saved. The page cannot see where, so it cannot open it again.
  bool get inBrowser => path == 'browser';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'name': name,
        'path': path,
        'category': category.name,
        'mime': mime,
        'size': size,
        'at': savedAt.millisecondsSinceEpoch,
      };

  static DownloadedFile? fromJson(Object? j) {
    if (j is! Map) return null;
    final key = j['key'];
    final name = j['name'];
    final path = j['path'];
    if (key is! String || name is! String || path is! String) return null;
    final cat = FileCategory.values.where((c) => c.name == j['category']);
    final at = j['at'];
    return DownloadedFile(
      key: key,
      name: name,
      path: path,
      category: cat.isEmpty ? FileCategory.other : cat.first,
      mime: j['mime'] is String ? j['mime'] as String : null,
      size: j['size'] is int ? j['size'] as int : null,
      savedAt: at is int ? DateTime.fromMillisecondsSinceEpoch(at) : DateTime.now(),
    );
  }
}

class DownloadsState {
  const DownloadsState({this.files = const <String, DownloadedFile>{}, this.active = const <String, double>{}});

  /// Saved files by file key.
  final Map<String, DownloadedFile> files;

  /// Files being downloaded now, with progress from 0 to 1. A value below 0 means the size is not known yet.
  final Map<String, double> active;

  DownloadsState copyWith({Map<String, DownloadedFile>? files, Map<String, double>? active}) =>
      DownloadsState(files: files ?? this.files, active: active ?? this.active);
}

class DownloadsController extends Notifier<DownloadsState> {
  static const String _kIndex = 'msgr_downloads';

  bool _loaded = false;

  @override
  DownloadsState build() {
    _load();
    return const DownloadsState();
  }

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kIndex);
      if (raw == null) return;
      final list = jsonDecode(raw);
      if (list is! List) return;
      final files = <String, DownloadedFile>{};
      for (final item in list) {
        final f = DownloadedFile.fromJson(item);
        if (f != null && !f.inBrowser) files[f.key] = f;
      }
      state = state.copyWith(files: <String, DownloadedFile>{...files, ...state.files});
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keep = state.files.values.where((f) => !f.inBrowser).map((f) => f.toJson()).toList();
      await prefs.setString(_kIndex, jsonEncode(keep));
    } catch (_) {}
  }

  bool isActive(String key) => state.active.containsKey(key);

  DownloadedFile? savedFile(String key) => state.files[key];

  /// The saved copy of [ref] if it is still on this device. A file that was moved or deleted is forgotten.
  Future<DownloadedFile?> existing(String key) async {
    final f = state.files[key];
    if (f == null) return null;
    if (f.inBrowser) return f;
    if (await fileStoreExists(f.path)) return f;
    final next = Map<String, DownloadedFile>.from(state.files)..remove(key);
    state = state.copyWith(files: next);
    await _persist();
    return null;
  }

  /// Saves the file into the folder for its kind. Returns the saved file, or the earlier copy when there is one.
  /// Throws when the download fails, so the screen can say why.
  Future<DownloadedFile> download(FileRef file) async {
    final already = await existing(file.key);
    if (already != null && !already.inBrowser) return already;
    final url = file.url;
    if (url == null) throw StateError('This file has no download link.');
    if (isActive(file.key)) throw StateError('This file is already downloading.');

    final folder = await ref.read(fileSettingsProvider.notifier).folderFor(file.category);
    state = state.copyWith(active: <String, double>{...state.active, file.key: -1});
    try {
      final path = await fileStoreDownload(
        url: url,
        fileName: file.name,
        folder: folder,
        mimeType: file.mime,
        onProgress: (p) {
          if (!state.active.containsKey(file.key)) return;
          state = state.copyWith(active: <String, double>{...state.active, file.key: p});
        },
      );
      final saved = DownloadedFile(key: file.key, name: file.name, path: path, category: file.category, mime: file.mime, size: file.size, savedAt: DateTime.now());
      final active = Map<String, double>.from(state.active)..remove(file.key);
      state = state.copyWith(files: <String, DownloadedFile>{...state.files, file.key: saved}, active: active);
      await _persist();
      return saved;
    } catch (_) {
      final active = Map<String, double>.from(state.active)..remove(file.key);
      state = state.copyWith(active: active);
      rethrow;
    }
  }

  /// Takes a file out of the list, and off the device when [deleteFile] is true.
  Future<void> remove(String key, {bool deleteFile = false}) async {
    final f = state.files[key];
    if (f == null) return;
    if (deleteFile && !f.inBrowser) await fileStoreDelete(f.path);
    final next = Map<String, DownloadedFile>.from(state.files)..remove(key);
    state = state.copyWith(files: next);
    await _persist();
  }
}

final downloadsProvider = NotifierProvider<DownloadsController, DownloadsState>(DownloadsController.new);
