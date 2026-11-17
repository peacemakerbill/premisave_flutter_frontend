import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart' show PdfViewer;

import '../../core/files/file_kinds.dart';
import '../../core/files/file_store.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/messenger_repository.dart';
import 'file_preview.dart';

/// Shows what is about to be sent, a picture for photos and the first page for PDFs, with a box for a caption.
/// Returns the caption, which may be empty, or null when the person cancels.
Future<String?> showSendFilesPreview(BuildContext context, List<LocalFile> files) {
  return showDialog<String>(context: context, builder: (_) => _SendPreview(files: files));
}

class _SendPreview extends StatefulWidget {
  const _SendPreview({required this.files});

  final List<LocalFile> files;

  @override
  State<_SendPreview> createState() => _SendPreviewState();
}

class _SendPreviewState extends State<_SendPreview> {
  final TextEditingController _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final many = widget.files.length > 1;
    return AlertDialog(
      backgroundColor: context.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.radius(Brand.radiusLarge))),
      title: Text(many ? 'Send ${widget.files.length} files' : 'Send file', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final f in widget.files) Padding(padding: const EdgeInsets.only(bottom: 10), child: _PickedPreview(file: f, large: !many)),
              const SizedBox(height: 4),
              TextField(
                controller: _caption,
                autofocus: true,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Caption (optional)'),
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        PButton(label: 'Cancel', kind: PButtonKind.text, small: true, onPressed: () => Navigator.of(context).pop()),
        PButton(label: 'Send', small: true, icon: Icons.send_rounded, onPressed: () => Navigator.of(context).pop(_caption.text.trim())),
      ],
    );
  }
}

/// One chosen file: its picture when it has one, otherwise its type, name and size.
class _PickedPreview extends StatefulWidget {
  const _PickedPreview({required this.file, required this.large});

  final LocalFile file;
  final bool large;

  @override
  State<_PickedPreview> createState() => _PickedPreviewState();
}

class _PickedPreviewState extends State<_PickedPreview> {
  Uint8List? _bytes;
  bool _loading = true;

  FileKind get _kind => kindOfFile(name: widget.file.name);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final kind = _kind;
    if (kind != FileKind.image && kind != FileKind.pdf) {
      setState(() => _loading = false);
      return;
    }
    Uint8List? b = widget.file.bytes;
    final path = widget.file.path;
    if (b == null && path != null) b = await fileStoreRead(path, maxBytes: 25 * 1024 * 1024);
    if (!mounted) return;
    setState(() {
      _bytes = b;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    final b = _bytes;
    final height = widget.large ? 240.0 : 110.0;

    Widget? picture;
    if (b != null && kind == FileKind.image) {
      picture = Image.memory(b, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(kind.icon, size: 36, color: kind.tint));
    } else if (b != null && kind == FileKind.pdf) {
      picture = IgnorePointer(child: PdfViewer.data(b, sourceName: 'send:${widget.file.name}:${b.length}'));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.radius(12)),
      child: Container(
        color: context.pal.panel2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (_loading)
              SizedBox(height: height, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))
            else if (picture != null)
              SizedBox(height: height, child: picture),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: <Widget>[
                  KindBadge(kind: kind, name: widget.file.name, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(widget.file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                        if (widget.file.size > 0) Text('${kind.label}  ·  ${formatBytes(widget.file.size)}', style: TextStyle(fontSize: 12, color: context.mutedColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
