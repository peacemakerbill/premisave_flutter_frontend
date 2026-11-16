import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';

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
