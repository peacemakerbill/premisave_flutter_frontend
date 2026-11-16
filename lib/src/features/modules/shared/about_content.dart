import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/widgets/widgets.dart';
import 'info_parts.dart';

/// Who Premisave is and how it works. Only describes what the product does; no invented figures or people.
class AboutContent extends StatelessWidget {
  const AboutContent({super.key});

  @override
  Widget build(BuildContext context) {
    return PageBody(
      bottomPadding: 48,
      children: <Widget>[
        InfoHero(
          eyebrow: 'About Premisave',
          title: 'Property you can trust, all in one place',
          message: 'Premisave brings clients, home owners and the team that supports them onto one secure platform, '
              'so finding, verifying and managing property is clear for everyone involved.',
          actions: <Widget>[
            HeroAction(
              label: 'Contact us',
              icon: Icons.mail_outline_rounded,
              onPressed: () => context.push('/home/contact'),
            ),
          ],
        ),
        const InfoSection(
          title: 'What we stand for',
          subtitle: 'Four commitments shape every part of the product.',
          child: _Principles(),
        ),
        const InfoSection(
          title: 'Who Premisave is for',
          subtitle: 'One account, with the tools each person needs.',
          child: _Audiences(),
        ),
        const InfoSection(
          title: 'How it works',
          subtitle: 'From sign up to a verified, ready to use account.',
          child: _Steps(),
        ),
        const SizedBox(height: 42),
        const _ClosingCard(),
      ],
    );
  }
}

class _Principle {
  const _Principle(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;
}

class _Principles extends StatelessWidget {
  const _Principles();

  static const List<_Principle> _items = <_Principle>[
    _Principle(
      Icons.verified_outlined,
      'Verified before listed',
      'Home owners apply with their documents, and our team reviews every application before anything goes live.',
    ),
    _Principle(
      Icons.lock_outline_rounded,
      'Secure by default',
      'Email alerts for new sign ins, control over your devices and sessions, and a full activity history to review.',
    ),
    _Principle(
      Icons.visibility_outlined,
      'Clear at every step',
      'You can always see where an application stands, and we email you whenever its status changes.',
    ),
    _Principle(
      Icons.public_rounded,
      'Built for anywhere',
      'Designed for use in any country, with international phone numbers and addresses and a look you can personalise.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrap(
      minItemWidth: 250,
      spacing: 14,
      maxColumns: 4,
      children: <Widget>[
        for (final p in _items)
          PCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconBadge(p.icon),
                const SizedBox(height: 16),
                Text(p.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                const SizedBox(height: 8),
                Text(p.text, style: TextStyle(fontSize: 13.5, height: 1.55, color: context.mutedColor)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Audience {
  const _Audience(this.icon, this.title, this.text);

  final IconData icon;
  final String title;
  final String text;
}

class _Audiences extends StatelessWidget {
  const _Audiences();

  static const List<_Audience> _items = <_Audience>[
    _Audience(
      Icons.person_search_outlined,
      'Clients',
      'Look for places, keep your favourites, and manage bookings, payments and messages in one spot.',
    ),
    _Audience(
      Icons.home_work_outlined,
      'Home owners',
      'Apply to list your property, upload documents securely, and follow the review from start to finish.',
    ),
    _Audience(
      Icons.support_agent_outlined,
      'The Premisave team',
      'Operations, finance and support staff review applications and help members from one workspace.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrap(
      minItemWidth: 270,
      spacing: 14,
      maxColumns: 3,
      children: <Widget>[
        for (final a in _items)
          PCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                IconBadge(a.icon, size: 44),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(a.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                      const SizedBox(height: 6),
                      Text(a.text, style: TextStyle(fontSize: 13.5, height: 1.55, color: context.mutedColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Step {
  const _Step(this.title, this.text);

  final String title;
  final String text;
}

class _Steps extends StatelessWidget {
  const _Steps();

  static const List<_Step> _items = <_Step>[
    _Step('Create your account', 'Sign up with your email or a social account, then confirm your address.'),
    _Step('Complete your profile', 'Add your details. Home owners start an application and upload their documents.'),
    _Step('Get verified', 'Our team reviews applications and keeps you updated by email until you are ready to go.'),
  ];

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return ResponsiveWrap(
      minItemWidth: 250,
      spacing: 14,
      maxColumns: 3,
      children: <Widget>[
        for (var i = 0; i < _items.length; i++)
          PCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: pal.accent, shape: BoxShape.circle),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: pal.accentInk),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_items[i].title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                const SizedBox(height: 8),
                Text(_items[i].text, style: TextStyle(fontSize: 13.5, height: 1.55, color: context.mutedColor)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ClosingCard extends StatelessWidget {
  const _ClosingCard();

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final compact = context.isCompact;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Have a question or an idea?',
          style: context.display(size: 20, weight: FontWeight.w800, spacing: -0.4, height: 1.2),
        ),
        const SizedBox(height: 6),
        Text(
          'We read every message, and your feedback shapes what we build next.',
          style: TextStyle(fontSize: 14, height: 1.5, color: context.mutedColor),
        ),
      ],
    );
    final button = PButton(
      label: 'Contact us',
      icon: Icons.arrow_forward_rounded,
      onPressed: () => context.push('/home/contact'),
    );
    return PCard(
      color: pal.accentSoft,
      borderColor: pal.accent.op(0.25),
      padding: EdgeInsets.all(compact ? 20 : 26),
      child: compact
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[text, const SizedBox(height: 18), button])
          : Row(children: <Widget>[Expanded(child: text), const SizedBox(width: 24), button]),
    );
  }
}
