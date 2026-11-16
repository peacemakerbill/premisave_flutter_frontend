import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'palette.dart';

/// Living backdrop for brand panels: soft colour orbs that drift, a field of dots with a light
/// wave travelling through it, and a skyline whose windows switch on and off. It is drawn from
/// the active theme's hero colour, so it changes with the theme. Static when the device asks
/// to reduce motion.
class AnimatedHeroBackdrop extends StatelessWidget {
  const AnimatedHeroBackdrop({super.key, required this.child, this.horizon = 0.58});

  final Widget child;

  /// Where the skyline stands, as a fraction of the height (1 is the bottom edge).
  final double horizon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned.fill(child: HeroBackdropLayer(horizon: horizon)),
        child,
      ],
    );
  }
}

/// Just the moving picture, for placing behind content of your own, for example a banner.
class HeroBackdropLayer extends StatefulWidget {
  const HeroBackdropLayer({super.key, this.horizon = 0.58, this.skyline = true});

  final double horizon;
  final bool skyline;

  @override
  State<HeroBackdropLayer> createState() => _HeroBackdropLayerState();
}

class _HeroBackdropLayerState extends State<HeroBackdropLayer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 60));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller
        ..stop()
        ..value = 0.18;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final glow = p.dark ? p.accent : const Color(0xFFF2B544);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _HeroPainter(_controller, p.hero, glow, widget.horizon, widget.skyline),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  _HeroPainter(this.t, this.base, this.glow, this.horizon, this.skyline) : super(repaint: t);

  final Animation<double> t;
  final Color base;
  final Color glow;
  final double horizon;
  final bool skyline;

  static const double _tau = math.pi * 2;

  // Whole numbers of cycles per 60 s loop, so the motion never jumps when it repeats.
  static double _s(double u, int cycles, double phase) => math.sin(_tau * (u * cycles + phase));

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final u = t.value;
    final m = math.max(size.width, size.height);

    canvas.drawRect(Offset.zero & size, Paint()..color = base);

    void orb(Offset c, double r, Color color) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: <Color>[color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    orb(Offset(size.width * (0.25 + 0.18 * _s(u, 1, 0)), size.height * (0.28 + 0.14 * _s(u, 2, 0.1))), m * 0.55,
        Colors.white.withValues(alpha: 0.16));
    orb(Offset(size.width * (0.80 + 0.16 * _s(u, 2, 0.3)), size.height * (0.55 + 0.18 * _s(u, 1, 0.6))), m * 0.5,
        glow.withValues(alpha: 0.22));
    orb(Offset(size.width * (0.45 + 0.25 * _s(u, 1, 0.5)), size.height * (0.98 + 0.06 * _s(u, 3, 0))), m * 0.6,
        Colors.black.withValues(alpha: 0.24));

    _dots(canvas, size, u, m);
    if (skyline) _drawSkyline(canvas, size, u);
  }

  void _dots(Canvas canvas, Size size, double u, double m) {
    const step = 30.0;
    final buckets = List<List<Offset>>.generate(4, (_) => <Offset>[]);
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        final w = 0.5 + 0.5 * math.sin(_tau * ((x + y) / (m * 0.9) - u * 3));
        buckets[(w * 3.999).floor()].add(Offset(x, y));
      }
    }
    for (var b = 0; b < 4; b++) {
      canvas.drawPoints(
        ui.PointMode.points,
        buckets[b],
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 1.6 + b * 1.2
          ..color = Colors.white.withValues(alpha: 0.05 + 0.065 * b),
      );
    }
  }

  void _drawSkyline(Canvas canvas, Size size, double u) {
    final ground = size.height * horizon;
    final maxH = math.min(size.height * 0.24, 260.0);
    final rnd = math.Random(11);
    final body = Paint()..color = Colors.black.withValues(alpha: 0.16);
    var x = -12.0;
    var index = 0;
    while (x < size.width) {
      final w = 46.0 + rnd.nextInt(5) * 12;
      final h = maxH * (0.35 + rnd.nextDouble() * 0.65);
      canvas.drawRect(Rect.fromLTWH(x, ground - h, w, h), body);
      for (var wy = ground - h + 10; wy < ground - 12; wy += 16) {
        for (var wx = x + 8; wx < x + w - 10; wx += 14) {
          index++;
          final phase = (index * 0.6180339) % 1.0;
          final lit = _s(u, 1 + index % 3, phase) > 0.52;
          canvas.drawRect(
            Rect.fromLTWH(wx, wy, 7, 8),
            Paint()..color = lit ? glow.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06),
          );
        }
      }
      x += w + 4 + rnd.nextInt(3) * 4;
    }
    canvas.drawRect(
      Rect.fromLTWH(0, ground, size.width, 1.2),
      Paint()..color = Colors.white.withValues(alpha: 0.14),
    );
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.base != base || old.glow != glow || old.horizon != horizon || old.skyline != skyline;
}
