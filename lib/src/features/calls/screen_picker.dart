import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc show desktopCapturer, DesktopCapturerSource, SourceType;

import 'call_widgets.dart';

/// On Linux, Windows and macOS the app lists the screens and windows itself. Returns the id of the one picked,
/// or null when the person cancels.
Future<String?> pickScreenSource(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => const _ScreenPickerDialog(),
  );
}

class _ScreenPickerDialog extends StatefulWidget {
  const _ScreenPickerDialog();

  @override
  State<_ScreenPickerDialog> createState() => _ScreenPickerDialogState();
}

class _ScreenPickerDialogState extends State<_ScreenPickerDialog> with SingleTickerProviderStateMixin {
  List<rtc.DesktopCapturerSource> _sources = const <rtc.DesktopCapturerSource>[];
  Timer? _refresh;
  bool _loading = true;
  Object? _error;
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void initState() {
    super.initState();
    _load();
    // Thumbnails arrive a moment after the list, and windows change, so redraw now and then.
    _refresh = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await rtc.desktopCapturer.getSources(types: <rtc.SourceType>[rtc.SourceType.Screen, rtc.SourceType.Window]);
      if (!mounted) return;
      setState(() {
        _sources = list;
        _loading = false;
      });
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _sources.where((s) => s.type == rtc.SourceType.Screen).toList();
    final windows = _sources.where((s) => s.type == rtc.SourceType.Window).toList();
    return Dialog(
      backgroundColor: CallColors.bg,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: <Widget>[
                  const Expanded(child: Text('Choose what to share', style: TextStyle(color: CallColors.text, fontSize: 18, fontWeight: FontWeight.w800))),
                  IconButton(icon: const Icon(Icons.close_rounded, color: CallColors.text), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            TabBar(
              controller: _tabs,
              labelColor: CallColors.text,
              unselectedLabelColor: CallColors.muted,
              indicatorColor: CallColors.speaking,
              tabs: <Widget>[Tab(text: 'Screens (${screens.length})'), Tab(text: 'Windows (${windows.length})')],
            ),
            Flexible(
              child: _loading
                  ? const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: CallColors.speaking))
                  : _error != null
                      ? Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            'This computer did not let the app list its screens. On Linux with Wayland, sharing needs the X11 session or a desktop portal.',
                            style: const TextStyle(color: CallColors.muted, height: 1.4),
                          ),
                        )
                      : SizedBox(
                          height: 420,
                          child: TabBarView(
                            controller: _tabs,
                            children: <Widget>[_grid(screens), _grid(windows)],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grid(List<rtc.DesktopCapturerSource> list) {
    if (list.isEmpty) return const Center(child: Text('Nothing to share here.', style: TextStyle(color: CallColors.muted)));
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 220, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.25),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final s = list[i];
        final Uint8List? thumb = s.thumbnail;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).pop(s.id),
          child: Container(
            decoration: BoxDecoration(color: CallColors.tile, borderRadius: BorderRadius.circular(12), border: Border.all(color: CallColors.control)),
            padding: const EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: thumb == null
                        ? const Center(child: Icon(Icons.desktop_windows_outlined, color: CallColors.muted, size: 34))
                        : Image.memory(thumb, fit: BoxFit.contain, gaplessPlayback: true, width: double.infinity),
                  ),
                ),
                const SizedBox(height: 6),
                Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CallColors.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }
}
