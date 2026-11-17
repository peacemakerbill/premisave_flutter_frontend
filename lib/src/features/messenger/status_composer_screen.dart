import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show XFile;

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/messenger_models.dart';
import '../../data/repositories/messenger_repository.dart';
import '../../state/messenger_providers.dart';
import '../../state/providers.dart';
import 'messenger_common.dart';

/// Write a text status on a coloured background, or share a photo, video or audio clip with a caption.
class StatusComposerScreen extends ConsumerStatefulWidget {
  const StatusComposerScreen({super.key});

  @override
  ConsumerState<StatusComposerScreen> createState() => _StatusComposerScreenState();
}

class _StatusComposerScreenState extends ConsumerState<StatusComposerScreen> {
  final TextEditingController _text = TextEditingController();
  final TextEditingController _caption = TextEditingController();
  int _color = 0;
  int? _hours;
  LocalFile? _file;
  Uint8List? _preview;
  bool _audio = false;
  bool _sending = false;
  double _progress = 0;

  @override
  void dispose() {
    _text.dispose();
    _caption.dispose();
    super.dispose();
  }

  Future<void> _choose({required bool audio}) async {
    final f = await pickStatusMedia(audio: audio);
    if (f == null || !mounted) return;
    Uint8List? preview = f.bytes;
    if (preview == null && f.path != null && looksLikeImage(f.name) && f.size < 15 * 1024 * 1024) {
      try {
        preview = await XFile(f.path ?? '').readAsBytes();
      } catch (_) {
        preview = null;
      }
    }
    if (!looksLikeImage(f.name)) preview = null;
    setState(() {
      _file = f;
      _preview = preview;
      _audio = audio;
    });
  }

  Future<void> _post() async {
    final settings = ref.read(statusSettingsProvider).valueOrNull ?? const StatusSettings();
    final repo = ref.read(messengerRepositoryProvider);
    final hours = _hours ?? settings.defaultHours;
    final file = _file;

    if (file == null && _text.text.trim().isEmpty) {
      showToast(context, 'Write something or choose a file first.', error: true);
      return;
    }
    setState(() {
      _sending = true;
      _progress = 0;
    });
    try {
      if (file == null) {
        await repo.postTextStatus(text: _text.text.trim(), backgroundColor: kStatusColors[_color], durationHours: hours);
      } else {
        await repo.postFileStatus(
          file: file,
          caption: _caption.text,
          durationHours: hours,
          onProgress: (sent, total) {
            if (total > 0 && mounted) setState(() => _progress = sent / total);
          },
        );
      }
      ref.invalidate(myStatusesProvider);
      ref.invalidate(statusFeedProvider);
      if (!mounted) return;
      showToast(context, 'Status posted');
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/messages');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        showApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(statusSettingsProvider).valueOrNull ?? const StatusSettings();
    final hours = _hours ?? settings.defaultHours;
    final choices = <int>{for (final h in <int>[1, 6, 12, 24, 48, 72]) if (h <= settings.maxHours) h, settings.defaultHours}.toList()..sort();

    return SubPage(
      title: 'New status',
      fallbackRoute: '/messages',
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: PButton(label: 'Post', small: true, icon: Icons.send_rounded, loading: _sending, onPressed: _post),
        ),
      ],
      body: Column(
        children: <Widget>[
          if (_sending && _file != null) LinearProgressIndicator(value: _progress == 0 ? null : _progress, minHeight: 3),
          Expanded(child: _file == null ? _textMode(context, settings) : _fileMode(context, settings)),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            decoration: BoxDecoration(color: context.pal.panel, border: Border(top: BorderSide(color: context.borderColor))),
            child: SafeArea(
              top: false,
              child: Row(children: <Widget>[
                _Tool(icon: Icons.photo_library_outlined, label: 'Photo or video', onTap: _sending ? null : () => _choose(audio: false)),
                _Tool(icon: Icons.mic_none_rounded, label: 'Audio', onTap: _sending ? null : () => _choose(audio: true)),
                if (_file != null) _Tool(icon: Icons.text_fields_rounded, label: 'Text', onTap: _sending ? null : () => setState(() => _file = null)),
                const Spacer(),
                PopupMenuButton<int>(
                  tooltip: 'How long it stays up',
                  initialValue: hours,
                  onSelected: (v) => setState(() => _hours = v),
                  itemBuilder: (_) => <PopupMenuEntry<int>>[for (final h in choices) PopupMenuItem<int>(value: h, child: Text(h == 1 ? '1 hour' : '$h hours'))],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                      Icon(Icons.timer_outlined, size: 18, color: context.pal.ink2),
                      const SizedBox(width: 6),
                      Text('$hours h', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textMode(BuildContext context, StatusSettings settings) {
    final bg = parseHexColor(kStatusColors[_color], const Color(0xFF0E3B2F));
    return Container(
      color: bg,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: TextField(
                  controller: _text,
                  maxLength: settings.textMaxLength,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.25),
                  cursorColor: Colors.white,
                  decoration: const InputDecoration(
                    hintText: 'Type a status',
                    hintStyle: TextStyle(color: Colors.white60, fontSize: 28, fontWeight: FontWeight.w700),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    counterStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: kStatusColors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => setState(() => _color = i),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: parseHexColor(kStatusColors[i], Colors.black),
                    shape: BoxShape.circle,
                    border: Border.all(color: i == _color ? Colors.white : Colors.white38, width: i == _color ? 3 : 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _fileMode(BuildContext context, StatusSettings settings) {
    final f = _file;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(context.radius(18)),
          child: Container(
            height: 360,
            color: Colors.black,
            alignment: Alignment.center,
            child: _preview != null
                ? Image.memory(_preview ?? Uint8List(0), fit: BoxFit.contain, width: double.infinity, height: 360)
                : Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                    Icon(_audio ? Icons.graphic_eq_rounded : Icons.movie_outlined, color: Colors.white70, size: 64),
                    const SizedBox(height: 10),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text(f?.name ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70))),
                  ]),
          ),
        ),
        const SizedBox(height: 14),
        PTextField(label: 'Caption', controller: _caption, optional: true, hint: 'Add a caption', maxLines: 3, minLines: 1, maxLength: settings.textMaxLength, textCapitalization: TextCapitalization.sentences),
      ],
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: onTap == null ? context.mutedColor : context.pal.ink2),
        ),
      ),
    );
  }
}
