// Premisave animated logo, splash and loader.
//
// Pure Flutter: everything is drawn with CustomPainter, so there are no new
// dependencies (no flutter_svg, lottie or google_fonts). The wordmark outlines
// live in premisave_logo_glyphs.dart. Both files go in the same folder.
//
// Timeline (seconds), identical to the animated SVG files:
//   0.00  left half of the house rises       0.14  right half rises
//   0.55  letters of "premisave" rise one by one (50 ms apart)
//   0.95  door grows                          1.05  four window panes pop in
//
// Usage:
//   PremisaveLogo(width: 260)                       // animated horizontal logo
//   PremisaveLogo(width: 260, animate: false)       // static
//   PremisaveSplash(onFinished: () => context.go('/'))
//   PremisaveLoader(size: 48)                       // looping, for busy states
//
// Animations are skipped when the platform asks to reduce motion.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'premisave_logo_glyphs.dart';

class PremisaveColors {
  PremisaveColors._();
  static const Color green = Color(0xFF0E3B2F);
  static const Color gold = Color(0xFFE3A72F);
  static const Color cream = Color(0xFFF6F1E7);
  static const Color skyline = Color(0xFF14493B);
}

const Cubic _rise = Cubic(0.22, 1.0, 0.36, 1.0);
const Cubic _pop = Cubic(0.34, 1.56, 0.64, 1.0);

/// Eased progress of a segment that starts at [start] seconds and lasts [dur].
double _seg(double t, double start, double dur, Curve curve) {
  final double x = ((t - start) / dur).clamp(0.0, 1.0).toDouble();
  return curve.transform(x);
}

// ---------------------------------------------------------------------------
// The mark: a house split into two halves on a 48 x 48 grid.
// ---------------------------------------------------------------------------

Path _leftHalf() => Path()
  ..moveTo(24, 0)
  ..lineTo(0, 20)
  ..lineTo(0, 48)
  ..lineTo(24, 48)
  ..close();

Path _rightHalf() => Path()
  ..moveTo(26.5, 2.08)
  ..lineTo(48, 20)
  ..lineTo(48, 48)
  ..lineTo(26.5, 48)
  ..close();

Path _door() => Path()
  ..moveTo(7, 48)
  ..lineTo(7, 35)
  ..arcToPoint(const Offset(17, 35), radius: const Radius.circular(5), clockwise: true)
  ..lineTo(17, 48)
  ..close();

// Window pane centres, clockwise from top left.
const List<Offset> _paneCentres = <Offset>[
  Offset(33.75, 29.5),
  Offset(40.75, 29.5),
  Offset(40.75, 36.5),
  Offset(33.75, 36.5),
];

/// Draws the mark in its own 48-unit space. All parameters are 0..1 progress
/// values (panes may overshoot slightly for the pop effect).
void _drawMark(
  Canvas canvas, {
  required Color left,
  required Color right,
  double riseLeft = 1,
  double riseRight = 1,
  double door = 1,
  List<double> panes = const <double>[1, 1, 1, 1],
}) {
  void half(Path shape, Color color, double rise) {
    if (rise <= 0) return;
    canvas.save();
    canvas.translate(0, 48);
    canvas.scale(1, rise);
    canvas.translate(0, -48);
    canvas.drawPath(shape, Paint()..color = color..isAntiAlias = true);
    canvas.restore();
  }

  Path leftShape = _leftHalf();
  if (door > 0) {
    final Matrix4 m = Matrix4.translationValues(12, 48, 0) *
        Matrix4.diagonal3Values(1, door, 1) *
        Matrix4.translationValues(-12, -48, 0);
    leftShape = Path.combine(PathOperation.difference, leftShape, _door().transform(m.storage));
  }

  Path rightShape = _rightHalf();
  final Path cut = Path();
  for (int i = 0; i < _paneCentres.length; i++) {
    final double s = panes[i];
    if (s <= 0) continue;
    cut.addRect(Rect.fromCenter(center: _paneCentres[i], width: 5 * s, height: 5 * s));
  }
  rightShape = Path.combine(PathOperation.difference, rightShape, cut);

  half(leftShape, left, riseLeft);
  half(rightShape, right, riseRight);
}

