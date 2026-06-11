import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _brandLight = Color(0xFF2D5A4F);
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
          horizontal: isLarge ? 36 : 20,
          vertical: 28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const SizedBox(height: 28),
            isLarge ? _buildContactCardsRow() : _buildContactCardsColumn(isMedium),
            const SizedBox(height: 32),
            isLarge
                ? const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _MessageFormSection()),
                SizedBox(width: 24),
                Expanded(flex: 2, child: _MapSection()),
              ],
            )
                : const Column(
              children: [
                _MessageFormSection(),
                SizedBox(height: 24),
                _MapSection(),
              ],
            ),
            const SizedBox(height: 32),
            _TeamSection(isLarge: isLarge, isMedium: isMedium),
            const SizedBox(height: 32),
            _OfficesSection(isMedium: isMedium),
            const SizedBox(height: 32),
            const _FaqSection(),
          ],
        ),
      );
    });
  }

  Widget _buildContactCardsRow() {
    return const Row(
      children: [
        Expanded(child: _ContactCard(icon: Icons.location_on_rounded, title: 'Visit Us', items: ['Premisave Plaza, 4th Floor', 'Westlands, Nairobi'], color: Color(0xFF22C55E))),
        SizedBox(width: 20),
        Expanded(child: _ContactCard(icon: Icons.phone_rounded, title: 'Call Us', items: ['+254 700 123 456', '24/7 Support Line'], color: Color(0xFF3B82F6))),
        SizedBox(width: 20),
        Expanded(child: _ContactCard(icon: Icons.email_rounded, title: 'Email Us', items: ['info@premisave.co.ke', 'Reply within 2 hours'], color: Color(0xFFF59E0B))),
        SizedBox(width: 20),
        Expanded(child: _ContactCard(icon: Icons.access_time_rounded, title: 'Working Hours', items: ['Mon – Fri: 8AM – 6PM', 'Sat: 9AM – 2PM'], color: Color(0xFF8B5CF6))),
      ],
    );
  }

  Widget _buildContactCardsColumn(bool isMedium) {
    final cards = const [
      _ContactCard(icon: Icons.location_on_rounded, title: 'Visit Us', items: ['Premisave Plaza, 4th Floor', 'Westlands, Nairobi'], color: Color(0xFF22C55E)),
      _ContactCard(icon: Icons.phone_rounded, title: 'Call Us', items: ['+254 700 123 456', '24/7 Support Line'], color: Color(0xFF3B82F6)),
      _ContactCard(icon: Icons.email_rounded, title: 'Email Us', items: ['info@premisave.co.ke', 'Reply within 2 hours'], color: Color(0xFFF59E0B)),
      _ContactCard(icon: Icons.access_time_rounded, title: 'Working Hours', items: ['Mon – Fri: 8AM – 6PM', 'Sat: 9AM – 2PM'], color: Color(0xFF8B5CF6)),
    ];

    if (isMedium) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.4,
        children: cards,
      );
    }

    return Column(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          cards[i],
        ],
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
      padding: const EdgeInsets.all(40),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: _gold.withOpacity(0.12)),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold.withOpacity(0.4)),
                ),
                child: const Icon(Icons.support_agent_rounded, color: _gold, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'Get in Touch',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8),
              ),
              const SizedBox(height: 10),
              Text(
                "Have a question, a property to list, or just want to say hi?\n"
                    "Our team is ready to help — reach out anytime.",
                style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8), height: 1.6, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.18), color.withOpacity(0.06)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 18),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(item, style: const TextStyle(fontSize: 14, color: _slate, height: 1.5)),
          )),
        ],
      ),
    );
  }
}

// ── Message Form ─────────────────────────────────────────────────────────────

