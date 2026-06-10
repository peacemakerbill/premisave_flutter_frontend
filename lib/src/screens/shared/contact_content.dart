import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);
const _border = Color(0xFFEAE6DE);

class ContactContent extends StatelessWidget {
  const ContactContent({super.key});

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
            const _Header(),
            const SizedBox(height: 32),
            isLarge ? _buildContactCardsRow() : _buildContactCardsColumn(),
            const SizedBox(height: 40),
            _TeamSection(isMedium: isMedium),
            const SizedBox(height: 40),
            const _OfficesSection(),
          ],
        ),
      );
    });
  }

  Widget _buildContactCardsRow() {
    return const Row(
      children: [
        Expanded(child: _ContactCard(icon: Icons.location_on_rounded, title: 'Visit Us', items: ['Premisave Plaza', 'Nairobi, Kenya'], color: Color(0xFF22C55E))),
        SizedBox(width: 20),
        Expanded(child: _ContactCard(icon: Icons.phone_rounded, title: 'Call Us', items: ['+254 700 123 456', '24/7 Support'], color: Color(0xFF3B82F6))),
        SizedBox(width: 20),
        Expanded(child: _ContactCard(icon: Icons.email_rounded, title: 'Email Us', items: ['info@premisave.co.ke', 'Quick Response'], color: Color(0xFFF59E0B))),
        SizedBox(width: 20),
        Expanded(child: _ContactCard(icon: Icons.access_time_rounded, title: 'Hours', items: ['Mon-Fri: 8AM-6PM', 'Sat: 9AM-2PM'], color: Color(0xFF8B5CF6))),
      ],
    );
  }

  Widget _buildContactCardsColumn() {
    return const Column(
      children: [
        _ContactCard(icon: Icons.location_on_rounded, title: 'Visit Us', items: ['Premisave Plaza', 'Nairobi, Kenya'], color: Color(0xFF22C55E)),
        SizedBox(height: 20),
        _ContactCard(icon: Icons.phone_rounded, title: 'Call Us', items: ['+254 700 123 456', '24/7 Support'], color: Color(0xFF3B82F6)),
        SizedBox(height: 20),
        _ContactCard(icon: Icons.email_rounded, title: 'Email Us', items: ['info@premisave.co.ke', 'Quick Response'], color: Color(0xFFF59E0B)),
        SizedBox(height: 20),
        _ContactCard(icon: Icons.access_time_rounded, title: 'Hours', items: ['Mon-Fri: 8AM-6PM', 'Sat: 9AM-2PM'], color: Color(0xFF8B5CF6)),
      ],
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

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
          Text('Get in Touch', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.8)),
          SizedBox(height: 8),
          Text("We’re here to help you", style: TextStyle(fontSize: 16.5, color: _slate, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Contact Cards ───────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color color;

  const _ContactCard({required this.icon, required this.title, required this.items, required this.color});

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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 18),
          Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 14),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(item, style: const TextStyle(fontSize: 14.5)),
          )),
        ],
      ),
    );
  }
}

// ── Team ────────────────────────────────────────────────────────────────────

class _TeamSection extends StatelessWidget {
  final bool isMedium;

  const _TeamSection({required this.isMedium});

  final List<Map<String, dynamic>> team = const [
    {'name': 'John Mwangi', 'role': 'Operations', 'email': 'john@premisave.co.ke', 'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'},
    {'name': 'Sarah Kimani', 'role': 'Technical', 'email': 'sarah@premisave.co.ke', 'image': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200'},
    {'name': 'David Ochieng', 'role': 'Support', 'email': 'david@premisave.co.ke', 'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200'},
    {'name': 'Grace Wambui', 'role': 'Finance', 'email': 'grace@premisave.co.ke', 'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'},
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Our Team',
      subtitle: 'Dedicated professionals ready to assist you',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isMedium ? 2 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: team.length,
        itemBuilder: (_, i) => _TeamCard(member: team[i]),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> member;
  const _TeamCard({required this.member});

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
          CircleAvatar(radius: 36, backgroundImage: NetworkImage(member['image'])),
          const SizedBox(height: 16),
          Text(member['name'], style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: _brand), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(member['role'], style: TextStyle(fontSize: 13, color: _slate)),
          const SizedBox(height: 6),
          Text(member['email'], style: const TextStyle(fontSize: 12.5, color: _slate), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Offices ─────────────────────────────────────────────────────────────────

class _OfficesSection extends StatelessWidget {
  const _OfficesSection();

  @override
  Widget build(BuildContext context) {
    final offices = ['Nairobi Office', 'Mombasa Office', 'Kisumu Office', 'Nakuru Office'];

    return _Section(
      title: 'Regional Offices',
      subtitle: 'Find us across Kenya',
      child: Column(
        children: offices.map((office) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _OfficeCard(name: office),
        )).toList(),
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  final String name;
  const _OfficeCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.business_rounded, color: Color(0xFF22C55E)),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: _brand, fontSize: 15.5)),
        subtitle: Text('${name.split(' ')[0]} CBD', style: TextStyle(color: _slate, fontSize: 13.5)),
        trailing: const Icon(Icons.location_on_rounded, color: _brand),
      ),
    );
  }
}

// ── Shared Section ──────────────────────────────────────────────────────────

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
          Text(subtitle, style: TextStyle(fontSize: 14.5, color: _slate)),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF3EFE6)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}