/// Paints the mark with its top-left corner at [origin]. [scale] converts the
/// 48-unit grid to logical pixels. [t] is seconds since the intro began; the
/// default (infinity) draws the finished mark.
void paintPremisaveMark(
  Canvas canvas, {
  required Offset origin,
  required double scale,
  double t = double.infinity,
  Color left = PremisaveColors.green,
  Color right = PremisaveColors.gold,
}) {
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  canvas.scale(scale);
  _drawMark(
    canvas,
    left: left,
    right: right,
    riseLeft: _seg(t, 0, 0.85, _rise),
    riseRight: _seg(t, 0.14, 0.85, _rise),
    door: _seg(t, 0.95, 0.5, _rise),
    panes: <double>[
      for (int i = 0; i < 4; i++) _seg(t, 1.05 + i * 0.1, 0.42, _pop),
    ],
  );
  canvas.restore();
}

/// Paints "premisave" with its baseline-left corner at [origin]. Letters rise
/// through a clip, one after another, starting at [start] seconds.
void paintPremisaveWord(
  Canvas canvas, {
  required Offset origin,
  required double scale,
  required Color color,
  double t = double.infinity,
  double start = 0.55,
  double rise = 34,
}) {
  canvas.save();
  canvas.translate(origin.dx, origin.dy);
  canvas.scale(scale);
  canvas.clipRect(const Rect.fromLTRB(
    -4,
    -PremisaveGlyphs.ascent - 6,
    PremisaveGlyphs.wordWidth + 4,
    PremisaveGlyphs.descent + 6,
  ));
  final List<PremisaveGlyph> glyphs = PremisaveGlyphs.word;
  for (int i = 0; i < glyphs.length; i++) {
    final double p = _seg(t - start, i * 0.05, 0.7, _rise);
    if (p <= 0) continue;
    canvas.save();
    canvas.translate(glyphs[i].dx, (1 - p) * rise);
    canvas.drawPath(
      glyphs[i].path,
      Paint()
        ..color = color.withAlpha((255 * p).round())
        ..isAntiAlias = true,
    );
    canvas.restore();
  }
  canvas.restore();
}

// ---------------------------------------------------------------------------
// Horizontal logo
// ---------------------------------------------------------------------------

/// Horizontal logo (mark + wordmark). Plays once when first built.
class PremisaveLogo extends StatefulWidget {
  const PremisaveLogo({
    super.key,
    this.width = 260,
    this.onDark = false,
    this.animate = true,
    this.onCompleted,
  });

  final double width;
  final bool onDark;
  final bool animate;
  final VoidCallback? onCompleted;

  static const double _pad = 16;
  static const double _gap = 16;
  static double get _totalWidth => _pad + 48 + _gap + PremisaveGlyphs.wordWidth + _pad;
  static double get _totalHeight => _pad * 2 + 48 + PremisaveGlyphs.descent;

  @override
  State<PremisaveLogo> createState() => _PremisaveLogoState();
}

