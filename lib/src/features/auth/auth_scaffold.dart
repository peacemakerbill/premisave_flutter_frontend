import 'package:flutter/material.dart';

import '../../core/branding/premisave_logo.dart';
import '../../core/theme/brand.dart';
import '../../core/widgets/p_scaffold.dart';
import '../../core/theme/palette.dart';
import '../account/appearance_picker.dart';

/// Shared frame for every signed-out screen. Wide screens get a brand panel beside the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 920;
    final form = _FormColumn(title: title, subtitle: subtitle, footer: footer, leading: leading, showLogo: !wide, child: child);

    final content = wide
        ? Row(
            children: <Widget>[
              const Expanded(flex: 5, child: _BrandPanel()),
              Expanded(
                flex: 6,
                child: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(40), child: form))),
              ),
            ],
          )
        : SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
                child: form,
              ),
            ),
          );

    return PScaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: content),
          const Positioned(
            top: 0,
            right: 0,
            child: SafeArea(child: Padding(padding: EdgeInsets.all(6), child: AppearanceButton())),
          ),
        ],
      ),
    );
  }
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.title,
    required this.child,
    required this.showLogo,
    this.subtitle,
    this.footer,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final Widget? leading;
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (showLogo)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: PremisaveLogo(width: 200, onDark: context.isDark, ink: context.isDark ? null : context.pal.accent, animate: false),
              ),
            ),
          if (leading != null) ...<Widget>[leading!, const SizedBox(height: 10)],
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -1, height: 1.1)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(subtitle!, style: TextStyle(fontSize: 15, height: 1.5, color: context.mutedColor)),
            ),
          const SizedBox(height: 26),
          child,
          if (footer != null) ...<Widget>[const SizedBox(height: 22), footer!],
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.pal.hero,
      padding: const EdgeInsets.all(48),
      child: const SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PremisaveLogo(width: 260, onDark: true, animate: false),
            Spacer(),
            Text(
              'Find a place.\nTrust the people behind it.',
              style: TextStyle(fontSize: 40, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: Brand.cream),
            ),
            SizedBox(height: 28),
            _Point(Icons.verified_user_outlined, 'Verified home owners', 'Every owner is reviewed before they can list.'),
            _Point(Icons.shield_outlined, 'Security you can see', 'Know every device and session on your account.'),
            _Point(Icons.public_rounded, 'Made for anywhere', 'One account for renting, hosting and managing property.'),
            SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Brand.gold.op(0.16), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Brand.gold, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: const TextStyle(color: Brand.cream, fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 2),
                Text(text, style: TextStyle(color: Brand.cream.op(0.7), fontSize: 13.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Already have an account? Sign in" style footer.
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({super.key, required this.prompt, required this.action, required this.onTap});

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(prompt, style: TextStyle(color: context.mutedColor, fontSize: 14)),
          TextButton(onPressed: onTap, child: Text(action, style: const TextStyle(fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

/// Shown after an action that ends in "check your email".
class AuthResultView extends StatelessWidget {
  const AuthResultView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.success = true,
    this.actions = const <Widget>[],
  });

  final IconData icon;
  final String title;
  final String message;
  final bool success;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = success ? Brand.success : Brand.danger;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(color: c.op(0.12), shape: BoxShape.circle),
          child: Icon(icon, size: 30, color: c),
        ),
        const SizedBox(height: 18),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(fontSize: 15, height: 1.5, color: context.mutedColor)),
        const SizedBox(height: 24),
        for (final a in actions) Padding(padding: const EdgeInsets.only(bottom: 10), child: a),
      ],
    );
  }
}
