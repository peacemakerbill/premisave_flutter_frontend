import 'package:flutter/material.dart';

import '../branding/premisave_logo.dart';

/// The house mark on its own (no wordmark). Use [onDark] on green backgrounds.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.onDark = false, this.ink});

  final double size;
  final bool onDark;
  final Color? ink;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MarkPainter(onDark, ink)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.onDark, this.ink);

  final bool onDark;
  final Color? ink;

  @override
  void paint(Canvas canvas, Size size) {
    paintPremisaveMark(
      canvas,
      origin: Offset.zero,
      scale: size.width / 48,
      left: ink ?? (onDark ? PremisaveColors.cream : PremisaveColors.green),
      right: PremisaveColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.onDark != onDark || old.ink != ink;
}