class _PremisaveLogoState extends State<PremisaveLogo> with SingleTickerProviderStateMixin {
  static const double _seconds = 2.2;
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final bool reduce = MediaQuery.of(context).disableAnimations;
    if (!widget.animate || reduce) {
      _controller.value = 1;
      // Deferred: calling parent code while the tree is building can throw.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCompleted?.call();
      });
    } else {
      _controller.forward().whenComplete(() {
        if (mounted) widget.onCompleted?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = widget.width * PremisaveLogo._totalHeight / PremisaveLogo._totalWidth;
    return Semantics(
      label: 'Premisave',
      child: CustomPaint(
        size: Size(widget.width, height),
        painter: _LogoPainter(_controller, widget.onDark, _seconds),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.animation, this.onDark, this.seconds) : super(repaint: animation);

  final Animation<double> animation;
  final bool onDark;
  final double seconds;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / PremisaveLogo._totalWidth;
    final double t = animation.value >= 1 ? double.infinity : animation.value * seconds;
    final Color ink = onDark ? PremisaveColors.cream : PremisaveColors.green;
    paintPremisaveMark(
      canvas,
      origin: Offset(PremisaveLogo._pad * s, PremisaveLogo._pad * s),
      scale: s,
      t: t,
      left: ink,
    );
    paintPremisaveWord(
      canvas,
      origin: Offset((PremisaveLogo._pad + 48 + PremisaveLogo._gap) * s, (PremisaveLogo._pad + 48) * s),
      scale: s,
      color: ink,
      t: t,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.onDark != onDark;
}

// ---------------------------------------------------------------------------
// Splash screen
// ---------------------------------------------------------------------------

/// Full-screen animated splash: skyline rises, the house builds, the wordmark
/// and tagline follow, then a few skyline windows glow gold on a slow loop.
/// [onFinished] fires once the intro completes (about 3 s) plus [hold].
class PremisaveSplash extends StatefulWidget {
  const PremisaveSplash({
    super.key,
    this.onFinished,
    this.hold = const Duration(milliseconds: 500),
  });

  final VoidCallback? onFinished;
  final Duration hold;

  @override
  State<PremisaveSplash> createState() => _PremisaveSplashState();
}

class _PremisaveSplashState extends State<PremisaveSplash> with TickerProviderStateMixin {
  static const double _introSeconds = 3.2;
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  late final AnimationController _ambient =
      AnimationController(vsync: this, duration: const Duration(seconds: 8));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _intro.value = 1;
      Future<void>.delayed(widget.hold, () {
        if (mounted) widget.onFinished?.call();
      });
      return;
    }
    _ambient.repeat();
    _intro.forward().whenComplete(() {
      Future<void>.delayed(widget.hold, () {
        if (mounted) widget.onFinished?.call();
      });
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Premisave',
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _SplashPainter(_intro, _ambient, _introSeconds),
        ),
      ),
    );
  }
}

class _Building {
  const _Building(this.w, this.h, this.pitched);
  final double w;
  final double h;
  final bool pitched;
}

const List<_Building> _skyline = <_Building>[
  _Building(170, 300, true),
  _Building(120, 380, false),
  _Building(200, 260, true),
  _Building(140, 430, false),
  _Building(180, 320, true),
  _Building(130, 250, false),
  _Building(190, 360, true),
  _Building(150, 290, false),
  _Building(160, 400, true),
];

class _SplashPainter extends CustomPainter {
  _SplashPainter(this.intro, this.ambient, this.introSeconds)
      : super(repaint: Listenable.merge(<Listenable>[intro, ambient]));

  final Animation<double> intro;
  final Animation<double> ambient;
  final double introSeconds;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 1080; // design width is 1080
    final double t = intro.value >= 1 ? double.infinity : intro.value * introSeconds;
    final double clock = ambient.value * 8; // seconds, loops every 8 s

    canvas.drawRect(Offset.zero & size, Paint()..color = PremisaveColors.green);
    _paintSkyline(canvas, size, s, t, clock);

    // Lockup block.
    const double wsc = 3.2;
    const double markScale = 5.2;
    final double top = size.height * 0.29;
    final double markPx = 48 * markScale * s;
    paintPremisaveMark(
      canvas,
      origin: Offset((size.width - markPx) / 2, top),
      scale: markScale * s,
      t: t - 0.6,
      left: PremisaveColors.cream,
    );

    final double wordPx = PremisaveGlyphs.wordWidth * wsc * s;
    final double baseline = top + markPx + 90 * s + PremisaveGlyphs.ascent * wsc * s;
    paintPremisaveWord(
      canvas,
      origin: Offset((size.width - wordPx) / 2, baseline),
      scale: wsc * s,
      color: PremisaveColors.cream,
      t: t,
      start: 1.4,
      rise: 110,
    );

    final double p = _seg(t, 2.3, 0.9, Curves.easeOut);
    if (p > 0) {
      canvas.save();
      canvas.translate(
        (size.width - PremisaveGlyphs.taglineWidth * s) / 2,
        baseline + PremisaveGlyphs.descent * wsc * s + 70 * s + (1 - p) * 14 * s,
      );
      canvas.scale(s);
      canvas.drawPath(
        PremisaveGlyphs.tagline(),
        Paint()..color = PremisaveColors.gold.withAlpha((255 * p).round()),
      );
      canvas.restore();
    }
  }

  void _paintSkyline(Canvas canvas, Size size, double s, double t, double clock) {
    final Paint body = Paint()..color = PremisaveColors.skyline;
    final Paint window = Paint()..color = PremisaveColors.green;
    double x = -30;
    int lit = 0;
    for (int i = 0; i < _skyline.length; i++) {
      final _Building b = _skyline[i];
      final double roof = b.pitched ? b.w * 0.30 : 0;
      final double p = _seg(t, i * 0.06, 1.1, _rise);
      final double dy = (1 - p) * (b.h + roof) * s;
      final double topY = size.height - b.h * s + dy;

      final Path shape = Path();
      if (b.pitched) {
        shape
          ..moveTo(x * s, topY)
          ..lineTo((x + b.w / 2) * s, topY - roof * s)
          ..lineTo((x + b.w) * s, topY);
      } else {
        shape
          ..moveTo(x * s, topY)
          ..lineTo((x + b.w) * s, topY);
      }
      shape
        ..lineTo((x + b.w) * s, size.height + dy)
        ..lineTo(x * s, size.height + dy)
        ..close();
      canvas.drawPath(shape, body);

      final int cols = math.max(2, b.w ~/ 58);
      final double gap = b.w / (cols + 1);
      int row = 0;
      for (double y = 46; y < b.h - 70; y += 62, row++) {
        for (int c = 0; c < cols; c++) {
          final double cx = x + gap * (c + 1);
          final Rect r = Rect.fromLTWH((cx - 9) * s, topY + y * s, 18 * s, 18 * s);
          final RRect rr = RRect.fromRectAndRadius(r, Radius.circular(2 * s));
          canvas.drawRRect(rr, window);
          if ((i * 7 + row * 3 + c * 5) % 5 == 0) {
            // Slow gold "lights on" once the intro has settled.
            final double on = _seg(t, 2.6 + lit * 0.35, 0.6, Curves.easeOut);
            // 1, 2 or 3 whole cycles per 8 s loop, so the loop restarts without a jump.
            final int cycles = 1 + lit % 3;
            final double wave = 0.5 + 0.5 * math.sin(2 * math.pi * cycles * (clock / 8) + lit);
            final double a = on * wave;
            if (a > 0.02) {
              canvas.drawRRect(
                rr,
                Paint()..color = PremisaveColors.gold.withAlpha((255 * a).round()),
              );
            }
            lit++;
          }
        }
      }
      x += b.w + 14;
    }
  }

  @override
  bool shouldRepaint(_SplashPainter old) => false;
}

