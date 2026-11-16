import 'package:flutter/material.dart';

import '../theme/brand.dart';

/// Button that stays readable on the hero panel whatever theme is chosen.
class HeroAction extends StatelessWidget {
  const HeroAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(context.radius(13)));
    const padding = EdgeInsets.symmetric(horizontal: 18, vertical: 14);
    const textStyle = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[Icon(icon, size: 18), const SizedBox(width: 8), Flexible(child: Text(label))],
    );
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Brand.cream,
          foregroundColor: Brand.ink,
          padding: padding,
          shape: shape,
          textStyle: textStyle,
        ),
        child: content,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Brand.cream,
        side: BorderSide(color: Brand.cream.op(0.55), width: 1.4),
        padding: padding,
        shape: shape,
        textStyle: textStyle,
      ),
      child: content,
    );
  }
}
