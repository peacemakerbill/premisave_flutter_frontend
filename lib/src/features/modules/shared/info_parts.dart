import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/widgets.dart';

/// Page header shared by About and Contact: a small label, a headline and a short paragraph on the hero panel.
class InfoHero extends StatelessWidget {
  const InfoHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.message,
    this.actions = const <Widget>[],
  });

  final String eyebrow;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final compact = context.isCompact;
    return HeroPanel(
      padding: EdgeInsets.fromLTRB(compact ? 22 : 38, compact ? 26 : 42, compact ? 22 : 38, compact ? 26 : 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Brand.cream.op(0.16), borderRadius: BorderRadius.circular(99)),
            child: Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: Brand.cream),
            ),
          ),
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              title,
              style: context.display(size: compact ? 28 : 40, weight: FontWeight.w800, spacing: -1, height: 1.1, color: Brand.cream),
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Text(
              message,
              style: TextStyle(fontSize: compact ? 14.5 : 16, height: 1.55, color: Brand.cream.op(0.88)),
            ),
          ),
          if (actions.isNotEmpty) ...<Widget>[
            const SizedBox(height: 24),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      ),
    );
  }
}

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

/// A titled block of the page with room above it.
class InfoSection extends StatelessWidget {
  const InfoSection({super.key, required this.title, this.subtitle, required this.child});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: context.isCompact ? 30 : 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: context.display(size: context.isCompact ? 21 : 24, weight: FontWeight.w800, spacing: -0.6, height: 1.2)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(subtitle!, style: TextStyle(fontSize: 14.5, height: 1.45, color: context.mutedColor)),
            ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

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

/// Opens the user's email app with a message to the support address already filled in.
/// When no email app is available the text is copied instead, so nothing the person typed is lost.
Future<void> composeSupportEmail(BuildContext context, {String subject = '', String body = ''}) async {
  final query = <String>[
    if (subject.isNotEmpty) 'subject=${Uri.encodeComponent(subject)}',
    if (body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
  ].join('&');
  final uri = Uri.parse('mailto:${AppConfig.supportEmail}${query.isEmpty ? '' : '?$query'}');

  var opened = false;
  try {
    opened = await launchUrl(uri);
  } catch (_) {
    opened = false;
  }
  if (opened || !context.mounted) return;

  await Clipboard.setData(ClipboardData(text: body.isEmpty ? AppConfig.supportEmail : body));
  if (!context.mounted) return;
  showToast(
    context,
    body.isEmpty
        ? 'No email app found. ${AppConfig.supportEmail} was copied.'
        : 'No email app found. Your message was copied, so you can send it to ${AppConfig.supportEmail}.',
  );
}

Future<void> copySupportEmail(BuildContext context) async {
  await Clipboard.setData(const ClipboardData(text: AppConfig.supportEmail));
  if (!context.mounted) return;
  showToast(context, '${AppConfig.supportEmail} copied');
}
