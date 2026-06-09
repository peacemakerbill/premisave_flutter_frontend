import 'package:flutter/material.dart';

class ProfileCompletionBar extends StatelessWidget {
  final double percentage;
  const ProfileCompletionBar({super.key, required this.percentage});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      return Stack(children: [
        Container(
          height: 6,
          decoration: BoxDecoration(color: const Color(0xFFEAE6DE), borderRadius: BorderRadius.circular(4)),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOut,
          height: 6,
          width: (percentage / 100).clamp(0.0, 1.0) * c.maxWidth,
          decoration: BoxDecoration(
            color: const Color(0xFFC9A84C),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ]);
    });
  }
}