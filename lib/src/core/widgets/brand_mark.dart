import 'package:flutter/material.dart';

import '../branding/premisave_logo.dart';

/// The house mark on its own (no wordmark). Use [onDark] on green backgrounds.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40, this.onDark = false});

  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MarkPainter(onDark)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.onDark);

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    paintPremisaveMark(
      canvas,
      origin: Offset.zero,
      scale: size.width / 48,
      left: onDark ? PremisaveColors.cream : PremisaveColors.green,
      right: PremisaveColors.gold,
    );
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.onDark != onDark;
}
