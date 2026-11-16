import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'palette.dart';

/// Draws one of the console background tiles across the whole area.
class PatternPainter extends CustomPainter {
  const PatternPainter({required this.kind, required this.color, required this.color2});

  final PatternKind kind;
  final Color color;
  final Color color2;

  Paint _stroke(Color c, [double width = 1]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..color = c;

  Paint _fill(Color c) => Paint()
    ..style = PaintingStyle.fill
    ..color = c;

  void _grid(Canvas canvas, Size size, double step, Paint paint) {
    final path = Path();
    for (double x = 0; x <= size.width; x += step) {
      path.moveTo(x + 0.5, 0);
      path.lineTo(x + 0.5, size.height);
    }
    for (double y = 0; y <= size.height; y += step) {
      path.moveTo(0, y + 0.5);
      path.lineTo(size.width, y + 0.5);
    }
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (kind == PatternKind.none || size.isEmpty) return;
    switch (kind) {
      case PatternKind.none:
        return;
      case PatternKind.grid:
        _grid(canvas, size, 28, _stroke(color));
        return;
      case PatternKind.blueprint:
        _grid(canvas, size, 20, _stroke(color2));
        _grid(canvas, size, 100, _stroke(color));
        return;
      case PatternKind.dots:
        final points = <Offset>[];
        for (double x = 0; x < size.width + 22; x += 22) {
          for (double y = 0; y < size.height + 22; y += 22) {
            points.add(Offset(x + 2, y + 2));
          }
        }
        final p = _stroke(color, 2.2)..strokeCap = StrokeCap.round;
        canvas.drawPoints(ui.PointMode.points, points, p);
        return;
      case PatternKind.waves:
        final path = Path();
        for (double x = 0; x < size.width; x += 120) {
          for (double y = 0; y < size.height + 120; y += 120) {
            for (final off in const <double>[20, 60, 100]) {
              final cy = y + off;
              path.moveTo(x, cy);
              path.quadraticBezierTo(x + 30, cy - 20, x + 60, cy);
              path.quadraticBezierTo(x + 90, cy + 20, x + 120, cy);
            }
          }
        }
        canvas.drawPath(path, _stroke(color, 1.2));
        return;
      case PatternKind.hatch:
        final path = Path();
        final top = (size.width + size.height) / 14;
        for (var k = 0; k <= top; k++) {
          final c = k * 14.0;
          path.moveTo(c, 0);
          path.lineTo(c - size.height, size.height);
        }
        canvas.drawPath(path, _stroke(color));
        return;
      case PatternKind.rules:
        final path = Path();
        for (double y = 23.5; y < size.height + 24; y += 24) {
          path.moveTo(0, y);
          path.lineTo(size.width, y);
        }
        canvas.drawPath(path, _stroke(color));
        return;
      case PatternKind.rings:
        final p = _stroke(color);
        for (double x = 24; x < size.width + 48; x += 48) {
          for (double y = 24; y < size.height + 48; y += 48) {
            canvas.drawCircle(Offset(x, y), 7, p);
            canvas.drawCircle(Offset(x, y), 15, p);
            canvas.drawCircle(Offset(x, y), 23, p);
          }
        }
        return;
      case PatternKind.lattice:
        final path = Path();
        for (double x = 0; x < size.width + 36; x += 36) {
          for (double y = 0; y < size.height + 36; y += 36) {
            path.moveTo(x + 18, y);
            path.lineTo(x + 36, y + 18);
            path.lineTo(x + 18, y + 36);
            path.lineTo(x, y + 18);
            path.close();
          }
        }
        canvas.drawPath(path, _stroke(color));
        return;
      case PatternKind.plus:
        final path = Path();
        for (double x = 0; x < size.width + 26; x += 26) {
          for (double y = 0; y < size.height + 26; y += 26) {
            path.moveTo(x + 13, y + 9);
            path.lineTo(x + 13, y + 17);
            path.moveTo(x + 9, y + 13);
            path.lineTo(x + 17, y + 13);
          }
        }
        canvas.drawPath(path, _stroke(color));
        return;
      case PatternKind.scanlines:
        final p = _fill(color);
        for (double y = 3; y < size.height; y += 4) {
          canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
        }
        return;
      case PatternKind.blossoms:
        final p = _stroke(color);
        for (double x = 0; x < size.width + 30; x += 30) {
          for (double y = 0; y < size.height + 30; y += 30) {
            canvas.drawCircle(Offset(x + 8, y + 8), 2.2, p);
            canvas.drawCircle(Offset(x + 23, y + 23), 2.2, p);
          }
        }
        return;
    }
  }

  @override
  bool shouldRepaint(PatternPainter old) => old.kind != kind || old.color != color || old.color2 != color2;
}

/// Page colour with the theme's texture behind [child].
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child, this.palette});

  final Widget child;

  /// Draw this palette instead of the active one (used by the theme previews).
  final AppPalette? palette;

  @override
  Widget build(BuildContext context) {
    final p = palette ?? context.pal;
    if (p.pattern == PatternKind.none) return ColoredBox(color: p.bg, child: child);
    return ColoredBox(
      color: p.bg,
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: PatternPainter(kind: p.pattern, color: p.patternColor, color2: p.patternColor2),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
