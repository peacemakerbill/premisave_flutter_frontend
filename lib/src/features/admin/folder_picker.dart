import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/storage_models.dart';

typedef BrowseFolders = Future<FolderListing> Function(String? path);
typedef CreateFolder = Future<FolderListing> Function(String parent, String name);

String _trimSlash(String v) {
  var t = v.trim();
  while (t.length > 1 && t.endsWith('/')) {
    t = t.substring(0, t.length - 1);
  }
  return t;
}

/// "/data/recordings/team" inside "/data/recordings" is "team", and the folder itself is "".
String _relative(String base, String full) {
  final b = _trimSlash(base);
  final f = _trimSlash(full);
  if (f == b) return '';
  if (f.startsWith('$b/')) return f.substring(b.length + 1);
  return f;
}

/// A text field for a folder on the server, with a button that opens the folder picker. The person can still type the path.
///
/// The picker shows the server's own folders, not the folders of the device the app runs on, because the files are kept on
/// the server. It only shows folders the server allows. With [relativeTo] the field holds a folder inside another one, such
/// as the folder inside a network share, and the picker cannot leave that folder.
class FolderField extends StatelessWidget {
  const FolderField({
    super.key,
    required this.label,
    required this.controller,
    required this.browse,
    required this.create,
    this.enabled = true,
    this.optional = false,
    this.hint,
    this.helper,
    this.relativeTo,
  });

  final String label;
  final TextEditingController controller;
  final BrowseFolders browse;
  final CreateFolder create;
  final bool enabled;
  final bool optional;
  final String? hint;
  final String? helper;

  /// The folder this one is inside, read when the picker opens. Null means the field holds a full path.
  final String Function()? relativeTo;

  Future<void> _open(BuildContext context) async {
    final relative = relativeTo != null;
    final base = relative ? _trimSlash(relativeTo!()) : '';
    if (relative && base.isEmpty) {
      showToast(context, 'Choose the folder above first', error: true);
      return;
    }
    final typed = controller.text.trim();
    final String? start;
    if (relative) {
      start = typed.isEmpty ? base : '$base/${_trimSlash(typed)}';
    } else {
      start = typed.isEmpty ? null : typed;
    }
    final picked = await showFolderPicker(
      context,
      title: label,
      browse: browse,
      create: create,
      start: start,
      floor: relative ? base : null,
    );
    if (picked == null) return;
    controller.text = relative ? _relative(base, picked) : picked;
  }

  @override
  Widget build(BuildContext context) {
    return PTextField(
      label: label,
      controller: controller,
      enabled: enabled,
      optional: optional,
      hint: hint,
      helper: helper,
      suffix: IconButton(
        tooltip: 'Browse folders',
        icon: const Icon(Icons.folder_open_rounded),
        onPressed: enabled ? () => _open(context) : null,
      ),
    );
  }
}

/// Opens the folder picker and returns the full path of the folder chosen, or null when it is closed without choosing.
Future<String?> showFolderPicker(
  BuildContext context, {
  required String title,
  required BrowseFolders browse,
  required CreateFolder create,
  String? start,
  String? floor,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _FolderSheet(title: title, browse: browse, create: create, start: start, floor: floor),
  );
}

class _FolderSheet extends StatefulWidget {
  const _FolderSheet({required this.title, required this.browse, required this.create, this.start, this.floor});

  final String title;
  final BrowseFolders browse;
  final CreateFolder create;
  final String? start;
  final String? floor;

  @override
  State<_FolderSheet> createState() => _FolderSheetState();
}

