import 'package:flutter/material.dart';

/// What a file is, worked out from its type and name. It decides the preview a chat shows and how the file opens.
enum FileKind { image, video, audio, pdf, text, word, sheet, slides, archive, other }

/// Which download folder a file goes to. Each has its own subfolder, like WhatsApp and Telegram keep.
enum FileCategory { images, video, audio, documents, other }

extension FileCategoryX on FileCategory {
  /// Short name for settings and for the folder: "Images", "Video", "Audio", "Documents", "Other".
  String get label {
    switch (this) {
      case FileCategory.images:
        return 'Images';
      case FileCategory.video:
        return 'Video';
      case FileCategory.audio:
        return 'Audio';
      case FileCategory.documents:
        return 'Documents';
      case FileCategory.other:
        return 'Other';
    }
  }

  /// The subfolder created by default, for example "Premisave Images".
  String get folderName => 'Premisave $label';

  IconData get icon {
    switch (this) {
      case FileCategory.images:
        return Icons.photo_library_outlined;
      case FileCategory.video:
        return Icons.videocam_outlined;
      case FileCategory.audio:
        return Icons.headphones_outlined;
      case FileCategory.documents:
        return Icons.description_outlined;
      case FileCategory.other:
        return Icons.folder_outlined;
    }
  }
}

const Set<String> _imageExt = <String>{'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif'};
const Set<String> _videoExt = <String>{'mp4', 'mov', 'm4v', 'mkv', 'webm', 'avi', '3gp', 'mpeg', 'mpg'};
const Set<String> _audioExt = <String>{'mp3', 'm4a', 'aac', 'wav', 'ogg', 'oga', 'opus', 'flac', 'amr', 'weba'};
const Set<String> _textExt = <String>{
  'txt', 'md', 'csv', 'tsv', 'log', 'json', 'xml', 'yaml', 'yml', 'ini', 'conf', 'properties', 'sql', 'sh', //
  'java', 'kt', 'dart', 'js', 'ts', 'py', 'html', 'css', 'env',
};
const Set<String> _wordExt = <String>{'doc', 'docx', 'odt', 'rtf', 'dotx'};
const Set<String> _sheetExt = <String>{'xls', 'xlsx', 'ods', 'xlsm'};
const Set<String> _slidesExt = <String>{'ppt', 'pptx', 'odp'};
const Set<String> _archiveExt = <String>{'zip', 'rar', '7z', 'tar', 'gz', 'tgz', 'bz2'};

/// The lower case extension without the dot, or an empty string.
String extensionOf(String? name) {
  final n = (name ?? '').trim();
  final dot = n.lastIndexOf('.');
  if (dot < 0 || dot == n.length - 1) return '';
  return n.substring(dot + 1).toLowerCase();
}

/// Works out the kind from the media type first, then the extension. [hint] is the message type from the server
/// ("image", "video", "voice") and is used last, so a file with a missing type still lands in the right folder.
FileKind kindOfFile({String? name, String? mime, String? hint}) {
  final m = (mime ?? '').toLowerCase();
  final ext = extensionOf(name);

  if (m == 'application/pdf' || ext == 'pdf') return FileKind.pdf;
  if (m.startsWith('image/') && !m.contains('svg')) return FileKind.image;
  if (m.startsWith('video/')) return FileKind.video;
  if (m.startsWith('audio/')) return FileKind.audio;
  if (m.startsWith('text/') || m == 'application/json' || m == 'application/xml') return FileKind.text;

  if (_imageExt.contains(ext)) return FileKind.image;
  if (_videoExt.contains(ext)) return FileKind.video;
  if (_audioExt.contains(ext)) return FileKind.audio;
  if (_textExt.contains(ext)) return FileKind.text;
  if (_wordExt.contains(ext) || m.contains('msword') || m.contains('wordprocessingml')) return FileKind.word;
  if (_sheetExt.contains(ext) || m.contains('ms-excel') || m.contains('spreadsheetml')) return FileKind.sheet;
  if (_slidesExt.contains(ext) || m.contains('ms-powerpoint') || m.contains('presentationml')) return FileKind.slides;
  if (_archiveExt.contains(ext) || m.contains('zip') || m.contains('compressed')) return FileKind.archive;

  switch ((hint ?? '').toLowerCase()) {
    case 'image':
      return FileKind.image;
    case 'video':
      return FileKind.video;
    case 'voice':
    case 'audio':
      return FileKind.audio;
  }
  return FileKind.other;
}

