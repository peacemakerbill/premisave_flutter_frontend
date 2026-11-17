import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../core/widgets/widgets.dart';
import '../../state/call_controller.dart';

/// The call screen is always dark, whatever theme the app uses, so faces and shared screens stand out.
class CallColors {
  CallColors._();

  static const Color bg = Color(0xFF0B1310);
  static const Color tile = Color(0xFF16231E);
  static const Color control = Color(0xFF24352D);
  static const Color controlOn = Color(0xFFF1F5F3);
  static const Color speaking = Color(0xFF3DDC97);
  static const Color danger = Color(0xFFE5484D);
  static const Color hand = Color(0xFFF5B83D);
  static const Color text = Color(0xFFF1F5F3);
  static const Color muted = Color(0xFF9BB0A6);
}

String initialsOf(String name) {
  final bits = name.trim().split(RegExp(r'\s+')).where((b) => b.isNotEmpty).toList();
  if (bits.isEmpty) return 'P';
  if (bits.length == 1) return bits.first[0].toUpperCase();
  return (bits.first[0] + bits[1][0]).toUpperCase();
}

String clock(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

/// A running mm:ss clock from [since].
class CallTimerText extends StatefulWidget {
  const CallTimerText({super.key, required this.since, this.style});

  final DateTime? since;
  final TextStyle? style;

  @override
  State<CallTimerText> createState() => _CallTimerTextState();
}

class _CallTimerTextState extends State<CallTimerText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final since = widget.since;
    final d = since == null ? Duration.zero : DateTime.now().difference(since);
    return Text(clock(d.isNegative ? Duration.zero : d), style: widget.style);
  }
}

/// One round control at the bottom of the call screen.
class CallControl extends StatelessWidget {
  const CallControl({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.danger = false,
    this.badge = 0,
    this.size = 54,
    this.showLabel = true,
    this.enabled = true,
    this.tooltip = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Drawn light, to show the control is switched on (a raised hand, a shared screen, a muted microphone).
  final bool active;
  final bool danger;
  final int badge;
  final double size;
  final bool showLabel;
  final bool enabled;

  /// Off for controls drawn above the app's Navigator, where there is no Overlay to hold a tooltip.
  final bool tooltip;

  @override
  Widget build(BuildContext context) {
    final Color bg = danger ? CallColors.danger : (active ? CallColors.controlOn : CallColors.control);
    final Color fg = danger ? Colors.white : (active ? CallColors.bg : CallColors.text);
    Widget core = Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Material(
            color: bg,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: enabled ? onTap : null,
              child: SizedBox(width: size, height: size, child: Icon(icon, color: fg, size: size * 0.44)),
            ),
          ),
        );
    if (tooltip) core = Tooltip(message: label, child: core);
    final button = Semantics(button: true, label: label, child: core);
    final stack = Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        button,
        if (badge > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(color: CallColors.speaking, borderRadius: BorderRadius.circular(9)),
              child: Text(badge > 99 ? '99+' : '$badge', textAlign: TextAlign.center, style: const TextStyle(color: CallColors.bg, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ),
      ],
    );
    if (!showLabel) return stack;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        stack,
        const SizedBox(height: 6),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: CallColors.muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// One person's picture, camera or shared screen, with their name, a muted microphone, a raised hand and a ring
/// while they speak.
class CallTileView extends StatelessWidget {
  const CallTileView({
    super.key,
    required this.tile,
    this.onTap,
    this.onLongPress,
    this.compact = false,
    this.pinned = false,
    this.radius = 16,
  });

  final CallTile tile;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool compact;
  final bool pinned;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final video = tile.video;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            const ColoredBox(color: CallColors.tile),
            if (video != null)
              lk.VideoTrackRenderer(video, key: ObjectKey(video))
            else
              LayoutBuilder(builder: (context, c) {
                final side = (c.biggest.shortestSide * 0.42).clamp(36.0, 140.0);
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      UserAvatar(initials: initialsOf(tile.name), imageUrl: tile.picture, size: side),
                      if (tile.status != null && !compact) ...<Widget>[
                        const SizedBox(height: 10),
                        Text(tile.status!, style: const TextStyle(color: CallColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                );
              }),
            if (tile.speaking)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: CallColors.speaking, width: 3),
                    ),
                  ),
                ),
              ),
            if (!compact)
              Positioned(
                left: 8,
                bottom: 8,
                right: 8,
                child: Row(
                  children: <Widget>[
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (tile.micOff && tile.status == null) ...<Widget>[
                              const Icon(Icons.mic_off_rounded, size: 14, color: CallColors.text),
                              const SizedBox(width: 5),
                            ],
                            Flexible(
                              child: Text(
                                tile.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: CallColors.text, fontSize: 12.5, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (tile.handUp)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(compact ? 3 : 6),
                  decoration: const BoxDecoration(color: CallColors.hand, shape: BoxShape.circle),
                  child: Icon(Icons.back_hand_rounded, size: compact ? 12 : 16, color: CallColors.bg),
                ),
              ),
            if (pinned)
              const Positioned(
                top: 8,
                left: 8,
                child: Icon(Icons.push_pin_rounded, size: 16, color: CallColors.text),
              ),
            if (compact && tile.micOff && tile.status == null)
              const Positioned(
                bottom: 6,
                left: 6,
                child: Icon(Icons.mic_off_rounded, size: 14, color: CallColors.text),
              ),
          ],
        ),
      ),
    );
  }
}

/// Emojis that float up the screen when someone reacts.
class ReactionsLayer extends StatelessWidget {
  const ReactionsLayer({super.key, required this.reactions});

  final List<CallReaction> reactions;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: LayoutBuilder(builder: (context, c) {
        return Stack(
          children: <Widget>[
            for (final r in reactions)
              _Floating(
                key: ValueKey<int>(r.id),
                reaction: r,
                width: c.maxWidth,
                height: c.maxHeight,
              ),
          ],
        );
      }),
    );
  }
}

class _Floating extends StatelessWidget {
  const _Floating({super.key, required this.reaction, required this.width, required this.height});

  final CallReaction reaction;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    // The same reaction always drifts the same way, so a rebuild does not make it jump.
    final seed = reaction.id * 7919 % 1000 / 1000.0;
    final left = 24 + seed * (width - 120).clamp(40.0, 4000.0);
    final rise = (height * 0.55).clamp(160.0, 520.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 3200),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final fade = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25);
        return Positioned(
          left: left + (seed - 0.5) * 40 * t,
          bottom: 110 + rise * t,
          child: Opacity(
            opacity: fade.clamp(0.0, 1.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(reaction.emoji, style: const TextStyle(fontSize: 38)),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(8)),
                  child: Text(reaction.name, style: const TextStyle(color: CallColors.text, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

const List<String> kReactionEmojis = <String>['👍', '👏', '❤️', '😂', '😮', '🎉'];
