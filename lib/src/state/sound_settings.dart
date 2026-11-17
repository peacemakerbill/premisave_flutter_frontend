import 'dart:convert';

import 'package:audioplayers/audioplayers.dart' show AssetSource, AudioPlayer, BytesSource, DeviceFileSource, ReleaseMode, Source;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/files/file_chooser.dart';
import '../core/files/sound_store.dart';

// Which sound plays for an incoming call (the ringtone) and for a new message or notification.
//
// Each one is a built-in sound that ships with the app, a file the person chose, or (for messages) silence.

enum SoundSlot { ringtone, notification }

enum SoundKind { builtIn, file, silent }

/// A sound that ships with the app, in assets/sounds.
class BuiltInSound {
  const BuiltInSound(this.file, this.label);

  final String file;
  final String label;
}

const List<BuiltInSound> builtInRingtones = <BuiltInSound>[
  BuiltInSound('ringtone.wav', 'Classic'),
  BuiltInSound('ring_marimba.wav', 'Marimba'),
  BuiltInSound('ring_bell.wav', 'Bell'),
  BuiltInSound('ring_sparkle.wav', 'Sparkle'),
  BuiltInSound('ring_pulse.wav', 'Pulse'),
  BuiltInSound('ring_gentle.wav', 'Gentle'),
];

const List<BuiltInSound> builtInNotificationSounds = <BuiltInSound>[
  BuiltInSound('notif_ping.wav', 'Ping'),
  BuiltInSound('notif_droplet.wav', 'Droplet'),
  BuiltInSound('notif_chime.wav', 'Chime'),
  BuiltInSound('notif_marimba.wav', 'Marimba'),
  BuiltInSound('notif_pop.wav', 'Pop'),
  BuiltInSound('notif_knock.wav', 'Knock'),
];

/// What one slot is set to.
class SoundPick {
  const SoundPick({required this.kind, this.value = '', this.label = '', this.bytes});

  factory SoundPick.builtIn(BuiltInSound s) => SoundPick(kind: SoundKind.builtIn, value: s.file, label: s.label);

  static const SoundPick silent = SoundPick(kind: SoundKind.silent, label: 'Silent');

  final SoundKind kind;

  /// The asset file name for a built-in sound, or the saved copy's path for a chosen file.
  final String value;

  /// The name shown to the person.
  final String label;

  /// The sound itself, in the browser only. Other platforms keep a copy as a file.
  final Uint8List? bytes;

  bool get isSilent => kind == SoundKind.silent;

  /// What the audio player plays. Null for silence.
  Source? get source {
    switch (kind) {
      case SoundKind.silent:
        return null;
      case SoundKind.builtIn:
        return AssetSource('sounds/$value');
      case SoundKind.file:
        final b = bytes;
        if (b != null) return BytesSource(b, mimeType: _mimeOf(value));
        return value.isEmpty ? null : DeviceFileSource(value);
    }
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind.name,
        'value': value,
        'label': label,
        if (bytes != null) 'data': base64Encode(bytes!),
      };

  static SoundPick? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = SoundKind.values.where((k) => k.name == raw['kind']).firstOrNull;
    if (kind == null) return null;
    Uint8List? data;
    final d = raw['data'];
    if (d is String && d.isNotEmpty) {
      try {
        data = base64Decode(d);
      } catch (_) {
        return null;
      }
    }
    return SoundPick(kind: kind, value: (raw['value'] ?? '').toString(), label: (raw['label'] ?? '').toString(), bytes: data);
  }
}

String? _mimeOf(String name) {
  final dot = name.lastIndexOf('.');
  final ext = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  switch (ext) {
    case 'mp3':
      return 'audio/mpeg';
    case 'wav':
      return 'audio/wav';
    case 'ogg':
    case 'oga':
    case 'opus':
      return 'audio/ogg';
    case 'm4a':
      return 'audio/mp4';
    case 'aac':
      return 'audio/aac';
    case 'flac':
      return 'audio/flac';
    default:
      return null;
  }
}

const SoundPick defaultRingtone = SoundPick(kind: SoundKind.builtIn, value: 'ringtone.wav', label: 'Classic');
const SoundPick defaultNotificationSound = SoundPick(kind: SoundKind.builtIn, value: 'notif_ping.wav', label: 'Ping');

class SoundSettings {
  const SoundSettings({this.ringtone = defaultRingtone, this.notification = defaultNotificationSound});

  final SoundPick ringtone;
  final SoundPick notification;

  SoundPick of(SoundSlot slot) => slot == SoundSlot.ringtone ? ringtone : notification;

  SoundSettings withSlot(SoundSlot slot, SoundPick pick) =>
      slot == SoundSlot.ringtone ? SoundSettings(ringtone: pick, notification: notification) : SoundSettings(ringtone: ringtone, notification: pick);
}

final soundSettingsProvider = NotifierProvider<SoundSettingsController, SoundSettings>(SoundSettingsController.new);

