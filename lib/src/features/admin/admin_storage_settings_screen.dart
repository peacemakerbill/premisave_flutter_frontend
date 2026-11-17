import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/storage_models.dart';
import '../../state/providers.dart';
import '../../state/storage_providers.dart';

/// Administrators: where files are kept. The sign-up service keeps the documents of Home Owner applications, and the
/// messenger keeps chat files and call recordings. Each has its own settings. The values in the server's .env file apply
/// until something is saved here, and "Reset to .env" goes back to them. Folders must be inside the roots the server allows.
class AdminStorageSettingsScreen extends ConsumerWidget {
  const AdminStorageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentStorageProvider);
    final messenger = ref.watch(storageSettingsProvider);
    return SubPage(
      title: 'Storage',
      fallbackRoute: '/admin/users',
      body: PageBody(
        maxWidth: 720,
        children: <Widget>[
          const SectionHeader('Home owner documents', padding: EdgeInsets.only(top: 12, bottom: 10)),
          _loaded<DocumentStorageSettings>(
            documents,
            () => ref.invalidate(documentStorageProvider),
            (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _DocumentsCard(key: ValueKey<String>('d|${s.fingerprint}'), settings: s),
                _RootsNote(s.allowedRoots),
              ],
            ),
          ),
          const SectionHeader('Chat files', padding: EdgeInsets.only(top: 22, bottom: 10)),
          _loaded<StorageSettings>(
            messenger,
            () => ref.invalidate(storageSettingsProvider),
            (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _AttachmentsCard(key: ValueKey<String>('a|${s.fingerprint}'), settings: s),
                _RootsNote(s.allowedRoots),
              ],
            ),
          ),
          const SectionHeader('Call recordings', padding: EdgeInsets.only(top: 22, bottom: 10)),
          _loaded<StorageSettings>(
            messenger,
            () => ref.invalidate(storageSettingsProvider),
            (s) => _RecordingsCard(key: ValueKey<String>('r|${s.fingerprint}'), settings: s),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.info_outline_rounded, size: 18, color: context.mutedColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Files saved before a change stay where they are and keep opening. Only new files go to the new folder.',
                    style: TextStyle(fontSize: 12.5, height: 1.5, color: context.mutedColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One section: a spinner while it loads, the error with a retry if the service cannot be reached, the content when it is there.
  Widget _loaded<T>(AsyncValue<T> value, VoidCallback retry, Widget Function(T) content) {
    return value.when(
      skipLoadingOnReload: true,
      loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
      error: (e, _) => ErrorState(error: e, onRetry: retry),
      data: content,
    );
  }
}

class _RootsNote extends StatelessWidget {
  const _RootsNote(this.roots);

  final List<String> roots;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, left: 4),
        child: Text(
          'Allowed folders: ${roots.isEmpty ? 'none set' : roots.join(', ')}',
          style: TextStyle(fontSize: 12, height: 1.45, color: context.mutedColor),
        ),
      );
}

String _free(int mb) => mb >= 1024 ? '${(mb / 1024).toStringAsFixed(1)} GB' : '$mb MB';

/// What a check or a save said, shown under the buttons.
class _Outcome {
  const _Outcome(this.ok, this.text);
  final bool ok;
  final String text;
}

Widget _sourcePill(bool fromDashboard) => StatusPill(
      fromDashboard ? 'Set in dashboard' : 'From .env',
      dense: true,
      color: fromDashboard ? Brand.info : Brand.muted,
    );

class _AttachmentsCard extends ConsumerStatefulWidget {
  const _AttachmentsCard({super.key, required this.settings});

  final StorageSettings settings;

  @override
  ConsumerState<_AttachmentsCard> createState() => _AttachmentsCardState();
}

class _AttachmentsCardState extends ConsumerState<_AttachmentsCard> {
  late String _mode;
  late bool _requireMount;
  late final TextEditingController _root;
  late final TextEditingController _mount;
  late final TextEditingController _directory;
  bool _busy = false;
  _Outcome? _outcome;

  AttachmentsStorage get _a => widget.settings.attachments;

  @override
  void initState() {
    super.initState();
    _mode = _a.mode;
    _requireMount = _a.networkRequireMount;
    _root = TextEditingController(text: _a.root);
    _mount = TextEditingController(text: _a.networkMountPath);
    _directory = TextEditingController(text: _a.networkDirectory);
  }

