import 'package:flutter/material.dart';

import '../theme/brand.dart';

/// Flat bordered surface. Taps ripple inside the rounded corners.
class PCard extends StatelessWidget {
  const PCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = Brand.radius,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: color ?? context.surfaceColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: borderColor ?? context.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}

/// A solid brand-green panel for hero areas. Text inside should be cream.
class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key, required this.child, this.padding = const EdgeInsets.all(22)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: context.isDark ? Brand.greenTonal : Brand.green,
        borderRadius: BorderRadius.circular(Brand.radiusLarge),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: Brand.cream),
        child: IconTheme.merge(data: const IconThemeData(color: Brand.cream), child: child),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.padding});

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 26, bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.tint,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? tint;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = tint ?? (context.isDark ? Brand.gold : Brand.green);
    return PCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: c.op(0.13), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: c, size: 20),
          ),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.8, height: 1)),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: context.mutedColor)),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(caption!, style: TextStyle(fontSize: 11.5, color: context.mutedColor)),
          ],
        ],
      ),
    );
  }
}

Color colorFromHex(String? hex, {Color fallback = Brand.muted}) {
  if (hex == null) return fallback;
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(v);
}

/// Small coloured label such as "Verified" or "Action needed".
class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.color = Brand.muted, this.icon, this.dense = false});

  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(color: color.op(0.12), borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: dense ? 11 : 12, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label and value on one line, for detail screens.
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.icon, this.trailing});

  final String label;
  final String? value;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: context.mutedColor),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 118,
            child: Text(label, style: TextStyle(fontSize: 13, color: context.mutedColor, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              (value == null || value!.isEmpty) ? 'Not provided' : value!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: (value == null || value!.isEmpty) ? context.mutedColor : context.inkColor,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A grouped list of rows inside one card, with hairlines between them.
class MenuGroup extends StatelessWidget {
  const MenuGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Divider(height: 1, indent: 62, color: context.borderColor));
      }
    }
    return PCard(padding: EdgeInsets.zero, child: Column(children: rows));
  }
}

class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.tint,
    this.trailing,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? tint;
  final Widget? trailing;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = tint ?? (context.isDark ? Brand.gold : Brand.green);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: c.op(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 19, color: c),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(subtitle!, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                    ),
                ],
              ),
            ),
            if (badge != null) ...<Widget>[StatusPill(badge!, color: Brand.danger, dense: true), const SizedBox(width: 8)],
            trailing ?? Icon(Icons.chevron_right_rounded, color: context.mutedColor),
          ],
        ),
      ),
    );
  }
}