class _MessageFormSection extends StatelessWidget {
  const _MessageFormSection();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Send Us a Message',
      subtitle: "Fill out the form and we'll get back to you shortly",
      icon: Icons.send_rounded,
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(child: _FormField(label: 'Full Name', hint: 'e.g. John Doe', icon: Icons.person_outline_rounded)),
              SizedBox(width: 16),
              Expanded(child: _FormField(label: 'Phone Number', hint: '+254 7XX XXX XXX', icon: Icons.phone_outlined)),
            ],
          ),
          const SizedBox(height: 16),
          const _FormField(label: 'Email Address', hint: 'you@example.com', icon: Icons.alternate_email_rounded),
          const SizedBox(height: 16),
          const _FormField(label: 'Subject', hint: 'What is this about?', icon: Icons.topic_outlined),
          const SizedBox(height: 16),
          const _FormField(label: 'Message', hint: 'Tell us more...', icon: Icons.message_outlined, maxLines: 5),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Send Message', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;

  const _FormField({required this.label, required this.hint, required this.icon, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _brand)),
        const SizedBox(height: 8),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFB0AFA9), fontSize: 14),
            prefixIcon: maxLines == 1 ? Icon(icon, size: 19, color: _slate) : null,
            filled: true,
            fillColor: _stone.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _brand, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Map / Quick Links Section ───────────────────────────────────────────────

class _MapSection extends StatelessWidget {
  const _MapSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: _stone,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1577086664693-894d8405334a?w=600&auto=format&fit=crop'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [_brand.withOpacity(0.65), Colors.transparent],
              ),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded, color: _gold, size: 20),
                SizedBox(width: 8),
                Text('Premisave HQ — Westlands, Nairobi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Connect With Us', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _brand)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _SocialChip(icon: Icons.facebook_rounded, label: 'Facebook', color: Color(0xFF3B82F6)),
                  _SocialChip(icon: Icons.alternate_email_rounded, label: 'Twitter / X', color: Color(0xFF1A3C34)),
                  _SocialChip(icon: Icons.camera_alt_rounded, label: 'Instagram', color: Color(0xFFEF4444)),
                  _SocialChip(icon: Icons.business_center_rounded, label: 'LinkedIn', color: Color(0xFF3B82F6)),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(color: Color(0xFFF3EFE6)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF22C55E), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Chat with us live, Mon–Sat, 8AM–8PM', style: TextStyle(fontSize: 13, color: _slate, height: 1.4)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SocialChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
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

  final List<Map<String, dynamic>> team = const [
    {'name': 'John Mwangi', 'role': 'Operations Lead', 'email': 'john@premisave.co.ke', 'phone': '+254 711 222 333', 'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200'},
    {'name': 'Sarah Kimani', 'role': 'Technical Support', 'email': 'sarah@premisave.co.ke', 'phone': '+254 722 333 444', 'image': 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200'},
    {'name': 'David Ochieng', 'role': 'Customer Support', 'email': 'david@premisave.co.ke', 'phone': '+254 733 444 555', 'image': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200'},
    {'name': 'Grace Wambui', 'role': 'Finance & Billing', 'email': 'grace@premisave.co.ke', 'phone': '+254 744 555 666', 'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200'},
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Our Support Team',
      subtitle: 'Dedicated professionals ready to assist you',
      icon: Icons.support_rounded,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLarge ? 4 : (isMedium ? 2 : 1),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isLarge ? 0.85 : 1.7,
        ),
        itemCount: team.length,
        itemBuilder: (_, i) => _TeamCard(member: team[i], isLarge: isLarge),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool isLarge;
  const _TeamCard({required this.member, required this.isLarge});

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(radius: isLarge ? 38 : 32, backgroundImage: NetworkImage(member['image']));

    final details = Column(
      crossAxisAlignment: isLarge ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(member['name'], style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _brand), textAlign: isLarge ? TextAlign.center : TextAlign.left),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: _gold.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(member['role'], style: const TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.email_outlined, size: 13, color: _slate),
            const SizedBox(width: 6),
            Flexible(child: Text(member['email'], style: const TextStyle(fontSize: 12, color: _slate), overflow: TextOverflow.ellipsis)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_outlined, size: 13, color: _slate),
            const SizedBox(width: 6),
            Text(member['phone'], style: const TextStyle(fontSize: 12, color: _slate)),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: isLarge
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [avatar, const SizedBox(height: 14), details])
          : Row(children: [avatar, const SizedBox(width: 16), Expanded(child: details)]),
    );
  }
}

