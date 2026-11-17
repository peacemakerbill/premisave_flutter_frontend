import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/call_models.dart';
import '../../state/call_controller.dart';
import 'call_chat_panel.dart';
import 'call_people_panel.dart';
import 'call_widgets.dart';
import 'screen_picker.dart';

/// The full call screen. [CallHost] shows it over the whole app while a call is open and not minimised.
class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key, required this.session});

  final CallSession session;

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

enum _Panel { none, people, chat }

class _CallScreenState extends ConsumerState<CallScreen> {
  _Panel _panel = _Panel.none;
  bool _speakerView = false;
  bool _selfSwapped = false;
  String? _lastSpeakerId;

  CallSession get _s => widget.session;

  @override
  void initState() {
    super.initState();
    _s.addListener(_onSession);
  }

  @override
  void dispose() {
    _s.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    if (mounted) setState(() {});
  }

  bool get _wide => MediaQuery.of(context).size.width >= 820;

  // ---------------------------------------------------------------- actions

  Future<void> _guard(Future<void> Function() job) async {
    try {
      await job();
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _toggleShare() async {
    if (_s.sharing) {
      await _s.stopScreenShare();
      return;
    }
    if (_s.needsScreenPicker) {
      final id = await pickScreenSource(context);
      if (id == null) return;
      await _s.startScreenShare(sourceId: id);
    } else {
      await _s.startScreenShare();
    }
  }

  Future<void> _hangUp() async {
    final ctl = ref.read(callProvider.notifier);
    final call = _s.call;
    // A host of a group call can leave and let it carry on, or end it for everyone.
    if (_s.isManager && call.isGroupLike) {
      final choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: CallColors.control,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: CallColors.text),
                title: const Text('Leave call', style: TextStyle(color: CallColors.text, fontWeight: FontWeight.w700)),
                subtitle: const Text('The others stay on the call.', style: TextStyle(color: CallColors.muted)),
                onTap: () => Navigator.of(ctx).pop('leave'),
              ),
              ListTile(
                leading: const Icon(Icons.call_end_rounded, color: CallColors.danger),
                title: const Text('End call for everyone', style: TextStyle(color: CallColors.danger, fontWeight: FontWeight.w700)),
                onTap: () => Navigator.of(ctx).pop('end'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
      if (choice == 'leave') await ctl.leave();
      if (choice == 'end') await ctl.endForAll();
      return;
    }
    await ctl.leave();
  }

  void _openPanel(_Panel panel) {
    if (_wide) {
      setState(() => _panel = _panel == panel ? _Panel.none : panel);
      _s.setChatOpen(_panel == _Panel.chat);
      return;
    }
    _showSheet(panel);
  }

  Future<void> _showSheet(_Panel panel) async {
    if (panel == _Panel.chat) _s.setChatOpen(true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: CallColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.88,
        child: panel == _Panel.chat ? CallChatPanel(session: _s, onClose: () => Navigator.of(ctx).pop()) : CallPeoplePanel(session: _s, onClose: () => Navigator.of(ctx).pop()),
      ),
    );
    if (panel == _Panel.chat) _s.setChatOpen(false);
  }

  Future<void> _more() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CallColors.bg,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _MoreSheet(session: _s, speakerView: _speakerView),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'share':
        await _toggleShare();
        break;
      case 'hand':
        await _s.toggleHand();
        break;
      case 'chat':
        _openPanel(_Panel.chat);
        break;
      case 'people':
        _openPanel(_Panel.people);
        break;
      case 'add':
        await addPeopleToCall(context, _s);
        break;
      case 'layout':
        setState(() => _speakerView = !_speakerView);
        break;
      case 'flip':
        await _s.flipCamera();
        break;
      case 'speaker':
        await _s.toggleSpeaker();
        break;
      case 'link':
        final link = _s.call.linkUrl;
        if (link != null) {
          await Clipboard.setData(ClipboardData(text: link));
          if (mounted) showToast(context, 'Call link copied');
        }
        break;
      case 'lock':
        await _guard(() => _s.setLocked(!_s.call.locked));
        break;
      case 'muteAll':
        await _guard(() async {
          await _s.muteAll();
          if (mounted) showToast(context, 'Everyone is muted');
        });
        break;
      default:
        if (action.startsWith('react:')) await _s.react(action.substring(6));
    }
  }

  // ----------------------------------------------------------------- layout

  /// Which tile fills the stage, or null for an even grid.
  CallTile? _stageTile(List<CallTile> tiles) {
    final pinned = _s.pinnedId;
    if (pinned != null) {
      for (final t in tiles) {
        if (t.id == pinned) return t;
      }
    }
    for (final t in tiles) {
      if (t.isScreen && !t.isLocal) return t;
    }
    for (final t in tiles) {
      if (t.isScreen) return t;
    }
    if (_speakerView) {
      for (final t in tiles) {
        if (t.speaking && !t.isLocal && !t.isScreen) {
          _lastSpeakerId = t.id;
          return t;
        }
      }
      if (_lastSpeakerId != null) {
        for (final t in tiles) {
          if (t.id == _lastSpeakerId) return t;
        }
      }
      for (final t in tiles) {
        if (!t.isLocal && !t.isScreen) return t;
      }
    }
    return null;
  }

  Widget _stage(BuildContext context, List<CallTile> tiles) {
    final selfTile = tiles.firstWhere((t) => t.isLocal && !t.isScreen, orElse: () => tiles.first);
    final focus = _stageTile(tiles);

    // One to one: the other person fills the screen and your own camera floats in a corner.
    final people = tiles.where((t) => !t.isScreen).toList();
    if (focus == null && people.length == 2 && !_s.call.isGroupLike) {
      final other = people.firstWhere((t) => !t.isLocal, orElse: () => people.last);
      final big = _selfSwapped ? selfTile : other;
      final small = _selfSwapped ? other : selfTile;
      return Stack(
        children: <Widget>[
          Positioned.fill(child: CallTileView(tile: big, radius: 0, onTap: () => setState(() => _selfSwapped = false))),
          Positioned(
            right: 12,
            bottom: 12,
            width: _wide ? 220 : 108,
            height: _wide ? 124 : 152,
            child: CallTileView(tile: small, compact: !_wide, onTap: () => setState(() => _selfSwapped = !_selfSwapped)),
          ),
        ],
      );
    }

    if (focus != null) {
      final strip = tiles.where((t) => t.id != focus.id).toList();
      final main = Padding(
        padding: const EdgeInsets.all(6),
        child: CallTileView(tile: focus, pinned: _s.pinnedId == focus.id, onTap: () => _s.pin(focus.id)),
      );
      if (strip.isEmpty) return main;
      if (_wide) {
        return Row(
          children: <Widget>[
            Expanded(child: main),
            SizedBox(width: 210, child: _filmstrip(strip, vertical: true)),
          ],
        );
      }
      return Column(
        children: <Widget>[
          Expanded(child: main),
          SizedBox(height: 116, child: _filmstrip(strip, vertical: false)),
        ],
      );
    }

    return _grid(tiles);
  }

  Widget _filmstrip(List<CallTile> strip, {required bool vertical}) {
    return ListView.separated(
      scrollDirection: vertical ? Axis.vertical : Axis.horizontal,
      padding: const EdgeInsets.all(6),
      itemCount: strip.length,
      separatorBuilder: (_, __) => const SizedBox(width: 6, height: 6),
      itemBuilder: (context, i) {
        final t = strip[i];
        return SizedBox(
          width: vertical ? double.infinity : 150,
          height: vertical ? 118 : double.infinity,
          child: CallTileView(tile: t, compact: !vertical, pinned: _s.pinnedId == t.id, onTap: () => _s.pin(t.id)),
        );
      },
    );
  }

  /// The even grid. Shows the people most worth seeing and folds the rest into a "more" tile.
  Widget _grid(List<CallTile> all) {
    final maxShown = _wide ? 16 : 6;
    var shown = all;
    var hidden = 0;
    if (all.length > maxShown) {
      final ranked = List<CallTile>.of(all)
        ..sort((a, b) {
          int score(CallTile t) => (t.isLocal ? 4 : 0) + (t.speaking ? 3 : 0) + (t.handUp ? 2 : 0) + (t.hasVideo ? 1 : 0);
          return score(b).compareTo(score(a));
        });
      final keep = ranked.take(maxShown - 1).map((t) => t.id).toSet();
      shown = all.where((t) => keep.contains(t.id)).toList();
      hidden = all.length - shown.length;
    }
    final count = shown.length + (hidden > 0 ? 1 : 0);
    return LayoutBuilder(builder: (context, c) {
      const gap = 6.0;
      var bestCols = 1;
      var bestArea = 0.0;
      for (var cols = 1; cols <= count; cols++) {
        final rows = (count / cols).ceil();
        final w = (c.maxWidth - gap * (cols + 1)) / cols;
        final h = (c.maxHeight - gap * (rows + 1)) / rows;
        // Tiles look best a little wider than tall.
        final side = math.min(w, h * 1.45);
        final area = side * math.min(h, side / 0.6);
        if (w > 0 && h > 0 && area > bestArea) {
          bestArea = area;
          bestCols = cols;
        }
      }
      final rows = (count / bestCols).ceil();
      final w = (c.maxWidth - gap * (bestCols + 1)) / bestCols;
      final h = (c.maxHeight - gap * (rows + 1)) / rows;
      final children = <Widget>[
        for (final t in shown)
          SizedBox(width: w, height: h, child: CallTileView(tile: t, pinned: _s.pinnedId == t.id, onTap: () => _s.pin(t.id), onLongPress: () => _s.pin(t.id))),
        if (hidden > 0)
          SizedBox(
            width: w,
            height: h,
            child: GestureDetector(
              onTap: () => _openPanel(_Panel.people),
              child: Container(
                decoration: BoxDecoration(color: CallColors.control, borderRadius: BorderRadius.circular(16)),
                alignment: Alignment.center,
                child: Text('+$hidden more', style: const TextStyle(color: CallColors.text, fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
      ];
      return Center(
        child: Wrap(
          spacing: gap,
          runSpacing: gap,
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          children: children,
        ),
      );
    });
  }

  // ---------------------------------------------------------------- chrome

  String _statusLine() {
    switch (_s.phase) {
      case CallPhase.connecting:
        return 'Connecting';
      case CallPhase.reconnecting:
        return 'Reconnecting';
      case CallPhase.live:
        break;
    }
    if (_s.ringingOut) return 'Ringing';
    return '';
  }

  Widget _topBar() {
    final status = _statusLine();
    final started = _s.call.startedAt ?? _s.connectedAt;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Minimise',
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: CallColors.text, size: 30),
            onPressed: () => ref.read(callProvider.notifier).setExpanded(false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CallColors.text, fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                status.isNotEmpty
                    ? Text(status, style: const TextStyle(color: CallColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600))
                    : Row(
                        children: <Widget>[
                          if (_s.call.locked) const Padding(padding: EdgeInsets.only(right: 4), child: Icon(Icons.lock_rounded, size: 12, color: CallColors.muted)),
                          CallTimerText(since: started, style: const TextStyle(color: CallColors.muted, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ],
            ),
          ),
          if (_s.call.linkUrl != null)
            IconButton(
              tooltip: 'Copy call link',
              icon: const Icon(Icons.link_rounded, color: CallColors.text),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: _s.call.linkUrl!));
                if (mounted) showToast(context, 'Call link copied');
              },
            ),
          IconButton(
            tooltip: _speakerView ? 'Grid view' : 'Speaker view',
            icon: Icon(_speakerView ? Icons.grid_view_rounded : Icons.person_pin_rounded, color: CallColors.text),
            onPressed: () => setState(() => _speakerView = !_speakerView),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    final wide = _wide;
    final width = MediaQuery.of(context).size.width;
    final compact = width < 400;
    final size = compact ? 48.0 : 54.0;
    final people = _s.peopleCount;
    final items = <Widget>[
      CallControl(
        icon: _s.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
        label: _s.micOn ? 'Mute' : 'Unmute',
        active: !_s.micOn,
        size: size,
        showLabel: wide,
        onTap: _s.toggleMic,
      ),
      CallControl(
        icon: _s.camOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
        label: _s.camOn ? 'Stop video' : 'Start video',
        active: !_s.camOn,
        size: size,
        showLabel: wide,
        onTap: _s.toggleCamera,
      ),
      if (wide && _s.canShareScreen)
        CallControl(
          icon: _s.sharing ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded,
          label: _s.sharing ? 'Stop sharing' : 'Share screen',
          active: _s.sharing,
          size: size,
          onTap: _toggleShare,
        ),
      if (wide)
        CallControl(
          icon: Icons.back_hand_rounded,
          label: _s.handUp ? 'Lower hand' : 'Raise hand',
          active: _s.handUp,
          size: size,
          onTap: _s.toggleHand,
        ),
      if (wide)
        CallControl(
          icon: Icons.emoji_emotions_outlined,
          label: 'React',
          size: size,
          onTap: () => _pickReaction(),
        ),
      if (wide)
        CallControl(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat',
          size: size,
          active: _panel == _Panel.chat,
          badge: _s.unreadChat,
          onTap: () => _openPanel(_Panel.chat),
        ),
      if (wide)
        CallControl(
          icon: Icons.people_alt_outlined,
          label: 'People',
          size: size,
          active: _panel == _Panel.people,
          badge: people > 2 ? people : 0,
          onTap: () => _openPanel(_Panel.people),
        ),
      if (!wide && _s.canFlipCamera && _s.camOn)
        CallControl(icon: Icons.cameraswitch_rounded, label: 'Flip', size: size, showLabel: false, onTap: _s.flipCamera),
      if (!wide && _s.canPickSpeaker && !_s.camOn)
        CallControl(
          icon: _s.speakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded,
          label: _s.speakerOn ? 'Speaker' : 'Earpiece',
          active: _s.speakerOn,
          size: size,
          showLabel: false,
          onTap: _s.toggleSpeaker,
        ),
      CallControl(
        icon: Icons.more_horiz_rounded,
        label: 'More',
        size: size,
        showLabel: wide,
        badge: wide ? 0 : _s.unreadChat,
        onTap: _more,
      ),
      CallControl(icon: Icons.call_end_rounded, label: 'Leave', danger: true, size: size, showLabel: wide, onTap: _hangUp),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 8, 8, wide ? 14 : 10),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: wide ? 16 : (compact ? 10 : 14),
        runSpacing: 10,
        children: items,
      ),
    );
  }

  Future<void> _pickReaction() async {
    final emoji = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: CallColors.control,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: <Widget>[
              for (final e in kReactionEmojis)
                InkResponse(
                  onTap: () => Navigator.of(ctx).pop(e),
                  radius: 30,
                  child: Padding(padding: const EdgeInsets.all(8), child: Text(e, style: const TextStyle(fontSize: 32))),
                ),
            ],
          ),
        ),
      ),
    );
    if (emoji != null) await _s.react(emoji);
  }

  Widget _banner() {
    final msgs = <Widget>[];
    if (_s.phase == CallPhase.reconnecting) {
      msgs.add(_pill(Icons.wifi_off_rounded, 'Connection is weak. Trying to reconnect', CallColors.hand));
    }
    if (_s.sharing) {
      msgs.add(_pill(Icons.screen_share_rounded, 'You are sharing your screen', CallColors.speaking));
    }
    if (msgs.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.center, children: msgs));
  }

  /// Tells this person, and nobody else, that they are talking while muted. Tapping it unmutes.
  Widget _mutedNudge() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: !_s.mutedSpeaking
          ? const SizedBox.shrink(key: ValueKey<String>('nudge-off'))
          : Semantics(
              key: const ValueKey<String>('nudge-on'),
              liveRegion: true,
              button: true,
              label: 'You are muted. Tap to unmute.',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: _s.toggleMic,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: CallColors.bg.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: CallColors.hand, width: 1.5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.mic_off_rounded, size: 18, color: CallColors.hand),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'You are muted. Tap to unmute.',
                            style: TextStyle(color: CallColors.text, fontSize: 13.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _pill(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _s.tiles();
    final side = _wide && _panel != _Panel.none;
    return Scaffold(
      backgroundColor: CallColors.bg,
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                _topBar(),
                Expanded(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: <Widget>[
                            tiles.isEmpty
                                ? const Center(child: CircularProgressIndicator(color: CallColors.speaking))
                                : Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: _stage(context, tiles)),
                            // Floats over the stage so it never resizes the tiles. Shown to this person only.
                            Positioned(
                              top: 8,
                              left: 12,
                              right: 12,
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[Flexible(child: _mutedNudge())]),
                            ),
                          ],
                        ),
                      ),
                      if (side)
                        Container(
                          width: 360,
                          margin: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                          decoration: BoxDecoration(color: CallColors.tile, borderRadius: BorderRadius.circular(16)),
                          clipBehavior: Clip.antiAlias,
                          child: _panel == _Panel.chat
                              ? CallChatPanel(session: _s, onClose: () => _openPanel(_Panel.chat))
                              : CallPeoplePanel(session: _s, onClose: () => _openPanel(_Panel.people)),
                        ),
                    ],
                  ),
                ),
                _banner(),
                _controls(),
              ],
            ),
            Positioned.fill(child: ReactionsLayer(reactions: List<CallReaction>.of(_s.reactions))),
          ],
        ),
      ),
    );
  }
}

