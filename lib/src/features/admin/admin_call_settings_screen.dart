import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/call_models.dart';
import '../../state/call_providers.dart';
import '../../state/providers.dart';

/// Administrators: the switches for calls. Call recording can be turned on and off for everyone here. When it is off, the
/// record button, the "Recording" sign and the recordings list disappear for every user.
class AdminCallSettingsScreen extends ConsumerStatefulWidget {
  const AdminCallSettingsScreen({super.key});

  @override
  ConsumerState<AdminCallSettingsScreen> createState() => _AdminCallSettingsScreenState();
}

class _AdminCallSettingsScreenState extends ConsumerState<AdminCallSettingsScreen> {
  bool _saving = false;

  Future<void> _setRecording(bool on) async {
    if (_saving) return;
    if (!on) {
      final ok = await confirmDialog(
        context,
        title: 'Turn off call recording?',
        message: 'Recording disappears for everyone, and any recording that is running now is stopped and saved. '
            'Videos already saved are kept and come back when you turn recording on again.',
        confirmLabel: 'Turn off',
        danger: true,
      );
      if (!ok || !mounted) return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(callRepositoryProvider).setRecordingEnabled(on);
      ref.invalidate(callSettingsProvider);
      await ref.read(callSettingsProvider.future);
      if (mounted) showToast(context, on ? 'Call recording is on' : 'Call recording is off');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(callSettingsProvider);
    return SubPage(
      title: 'Calls',
      fallbackRoute: '/admin/users',
      body: value.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(callSettingsProvider)),
        data: (CallSettings s) => PageBody(
          maxWidth: 720,
          children: <Widget>[
            const SectionHeader('Recording', padding: EdgeInsets.only(top: 12, bottom: 10)),
            PCard(
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                contentPadding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
                title: const Text('Call recording', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    s.recordingEnabled
                        ? 'On. Hosts and co-hosts can record a call. Everyone who was in the call can watch the recording afterwards.'
                        : 'Off. Nobody can record, and recording is hidden everywhere.',
                    style: TextStyle(height: 1.45, color: context.mutedColor),
                  ),
                ),
                value: s.recordingEnabled,
                onChanged: s.canManage && !_saving ? _setRecording : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.info_outline_rounded, size: 18, color: context.mutedColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.canManage
                          ? 'Recordings are kept on the server until someone deletes them: the person who recorded, or a host of that call. '
                              'The recording service must be running on the server for this to work.'
                          : 'Only an administrator can change this.',
                      style: TextStyle(fontSize: 12.5, height: 1.5, color: context.mutedColor),
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