class SoundSettingsController extends Notifier<SoundSettings> {
  static const String _kRingtone = 'snd_ringtone';
  static const String _kNotification = 'snd_notification';

  bool _loaded = false;

  @override
  SoundSettings build() {
    _load();
    return const SoundSettings();
  }

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      SoundPick? read(String key) {
        final raw = prefs.getString(key);
        if (raw == null || raw.isEmpty) return null;
        try {
          return SoundPick.fromJson(jsonDecode(raw));
        } catch (_) {
          return null;
        }
      }

      final ring = read(_kRingtone);
      final note = read(_kNotification);
      // A ringtone is never silent, so a call cannot be missed because of a saved setting.
      state = SoundSettings(
        ringtone: ring == null || ring.isSilent ? defaultRingtone : ring,
        notification: note ?? defaultNotificationSound,
      );
    } catch (_) {
      // Unreadable storage: keep the defaults.
    }
  }

  Future<void> _set(SoundSlot slot, SoundPick pick) async {
    final old = state.of(slot);
    state = state.withSlot(slot, pick);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(slot == SoundSlot.ringtone ? _kRingtone : _kNotification, jsonEncode(pick.toJson()));
    } catch (_) {
      // The choice still applies until the app closes.
    }
    if (old.kind == SoundKind.file && old.value.isNotEmpty && old.value != pick.value) await soundStoreDelete(old.value);
  }

  Future<void> useBuiltIn(SoundSlot slot, BuiltInSound sound) => _set(slot, SoundPick.builtIn(sound));

  Future<void> useSilent() => _set(SoundSlot.notification, SoundPick.silent);

  /// Back to the sound the app started with.
  Future<void> reset(SoundSlot slot) => _set(slot, slot == SoundSlot.ringtone ? defaultRingtone : defaultNotificationSound);

  /// Uses a file the person chose. Returns a message saying why it could not be used, or null when it worked.
  Future<String?> useFile(SoundSlot slot, ChosenFile file) async {
    final dot = file.name.lastIndexOf('.');
    final ext = dot < 0 ? '' : file.name.substring(dot + 1).toLowerCase();
    if (!audioExtensions.contains(ext)) return 'Choose an audio file, such as MP3, WAV, M4A or OGG.';
    final label = dot > 0 ? file.name.substring(0, dot) : file.name;

    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) return 'That file could not be read.';
      if (bytes.length > soundStoreMaxBytes) return 'A browser keeps sounds up to 1 MB. Choose a shorter one, or use the phone or computer app for longer sounds.';
      await _set(slot, SoundPick(kind: SoundKind.file, value: file.name, label: label, bytes: bytes));
      return null;
    }

    final path = file.path;
    if (path == null) return 'That file could not be read.';
    if (file.size > soundStoreMaxBytes) return 'That file is too big. Choose one under 15 MB.';
    final saved = await soundStoreSave(slot: slot.name, name: file.name, sourcePath: path);
    if (saved == null) return 'That file could not be saved.';
    await _set(slot, SoundPick(kind: SoundKind.file, value: saved, label: label));
    return null;
  }
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});

/// Plays the chosen sounds. Browsers refuse sound before the first tap, so a failure to play is ignored.
class SoundService {
  AudioPlayer? _preview;
  AudioPlayer? _alert;
  DateTime _lastAlert = DateTime.fromMillisecondsSinceEpoch(0);

  /// What to play for [pick]. A chosen file that has gone missing falls back to [fallback].
  Future<Source?> sourceFor(SoundPick pick, {required SoundPick fallback}) async {
    if (pick.isSilent) return null;
    if (pick.kind == SoundKind.file && pick.bytes == null && !await soundStoreExists(pick.value)) return fallback.source;
    return pick.source;
  }

  /// The short sound for a new message or notification. Close sounds are folded into one.
  Future<void> playNotification(SoundPick pick) async {
    final now = DateTime.now();
    if (now.difference(_lastAlert) < const Duration(milliseconds: 1500)) return;
    try {
      final src = await sourceFor(pick, fallback: defaultNotificationSound);
      if (src == null) return;
      _lastAlert = now;
      final p = _alert ??= AudioPlayer();
      await p.setReleaseMode(ReleaseMode.release);
      await p.play(src, volume: 0.8);
    } catch (e) {
      debugPrint('Sounds: could not play the notification sound: $e');
    }
  }

  /// Plays a sound once so the person can hear it before choosing it.
  Future<void> preview(SoundPick pick, {required SoundPick fallback}) async {
    try {
      final src = await sourceFor(pick, fallback: fallback);
      if (src == null) return;
      final p = _preview ??= AudioPlayer();
      await p.stop();
      await p.setReleaseMode(ReleaseMode.release);
      await p.play(src, volume: 0.9);
    } catch (e) {
      debugPrint('Sounds: could not play the preview: $e');
    }
  }

  Future<void> stopPreview() async {
    try {
      await _preview?.stop();
    } catch (_) {}
  }

  void dispose() {
    _preview?.dispose();
    _alert?.dispose();
  }
}
