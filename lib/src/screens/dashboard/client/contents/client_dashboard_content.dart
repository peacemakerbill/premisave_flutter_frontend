import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/auth/user_model.dart';
import '../../../../providers/auth/auth_provider.dart';
import 'widgets/client_explore/property_details_dialog.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);

class ClientDashboardContent extends ConsumerWidget {
  const ClientDashboardContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final isWide = MediaQuery.of(context).size.width >= 768;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 36 : 20,
        vertical: 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(user: user),
          const SizedBox(height: 28),
          _StatsRow(isWide: isWide),
          const SizedBox(height: 28),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _UpcomingBookings()),
                const SizedBox(width: 20),
                Expanded(flex: 2, child: _QuickActions()),
              ],
            )
          else ...[
            _UpcomingBookings(),
            const SizedBox(height: 20),
            _QuickActions(),
          ],
          const SizedBox(height: 24),
          _TrendingProperties(),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final UserModel? user;
  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, ${user?.firstName ?? "Client"}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _brand,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'June 2026  ·  Q2',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _StatusChip(label: 'Active Member', dot: true),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool dot;
  const _StatusChip({required this.label, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final bool isWide;
  const _StatsRow({required this.isWide});

  static const _stats = [
    _StatData('Saved Properties', '12', '4 this month', Icons.favorite_rounded, true),
    _StatData('Total Spent', 'KES 450K', '↑ 18% vs last Q', Icons.payments_rounded, true),
    _StatData('Upcoming Stays', '3', 'Next in 12 days', Icons.calendar_today_rounded, false),
    _StatData('Active Bookings', '2', 'All confirmed', Icons.check_circle_rounded, true),
  ];

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        children: _stats
            .map((s) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: s == _stats.last ? 0 : 14),
            child: _StatCard(data: s),
          ),
        ))
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 148,
      ),
      itemCount: _stats.length,
      itemBuilder: (_, i) => _StatCard(data: _stats[i]),
    );
  }
}

class _StatData {
  final String label, value, sub;
  final IconData icon;
  final bool positive;
  const _StatData(this.label, this.value, this.sub, this.icon, this.positive);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _gold, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, size: 18, color: _brand),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: data.positive ? const Color(0xFFECFDF3) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  data.positive ? '↑' : '↓',
                  style: TextStyle(
                    fontSize: 11,
                    color: data.positive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _brand,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.sub,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming Bookings ─────────────────────────────────────────────────────

class _UpcomingBookings extends StatelessWidget {
  const _UpcomingBookings();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Upcoming Bookings',
      trailing: 'View all',
      child: Column(
        children: const [
          _BookingRow(
            property: 'Ocean View Villa',
            location: 'Diani Beach · 5 nights',
            date: '22 - 27 Jan 2026',
            amount: 'KES 125,000',
            status: 'Confirmed',
          ),
          Divider(height: 1, color: Color(0xFFF3EFE6)),
          _BookingRow(
            property: 'Mountain Cabin',
            location: 'Mount Kenya · 3 nights',
            date: '10 - 13 Feb 2026',
            amount: 'KES 36,000',
            status: 'Confirmed',
          ),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  final String property, location, date, amount, status;
  const _BookingRow({
    required this.property,
    required this.location,
    required this.date,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.home_outlined, color: _brand, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(property, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _brand)),
                Text(location, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _brand)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF3),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  status,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF22C55E)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ─────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Quick Actions',
      child: Column(
        children: [
          _ActionTile(icon: Icons.search_rounded, title: 'Browse Properties', subtitle: 'Find your next stay'),
          const Divider(height: 1, color: Color(0xFFF3EFE6)),
          _ActionTile(icon: Icons.favorite_rounded, title: 'My Wishlists', subtitle: '12 saved properties'),
          const Divider(height: 1, color: Color(0xFFF3EFE6)),
          _ActionTile(icon: Icons.calendar_month_rounded, title: 'Manage Bookings', subtitle: '3 upcoming'),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;

  const _ActionTile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: _brand.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: _brand),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _brand)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
      onTap: () {},
    );
  }
}

// ── Trending Properties ───────────────────────────────────────────────────

class _TrendingProperties extends StatelessWidget {
  const _TrendingProperties();

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Trending Properties',
      trailing: 'See all',
      child: const _TrendingList(),
    );
  }
}

class _TrendingList extends StatelessWidget {
  const _TrendingList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _TrendingCard(
            title: 'Ocean View Villa',
            location: 'Diani Beach',
            price: 'KSh 25,000/night',
            rating: 4.9,
            image: 'https://picsum.photos/id/1015/400/220',
          ),
          _TrendingCard(
            title: 'Modern Penthouse',
            location: 'Nairobi CBD',
            price: 'KSh 12,500/night',
            rating: 4.8,
            image: 'https://picsum.photos/id/106/400/220',
          ),
          _TrendingCard(
            title: 'Forest Retreat',
            location: 'Aberdare',
            price: 'KSh 9,800/night',
            rating: 4.95,
            image: 'https://picsum.photos/id/1018/400/220',
          ),
        ],
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final String title, location, price, image;
  final double rating;

  const _TrendingCard({
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPropertyDetails(context),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                image,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _brand)),
                  const SizedBox(height: 4),
                  Text(location, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(price, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _brand)),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(rating.toString(), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPropertyDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PropertyDetailsDialog(
        property: {
          'title': title,
          'location': location,
          'dailyPrice': price.replaceAll('/night', '').trim(),
          'monthlyPrice': '${(double.tryParse(price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0 * 30).toInt()} / month',
          'rating': rating,
          'image': image,
          'type': 'Villa',
          'badge': 'Trending',
        },
        rentalType: 'daily',
      ),
    );
  }
}

// ── Shared Section Wrapper ───────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;

  const _Section({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _brand,
                  letterSpacing: -0.2,
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _gold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(color: Color(0xFFF3EFE6)),
          child,
        ],
      ),
    );
  }
}