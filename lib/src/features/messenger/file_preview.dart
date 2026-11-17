import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart' show AudioPlayer, DeviceFileSource, PlayerState, Source, UrlSource;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart' show PdfViewer;

import '../../core/files/file_kinds.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/file_ref.dart';
import '../../data/models/messenger_models.dart';
import '../../state/file_downloads.dart';
import 'file_actions.dart';
import 'file_viewer_screen.dart';
import 'messenger_common.dart';

// How a file looks inside a chat bubble. A PDF shows its first page, a text file its first lines, a video a poster,
// audio a player, and anything else a coloured tile with its type. Under it sits the name, the size and a download button.

const double _cardWidth = 264;
const int _previewLimit = 12 * 1024 * 1024; // do not fetch a file bigger than this just to draw a thumbnail

/// A file message's body, for everything except photos.
class FileAttachment extends ConsumerWidget {
  const FileAttachment({super.key, required this.message, required this.mine, required this.fg, required this.soft});

  final MMessage message;
  final bool mine;
  final Color fg;
  final Color soft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = message;
    final file = FileRef.fromMessage(m, resolveMedia(m.mediaUrl));
    final kind = file.kind;
    final uploading = m.status == MDelivery.sending && m.progress != null;
    final canOpen = file.url != null && !uploading;
    final pal = context.pal;

    Widget? preview;
    if (canOpen) {
      switch (kind) {
        case FileKind.pdf:
          if ((file.size ?? 0) <= _previewLimit) preview = PdfThumb(file: file);
        case FileKind.text:
          if ((file.size ?? 0) > 0 && (file.size ?? 0) <= 256 * 1024) preview = TextThumb(file: file);
        case FileKind.video:
          preview = VideoPoster(file: file);
        case FileKind.image:
        case FileKind.audio:
        case FileKind.word:
        case FileKind.sheet:
        case FileKind.slides:
        case FileKind.archive:
        case FileKind.other:
          break;
      }
    }

    final tile = (mine ? pal.accentInk : pal.accent).op(0.12);

    if (kind == FileKind.audio && canOpen) {
      return Container(
        width: _cardWidth,
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
        decoration: BoxDecoration(color: tile, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AudioPlayerBar(file: file, color: fg, soft: soft),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 0, 4),
              child: Text(
                '${file.name}${(file.size ?? 0) > 0 ? '  ·  ${formatBytes(file.size ?? 0)}' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: soft),
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: canOpen ? () => openFileViewer(context, file) : null,
      child: Container(
        width: _cardWidth,
        decoration: BoxDecoration(color: tile, borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (preview != null) SizedBox(height: kind == FileKind.video ? 150 : 190, child: preview),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: <Widget>[
                  KindBadge(kind: kind, name: file.name),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: fg, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(
                          <String>[kind.label, if ((file.size ?? 0) > 0) formatBytes(file.size ?? 0)].join('  ·  '),
                          style: TextStyle(fontSize: 12, color: soft),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (uploading)
                    SizedBox(width: 34, height: 34, child: CircularProgressIndicator(value: (m.progress ?? 0) <= 0 ? null : m.progress, strokeWidth: 3, color: fg))
                  else if (canOpen)
                    DownloadButton(file: file, color: fg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The coloured square that tells file types apart: the extension for documents, an icon for media.
class KindBadge extends StatelessWidget {
  const KindBadge({super.key, required this.kind, required this.name, this.size = 42});

  final FileKind kind;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ext = extensionOf(name);
    final showText = ext.isNotEmpty && ext.length <= 4 && kind != FileKind.image && kind != FileKind.video && kind != FileKind.audio;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: kind.tint, borderRadius: BorderRadius.circular(size * 0.24)),
      child: showText
          ? Text(ext.toUpperCase(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * (ext.length > 3 ? 0.22 : 0.26)))
          : Icon(kind.icon, color: Colors.white, size: size * 0.55),
    );
  }
}

/// Download, progress and saved, in one round button.
class DownloadButton extends ConsumerWidget {
  const DownloadButton({super.key, required this.file, required this.color, this.size = 36});

  final FileRef file;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(downloadsProvider.select((s) => s.active[file.key]));
    final saved = ref.watch(downloadsProvider.select((s) => s.files[file.key]));

    if (progress != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            CircularProgressIndicator(value: progress < 0 || progress >= 1 ? null : progress, strokeWidth: 3, color: color),
            Icon(Icons.arrow_downward_rounded, size: size * 0.4, color: color),
          ],
        ),
      );
    }

    final done = saved != null && !saved.inBrowser;
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: done ? 'Open the saved file' : 'Download',
        style: IconButton.styleFrom(side: BorderSide(color: color.op(0.55), width: 1.4)),
        onPressed: () async {
          if (done) {
            await openSavedFile(context, ref, saved);
          } else {
            await saveFile(context, ref, file);
          }
        },
        icon: Icon(done ? Icons.check_rounded : Icons.arrow_downward_rounded, size: size * 0.52, color: color),
      ),
    );
  }
}

// ------------------------------------------------------------------ previews

/// The first page of a PDF, drawn small so the chat shows what the file is before it is opened.
class PdfThumb extends ConsumerStatefulWidget {
  const PdfThumb({super.key, required this.file});

  final FileRef file;

  @override
  ConsumerState<PdfThumb> createState() => _PdfThumbState();
}

