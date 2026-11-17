import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import '../../state/call_providers.dart';

/// Administrators: the settings of the platform that are not about one person. Calls (recording on or off) and where
/// files are kept. The Users tab keeps the people, and the audit trail stays there too.
class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calls = ref.watch(callSettingsProvider).valueOrNull;
    final recording = calls == null
        ? 'Switch recording on or off for everyone, and see where the videos are stored'
        : (calls.recordingEnabled
            ? 'On. Hosts and co-hosts can record calls. Open to turn it off.'
            : 'Off. Open to turn it on.');
    return SafeArea(
      bottom: false,
      child: PageBody(
        onRefresh: () async => ref.invalidate(callSettingsProvider),
        children: <Widget>[
          const PageTitle('Settings'),
          const SectionHeader('Calls'),
          MenuGroup(
            children: <Widget>[
              MenuTile(
                icon: Icons.video_call_outlined,
                title: 'Call recording',
                subtitle: recording,
                onTap: () => context.push('/admin/calls'),
              ),
            ],
          ),
          const SectionHeader('Storage'),
          MenuGroup(
            children: <Widget>[
              MenuTile(
                icon: Icons.storage_outlined,
                title: 'Where files are saved',
                subtitle: 'Home owner documents, chat files and call recordings. The server\'s .env values apply until you save something here.',
                onTap: () => context.push('/admin/storage'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
