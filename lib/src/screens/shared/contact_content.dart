import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class ContactContent extends StatelessWidget {
  const ContactContent({super.key});

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
          const _Header(),
          const SizedBox(height: 32),
          isLarge ? _buildContactCardsRow() : Column(children: _buildContactCards()),
          const SizedBox(height: 40),
          const _TeamSection(),
          const SizedBox(height: 40),
          const _OfficesSection(),
        ],
      ),
    );
  }

  Widget _buildContactCardsRow() {
    return Row(
      children: const [
        Expanded(child: _ContactCard(icon: Icons.location_on_rounded, title: 'Visit Us', items: ['Premisave Plaza', 'Nairobi, Kenya'], color: Colors.green)),
        SizedBox(width: 16),
        Expanded(child: _ContactCard(icon: Icons.phone_rounded, title: 'Call Us', items: ['+254 700 123 456', '24/7 Support'], color: Colors.blue)),
        SizedBox(width: 16),
        Expanded(child: _ContactCard(icon: Icons.email_rounded, title: 'Email Us', items: ['info@premisave.co.ke', 'Quick Response'], color: Colors.orange)),
        SizedBox(width: 16),
        Expanded(child: _ContactCard(icon: Icons.access_time_rounded, title: 'Hours', items: ['Mon-Fri: 8AM-6PM', 'Sat: 9AM-2PM'], color: Colors.purple)),
      ],
    );
  }

  List<Widget> _buildContactCards() {
    return [
      _ContactCard(icon: Icons.location_on_rounded, title: 'Visit Us', items: ['Premisave Plaza, 123 Business District', 'Nairobi, Kenya'], color: Colors.green),
      const SizedBox(height: 16),
      _ContactCard(icon: Icons.phone_rounded, title: 'Call Us', items: ['+254 700 123 456', 'Technical Support: +254 700 654 321'], color: Colors.blue),
      const SizedBox(height: 16),
      _ContactCard(icon: Icons.email_rounded, title: 'Email Us', items: ['info@premisave.co.ke', 'support@premisave.co.ke'], color: Colors.orange),
      const SizedBox(height: 16),
      _ContactCard(icon: Icons.access_time_rounded, title: 'Hours', items: ['Mon-Fri: 8:00 AM - 6:00 PM', 'Saturday: 9:00 AM - 2:00 PM'], color: Colors.purple),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
          const Text('Get in Touch', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.8)),
          const SizedBox(height: 8),
          Text('We\'re here to help you', style: TextStyle(fontSize: 16, color: _slate)),
        ],
      ),
    );
  }
}

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
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(item, style: const TextStyle(fontSize: 14.5)),
          )),
        ],
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Our Team', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => _TeamCard(index: index),
        ),
      ],
    );
  }
}

class _TeamCard extends StatelessWidget {
  final int index;
  const _TeamCard({required this.index});

  final List<Map<String, dynamic>> team = const [
    {'name': 'John Mwangi', 'role': 'Operations', 'email': 'john@premisave.co.ke', 'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'},
    {'name': 'Sarah Kimani', 'role': 'Technical', 'email': 'sarah@premisave.co.ke', 'image': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200'},
    {'name': 'David Ochieng', 'role': 'Support', 'email': 'david@premisave.co.ke', 'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200'},
    {'name': 'Grace Wambui', 'role': 'Finance', 'email': 'grace@premisave.co.ke', 'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'},
  ];

  @override
  Widget build(BuildContext context) {
    final member = team[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 32, backgroundImage: NetworkImage(member['image'])),
          const SizedBox(height: 12),
          Text(member['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: _brand), textAlign: TextAlign.center),
          Text(member['role'], style: TextStyle(color: _slate)),
          const SizedBox(height: 4),
          Text(member['email'], style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _OfficesSection extends StatelessWidget {
  const _OfficesSection();

  @override
  Widget build(BuildContext context) {
    final offices = ['Nairobi Office', 'Mombasa Office', 'Kisumu Office', 'Nakuru Office'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Regional Offices', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: offices.length,
          itemBuilder: (context, index) => _OfficeCard(name: offices[index]),
        ),
      ],
    );
  }
}

class _OfficeCard extends StatelessWidget {
  final String name;
  const _OfficeCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.business_rounded, color: Colors.green),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: _brand)),
        subtitle: Text('${name.split(' ')[0]} CBD', style: TextStyle(color: _slate)),
        trailing: const Icon(Icons.location_on_rounded, color: _brand),
      ),
    );
  }
}