class _FolderSheetState extends State<_FolderSheet> {
  FolderListing? _listing;
  Object? _error;
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _openStart();
  }

  /// The folder in the field if the server shows it, else the folder the picker may not leave, else the list of allowed folders.
  Future<void> _openStart() async {
    final tries = <String?>[
      if (widget.start != null && widget.start!.isNotEmpty) widget.start,
      if (widget.floor != null && widget.floor != widget.start) widget.floor,
      null,
    ];
    Object? last;
    for (final path in tries) {
      try {
        final listing = await widget.browse(path);
        if (!mounted) return;
        setState(() {
          _listing = listing;
          _error = null;
          _loading = false;
        });
        return;
      } catch (e) {
        last = e;
      }
    }
    if (!mounted) return;
    setState(() {
      _error = last;
      _loading = false;
    });
  }

  Future<void> _open(String? path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final listing = await widget.browse(path);
      if (!mounted) return;
      setState(() {
        _listing = listing;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  bool get _atFloor {
    final l = _listing;
    final f = widget.floor;
    return l != null && f != null && _trimSlash(l.path) == _trimSlash(f);
  }

  bool get _canGoUp {
    final l = _listing;
    return l != null && !l.top && l.parent != null && !_atFloor && !_loading;
  }

  Future<void> _newFolder() async {
    final l = _listing;
    if (l == null || l.top || _creating) return;
    final name = await promptDialog(
      context,
      title: 'New folder',
      label: 'Folder name',
      message: 'It is made inside ${l.path}.',
      confirmLabel: 'Create',
      required: true,
      multiline: false,
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    setState(() => _creating = true);
    try {
      final made = await widget.create(l.path, name.trim());
      if (!mounted) return;
      setState(() {
        _listing = made;
        _creating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _listing;
    final height = MediaQuery.sizeOf(context).height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height * 0.86),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(widget.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              l == null
                  ? 'These are folders on the server, not on this device.'
                  : (l.top ? 'Choose where to start. These are folders on the server.' : l.path),
              style: TextStyle(fontSize: 12.5, height: 1.4, color: context.mutedColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                TextButton.icon(
                  onPressed: _canGoUp ? () => _open((_listing!.parent ?? '').isEmpty ? null : _listing!.parent) : null,
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  label: const Text('Up'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: (l != null && !l.top && l.canCreate && !_creating && !_loading) ? _newFolder : null,
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  label: const Text('New folder'),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.borderColor),
          Flexible(child: _body(context)),
          Divider(height: 1, color: context.borderColor),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (l != null && !l.top && l.exists && !l.writable)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: InlineMessage('The service cannot write into this folder.', kind: MessageKind.warning),
                  ),
                if (l != null && !l.top && !l.exists)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'This folder does not exist yet. It is created when you save.',
                      style: TextStyle(fontSize: 12.5, color: context.mutedColor),
                    ),
                  ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: PButton(
                        label: 'Cancel',
                        kind: PButtonKind.outline,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: PButton(
                        label: 'Use this folder',
                        onPressed: (l == null || l.top || _loading) ? null : () => Navigator.of(context).pop(l.path),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading && _listing == null) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()));
    }
    if (_error != null && _listing == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: InlineMessage(
          'The folders could not be loaded. ${ApiException.from(_error!).message}',
          kind: MessageKind.error,
          actionLabel: 'Try again',
          onAction: _openStart,
        ),
      );
    }
    final l = _listing!;
    final children = <Widget>[
      if (_error != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: InlineMessage(ApiException.from(_error!).message, kind: MessageKind.error),
        ),
      if (l.folders.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Text(
            l.top ? 'The server has no folders set for this.' : 'No folders here. Use "New folder" to add one, or use this folder.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.mutedColor, height: 1.45),
          ),
        ),
      for (final f in l.folders)
        ListTile(
          leading: Icon(l.top ? Icons.dns_outlined : Icons.folder_rounded, color: context.pal.accent),
          title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: Icon(Icons.chevron_right_rounded, color: context.mutedColor),
          onTap: _loading ? null : () => _open(f.path),
        ),
      if (l.truncated)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
          child: Text(
            'Only the first folders are shown. Type the path if the one you want is missing.',
            style: TextStyle(fontSize: 12.5, color: context.mutedColor),
          ),
        ),
    ];
    return Stack(
      children: <Widget>[
        ListView(shrinkWrap: true, children: children),
        if (_loading) const Positioned(left: 0, right: 0, top: 0, child: LinearProgressIndicator(minHeight: 2)),
      ],
    );
  }
}
