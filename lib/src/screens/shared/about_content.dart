import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
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
          horizontal: isLarge ? 36 : 24,
          vertical: 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeaderSection(),
            const SizedBox(height: 32),
            isLarge ? const _MissionVisionRow() : const _MissionVisionColumn(),
            const SizedBox(height: 32),
            _TeamSection(isLarge: isLarge, isMedium: isMedium),
            const SizedBox(height: 32),
            _CoreValuesSection(isLarge: isLarge, isMedium: isMedium),
            const SizedBox(height: 32),
            const _ContactSection(),
          ],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(36),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 58,
            backgroundImage: NetworkImage(
              'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400&auto=format&fit=crop',
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Premisave',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.8),
          ),
          SizedBox(height: 8),
          Text(
            'Revolutionizing Real Estate in Kenya',
            style: TextStyle(fontSize: 16.5, color: _slate, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 20),
          Text(
            'Premisave connects property owners, buyers, and service providers through innovative technology.',
            style: TextStyle(fontSize: 15.5, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Mission & Vision ───────────────────────────────────────────────────────

class _MissionVisionRow extends StatelessWidget {
  const _MissionVisionRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _MissionVisionCard(icon: Icons.flag_rounded, title: 'Our Mission', content: 'To revolutionize real estate in Kenya with secure, transparent, and efficient digital solutions.', color: Color(0xFF22C55E))),
        SizedBox(width: 20),
        Expanded(child: _MissionVisionCard(icon: Icons.visibility_rounded, title: 'Our Vision', content: "To become East Africa's leading real estate platform, transforming property management.", color: Color(0xFF3B82F6))),
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
        _MissionVisionCard(icon: Icons.flag_rounded, title: 'Our Mission', content: 'To revolutionize real estate in Kenya with secure, transparent, and efficient digital solutions.', color: Color(0xFF22C55E)),
        SizedBox(height: 20),
        _MissionVisionCard(icon: Icons.visibility_rounded, title: 'Our Vision', content: "To become East Africa's leading real estate platform, transforming property management.", color: Color(0xFF3B82F6)),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 18),
          Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 14.5, height: 1.55), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Team & Values ───────────────────────────────────────────────────────────

class _TeamSection extends StatelessWidget {
  final bool isLarge;
  final bool isMedium;

  const _TeamSection({required this.isLarge, required this.isMedium});

  final List<Map<String, dynamic>> teamMembers = const [
    {'name': 'James Maina', 'role': 'CEO', 'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'},
    {'name': 'Grace Nyong\'o', 'role': 'CFO', 'image': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200'},
    {'name': 'Peter Kariuki', 'role': 'CTO', 'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200'},
    {'name': 'Lucy Wambui', 'role': 'Operations', 'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'},
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Meet Our Team',
      subtitle: 'Experts driving innovation in real estate',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLarge ? 4 : (isMedium ? 3 : 2),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.82,
        ),
        itemCount: teamMembers.length,
        itemBuilder: (_, i) => _TeamMemberCard(member: teamMembers[i]),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final Map<String, dynamic> member;
  const _TeamMemberCard({required this.member});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 40, backgroundImage: NetworkImage(member['image'])),
          const SizedBox(height: 16),
          Text(member['name'], style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: _brand), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(member['role'], style: TextStyle(fontSize: 13, color: _slate)),
        ],
      ),
    );
  }
}

class _CoreValuesSection extends StatelessWidget {
  final bool isLarge;
  final bool isMedium;

  const _CoreValuesSection({required this.isLarge, required this.isMedium});

  final List<Map<String, dynamic>> values = const [
    {'icon': Icons.verified_rounded, 'title': 'Integrity', 'description': 'Honesty and transparency in all dealings', 'color': Color(0xFF22C55E)},
    {'icon': Icons.lightbulb_rounded, 'title': 'Innovation', 'description': 'Creating better solutions with technology', 'color': Color(0xFF3B82F6)},
    {'icon': Icons.people_rounded, 'title': 'Customer Focus', 'description': 'Our customers are at the heart of everything', 'color': Color(0xFFF59E0B)},
    {'icon': Icons.star_rounded, 'title': 'Excellence', 'description': 'Highest standards in service delivery', 'color': Color(0xFF8B5CF6)},
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Core Values',
      subtitle: 'The principles that guide our work',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLarge ? 4 : (isMedium ? 2 : 1),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: values.length,
        itemBuilder: (_, i) => _ValueCard(value: values[i]),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(value['icon'] as IconData, size: 30, color: color),
          ),
          const SizedBox(height: 18),
          Text(value['title'], style: TextStyle(fontSize: 17.5, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 10),
          Text(value['description'], style: const TextStyle(fontSize: 14, height: 1.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Contact ─────────────────────────────────────────────────────────────────

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    return const _Section(
      title: 'Get in Touch',
      subtitle: "We'd love to hear from you",
      child: Column(
        children: [
          _ContactInfo(icon: Icons.email_rounded, title: 'Email', value: 'contact@premisave.co.ke'),
          SizedBox(height: 16),
          _ContactInfo(icon: Icons.phone_rounded, title: 'Phone', value: '+254 700 123 456'),
          SizedBox(height: 16),
          _ContactInfo(icon: Icons.location_on_rounded, title: 'Address', value: 'Nairobi, Kenya'),
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
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: _stone, shape: BoxShape.circle),
          child: Icon(icon, color: _brand, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13.5, color: _slate)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: _brand)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared Section (Dashboard Style) ────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 14.5, color: _slate)),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF3EFE6), thickness: 1),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}