import 'package:flutter/material.dart';

import '../theme/brand.dart';
import '../theme/palette.dart';

/// Rounded square holding an icon, tinted with the given colour (the theme accent by default).
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.size = 46, this.color});

  final IconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.pal.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.op(0.13), borderRadius: BorderRadius.circular(context.radius(size * 0.3))),
      child: Icon(icon, size: size * 0.5, color: c),
    );
  }
}
