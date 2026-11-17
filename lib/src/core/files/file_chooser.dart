
import 'package:file_picker/file_picker.dart' show FilePicker, FileType;
import 'package:file_selector/file_selector.dart' as selector;
import 'package:flutter/foundation.dart';

/// A file the person chose. The web gives bytes, other platforms give a path.
class ChosenFile {
  const ChosenFile({required this.name, this.path, this.bytes, this.size = 0});

  final String name;
  final String? path;
  final Uint8List? bytes;
  final int size;
}

/// On Linux the file window is the system's own GTK window, drawn by the app itself. The usual file_picker plugin
/// runs a separate program (zenity or kdialog) there, which a person may not have installed, so it is not used on Linux.
bool get _useGtkDialogs => !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

/// Lets the person choose files. Pass [extensions] (without dots) to limit the kinds shown. Set [withData] to read the
/// contents into memory, which the web needs because it has no file paths.
Future<List<ChosenFile>> chooseFiles({List<String>? extensions, bool multiple = false, bool withData = false}) async {
  final limited = extensions != null && extensions.isNotEmpty;

  if (_useGtkDialogs) {
    final groups = limited ? <selector.XTypeGroup>[selector.XTypeGroup(label: 'Files', extensions: extensions)] : const <selector.XTypeGroup>[];
    final files = await selector.openFiles(acceptedTypeGroups: groups);
    final picked = multiple ? files : files.take(1).toList();
    final out = <ChosenFile>[];
    for (final f in picked) {
      out.add(ChosenFile(name: f.name, path: f.path, bytes: withData ? await f.readAsBytes() : null, size: await f.length()));
    }
    return out;
  }

  final result = await FilePicker.platform.pickFiles(
    type: limited ? FileType.custom : FileType.any,
    allowedExtensions: limited ? extensions : null,
    allowMultiple: multiple,
    withData: withData,
  );
  if (result == null) return const <ChosenFile>[];
  return <ChosenFile>[
    for (final f in result.files)
      if (f.bytes != null || (!kIsWeb && f.path != null)) ChosenFile(name: f.name, path: kIsWeb ? null : f.path, bytes: f.bytes, size: f.size),
  ];
}

/// Lets the person choose a folder. Null when they cancel, or on the web, which has no folders to choose.
Future<String?> chooseFolder({String title = 'Choose a folder'}) async {
  if (kIsWeb) return null;
  try {
    if (_useGtkDialogs) return await selector.getDirectoryPath(confirmButtonText: 'Choose');
    return await FilePicker.platform.getDirectoryPath(dialogTitle: title);
  } catch (_) {
    return null;
  }
}

/// Picture file types, for choosing a photo from files.
const List<String> imageExtensions = <String>['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];

/// Picture and video file types, for a status.
const List<String> mediaExtensions = <String>[...imageExtensions, 'mp4', 'mov', 'm4v', 'mkv', 'webm', 'avi', '3gp'];

/// Audio file types.
const List<String> audioExtensions = <String>['mp3', 'm4a', 'aac', 'wav', 'ogg', 'oga', 'opus', 'flac', 'amr'];
