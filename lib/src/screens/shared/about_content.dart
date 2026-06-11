import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _brandLight = Color(0xFF2D5A4F);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);
const _border = Color(0xFFEAE6DE);

class AboutContent extends StatelessWidget {
  const AboutContent({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isLarge = constraints.maxWidth > 1100;
      final isMedium = constraints.maxWidth > 700;

      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 36 : 20,
          vertical: 28,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeaderSection(),
                const SizedBox(height: 24),
                _StatsRow(isLarge: isLarge, isMedium: isMedium),
                const SizedBox(height: 32),
                isLarge ? const _MissionVisionRow() : const _MissionVisionColumn(),
                const SizedBox(height: 32),
                const _StorySection(),
                const SizedBox(height: 32),
                _TeamSection(isLarge: isLarge, isMedium: isMedium),
                const SizedBox(height: 32),
                _CoreValuesSection(isLarge: isLarge, isMedium: isMedium),
                const SizedBox(height: 32),
                const _TimelineSection(),
                const SizedBox(height: 32),
                const _ContactSection(),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brand, _brandLight],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brand.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _gold.withOpacity(0.12),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold, width: 3),
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400&auto=format&fit=crop',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Premisave',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withOpacity(0.4)),
                ),
                child: const Text(
                  'Revolutionizing Real Estate in Kenya',
                  style: TextStyle(
                    fontSize: 13,
                    color: _gold,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Premisave connects property owners, buyers, and service providers '
                    'through innovative technology — making real estate transactions '
                    'simpler, safer, and more transparent for everyone in Kenya.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.white.withOpacity(0.85),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final bool isLarge;
  final bool isMedium;
  const _StatsRow({required this.isLarge, required this.isMedium});

  static const _stats = [
    {'value': '12K+', 'label': 'Properties Listed', 'icon': Icons.home_work_rounded, 'color': Color(0xFF22C55E)},
    {'value': '8K+', 'label': 'Happy Clients', 'icon': Icons.emoji_emotions_rounded, 'color': Color(0xFF3B82F6)},
    {'value': '47', 'label': 'Counties Covered', 'icon': Icons.map_rounded, 'color': Color(0xFFF59E0B)},
    {'value': '5+', 'label': 'Years of Trust', 'icon': Icons.workspace_premium_rounded, 'color': Color(0xFF8B5CF6)},
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Automatically determine item width based on viewport flags
        final double itemWidth = isLarge
            ? (constraints.maxWidth - 48) / 4
            : isMedium
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _stats.map((s) {
            final color = s['color'] as Color;
            return Container(
              width: itemWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(s['icon'] as IconData, color: color, size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s['value'] as String,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _brand),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    s['label'] as String,
                    style: const TextStyle(fontSize: 12, color: _slate, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Mission & Vision ───────────────────────────────────────────────────────

class _MissionVisionRow extends StatelessWidget {
  const _MissionVisionRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MissionVisionCard(
            icon: Icons.flag_rounded,
            title: 'Our Mission',
            content: 'To revolutionize real estate in Kenya with secure, transparent, '
                'and efficient digital solutions that put people first.',
            color: Color(0xFF22C55E),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _MissionVisionCard(
            icon: Icons.visibility_rounded,
            title: 'Our Vision',
            content: "To become East Africa's leading real estate platform, "
                "transforming how communities buy, sell, and manage property.",
            color: Color(0xFF3B82F6),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _MissionVisionCard(
            icon: Icons.diamond_rounded,
            title: 'Our Promise',
            content: 'Every listing verified, every transaction protected, '
                'every client treated like family.',
            color: Color(0xFFC9A84C),
          ),
        ),
      ],
    );
  }
}

class _MissionVisionColumn extends StatelessWidget {
  const _MissionVisionColumn();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _MissionVisionCard(
          icon: Icons.flag_rounded,
          title: 'Our Mission',
          content: 'To revolutionize real estate in Kenya with secure, transparent, '
              'and efficient digital solutions that put people first.',
          color: Color(0xFF22C55E),
        ),
        SizedBox(height: 16),
        _MissionVisionCard(
          icon: Icons.visibility_rounded,
          title: 'Our Vision',
          content: "To become East Africa's leading real estate platform, "
              "transforming how communities buy, sell, and manage property.",
          color: Color(0xFF3B82F6),
        ),
        SizedBox(height: 16),
        _MissionVisionCard(
          icon: Icons.diamond_rounded,
          title: 'Our Promise',
          content: 'Every listing verified, every transaction protected, '
              'every client treated like family.',
          color: Color(0xFFC9A84C),
        ),
      ],
    );
  }
}

class _MissionVisionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;

  const _MissionVisionCard({required this.icon, required this.title, required this.content, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 14, height: 1.5, color: _slate), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Story Section ───────────────────────────────────────────────────────────

class _StorySection extends StatelessWidget {
  const _StorySection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Our Story',
      subtitle: 'How it all began',
      icon: Icons.auto_stories_rounded,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 100,
            margin: const EdgeInsets.only(right: 16, top: 4),
            decoration: BoxDecoration(
              color: _gold,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Text(
              'Founded in Nairobi, Premisave began with a simple idea: real estate '
                  'in Kenya should be easier to navigate, safer to invest in, and open '
                  'to everyone — not just those with insider connections. What started '
                  'as a small team of passionate technologists and property experts has '
                  'grown into a trusted platform serving thousands of clients across the '
                  'country, with a mission to bring transparency and digital innovation '
                  'to every corner of the housing market.',
              style: const TextStyle(fontSize: 14, height: 1.6, color: _slate),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Team ────────────────────────────────────────────────────────────────────

class _TeamSection extends StatelessWidget {
  final bool isLarge;
  final bool isMedium;

  const _TeamSection({required this.isLarge, required this.isMedium});

  final List<Map<String, dynamic>> teamMembers = const [
    {'name': 'James Maina', 'role': 'CEO & Co-Founder', 'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200', 'bio': 'Real estate strategist with a passion for tech-driven growth.'},
    {'name': "Grace Nyong'o", 'role': 'CFO', 'image': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200', 'bio': 'Financial expert ensuring sustainable, transparent operations.'},
    {'name': 'Peter Kariuki', 'role': 'CTO', 'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200', 'bio': 'Engineering leader building secure, scalable platforms.'},
    {'name': 'Lucy Wambui', 'role': 'Head of Operations', 'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200', 'bio': 'Keeps every listing and transaction running smoothly.'},
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Meet Our Team',
      subtitle: 'Experts driving innovation in real estate',
      icon: Icons.groups_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = isLarge
              ? (constraints.maxWidth - 48) / 4
              : isMedium
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: teamMembers.map((m) => SizedBox(
              width: itemWidth,
              child: _TeamMemberCard(member: m, isLarge: isLarge),
            )).toList(),
          );
        },
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool isLarge;
  const _TeamMemberCard({required this.member, required this.isLarge});

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(radius: 36, backgroundImage: NetworkImage(member['image']));

    final textBlock = Column(
      crossAxisAlignment: isLarge ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          member['name'],
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _brand),
          textAlign: isLarge ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(member['role'], style: const TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        Text(
          member['bio'],
          style: const TextStyle(fontSize: 12, color: _slate, height: 1.4),
          textAlign: isLarge ? TextAlign.center : TextAlign.left,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: isLarge
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [avatar, const SizedBox(height: 14), textBlock],
      )
          : Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [avatar, const SizedBox(width: 16), Expanded(child: textBlock)],
      ),
    );
  }
}

// ── Core Values ─────────────────────────────────────────────────────────────

class _CoreValuesSection extends StatelessWidget {
  final bool isLarge;
  final bool isMedium;

  const _CoreValuesSection({required this.isLarge, required this.isMedium});

  final List<Map<String, dynamic>> values = const [
    {'icon': Icons.verified_rounded, 'title': 'Integrity', 'description': 'Honesty and transparency in all our dealings, every single time.', 'color': Color(0xFF22C55E)},
    {'icon': Icons.lightbulb_rounded, 'title': 'Innovation', 'description': 'Constantly creating smarter solutions through technology.', 'color': Color(0xFF3B82F6)},
    {'icon': Icons.people_rounded, 'title': 'Customer Focus', 'description': 'Our customers are at the heart of everything we build.', 'color': Color(0xFFF59E0B)},
    {'icon': Icons.star_rounded, 'title': 'Excellence', 'description': 'Holding ourselves to the highest standards of service.', 'color': Color(0xFF8B5CF6)},
    {'icon': Icons.handshake_rounded, 'title': 'Trust', 'description': 'Building lasting relationships through reliability.', 'color': Color(0xFFEF4444)},
    {'icon': Icons.eco_rounded, 'title': 'Sustainability', 'description': 'Promoting responsible growth for communities & environment.', 'color': Color(0xFF14B8A6)},
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Core Values',
      subtitle: 'The principles that guide our work',
      icon: Icons.diamond_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = isLarge
              ? (constraints.maxWidth - 32) / 3
              : isMedium
              ? (constraints.maxWidth - 16) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: values.map((v) => SizedBox(
              width: itemWidth,
              child: _ValueCard(value: v),
            )).toList(),
          );
        },
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final Map<String, dynamic> value;
  const _ValueCard({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = value['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(value['icon'] as IconData, size: 24, color: color),
          ),
          const SizedBox(height: 14),
          Text(value['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _brand)),
          const SizedBox(height: 6),
          Text(value['description'], style: const TextStyle(fontSize: 13, height: 1.4, color: _slate)),
        ],
      ),
    );
  }
}

// ── Timeline ─────────────────────────────────────────────────────────────────

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  static const _milestones = [
    {'year': '2020', 'title': 'Founded in Nairobi', 'desc': 'Premisave launches with a handful of verified listings.'},
    {'year': '2021', 'title': 'Mobile App Launch', 'desc': 'Reached 1,000+ active users within the first month.'},
    {'year': '2023', 'title': 'National Expansion', 'desc': 'Extended coverage to 47 counties across Kenya.'},
    {'year': '2025', 'title': 'East Africa Growth', 'desc': 'Began expansion into Uganda and Tanzania markets.'},
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Our Journey',
      subtitle: 'Milestones that shaped Premisave',
      icon: Icons.timeline_rounded,
      child: Column(
        children: List.generate(_milestones.length, (i) {
          final m = _milestones[i];
          final isLast = i == _milestones.length - 1;
          final dotColor = isLast ? _gold : _brand;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 14,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                      if (!isLast)
                        Positioned(
                          top: 14,
                          bottom: -24,
                          left: 6,
                          child: Container(width: 2, color: _border),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['year']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _gold, letterSpacing: 1)),
                      const SizedBox(height: 2),
                      Text(m['title']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _brand)),
                      const SizedBox(height: 4),
                      Text(m['desc']!, style: const TextStyle(fontSize: 13, color: _slate, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Contact ─────────────────────────────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brand, _brandLight],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Get in Touch', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text("We'd love to hear from you", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
          const SizedBox(height: 24),
          const _ContactInfo(icon: Icons.email_rounded, title: 'Email', value: 'contact@premisave.co.ke'),
          const SizedBox(height: 14),
          const _ContactInfo(icon: Icons.phone_rounded, title: 'Phone', value: '+254 700 123 456'),
          const SizedBox(height: 14),
          const _ContactInfo(icon: Icons.location_on_rounded, title: 'Address', value: 'Nairobi, Kenya'),
        ],
      ),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ContactInfo({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: _gold, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared Section ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final Widget child;

  const _Section({required this.title, required this.subtitle, required this.child, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _stone,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: _brand, size: 20),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 13.5, color: _slate)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF3EFE6), thickness: 1),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}