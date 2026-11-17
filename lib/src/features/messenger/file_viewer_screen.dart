import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart' show CachedNetworkImage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart' show PdfViewer;
import 'package:url_launcher/url_launcher.dart' show LaunchMode, launchUrl;
import 'package:video_player/video_player.dart' show VideoPlayer, VideoPlayerController, VideoPlayerValue, VideoProgressColors, VideoProgressIndicator;

import '../../core/files/file_kinds.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/file_ref.dart';
import '../../state/file_downloads.dart';
import 'file_actions.dart';
import 'file_preview.dart';

/// Opens a file inside the app: photos zoom, PDFs scroll, text reads, audio and video play.
/// Anything else shows what it is and offers to download it and open it with another app.
Future<void> openFileViewer(BuildContext context, FileRef file) {
  return Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => FileViewerScreen(file: file)));
}

class FileViewerScreen extends ConsumerWidget {
  const FileViewerScreen({super.key, required this.file});

  final FileRef file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(downloadsProvider.select((s) => s.files[file.key]));
    final progress = ref.watch(downloadsProvider.select((s) => s.active[file.key]));
    final kind = file.kind;
    final dark = kind == FileKind.image || kind == FileKind.video;
    final pal = context.pal;

    final onDisk = saved != null && !saved.inBrowser;
    final here = file.localPath ?? (onDisk ? saved.path : null);

    final body = switch (kind) {
      FileKind.image => _ImageBody(file: file, localPath: here),
      FileKind.pdf => _BytesBody(file: file, maxBytes: 80 * 1024 * 1024, builder: (_, b) => PdfViewer.data(b, sourceName: file.key)),
      FileKind.text => _BytesBody(
          file: file,
          maxBytes: 1024 * 1024,
          builder: (ctx, b) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(utf8.decode(b, allowMalformed: true), style: TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4, color: ctx.pal.ink)),
          ),
        ),
      FileKind.video => _VideoBody(file: file),
      FileKind.audio => _AudioBody(file: file),
      _ => _InfoBody(file: file, saved: saved, progress: progress),
    };

    return Scaffold(
      backgroundColor: dark ? Colors.black : pal.bg,
      appBar: AppBar(
        backgroundColor: dark ? Colors.black : pal.bg,
        foregroundColor: dark ? Colors.white : pal.ink,
        surfaceTintColor: Colors.transparent,
        title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        actions: <Widget>[
          if (onDisk || (file.localPath != null && !kIsWeb))
            IconButton(
              tooltip: 'Open with another app',
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () async {
                final path = here;
                if (path == null) return;
                final entry = saved ?? DownloadedFile(key: file.key, name: file.name, path: path, category: file.category, savedAt: DateTime.now());
                await openSavedFile(context, ref, entry);
              },
            ),
          if (file.url != null)
            if (progress != null)
              const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4)))
            else
              IconButton(
                tooltip: onDisk ? 'Saved on this device' : 'Download',
                icon: Icon(onDisk ? Icons.download_done_rounded : Icons.download_rounded),
                onPressed: onDisk ? () => showToast(context, 'Saved to ${folderOf(saved.path)}') : () => saveFile(context, ref, file),
              ),
        ],
      ),
      body: SafeArea(child: body),
    );
  }
}

// -------------------------------------------------------------------- loading

/// Reads a file's bytes, shows progress, and hands them to [builder]. When the read fails it says so and offers a way out.
class _BytesBody extends ConsumerStatefulWidget {
  const _BytesBody({required this.file, required this.builder, this.maxBytes});

  final FileRef file;
  final int? maxBytes;
  final Widget Function(BuildContext context, Uint8List bytes) builder;

  @override
  ConsumerState<_BytesBody> createState() => _BytesBodyState();
}

