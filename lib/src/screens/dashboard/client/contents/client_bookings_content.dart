import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);
const _border = Color(0xFFEAE6DE);

class ClientBookingsContent extends StatelessWidget {
  const ClientBookingsContent({super.key});

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
                const SizedBox(height: 28),
                _BookingStats(isLarge: isLarge, isMedium: isMedium),
                const SizedBox(height: 28),
                const _ActiveBookings(),
                const SizedBox(height: 28),
                const _PastBookings(),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ── Header Section ─────────────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 600;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        padding: EdgeInsets.all(isSmall ? 20 : 28),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Bookings',
                    style: TextStyle(
                      fontSize: isSmall ? 24 : 28,
                      fontWeight: FontWeight.w800,
                      color: _brand,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Manage all your property bookings in one place',
                    style: TextStyle(fontSize: 14, color: _slate),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: _stone, shape: BoxShape.circle),
              child: const Icon(Icons.calendar_today_rounded, color: _brand, size: 26),
            ),
          ],
        ),
      );
    });
  }
}

// ── Booking Stats ──────────────────────────────────────────────────────────

class _BookingStats extends StatelessWidget {
  final bool isLarge;
  final bool isMedium;

  const _BookingStats({required this.isLarge, required this.isMedium});

  static const stats = [
    {'title': 'Active', 'value': '3', 'color': Colors.green, 'icon': Icons.check_circle_rounded},
    {'title': 'Upcoming', 'value': '2', 'color': Colors.blue, 'icon': Icons.upcoming_rounded},
    {'title': 'Completed', 'value': '8', 'color': Colors.purple, 'icon': Icons.done_all_rounded},
    {'title': 'Cancelled', 'value': '1', 'color': Colors.orange, 'icon': Icons.cancel_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = isLarge
                ? (constraints.maxWidth - 36) / 4
                : isMedium
                ? (constraints.maxWidth - 36) / 4
                : (constraints.maxWidth - 12) / 2;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: stats.map((s) => SizedBox(
                width: itemWidth,
                child: _StatCard(stat: s),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Map<String, dynamic> stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final color = stat['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(stat['icon'] as IconData, color: color, size: 20),
              Container(width: 12, height: 3, decoration: const BoxDecoration(color: _gold, borderRadius: BorderRadius.all(Radius.circular(2)))),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stat['value'] as String,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _brand, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            stat['title'] as String,
            style: const TextStyle(fontSize: 12, color: _slate, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Active Bookings ─────────────────────────────────────────────────────────

class _ActiveBookings extends StatelessWidget {
  const _ActiveBookings();

  final List<Map<String, dynamic>> activeBookings = const [
    {'property': 'Modern Apartment', 'location': 'Nairobi CBD', 'checkIn': '15 Dec 2024', 'checkOut': '20 Dec 2024', 'amount': 'KSh 42,500', 'status': 'Confirmed', 'color': Colors.green},
    {'property': 'Luxury Villa', 'location': 'Mombasa', 'checkIn': '22 Jan 2025', 'checkOut': '29 Jan 2025', 'amount': 'KSh 175,000', 'status': 'Confirmed', 'color': Colors.green},
    {'property': 'Mountain Cabin', 'location': 'Mount Kenya', 'checkIn': '10 Feb 2025', 'checkOut': '15 Feb 2025', 'amount': 'KSh 60,000', 'status': 'Pending', 'color': Colors.orange},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Active Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 4),
        const Text('Your current and upcoming stays', style: TextStyle(color: _slate, fontSize: 13)),
        const SizedBox(height: 16),
        ...activeBookings.map((booking) => _BookingCard(booking: booking)),
      ],
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 480;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.home_outlined, color: _brand, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['property'],
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _brand),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          booking['location'],
                          style: const TextStyle(fontSize: 12.5, color: _slate, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (booking['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking['status'],
                      style: TextStyle(color: booking['color'] as Color, fontWeight: FontWeight.w700, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Color(0xFFF3EFE6)),
              if (isCompact) ...[
                _Detail(title: 'Check-in', value: booking['checkIn']),
                const SizedBox(height: 10),
                _Detail(title: 'Check-out', value: booking['checkOut']),
                const SizedBox(height: 10),
                _Detail(title: 'Total Amount', value: booking['amount'], isHighlight: true),
              ] else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _Detail(title: 'Check-in', value: booking['checkIn'])),
                    Expanded(child: _Detail(title: 'Check-out', value: booking['checkOut'])),
                    Expanded(child: _Detail(title: 'Total', value: booking['amount'], isHighlight: true)),
                  ],
                ),
              const SizedBox(height: 20),
              if (isCompact) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brand,
                      side: const BorderSide(color: _brand),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Support', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _brand,
                          side: const BorderSide(color: _brand),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('View Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Support', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  final String title;
  final String value;
  final bool isHighlight;
  const _Detail({required this.title, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: _slate, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isHighlight ? Colors.green : _brand,
            fontSize: 13.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Past Bookings ───────────────────────────────────────────────────────────

class _PastBookings extends StatelessWidget {
  const _PastBookings();

  final List<Map<String, dynamic>> pastBookings = const [
    {'date': '10 Nov 2024', 'property': 'Beach House', 'amount': 'KSh 35,000'},
    {'date': '25 Oct 2024', 'property': 'City Apartment', 'amount': 'KSh 28,500'},
    {'date': '15 Sep 2024', 'property': 'Mountain Lodge', 'amount': 'KSh 48,000'},
    {'date': '5 Aug 2024', 'property': 'Studio Flat', 'amount': 'KSh 19,500'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Past Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 4),
        const Text('Your previous stays', style: TextStyle(color: _slate, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: pastBookings.map((b) => _PastItem(booking: b)).toList(),
          ),
        ),
      ],
    );
  }
}

class _PastItem extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _PastItem({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3EFE6))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.history_rounded, color: _brand, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  booking['property'],
                  style: const TextStyle(fontWeight: FontWeight.w700, color: _brand, fontSize: 14.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  booking['date'],
                  style: const TextStyle(color: _slate, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            booking['amount'],
            style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.green, fontSize: 14),
          ),
        ],
      ),
    );
  }
}