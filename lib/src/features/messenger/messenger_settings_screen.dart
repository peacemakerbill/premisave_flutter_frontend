import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/files/file_kinds.dart';
import '../../core/files/file_store.dart';
import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../state/file_downloads.dart';
import '../../state/messenger_providers.dart';

/// Messenger settings: where downloaded files are saved, the files already saved, and how message editing works.
class MessengerSettingsScreen extends ConsumerWidget {
  const MessengerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(fileSettingsProvider);
    final controller = ref.read(fileSettingsProvider.notifier);
    final editWindow = ref.watch(editWindowProvider);
    final anyCustom = settings.root != null || settings.folders.isNotEmpty;

    Future<void> choose(Future<void> Function(String path) save) async {
      final path = await fileStorePickFolder();
      if (path == null || !context.mounted) return;
      await save(path);
      if (context.mounted) showToast(context, 'Folder saved');
    }

    return SubPage(
      title: 'Messenger settings',
      fallbackRoute: '/messages',
      body: PageBody(
        maxWidth: 720,
        children: <Widget>[
          const SectionHeader('Download folders', padding: EdgeInsets.only(top: 12, bottom: 10)),
          if (!fileStoreCanChooseFolders)
            PCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.info_outline_rounded, color: context.mutedColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'A web browser saves downloads into its own Downloads folder and does not let a page choose subfolders. '
                      'On the phone and computer apps, files are saved to Downloads/Premisave with a subfolder for images, video, audio, documents and other files, '
                      'and you can change each folder here.',
                      style: TextStyle(height: 1.5, color: context.mutedColor),
                    ),
                  ),
                ],
              ),
            )
          else ...<Widget>[
            PCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: <Widget>[
                  _FolderRow(
                    icon: Icons.folder_special_outlined,
                    title: 'Downloads folder',
                    note: 'Every kind of file is saved in a subfolder of this folder unless you give it its own folder below.',
                    path: controller.rootFolder(),
                    custom: settings.root != null,
                    onChange: () => choose(controller.setRoot),
                    onReset: settings.root == null ? null : () => controller.resetRoot(),
                    resetLabel: 'Use Downloads/Premisave',
                  ),
                  for (final c in FileCategory.values) ...<Widget>[
                    Divider(height: 1, color: context.borderColor),
                    _FolderRow(
                      icon: c.icon,
                      title: c.label,
                      path: controller.folderFor(c),
                      custom: settings.folders.containsKey(c),
                      onChange: () => choose((p) => controller.setFolder(c, p)),
                      onReset: settings.folders.containsKey(c) ? () => controller.resetFolder(c) : null,
                      resetLabel: 'Use the default folder',
                    ),
                  ],
                ],
              ),
            ),
            if (anyCustom)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PButton(label: 'Reset all folders', kind: PButtonKind.text, small: true, onPressed: () => controller.resetAll()),
                ),
              ),
            const SectionHeader('Saved files'),
            PCard(
              padding: EdgeInsets.zero,
              child: MenuTile(
                icon: Icons.download_done_rounded,
                title: 'Downloaded files',
                subtitle: 'Open the files you saved from chats',
                onTap: () => context.push('/messages/settings/downloads'),
              ),
            ),
          ],
          const SectionHeader('Messages'),
          PCard(
            padding: EdgeInsets.zero,
            child: MenuTile(
              icon: Icons.edit_outlined,
              title: 'Editing messages',
              subtitle: editWindow.when(
                data: (h) => h <= 0
                    ? 'Editing messages is turned off on this server.'
                    : 'You can edit a message for $h ${h == 1 ? 'hour' : 'hours'} after you send it. Press and hold it (or right click it) and choose Edit.',
                loading: () => 'Press and hold a message (or right click it) and choose Edit.',
                error: (_, __) => 'Press and hold a message (or right click it) and choose Edit.',
              ),
              trailing: const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.icon,
    required this.title,
    required this.path,
    required this.custom,
    required this.onChange,
    required this.resetLabel,
    this.note,
    this.onReset,
  });

  final IconData icon;
  final String title;
  final String? note;
  final Future<String> path;
  final bool custom;
  final VoidCallback onChange;
  final VoidCallback? onReset;
  final String resetLabel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: path,
      builder: (context, snap) {
        final shown = snap.data ?? '';
        final lines = <String>[if (note != null) note!, if (shown.isNotEmpty) shown];
        return MenuTile(
          icon: icon,
          title: custom ? '$title  (changed)' : title,
          subtitle: lines.isEmpty ? 'Loading' : lines.join('\n'),
          onTap: onChange,
          trailing: PopupMenuButton<String>(
            tooltip: 'Folder options',
            icon: Icon(Icons.more_vert_rounded, color: context.mutedColor),
            onSelected: (v) {
              if (v == 'change') onChange();
              if (v == 'reset') onReset?.call();
            },
            itemBuilder: (_) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'change', child: Text('Choose a folder')),
              if (onReset != null) PopupMenuItem<String>(value: 'reset', child: Text(resetLabel)),
            ],
          ),
        );
      },
    );
  }
}