class _BytesBodyState extends ConsumerState<_BytesBody> {
  Uint8List? _bytes;
  Object? _error;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _progress = 0;
    });
    try {
      final b = await loadFileBytes(ref, widget.file, maxBytes: widget.maxBytes, onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (mounted) setState(() => _bytes = b);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _bytes;
    if (b != null) return widget.builder(context, b);
    final err = _error;
    if (err != null) {
      final tooBig = err is StateError && err.message.contains('too large');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.error_outline_rounded, size: 44, color: context.mutedColor),
              const SizedBox(height: 12),
              Text(
                tooBig ? 'This file is too large to open here. Download it and open it with another app.' : 'This file could not be opened here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.mutedColor, height: 1.4),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: <Widget>[
                  if (!tooBig) PButton(label: 'Try again', small: true, onPressed: _load),
                  if (widget.file.url != null) PButton(label: 'Open in the browser', kind: PButtonKind.outline, small: true, onPressed: () => launchUrl(Uri.parse(widget.file.url!), mode: LaunchMode.externalApplication)),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: SizedBox(
        width: 120,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            LinearProgressIndicator(value: _progress <= 0 || _progress >= 1 ? null : _progress, color: context.pal.accent),
            const SizedBox(height: 10),
            Text('Opening', style: TextStyle(color: context.mutedColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------- photos

class _ImageBody extends ConsumerWidget {
  const _ImageBody({required this.file, required this.localPath});

  final FileRef file;
  final String? localPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = file.url;
    Widget broken() => const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48);
    if (localPath != null && !kIsWeb) {
      return _BytesBody(
        file: file.withLocal(localPath),
        builder: (_, b) => Center(child: InteractiveViewer(maxScale: 6, child: Image.memory(b, fit: BoxFit.contain, errorBuilder: (_, __, ___) => broken()))),
      );
    }
    if (url == null) return Center(child: broken());
    return Center(
      child: InteractiveViewer(
        maxScale: 6,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.contain,
          placeholder: (_, __) => const CircularProgressIndicator(),
          errorWidget: (_, __, ___) => broken(),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------- audio

class _AudioBody extends StatelessWidget {
  const _AudioBody({required this.file});

  final FileRef file;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              KindBadge(kind: FileKind.audio, name: file.name, size: 96),
              const SizedBox(height: 18),
              Text(file.name, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: context.display(size: 18, weight: FontWeight.w800)),
              if ((file.size ?? 0) > 0) Padding(padding: const EdgeInsets.only(top: 4), child: Text(formatBytes(file.size ?? 0), style: TextStyle(color: context.mutedColor))),
              const SizedBox(height: 20),
              AudioPlayerBar(file: file, color: pal.accent, soft: context.mutedColor, large: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------- video

class _VideoBody extends ConsumerStatefulWidget {
  const _VideoBody({required this.file});

  final FileRef file;

  @override
  ConsumerState<_VideoBody> createState() => _VideoBodyState();
}

class _VideoBodyState extends ConsumerState<_VideoBody> {
  VideoPlayerController? _controller;
  bool _failed = false;

  // The video plugin has no Linux or Windows version, so those open the saved file in the system player instead.
  static bool get _supported => kIsWeb || (defaultTargetPlatform != TargetPlatform.linux && defaultTargetPlatform != TargetPlatform.windows);

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final url = widget.file.url;
    if (!_supported || url == null) {
      setState(() => _failed = true);
      return;
    }
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url));
      _controller = c;
      await c.initialize();
      if (!mounted) return;
      setState(() {});
      await c.play();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (_failed || c == null) {
      if (!_failed) return const Center(child: CircularProgressIndicator());
      return _InfoBody(
        file: widget.file,
        saved: ref.watch(downloadsProvider.select((s) => s.files[widget.file.key])),
        progress: ref.watch(downloadsProvider.select((s) => s.active[widget.file.key])),
        note: _supported ? 'This video could not be played here.' : 'Video playback is not available on this computer yet.',
        dark: true,
      );
    }
    if (!c.value.isInitialized) return const Center(child: CircularProgressIndicator());
    return Column(
      children: <Widget>[
        Expanded(child: Center(child: AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c)))),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: c,
          builder: (_, v, __) => Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: v.isPlaying ? 'Pause' : 'Play',
                  color: Colors.white,
                  iconSize: 34,
                  icon: Icon(v.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  onPressed: () => v.isPlaying ? c.pause() : c.play(),
                ),
                Expanded(child: VideoProgressIndicator(c, allowScrubbing: true, colors: const VideoProgressColors(playedColor: Colors.white, bufferedColor: Colors.white30, backgroundColor: Colors.white12))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- everything else

/// For files that cannot be shown inside the app: what the file is, and the way to get it onto the device.
class _InfoBody extends ConsumerWidget {
  const _InfoBody({required this.file, required this.saved, required this.progress, this.note, this.dark = false});

  final FileRef file;
  final DownloadedFile? saved;
  final double? progress;
  final String? note;
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = dark ? Colors.white70 : context.mutedColor;
    final ink = dark ? Colors.white : context.pal.ink;
    final onDisk = saved != null && !saved!.inBrowser;
    final here = file.localPath ?? (onDisk ? saved!.path : null);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              KindBadge(kind: file.kind, name: file.name, size: 96),
              const SizedBox(height: 18),
              Text(file.name, textAlign: TextAlign.center, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
              const SizedBox(height: 4),
              Text(<String>[file.kind.label, if ((file.size ?? 0) > 0) formatBytes(file.size ?? 0)].join('  ·  '), style: TextStyle(color: muted)),
              const SizedBox(height: 14),
              Text(
                note ?? 'A preview is not available for this type of file. Download it, then open it with another app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, height: 1.45),
              ),
              if (onDisk) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Saved to ${folderOf(saved!.path)}', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12.5))),
              const SizedBox(height: 20),
              if (here != null && !kIsWeb)
                PButton(
                  label: 'Open',
                  icon: Icons.open_in_new_rounded,
                  onPressed: () => openSavedFile(context, ref, saved ?? DownloadedFile(key: file.key, name: file.name, path: here, category: file.category, savedAt: DateTime.now())),
                )
              else if (file.url != null)
                PButton(
                  label: progress != null ? 'Downloading' : 'Download',
                  icon: Icons.download_rounded,
                  loading: progress != null,
                  onPressed: () => saveFile(context, ref, file),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
