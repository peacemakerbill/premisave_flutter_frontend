import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/files/file_kinds.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/file_ref.dart';
import '../../state/file_downloads.dart';
import 'file_actions.dart';
import 'file_preview.dart';
import 'file_viewer_screen.dart';

/// The files saved from chats, newest first, grouped by the folder they went to. Tap one to view it inside the app.
class DownloadedFilesScreen extends ConsumerStatefulWidget {
  const DownloadedFilesScreen({super.key});

  @override
  ConsumerState<DownloadedFilesScreen> createState() => _DownloadedFilesScreenState();
}

class _DownloadedFilesScreenState extends ConsumerState<DownloadedFilesScreen> {
  FileCategory? _only;

  FileRef _ref(DownloadedFile f) => FileRef(key: f.key, name: f.name, mime: f.mime, size: f.size, localPath: f.path);

  Future<void> _open(DownloadedFile f) async {
    final present = await ref.read(downloadsProvider.notifier).existing(f.key);
    if (!mounted) return;
    if (present == null) {
      showToast(context, 'This file is no longer in its folder, so it was removed from the list.', error: true);
      return;
    }
    await openFileViewer(context, _ref(f));
  }

  Future<void> _remove(DownloadedFile f) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete this file?',
      message: '${f.name} will be deleted from this device.',
      confirmLabel: 'Delete',
      danger: true,
    );
    if (!ok) return;
    await ref.read(downloadsProvider.notifier).remove(f.key, deleteFile: true);
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(downloadsProvider.select((s) => s.files)).values.where((f) => !f.inBrowser).toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    final shown = _only == null ? all : all.where((f) => f.category == _only).toList();

    return SubPage(
      title: 'Downloaded files',
      fallbackRoute: '/messages/settings',
      body: all.isEmpty
          ? const EmptyState(
              icon: Icons.download_for_offline_outlined,
              title: 'No downloaded files yet',
              message: 'Files you download from a chat are listed here so you can open them again.',
            )
          : Column(
              children: <Widget>[
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(label: const Text('All'), selected: _only == null, onSelected: (_) => setState(() => _only = null)),
                      ),
                      for (final c in FileCategory.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(label: Text(c.label), selected: _only == c, onSelected: (_) => setState(() => _only = c)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: shown.isEmpty
                      ? Center(child: Text('Nothing here yet', style: TextStyle(color: context.mutedColor)))
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: shown.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: context.borderColor),
                          itemBuilder: (context, i) {
                            final f = shown[i];
                            final kind = kindOfFile(name: f.name, mime: f.mime);
                            return ListTile(
                              leading: KindBadge(kind: kind, name: f.name, size: 40),
                              title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                <String>[f.category.label, if ((f.size ?? 0) > 0) formatBytes(f.size ?? 0), formatDate(f.savedAt)].join('  ·  '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _open(f),
                              trailing: PopupMenuButton<String>(
                                tooltip: 'More',
                                onSelected: (v) {
                                  if (v == 'open') openSavedFile(context, ref, f);
                                  if (v == 'forget') ref.read(downloadsProvider.notifier).remove(f.key);
                                  if (v == 'delete') _remove(f);
                                },
                                itemBuilder: (_) => const <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(value: 'open', child: Text('Open with another app')),
                                  PopupMenuItem<String>(value: 'forget', child: Text('Remove from this list')),
                                  PopupMenuItem<String>(value: 'delete', child: Text('Delete from this device')),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