extension FileKindX on FileKind {
  FileCategory get category {
    switch (this) {
      case FileKind.image:
        return FileCategory.images;
      case FileKind.video:
        return FileCategory.video;
      case FileKind.audio:
        return FileCategory.audio;
      case FileKind.pdf:
      case FileKind.text:
      case FileKind.word:
      case FileKind.sheet:
      case FileKind.slides:
        return FileCategory.documents;
      case FileKind.archive:
      case FileKind.other:
        return FileCategory.other;
    }
  }

  IconData get icon {
    switch (this) {
      case FileKind.image:
        return Icons.image_outlined;
      case FileKind.video:
        return Icons.videocam_outlined;
      case FileKind.audio:
        return Icons.graphic_eq_rounded;
      case FileKind.pdf:
        return Icons.picture_as_pdf_outlined;
      case FileKind.text:
        return Icons.notes_rounded;
      case FileKind.word:
        return Icons.description_outlined;
      case FileKind.sheet:
        return Icons.table_chart_outlined;
      case FileKind.slides:
        return Icons.slideshow_rounded;
      case FileKind.archive:
        return Icons.folder_zip_outlined;
      case FileKind.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// The colour of the file tile, so a PDF, a spreadsheet and a photo can be told apart at a glance.
  Color get tint {
    switch (this) {
      case FileKind.image:
        return const Color(0xFF00897B);
      case FileKind.video:
        return const Color(0xFF5C6BC0);
      case FileKind.audio:
        return const Color(0xFF8E24AA);
      case FileKind.pdf:
        return const Color(0xFFE53935);
      case FileKind.text:
        return const Color(0xFF546E7A);
      case FileKind.word:
        return const Color(0xFF1E6FD9);
      case FileKind.sheet:
        return const Color(0xFF2E7D32);
      case FileKind.slides:
        return const Color(0xFFE65100);
      case FileKind.archive:
        return const Color(0xFF8D6E63);
      case FileKind.other:
        return const Color(0xFF78909C);
    }
  }

  String get label {
    switch (this) {
      case FileKind.image:
        return 'Photo';
      case FileKind.video:
        return 'Video';
      case FileKind.audio:
        return 'Audio';
      case FileKind.pdf:
        return 'PDF';
      case FileKind.text:
        return 'Text';
      case FileKind.word:
        return 'Document';
      case FileKind.sheet:
        return 'Spreadsheet';
      case FileKind.slides:
        return 'Presentation';
      case FileKind.archive:
        return 'Archive';
      case FileKind.other:
        return 'File';
    }
  }
}

/// Keeps a file name safe to save: no folders, no control characters, not too long.
String safeFileName(String? name, {String fallback = 'file'}) {
  var n = (name ?? '').replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), '_').trim();
  while (n.startsWith('.')) {
    n = n.substring(1);
  }
  if (n.isEmpty) n = fallback;
  if (n.length > 120) {
    final ext = extensionOf(n);
    final keep = ext.isEmpty || ext.length > 12 ? '' : '.$ext';
    n = n.substring(0, 120 - keep.length) + keep;
  }
  return n;
}

/// Joins two path parts with the separator the path already uses.
String joinPath(String a, String b) {
  if (a.isEmpty) return b;
  final sep = a.contains('\\') && !a.contains('/') ? '\\' : '/';
  return a.endsWith('/') || a.endsWith('\\') ? '$a$b' : '$a$sep$b';
}
