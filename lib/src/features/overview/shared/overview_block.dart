import 'package:flutter/material.dart';

import '../../../core/theme/brand.dart';

/// A titled section of an overview with room above it, matching the About and Contact pages.
class OverviewBlock extends StatelessWidget {
  const OverviewBlock({super.key, required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.isCompact ? 28 : 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: context.display(size: context.isCompact ? 20 : 22, weight: FontWeight.w800, spacing: -0.5, height: 1.2)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle!, style: TextStyle(fontSize: 14, height: 1.4, color: context.mutedColor)),
            ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Two blocks side by side on wide screens and stacked on phones.
class OverviewColumns extends StatelessWidget {
  const OverviewColumns({super.key, required this.left, required this.right, this.breakpoint = 860});

  final Widget left;
  final Widget right;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(children: <Widget>[left, right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: left),
            const SizedBox(width: 18),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}
