import 'package:flutter/material.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/widgets.dart';
import 'overview_format.dart';

/// A card of rows with a thin divider between them. An optional [header] sits above the first row.
class OverviewList extends StatelessWidget {
  const OverviewList({super.key, required this.children, this.header});

  final List<Widget> children;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return PCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          if (header != null) ...<Widget>[
            Padding(padding: const EdgeInsets.all(18), child: header),
            Divider(height: 1, color: context.borderColor),
          ],
          for (var i = 0; i < children.length; i++) ...<Widget>[
            if (i != 0) Divider(height: 1, color: context.borderColor),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// One row: a leading widget, a title with an optional second line, and something on the right.
class OverviewRow extends StatelessWidget {
  const OverviewRow({super.key, required this.leading, required this.title, this.subtitle, this.trailing, this.onTap});

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: <Widget>[
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.3)),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: TextStyle(fontSize: 13, height: 1.4, color: context.mutedColor)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

/// Right hand side of a row: a bold value with either a caption or a badge under it.
class OverviewTrailing extends StatelessWidget {
  const OverviewTrailing({super.key, required this.value, this.caption, this.badge, this.color});

  final String value;
  final String? caption;
  final Widget? badge;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        if (badge != null) ...<Widget>[const SizedBox(height: 4), badge!]
        else if (caption != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(caption!, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
        ],
      ],
    );
  }
}

/// Small calendar tile with the day number over the month.
class OverviewDateBox extends StatelessWidget {
  const OverviewDateBox(this.date, {super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(color: context.pal.panel2, borderRadius: BorderRadius.circular(context.radius(11))),
      child: Column(
        children: <Widget>[
          Text('${date.day}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, height: 1.1)),
          Text(
            overviewMonth(date.month).toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: context.mutedColor),
          ),
        ],
      ),
    );
  }
}

/// A labelled figure on a softly tinted tile, for totals above a list.
class OverviewFigure extends StatelessWidget {
  const OverviewFigure({super.key, required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: color.op(0.09), borderRadius: BorderRadius.circular(context.radius(12))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.mutedColor)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: color)),
          ),
        ],
      ),
    );
  }
}
