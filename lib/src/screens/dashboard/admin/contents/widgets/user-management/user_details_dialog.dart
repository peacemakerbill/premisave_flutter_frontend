import 'package:flutter/material.dart';
import '../../../../../../models/auth/user_model.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _divider = Color(0xFFF3EFE6);

class UserDetailsDialog extends StatelessWidget {
  final UserModel user;
  const UserDetailsDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DialogHeader(
                  icon: Icons.person_outline_rounded,
                  title: 'User Details',
                ),
                const SizedBox(height: 24),

                // Avatar + Name
                Row(children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _brand,
                    child: Text(
                      '${user.firstName[0]}${user.lastName[0]}',
                      style: const TextStyle(
                        color: _gold,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: _brand,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(user.email,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                        Text('@${user.username}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // Status Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(user.role.name.replaceAll('_', ' ').toUpperCase(), _roleColor(user.role.name)),
                    _Chip(user.active ? 'ACTIVE' : 'INACTIVE', user.active ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                    _Chip(user.verified ? 'VERIFIED' : 'UNVERIFIED', user.verified ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B)),
                  ],
                ),
                const SizedBox(height: 24),

                _SectionTitle('Personal Details'),
                const SizedBox(height: 12),
                _DetailRow(Icons.phone_outlined, 'Phone', user.phoneNumber),
                _DetailRow(Icons.language_outlined, 'Language', user.language),
                _DetailRow(Icons.location_on_outlined, 'Country', user.country),
                const SizedBox(height: 8),

                _SectionTitle('Address'),
                const SizedBox(height: 12),
                _DetailRow(Icons.home_outlined, 'Address Line 1', user.address1),
                _DetailRow(Icons.home_outlined, 'Address Line 2', user.address2),
                const SizedBox(height: 32),

                // Compact Close Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brand,
                      side: const BorderSide(color: Color(0xFFEAE6DE)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':      return const Color(0xFFDC2626);
      case 'client':     return const Color(0xFF16A34A);
      case 'home_owner': return const Color(0xFF3B82F6);
      case 'operations': return const Color(0xFFF59E0B);
      case 'finance':    return const Color(0xFF8B5CF6);
      case 'support':    return const Color(0xFF0D9488);
      default:           return const Color(0xFF6B7280);
    }
  }
}

// ── Reusable Components ─────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value.isNotEmpty ? value : '—',
                  style: const TextStyle(
                      fontSize: 13.5,
                      color: _brand,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DialogHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _DialogHeader({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: _brand.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 22, color: _brand),
    ),
    const SizedBox(width: 14),
    Expanded(
      child: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _brand,
              letterSpacing: -0.4)),
    ),
  ]);
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _brand,
              letterSpacing: 0.3)),
      const SizedBox(height: 6),
      const Divider(height: 1, color: _divider),
    ],
  );
}