// ── Offices ─────────────────────────────────────────────────────────────────

class _OfficesSection extends StatelessWidget {
  final bool isMedium;
  const _OfficesSection({required this.isMedium});

  @override
  Widget build(BuildContext context) {
    final offices = [
      {'name': 'Nairobi Office', 'area': 'Westlands CBD', 'hours': 'Mon–Fri: 8AM–6PM', 'phone': '+254 700 123 456'},
      {'name': 'Mombasa Office', 'area': 'Nyali, Mombasa', 'hours': 'Mon–Fri: 8AM–5PM', 'phone': '+254 700 234 567'},
      {'name': 'Kisumu Office', 'area': 'Milimani, Kisumu', 'hours': 'Mon–Fri: 8AM–5PM', 'phone': '+254 700 345 678'},
      {'name': 'Nakuru Office', 'area': 'Section 58, Nakuru', 'hours': 'Mon–Fri: 8AM–5PM', 'phone': '+254 700 456 789'},
    ];

    return _Section(
      title: 'Regional Offices',
      subtitle: 'Find us across Kenya',
      icon: Icons.apartment_rounded,
      child: isMedium
          ? GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.6,
        children: offices.map((o) => _OfficeCard(office: o)).toList(),
      )
          : Column(
        children: offices
            .map((o) => Padding(padding: const EdgeInsets.only(bottom: 14), child: _OfficeCard(office: o)))
            .toList(),
      ),
    );
  }
}

class _OfficeCard extends StatelessWidget {
  final Map<String, String> office;
  const _OfficeCard({required this.office});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _stone.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF22C55E).withOpacity(0.12), shape: BoxShape.circle),
            child: const Icon(Icons.business_rounded, color: Color(0xFF22C55E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(office['name']!, style: const TextStyle(fontWeight: FontWeight.w700, color: _brand, fontSize: 15)),
                const SizedBox(height: 3),
                Text(office['area']!, style: const TextStyle(color: _slate, fontSize: 12.5)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: _slate),
                    const SizedBox(width: 4),
                    Text(office['hours']!, style: const TextStyle(color: _slate, fontSize: 11.5)),
                    const SizedBox(width: 10),
                    const Icon(Icons.phone, size: 12, color: _slate),
                    const SizedBox(width: 4),
                    Text(office['phone']!, style: const TextStyle(color: _slate, fontSize: 11.5)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: _brand, size: 14),
        ],
      ),
    );
  }
}

// ── FAQ ─────────────────────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  const _FaqSection();

  static const _faqs = [
    {'q': 'How do I list my property on Premisave?', 'a': 'Sign up for a free account, click "List Property", and follow the guided steps to upload photos, details, and pricing.'},
    {'q': 'Is there a fee to use Premisave?', 'a': 'Browsing and contacting agents is free for buyers and renters. Listing fees vary by plan — see our Pricing page for details.'},
    {'q': 'How are listings verified?', 'a': 'Our team manually reviews ownership documents and conducts site visits before approving any listing for publication.'},
    {'q': 'Can I get support outside office hours?', 'a': 'Yes — our 24/7 support line and live chat are available for urgent issues at any time.'},
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Frequently Asked Questions',
      subtitle: "Quick answers to common questions",
      icon: Icons.quiz_rounded,
      child: Column(
        children: _faqs
            .map((f) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _stone.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: ExpansionTile(
            iconColor: _brand,
            collapsedIconColor: _slate,
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
            title: Text(f['q']!, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: _brand)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f['a']!, style: const TextStyle(fontSize: 13.5, color: _slate, height: 1.6)),
            ],
          ),
        ))
            .toList(),
      ),
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
                  decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: _brand, size: 20),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 14.5, color: _slate)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF3EFE6)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}