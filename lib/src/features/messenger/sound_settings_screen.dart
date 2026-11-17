import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/files/file_chooser.dart';
import '../../core/files/sound_store.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../state/sound_settings.dart';

/// Chooses the ringtone for incoming calls and the sound for new messages and notifications. Tap a sound to hear it and
/// pick it, or choose one of your own from a file.
class SoundSettingsScreen extends ConsumerStatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  ConsumerState<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends ConsumerState<SoundSettingsScreen> {
  late final SoundService _sounds;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sounds = ref.read(soundServiceProvider);
  }

  @override
  void dispose() {
    unawaited(_sounds.stopPreview());
    super.dispose();
  }

  Future<void> _pickBuiltIn(SoundSlot slot, BuiltInSound sound) async {
    await ref.read(soundSettingsProvider.notifier).useBuiltIn(slot, sound);
    await _hear(slot);
  }

  Future<void> _pickSilent() async {
    await _sounds.stopPreview();
    await ref.read(soundSettingsProvider.notifier).useSilent();
  }

  Future<void> _hear(SoundSlot slot) {
    final pick = ref.read(soundSettingsProvider).of(slot);
    return _sounds.preview(pick, fallback: slot == SoundSlot.ringtone ? defaultRingtone : defaultNotificationSound);
  }

  Future<void> _pickFile(SoundSlot slot) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final files = await chooseFiles(extensions: audioExtensions, withData: kIsWeb);
      if (files.isEmpty) return;
      final problem = await ref.read(soundSettingsProvider.notifier).useFile(slot, files.first);
      if (!mounted) return;
      if (problem != null) {
        showToast(context, problem, error: true);
      } else {
        await _hear(slot);
      }
    } catch (_) {
      if (mounted) showToast(context, 'That file could not be opened.', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(soundSettingsProvider);
    final controller = ref.read(soundSettingsProvider.notifier);

    return SubPage(
      title: 'Sounds',
      fallbackRoute: '/messages/settings',
      body: PageBody(
        maxWidth: 720,
        children: <Widget>[
          const SectionHeader('Ringtone', padding: EdgeInsets.only(top: 12, bottom: 10)),
          _SoundList(
            current: settings.ringtone,
            sounds: builtInRingtones,
            ownLabel: 'Your own ringtone',
            busy: _busy,
            onPick: (s) => _pickBuiltIn(SoundSlot.ringtone, s),
            onHear: () => _hear(SoundSlot.ringtone),
            onChooseFile: () => _pickFile(SoundSlot.ringtone),
            onReset: settings.ringtone.value == defaultRingtone.value ? null : () => controller.reset(SoundSlot.ringtone),
          ),
          const SectionHeader('Message and notification sound'),
          _SoundList(
            current: settings.notification,
            sounds: builtInNotificationSounds,
            ownLabel: 'Your own sound',
            busy: _busy,
            allowSilent: true,
            onPick: (s) => _pickBuiltIn(SoundSlot.notification, s),
            onSilent: _pickSilent,
            onHear: () => _hear(SoundSlot.notification),
            onChooseFile: () => _pickFile(SoundSlot.notification),
            onReset: settings.notification.value == defaultNotificationSound.value && !settings.notification.isSilent
                ? null
                : () => controller.reset(SoundSlot.notification),
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
                    soundStoreKeepsFiles
                        ? 'These sounds play while the app is open. Your phone keeps its own sound for alerts that arrive when the app is closed. '
                            'A file you choose is copied into the app, so it keeps working if you move the original.'
                        : 'These sounds play while the app is open in this browser. A browser keeps sounds up to 1 MB, saved on this device only, '
                            'and may wait for you to click the page once before it plays any sound.',
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
}

class _SoundList extends StatelessWidget {
  const _SoundList({
    required this.current,
    required this.sounds,
    required this.ownLabel,
    required this.busy,
    required this.onPick,
    required this.onHear,
    required this.onChooseFile,
    this.onSilent,
    this.onReset,
    this.allowSilent = false,
  });

  final SoundPick current;
  final List<BuiltInSound> sounds;
  final String ownLabel;
  final bool busy;
  final bool allowSilent;
  final ValueChanged<BuiltInSound> onPick;
  final VoidCallback? onSilent;
  final VoidCallback onHear;
  final VoidCallback onChooseFile;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final hasOwn = current.kind == SoundKind.file;
    return PCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          if (allowSilent) ...<Widget>[
            _SoundRow(title: 'Silent', icon: Icons.volume_off_outlined, selected: current.isSilent, onTap: onSilent ?? () {}),
            Divider(height: 1, color: context.borderColor),
          ],
          for (final s in sounds) ...<Widget>[
            _SoundRow(
              title: s.label,
              icon: Icons.music_note_rounded,
              selected: current.kind == SoundKind.builtIn && current.value == s.file,
              onTap: () => onPick(s),
              onHear: current.kind == SoundKind.builtIn && current.value == s.file ? onHear : null,
            ),
            Divider(height: 1, color: context.borderColor),
          ],
          _SoundRow(
            title: hasOwn ? current.label : ownLabel,
            subtitle: hasOwn ? 'Your file. Use the upload button to change it.' : 'Choose an audio file from this device',
            icon: Icons.folder_open_rounded,
            selected: hasOwn,
            onTap: busy ? () {} : (hasOwn ? onHear : onChooseFile),
            onHear: hasOwn ? onHear : null,
            trailingAction: busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(tooltip: 'Choose a file', icon: Icon(Icons.upload_file_rounded, color: context.mutedColor), onPressed: onChooseFile),
          ),
          if (onReset != null) ...<Widget>[
            Divider(height: 1, color: context.borderColor),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: PButton(label: 'Use the default sound', kind: PButtonKind.text, small: true, onPressed: onReset),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SoundRow extends StatelessWidget {
  const _SoundRow({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.onHear,
    this.trailingAction,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onHear;
  final Widget? trailingAction;

  @override
  Widget build(BuildContext context) {
    final accent = context.pal.accent;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, size: 22, color: selected ? accent : context.mutedColor),
              const SizedBox(width: 14),
              Icon(icon, size: 19, color: context.mutedColor),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5, fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle!, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                        ),
                    ],
                  ),
                ),
              ),
              if (onHear != null) IconButton(tooltip: 'Play', icon: Icon(Icons.play_circle_outline_rounded, color: accent), onPressed: onHear),
              if (trailingAction != null) trailingAction!,
            ],
          ),
        ),
      ),
    );
  }
}
