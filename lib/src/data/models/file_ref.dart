import '../../core/files/file_kinds.dart';
import 'messenger_models.dart';

/// A file the app can show, download and open: one from a chat message, or one already saved on this device.
class FileRef {
  const FileRef({
    required this.key,
    required this.name,
    this.mime,
    this.size,
    this.url,
    this.localPath,
    this.hint,
    this.caption = '',
  });

  /// Stable identity: the attachment id, so the same file is one download however many times it is shown.
  final String key;
  final String name;
  final String? mime;
  final int? size;

  /// Where to fetch it from. Null for a file that only exists on this device.
  final String? url;

  /// Set for a file already on this device.
  final String? localPath;
  final String? hint;
  final String caption;

  FileKind get kind => kindOfFile(name: name, mime: mime, hint: hint);
  FileCategory get category => kind.category;

  factory FileRef.fromMessage(MMessage m, String? resolvedUrl) => FileRef(
        key: (m.attachmentId != null && m.attachmentId!.isNotEmpty) ? m.attachmentId! : m.id,
        name: (m.fileName == null || m.fileName!.trim().isEmpty) ? 'file' : m.fileName!,
        mime: m.mimeType,
        size: m.fileSize,
        url: resolvedUrl,
        hint: mTypeApi(m.type),
        caption: m.content,
      );

  FileRef withLocal(String? path) => FileRef(key: key, name: name, mime: mime, size: size, url: url, localPath: path, hint: hint, caption: caption);
}