class _PdfThumbState extends ConsumerState<PdfThumb> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await loadFileBytes(ref, widget.file, maxBytes: _previewLimit);
      if (mounted) setState(() => _bytes = b);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _bytes;
    if (_failed) return const _PreviewPlaceholder(kind: FileKind.pdf, label: 'Preview not available');
    if (b == null) return const _PreviewPlaceholder(kind: FileKind.pdf, loading: true);
    return IgnorePointer(child: PdfViewer.data(b, sourceName: widget.file.key));
  }
}

/// The first lines of a small text file.
class TextThumb extends ConsumerStatefulWidget {
  const TextThumb({super.key, required this.file});

  final FileRef file;

  @override
  ConsumerState<TextThumb> createState() => _TextThumbState();
}

class _TextThumbState extends ConsumerState<TextThumb> {
  String? _text;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await loadFileBytes(ref, widget.file, maxBytes: 256 * 1024);
      final lines = const LineSplitter().convert(utf8.decode(b, allowMalformed: true)).take(12).join('\n');
      if (mounted) setState(() => _text = lines);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _text;
    if (_failed) return const _PreviewPlaceholder(kind: FileKind.text, label: 'Preview not available');
    if (t == null) return const _PreviewPlaceholder(kind: FileKind.text, loading: true);
    return Container(
      color: context.pal.panel2,
      padding: const EdgeInsets.all(10),
      alignment: Alignment.topLeft,
      child: Text(t, maxLines: 10, overflow: TextOverflow.fade, style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.35, color: context.pal.ink)),
    );
  }
}

/// A dark poster with a play button. The video itself loads when it is opened.
class VideoPoster extends StatelessWidget {
  const VideoPoster({super.key, required this.file});

  final FileRef file;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFF37474F), Color(0xFF0D1B22)]),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(color: Color(0x99000000), shape: BoxShape.circle),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({required this.kind, this.loading = false, this.label});

  final FileKind kind;
  final bool loading;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kind.tint.op(0.14),
      alignment: Alignment.center,
      child: loading
          ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: kind.tint))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(kind.icon, size: 40, color: kind.tint),
                if (label != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(label!, style: TextStyle(fontSize: 12, color: context.mutedColor))),
              ],
            ),
    );
  }
}

// --------------------------------------------------------------------- audio

/// A small audio player: play or pause, a seek bar and the time. Only one plays at a time.
class AudioPlayerBar extends ConsumerStatefulWidget {
  const AudioPlayerBar({super.key, required this.file, required this.color, required this.soft, this.large = false});

  final FileRef file;
  final Color color;
  final Color soft;
  final bool large;

  @override
  ConsumerState<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends ConsumerState<AudioPlayerBar> {
  static _AudioPlayerBarState? _current;

  AudioPlayer? _player;
  final List<StreamSubscription<dynamic>> _subs = <StreamSubscription<dynamic>>[];
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _failed = false;

  @override
  void dispose() {
    if (identical(_current, this)) _current = null;
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  AudioPlayer _create() {
    final p = AudioPlayer();
    _subs
      ..add(p.onPlayerStateChanged.listen((s) {
        if (mounted) setState(() => _state = s);
      }))
      ..add(p.onPositionChanged.listen((d) {
        if (mounted) setState(() => _position = d);
      }))
      ..add(p.onDurationChanged.listen((d) {
        if (mounted) setState(() => _total = d);
      }))
      ..add(p.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _position = Duration.zero);
      }));
    return p;
  }

  Future<void> _pauseFromOutside() async {
    try {
      await _player?.pause();
    } catch (_) {}
  }

  Future<void> _toggle() async {
    final p = _player ??= _create();
    try {
      if (_state == PlayerState.playing) {
        await p.pause();
        return;
      }
      if (!identical(_current, this)) {
        await _current?._pauseFromOutside();
        _current = this;
      }
      if (_state == PlayerState.paused) {
        await p.resume();
        return;
      }
      final saved = ref.read(downloadsProvider).files[widget.file.key];
      Source? source;
      if (!kIsWeb && saved != null && !saved.inBrowser) source = DeviceFileSource(saved.path);
      final url = widget.file.url;
      try {
        if (source != null) {
          await p.play(source);
          if (mounted) setState(() => _failed = false);
          return;
        }
      } catch (_) {
        // The saved copy could not be read: fall back to the link.
      }
      if (url == null) throw StateError('No link');
      await p.play(UrlSource(url));
      if (mounted) setState(() => _failed = false);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  String _clock(Duration d) {
    final m = d.inMinutes;
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final playing = _state == PlayerState.playing;
    final max = _total.inMilliseconds <= 0 ? 1.0 : _total.inMilliseconds.toDouble();
    final value = _position.inMilliseconds.clamp(0, max.toInt()).toDouble();
    return Row(
      children: <Widget>[
        IconButton(
          tooltip: playing ? 'Pause' : 'Play',
          onPressed: _toggle,
          iconSize: widget.large ? 44 : 30,
          icon: Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: widget.color),
        ),
        Expanded(
          child: _failed
              ? Text('Could not play this audio', style: TextStyle(fontSize: 12.5, color: widget.soft))
              : SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 3, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6), overlayShape: SliderComponentShape.noOverlay),
                  child: Slider(
                    value: value,
                    max: max,
                    activeColor: widget.color,
                    inactiveColor: widget.color.op(0.3),
                    onChanged: _total.inMilliseconds <= 0 ? null : (v) => setState(() => _position = Duration(milliseconds: v.round())),
                    onChangeEnd: (v) => _player?.seek(Duration(milliseconds: v.round())),
                  ),
                ),
        ),
        Text(_total.inMilliseconds > 0 ? _clock(playing || _position > Duration.zero ? _position : _total) : '', style: TextStyle(fontSize: 12, color: widget.soft)),
      ],
    );
  }
}