  @override
  void dispose() {
    _root.dispose();
    _mount.dispose();
    _directory.dispose();
    super.dispose();
  }

  bool get _network => _mode == 'NETWORK';

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _outcome = null;
    });
    try {
      final r = await ref.read(storageRepositoryProvider).checkAttachments(
            mode: _mode,
            root: _root.text.trim(),
            networkMountPath: _mount.text.trim(),
            networkDirectory: _directory.text.trim(),
            networkRequireMount: _requireMount,
          );
      if (!mounted) return;
      setState(() => _outcome = r.ok
          ? _Outcome(true, 'This works. Files would be saved in ${r.location ?? 'that folder'}'
              '${r.freeMb != null ? ', ${_free(r.freeMb!)} free' : ''}.')
          : _Outcome(false, r.problem ?? 'This folder cannot be used.'));
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _outcome = null;
    });
    try {
      await ref.read(storageRepositoryProvider).saveAttachments(
            mode: _mode,
            root: _root.text.trim(),
            networkMountPath: _mount.text.trim(),
            networkDirectory: _directory.text.trim(),
            networkRequireMount: _requireMount,
          );
      ref.invalidate(storageSettingsProvider);
      if (mounted) {
        showToast(context, 'Chat file storage saved');
        setState(() => _busy = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  Future<void> _reset() async {
    final ok = await confirmDialog(
      context,
      title: 'Go back to the .env values?',
      message: 'New chat files will be saved where the server\'s .env file says. Files already saved are kept and still open.',
      confirmLabel: 'Reset',
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = true;
      _outcome = null;
    });
    try {
      await ref.read(storageRepositoryProvider).resetAttachments();
      ref.invalidate(storageSettingsProvider);
      if (mounted) {
        showToast(context, 'Using the .env values again');
        setState(() => _busy = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _a;
    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text('Where attachments, group photos and status media are saved',
                    style: TextStyle(fontWeight: FontWeight.w800, height: 1.35)),
              ),
              const SizedBox(width: 10),
              _sourcePill(a.fromDashboard),
            ],
          ),
          const SizedBox(height: 6),
          InfoRow('In use now', a.location, icon: Icons.folder_outlined),
          if (a.freeMb != null) InfoRow('Free space', _free(a.freeMb!), icon: Icons.data_usage_rounded),
          if (!a.ready) InlineMessage(a.problem ?? 'This storage cannot be used right now.', kind: MessageKind.error),
          const SizedBox(height: 12),
          PSelectField<String>(
            label: 'Kept on',
            value: _mode,
            enabled: !_busy,
            options: const <PChoice<String>>[
              PChoice<String>('LOCAL', 'This server', description: 'A folder on the computer the service runs on'),
              PChoice<String>('NETWORK', 'A network share', description: 'A share the server already has mounted'),
            ],
            onChanged: (v) => setState(() {
              if (v != null) _mode = v;
            }),
          ),
          const SizedBox(height: 12),
          if (!_network)
            PTextField(
              label: 'Folder',
              controller: _root,
              enabled: !_busy,
              hint: '/srv/premisave/files',
              helper: 'A full path inside one of the allowed folders. It is created if it does not exist.',
            )
          else ...<Widget>[
            PTextField(
              label: 'Where the share is mounted',
              controller: _mount,
              enabled: !_busy,
              hint: '/mnt/premisave',
              helper: 'The server never mounts anything itself. Mount the share first.',
            ),
            const SizedBox(height: 12),
            PTextField(
              label: 'Folder inside the share',
              controller: _directory,
              enabled: !_busy,
              optional: true,
              hint: 'premisave-messenger',
              helper: 'Letters, digits, dot, dash, underscore and space. Leave blank to use the share itself.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Refuse if it is not a real network share', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Stops files filling this server\'s own disk when the share is not mounted.',
                  style: TextStyle(color: context.mutedColor, height: 1.4)),
              value: _requireMount,
              onChanged: _busy ? null : (v) => setState(() => _requireMount = v),
            ),
          ],
          if (_outcome != null) ...<Widget>[
            const SizedBox(height: 8),
            InlineMessage(_outcome!.text, kind: _outcome!.ok ? MessageKind.success : MessageKind.error),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              PButton(label: 'Try it', kind: PButtonKind.outline, onPressed: _busy ? null : _check),
              PButton(label: 'Save', loading: _busy, onPressed: _busy ? null : _save),
              if (a.fromDashboard) PButton(label: 'Reset to .env', kind: PButtonKind.text, onPressed: _busy ? null : _reset),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordingsCard extends ConsumerStatefulWidget {
  const _RecordingsCard({super.key, required this.settings});

  final StorageSettings settings;

  @override
  ConsumerState<_RecordingsCard> createState() => _RecordingsCardState();
}

class _RecordingsCardState extends ConsumerState<_RecordingsCard> {
  late final TextEditingController _subfolder;
  late final TextEditingController _minFree;
  bool _busy = false;
  String? _minFreeError;
  _Outcome? _outcome;

  RecordingsStorage get _r => widget.settings.recordings;

  @override
  void initState() {
    super.initState();
    _subfolder = TextEditingController(text: _r.subfolder);
    _minFree = TextEditingController(text: '${_r.minFreeMb}');
  }

  @override
  void dispose() {
    _subfolder.dispose();
    _minFree.dispose();
    super.dispose();
  }

  int? _parseMinFree() {
    final text = _minFree.text.trim();
    final n = text.isEmpty ? 0 : int.tryParse(text);
    final bad = n == null || n < 0;
    setState(() => _minFreeError = bad ? 'Enter a whole number, 0 or more' : null);
    return bad ? null : n;
  }

  Future<void> _check() async {
    final min = _parseMinFree();
    if (min == null) return;
    setState(() {
      _busy = true;
      _outcome = null;
    });
    try {
      final r = await ref.read(storageRepositoryProvider).checkRecordings(subfolder: _subfolder.text.trim(), minFreeMb: min);
      if (!mounted) return;
      setState(() => _outcome = r.ok
          ? _Outcome(true, 'This works. Recordings would be saved in ${r.location ?? 'that folder'}'
              '${r.freeMb != null ? ', ${_free(r.freeMb!)} free' : ''}.')
          : _Outcome(false, r.problem ?? 'This folder cannot be used.'));
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final min = _parseMinFree();
    if (min == null) return;
    setState(() {
      _busy = true;
      _outcome = null;
    });
    try {
      await ref.read(storageRepositoryProvider).saveRecordings(subfolder: _subfolder.text.trim(), minFreeMb: min);
      ref.invalidate(storageSettingsProvider);
      if (mounted) {
        showToast(context, 'Recording storage saved');
        setState(() => _busy = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  Future<void> _reset() async {
    final ok = await confirmDialog(
      context,
      title: 'Go back to the .env values?',
      message: 'New recordings will use the .env folder and free-space limit. Recordings already saved are kept and still play.',
      confirmLabel: 'Reset',
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = true;
      _outcome = null;
    });
    try {
      await ref.read(storageRepositoryProvider).resetRecordings();
      ref.invalidate(storageSettingsProvider);
      if (mounted) {
        showToast(context, 'Using the .env values again');
        setState(() => _busy = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text('Where call videos are saved', style: TextStyle(fontWeight: FontWeight.w800, height: 1.35)),
              ),
              const SizedBox(width: 10),
              _sourcePill(r.fromDashboard),
            ],
          ),
          const SizedBox(height: 6),
          InfoRow('Recorder folder', r.sharedFolder, icon: Icons.video_library_outlined),
          InfoRow('In use now', r.location, icon: Icons.folder_outlined),
          if (r.freeMb != null) InfoRow('Free space', _free(r.freeMb!), icon: Icons.data_usage_rounded),
          if (!r.ready) InlineMessage(r.problem ?? 'Recordings cannot be saved right now.', kind: MessageKind.error),
          const SizedBox(height: 12),
          PTextField(
            label: 'Folder inside the recorder folder',
            controller: _subfolder,
            enabled: !_busy,
            optional: true,
            hint: 'team-calls',
            helper: 'The recorder itself can only write to its own folder (set in .env and Docker), so you choose a folder inside it.',
          ),
          const SizedBox(height: 12),
          PTextField(
            label: 'Stop recording when free space is below (MB)',
            controller: _minFree,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            errorText: _minFreeError,
            helper: '0 turns the check off. The .env value is ${r.envMinFreeMb}.',
          ),
          if (_outcome != null) ...<Widget>[
            const SizedBox(height: 8),
            InlineMessage(_outcome!.text, kind: _outcome!.ok ? MessageKind.success : MessageKind.error),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              PButton(label: 'Try it', kind: PButtonKind.outline, onPressed: _busy ? null : _check),
              PButton(label: 'Save', loading: _busy, onPressed: _busy ? null : _save),
              if (r.fromDashboard) PButton(label: 'Reset to .env', kind: PButtonKind.text, onPressed: _busy ? null : _reset),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentsCard extends ConsumerStatefulWidget {
  const _DocumentsCard({super.key, required this.settings});

  final DocumentStorageSettings settings;

  @override
  ConsumerState<_DocumentsCard> createState() => _DocumentsCardState();
}

class _DocumentsCardState extends ConsumerState<_DocumentsCard> {
  late String _type;
  late String _protocol;
  late bool _requireMount;
  late final TextEditingController _local;
  late final TextEditingController _host;
  late final TextEditingController _share;
  late final TextEditingController _mount;
  late final TextEditingController _directory;
  late final TextEditingController _minFree;
  bool _busy = false;
  String? _minFreeError;
  _Outcome? _outcome;

  DocumentStorage get _d => widget.settings.documents;

  @override
  void initState() {
    super.initState();
    _type = _d.type;
    _protocol = _d.networkProtocol;
    _requireMount = _d.networkRequireMount;
    _local = TextEditingController(text: _d.localPath);
    _host = TextEditingController(text: _d.networkHost);
    _share = TextEditingController(text: _d.networkShare);
    _mount = TextEditingController(text: _d.networkMountPath);
    _directory = TextEditingController(text: _d.networkDirectory);
    _minFree = TextEditingController(text: '${_d.minFreeMb}');
  }

  @override
  void dispose() {
    _local.dispose();
    _host.dispose();
    _share.dispose();
    _mount.dispose();
    _directory.dispose();
    _minFree.dispose();
    super.dispose();
  }

  bool get _network => _type == 'NETWORK';

  int? _parseMinFree() {
    final text = _minFree.text.trim();
    final n = text.isEmpty ? 0 : int.tryParse(text);
    final bad = n == null || n < 0;
    setState(() => _minFreeError = bad ? 'Enter a whole number, 0 or more' : null);
    return bad ? null : n;
  }

  Future<void> _check() async {
    final min = _parseMinFree();
    if (min == null) return;
    setState(() {
      _busy = true;
      _outcome = null;
    });
    try {
      final r = await ref.read(documentStorageRepositoryProvider).check(
            type: _type,
            localPath: _local.text.trim(),
            networkProtocol: _protocol,
            networkHost: _host.text.trim(),
            networkShare: _share.text.trim(),
            networkMountPath: _mount.text.trim(),
            networkDirectory: _directory.text.trim(),
            networkRequireMount: _requireMount,
            minFreeMb: min,
          );
      if (!mounted) return;
      setState(() => _outcome = r.ok
          ? _Outcome(true, 'This works. Documents would be saved in ${r.location ?? 'that folder'}'
              '${r.freeMb != null ? ', ${_free(r.freeMb!)} free' : ''}.')
          : _Outcome(false, r.problem ?? 'This folder cannot be used.'));
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    final min = _parseMinFree();
    if (min == null) return;
    setState(() {
      _busy = true;
      _outcome = null;
    });
    try {
      await ref.read(documentStorageRepositoryProvider).save(
            type: _type,
            localPath: _local.text.trim(),
            networkProtocol: _protocol,
            networkHost: _host.text.trim(),
            networkShare: _share.text.trim(),
            networkMountPath: _mount.text.trim(),
            networkDirectory: _directory.text.trim(),
            networkRequireMount: _requireMount,
            minFreeMb: min,
          );
      ref.invalidate(documentStorageProvider);
      if (mounted) {
        showToast(context, 'Document storage saved');
        setState(() => _busy = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  Future<void> _reset() async {
    final ok = await confirmDialog(
      context,
      title: 'Go back to the .env values?',
      message: 'New documents will be saved where the server\'s .env file says. Documents already saved are kept and still open.',
      confirmLabel: 'Reset',
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = true;
      _outcome = null;
    });
    try {
      await ref.read(documentStorageRepositoryProvider).reset();
      ref.invalidate(documentStorageProvider);
      if (mounted) {
        showToast(context, 'Using the .env values again');
        setState(() => _busy = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _d;
    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text('Where identity and ownership documents of applications are saved',
                    style: TextStyle(fontWeight: FontWeight.w800, height: 1.35)),
              ),
              const SizedBox(width: 10),
              _sourcePill(d.fromDashboard),
            ],
          ),
          const SizedBox(height: 6),
          InfoRow('In use now', d.location, icon: Icons.folder_outlined),
          if (d.freeMb != null) InfoRow('Free space', _free(d.freeMb!), icon: Icons.data_usage_rounded),
          if (!d.ready) InlineMessage(d.problem ?? 'This storage cannot be used right now.', kind: MessageKind.error),
          const SizedBox(height: 12),
          PSelectField<String>(
            label: 'Kept on',
            value: _type,
            enabled: !_busy,
            options: const <PChoice<String>>[
              PChoice<String>('LOCAL', 'This server', description: 'A folder on the computer the service runs on'),
              PChoice<String>('NETWORK', 'A network share', description: 'A share the server already has mounted'),
            ],
            onChanged: (v) => setState(() {
              if (v != null) _type = v;
            }),
          ),
          const SizedBox(height: 12),
          if (!_network)
            PTextField(
              label: 'Folder',
              controller: _local,
              enabled: !_busy,
              hint: '/srv/premisave/homeowner-onboarding',
              helper: 'A full path inside one of the allowed folders. It is created if it does not exist.',
            )
          else ...<Widget>[
            PSelectField<String>(
              label: 'Share type',
              value: _protocol,
              enabled: !_busy,
              options: const <PChoice<String>>[
                PChoice<String>('SMB', 'SMB (Windows share, Synology)'),
                PChoice<String>('NFS', 'NFS'),
              ],
              onChanged: (v) => setState(() {
                if (v != null) _protocol = v;
              }),
            ),
            const SizedBox(height: 12),
            PTextField(
              label: 'Address of the storage server',
              controller: _host,
              enabled: !_busy,
              optional: true,
              hint: '192.168.1.50',
              helper: 'Only used to check the right share is mounted. The service never connects to it.',
            ),
            const SizedBox(height: 12),
            PTextField(
              label: _protocol == 'NFS' ? 'Exported path' : 'Share name',
              controller: _share,
              enabled: !_busy,
              optional: true,
              hint: _protocol == 'NFS' ? '/volume1/premisave' : 'premisave',
            ),
            const SizedBox(height: 12),
            PTextField(
              label: 'Where the share is mounted',
              controller: _mount,
              enabled: !_busy,
              hint: '/mnt/premisave-nas',
              helper: 'The server never mounts anything itself. Mount the share first.',
            ),
            const SizedBox(height: 12),
            PTextField(
              label: 'Folder inside the share',
              controller: _directory,
              enabled: !_busy,
              optional: true,
              hint: 'homeowner-onboarding',
              helper: 'Letters, digits, dot, dash, underscore, space and brackets. Leave blank to use the share itself.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Refuse if it is not a real network share', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('Stops files filling this server\'s own disk when the share is not mounted.',
                  style: TextStyle(color: context.mutedColor, height: 1.4)),
              value: _requireMount,
              onChanged: _busy ? null : (v) => setState(() => _requireMount = v),
            ),
          ],
          const SizedBox(height: 12),
          PTextField(
            label: 'Refuse uploads when free space is below (MB)',
            controller: _minFree,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            errorText: _minFreeError,
            helper: '0 turns the check off. The .env value is ${d.env.minFreeMb}.',
          ),
          if (_outcome != null) ...<Widget>[
            const SizedBox(height: 8),
            InlineMessage(_outcome!.text, kind: _outcome!.ok ? MessageKind.success : MessageKind.error),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              PButton(label: 'Try it', kind: PButtonKind.outline, onPressed: _busy ? null : _check),
              PButton(label: 'Save', loading: _busy, onPressed: _busy ? null : _save),
              if (d.fromDashboard) PButton(label: 'Reset to .env', kind: PButtonKind.text, onPressed: _busy ? null : _reset),
            ],
          ),
        ],
      ),
    );
  }
}
