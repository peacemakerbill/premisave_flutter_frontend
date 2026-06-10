import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class AboutContent extends StatelessWidget {
  const AboutContent({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLarge = screenWidth > 1200;
    final isMedium = screenWidth > 600;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isLarge ? 36 : 24, vertical: 28),
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
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundImage: const NetworkImage(
              'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400&auto=format&fit=crop',
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Premisave',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.8),
          ),
          const SizedBox(height: 8),
          Text(
            'Revolutionizing Real Estate in Kenya',
            style: TextStyle(fontSize: 16, color: _slate, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          const Text(
            'Premisave connects property owners, buyers, and service providers through innovative technology.',
            style: TextStyle(fontSize: 16, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MissionVisionRow extends StatelessWidget {
  const _MissionVisionRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(child: _MissionVisionCard(
          icon: Icons.flag_rounded,
          title: 'Our Mission',
          content: 'To revolutionize real estate in Kenya with secure, transparent, and efficient digital solutions.',
          color: Colors.green,
        )),
        SizedBox(width: 20),
        Expanded(child: _MissionVisionCard(
          icon: Icons.visibility_rounded,
          title: 'Our Vision',
          content: 'To become East Africa\'s leading real estate platform, transforming property management.',
          color: Colors.blue,
        )),
      ],
    );
  }
}

class _MissionVisionColumn extends StatelessWidget {
  const _MissionVisionColumn();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _MissionVisionCard(
          icon: Icons.flag_rounded,
          title: 'Our Mission',
          content: 'To revolutionize real estate in Kenya with secure, transparent, and efficient digital solutions.',
          color: Colors.green,
        ),
        SizedBox(height: 20),
        _MissionVisionCard(
          icon: Icons.visibility_rounded,
          title: 'Our Vision',
          content: 'To become East Africa\'s leading real estate platform, transforming property management.',
          color: Colors.blue,
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

  const _MissionVisionCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.5), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Meet Our Team', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _brand)),
        const SizedBox(height: 8),
        Text('Experts driving innovation in real estate', style: TextStyle(fontSize: 16, color: _slate)),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isLarge ? 4 : (isMedium ? 3 : 2),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: teamMembers.length,
          itemBuilder: (context, index) => _TeamMemberCard(member: teamMembers[index]),
        ),
      ],
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
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 42,
            backgroundImage: NetworkImage(member['image']),
          ),
          const SizedBox(height: 16),
          Text(member['name'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _brand), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(member['role'], style: TextStyle(fontSize: 13.5, color: _slate)),
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
    {'icon': Icons.verified_rounded, 'title': 'Integrity', 'description': 'Honesty and transparency in all dealings', 'color': Colors.green},
    {'icon': Icons.lightbulb_rounded, 'title': 'Innovation', 'description': 'Creating better solutions with technology', 'color': Colors.blue},
    {'icon': Icons.people_rounded, 'title': 'Customer Focus', 'description': 'Our customers are at the heart of everything', 'color': Colors.orange},
    {'icon': Icons.star_rounded, 'title': 'Excellence', 'description': 'Highest standards in service delivery', 'color': Colors.purple},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Core Values', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _brand)),
        const SizedBox(height: 8),
        Text('The principles that guide our work', style: TextStyle(fontSize: 16, color: _slate)),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isLarge ? 4 : (isMedium ? 2 : 1),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.95,
          ),
          itemCount: values.length,
          itemBuilder: (context, index) => _ValueCard(value: values[index]),
        ),
      ],
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
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(value['icon'] as IconData, size: 28, color: color),
          ),
          const SizedBox(height: 16),
          Text(value['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 8),
          Text(value['description'], style: const TextStyle(fontSize: 14, height: 1.4), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text('Get in Touch', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _brand)),
          const SizedBox(height: 8),
          Text('We\'d love to hear from you', style: TextStyle(fontSize: 16, color: _slate)),
          const SizedBox(height: 24),
          const _ContactInfo(icon: Icons.email_rounded, title: 'Email', value: 'contact@premisave.co.ke'),
          const SizedBox(height: 16),
          const _ContactInfo(icon: Icons.phone_rounded, title: 'Phone', value: '+254 700 123 456'),
          const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _stone, shape: BoxShape.circle),
          child: Icon(icon, color: _brand),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: _slate)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _brand)),
            ],
          ),
        ),
      ],
    );
  }
}