// ---------------------------------------------------------------------------
// Loader
// ---------------------------------------------------------------------------

/// Looping loader: the house stands still and its four window panes pulse
/// clockwise. Use it in place of a spinner for page or data loading.
class PremisaveLoader extends StatefulWidget {
  const PremisaveLoader({super.key, this.size = 48, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  State<PremisaveLoader> createState() => _PremisaveLoaderState();
}

class _PremisaveLoaderState extends State<PremisaveLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.of(context).disableAnimations) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _LoaderPainter(_controller, widget.onDark),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter(this.animation, this.onDark) : super(repaint: animation);

  final Animation<double> animation;
  final bool onDark;

  static double _pulse(double u) {
    if (u < 0.25) return 1 - 0.75 * Curves.easeInOut.transform(u / 0.25);
    if (u < 0.60) return 0.25 + 0.75 * Curves.easeInOut.transform((u - 0.25) / 0.35);
    return 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 60; // 48-unit mark with 6 units of padding
    canvas.save();
    canvas.translate(6 * s, 6 * s);
    canvas.scale(s);
    final double seconds = animation.value * 1.6;
    _drawMark(
      canvas,
      left: onDark ? PremisaveColors.cream : PremisaveColors.green,
      right: PremisaveColors.gold,
      panes: <double>[
        for (int i = 0; i < 4; i++) _pulse((((seconds - i * 0.2) % 1.6) + 1.6) % 1.6 / 1.6),
      ],
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LoaderPainter old) => old.onDark != onDark;
}
