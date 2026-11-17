import 'dart:async';
import 'dart:math' as math;

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

/// One person's picture, camera or shared screen. It always carries their name, and it shows a muted microphone, a
/// raised hand, a ring and a sound wave that moves with their voice while they speak.
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
        child: LayoutBuilder(builder: (context, c) {
          // A roomy tile without a camera puts the name under the picture. Every other tile carries it on a label.
          final roomy = video == null && !compact && c.biggest.shortestSide >= 200;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const ColoredBox(color: CallColors.tile),
              if (video != null) lk.VideoTrackRenderer(video, key: ObjectKey(video)) else _pictureBody(c, roomy),
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
              if (!roomy)
                Positioned(
                  left: compact ? 5 : 8,
                  right: compact ? 5 : 8,
                  bottom: compact ? 5 : 8,
                  child: Row(children: <Widget>[Flexible(child: _nameLabel())]),
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
            ],
          );
        }),
      ),
    );
  }

  /// What fills the tile when there is no camera: the picture, with the name and state under it on a roomy tile.
  Widget _pictureBody(BoxConstraints c, bool roomy) {
    final side = (c.biggest.shortestSide * (roomy ? 0.3 : 0.42)).clamp(36.0, roomy ? 150.0 : 140.0);
    final picture = SpeakingHalo(
      active: tile.speaking,
      level: tile.level,
      size: side,
      child: UserAvatar(initials: initialsOf(tile.name), imageUrl: tile.picture, size: side),
    );
    if (!roomy) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            picture,
            if (tile.status != null && !compact) ...<Widget>[
              const SizedBox(height: 10),
              Text(tile.status!, style: const TextStyle(color: CallColors.muted, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            picture,
            const SizedBox(height: 18),
            Text(
              tile.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: CallColors.text, fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 22, child: Center(child: _stateLine())),
          ],
        ),
      ),
    );
  }

  /// Under the name on a roomy tile: the wave while they speak, otherwise whether they are muted or still ringing.
  Widget _stateLine() {
    if (tile.status != null) {
      return Text(tile.status!, style: const TextStyle(color: CallColors.muted, fontSize: 13, fontWeight: FontWeight.w600));
    }
    if (tile.speaking) {
      return SpeakingWave(active: true, level: tile.level, height: 20, bars: 5, barWidth: 4);
    }
    if (tile.micOff) {
      final color = tile.mutedSpeaking ? CallColors.hand : CallColors.muted;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.mic_off_rounded, size: 16, color: color),
          const SizedBox(width: 6),
          Text('Muted', style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  /// The name on a dark label at the bottom of the tile, led by the wave while they speak or a muted microphone.
  Widget _nameLabel() {
    final small = compact;
    Widget? lead;
    if (tile.speaking) {
      lead = SpeakingWave(active: true, level: tile.level, height: small ? 10 : 13, bars: 3, barWidth: small ? 2 : 2.5);
    } else if (tile.micOff && tile.status == null) {
      lead = Icon(Icons.mic_off_rounded, size: small ? 12 : 14, color: tile.mutedSpeaking ? CallColors.hand : CallColors.text);
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 3 : 4),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(small ? 6 : 8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (lead != null) ...<Widget>[lead, SizedBox(width: small ? 4 : 6)],
          Flexible(
            child: Text(
              tile.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: CallColors.text, fontSize: small ? 11 : 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bars that move while someone speaks, like the sound wave on Teams and Meet. [level] is how loud they are, 0 to 1:
/// louder voices make taller bars. When [active] is false the bars rest as small dots.
class SpeakingWave extends StatefulWidget {
  const SpeakingWave({
    super.key,
    required this.active,
    this.level = 0.5,
    this.color = CallColors.speaking,
    this.height = 14,
    this.bars = 4,
    this.barWidth = 3,
  });

  final bool active;
  final double level;
  final Color color;
  final double height;
  final int bars;
  final double barWidth;

  @override
  State<SpeakingWave> createState() => _SpeakingWaveState();
}

class _SpeakingWaveState extends State<SpeakingWave> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SpeakingWave old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.active) {
      if (!_c.isAnimating) unawaited(_c.repeat());
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _barHeight(int i, double amp, bool still) {
    // Whole-number speeds keep the loop seamless; each bar has its own speed and offset so they do not move together.
    final wave = still ? 0.6 : (math.sin(_c.value * 2 * math.pi * (1 + i % 3) + i * 1.9) + 1) / 2;
    final rest = widget.barWidth;
    return rest + (widget.height - rest) * amp * (0.2 + 0.8 * wave);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    final target = widget.active ? 0.4 + 0.6 * widget.level.clamp(0.0, 1.0) : 0.0;
    final gap = widget.barWidth * 0.7;
    return RepaintBoundary(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: target),
        duration: const Duration(milliseconds: 260),
        builder: (context, amp, _) => AnimatedBuilder(
          animation: _c,
          builder: (context, _) => SizedBox(
            height: widget.height,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                for (var i = 0; i < widget.bars; i++) ...<Widget>[
                  if (i > 0) SizedBox(width: gap),
                  Container(
                    width: widget.barWidth,
                    height: _barHeight(i, amp, still),
                    decoration: BoxDecoration(color: widget.color, borderRadius: BorderRadius.circular(widget.barWidth)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rings that ripple out from a person's picture while they speak. The picture keeps its size and place either way.
class SpeakingHalo extends StatefulWidget {
  const SpeakingHalo({
    super.key,
    required this.active,
    required this.size,
    required this.child,
    this.level = 0.5,
  });

  final bool active;
  final double size;
  final Widget child;
  final double level;

  @override
  State<SpeakingHalo> createState() => _SpeakingHaloState();
}

class _SpeakingHaloState extends State<SpeakingHalo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SpeakingHalo old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.active) {
      if (!_c.isAnimating) unawaited(_c.repeat());
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _ring(int k, bool still) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = still ? 0.35 : (_c.value + k * 0.5) % 1.0;
        final reach = 0.18 + 0.28 * widget.level.clamp(0.0, 1.0);
        return Opacity(
          opacity: (1 - t) * 0.6,
          child: Transform.scale(
            scale: 1 + reach * t,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: CallColors.speaking, width: 2.5)),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    // The two ring slots stay in the list even when idle, so the picture keeps its place in the tree and never reloads.
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: <Widget>[
        widget.active ? _ring(0, still) : const SizedBox.shrink(),
        widget.active ? _ring(1, still) : const SizedBox.shrink(),
        widget.child,
      ],
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