/// Everything that does not fit on the bar, as a grid of buttons.
class _MoreSheet extends StatelessWidget {
  const _MoreSheet({required this.session, required this.speakerView});

  final CallSession session;
  final bool speakerView;

  @override
  Widget build(BuildContext context) {
    final s = session;
    final call = s.call;
    final wide = MediaQuery.of(context).size.width >= 820;
    Widget item(IconData icon, String label, String action, {bool active = false, int badge = 0, bool danger = false}) {
      return SizedBox(
        width: 86,
        child: CallControl(icon: icon, label: label, active: active, badge: badge, danger: danger, size: 52, onTap: () => Navigator.of(context).pop(action)),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(child: Container(width: 38, height: 4, decoration: BoxDecoration(color: CallColors.muted.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            const Text('Reactions', style: TextStyle(color: CallColors.muted, fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: <Widget>[
                for (final e in kReactionEmojis)
                  InkResponse(
                    onTap: () => Navigator.of(context).pop('react:$e'),
                    radius: 28,
                    child: Padding(padding: const EdgeInsets.all(8), child: Text(e, style: const TextStyle(fontSize: 30))),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              runSpacing: 16,
              spacing: 6,
              children: <Widget>[
                if (s.canShareScreen && !wide) item(s.sharing ? Icons.stop_screen_share_rounded : Icons.screen_share_rounded, s.sharing ? 'Stop sharing' : 'Share screen', 'share', active: s.sharing),
                if (!wide) item(Icons.back_hand_rounded, s.handUp ? 'Lower hand' : 'Raise hand', 'hand', active: s.handUp),
                if (!wide) item(Icons.chat_bubble_outline_rounded, 'Chat', 'chat', badge: s.unreadChat),
                if (!wide) item(Icons.people_alt_outlined, 'People', 'people'),
                item(Icons.person_add_alt_1_rounded, 'Add people', 'add'),
                item(speakerView ? Icons.grid_view_rounded : Icons.person_pin_rounded, speakerView ? 'Grid view' : 'Speaker view', 'layout'),
                if (s.canFlipCamera && s.camOn) item(Icons.cameraswitch_rounded, 'Flip camera', 'flip'),
                if (s.canPickSpeaker) item(s.speakerOn ? Icons.volume_up_rounded : Icons.hearing_rounded, s.speakerOn ? 'Speaker on' : 'Earpiece', 'speaker', active: s.speakerOn),
                if (call.linkUrl != null) item(Icons.link_rounded, 'Copy link', 'link'),
                if (s.isManager) item(call.locked ? Icons.lock_open_rounded : Icons.lock_rounded, call.locked ? 'Unlock call' : 'Lock call', 'lock', active: call.locked),
                if (s.isManager && call.isGroupLike) item(Icons.mic_off_rounded, 'Mute everyone', 'muteAll'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
