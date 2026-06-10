import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class ClientBookingsContent extends StatelessWidget {
  const ClientBookingsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 768;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 36 : 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderSection(),
          const SizedBox(height: 28),
          const _BookingStats(),
          const SizedBox(height: 28),
          const _ActiveBookings(),
          const SizedBox(height: 28),
          const _PastBookings(),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 768;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE6DE)),
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
                Text(
                  'Manage all your property bookings in one place',
                  style: TextStyle(fontSize: 14, color: _slate),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _stone, shape: BoxShape.circle),
            child: Icon(Icons.calendar_today_rounded, color: _brand, size: 28),
          ),
        ],
      ),
    );
  }
}

class _BookingStats extends StatelessWidget {
  const _BookingStats();

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    final stats = [
      {'title': 'Active', 'value': '3', 'color': Colors.green, 'icon': Icons.check_circle_rounded},
      {'title': 'Upcoming', 'value': '2', 'color': Colors.blue, 'icon': Icons.upcoming_rounded},
      {'title': 'Completed', 'value': '8', 'color': Colors.purple, 'icon': Icons.done_all_rounded},
      {'title': 'Cancelled', 'value': '1', 'color': Colors.orange, 'icon': Icons.cancel_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Booking Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmall ? 2 : 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isSmall ? 1.65 : 1.85,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => _StatCard(stat: stats[index]),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _gold, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(stat['icon'] as IconData, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            stat['value'] as String,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _brand),
          ),
          Text(
            stat['title'] as String,
            style: const TextStyle(fontSize: 11.5, color: _slate),
          ),
        ],
      ),
    );
  }
}

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
        const SizedBox(height: 6),
        Text('Your current and upcoming stays', style: TextStyle(color: _slate, fontSize: 13)),
        const SizedBox(height: 16),
        ...activeBookings.map((booking) => _BookingCard(booking: booking)).toList(),
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
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.home_outlined, color: _brand, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking['property'], style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: _brand)),
                      Text(booking['location'], style: TextStyle(fontSize: 12.5, color: _slate)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (booking['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking['status'],
                    style: TextStyle(color: booking['color'] as Color, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF3EFE6)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _Detail(title: 'Check-in', value: booking['checkIn']),
                _Detail(title: 'Check-out', value: booking['checkOut']),
                _Detail(title: 'Total', value: booking['amount'], isHighlight: true),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _brand,
                      side: const BorderSide(color: _brand),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text('View Details', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Text('Support', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ),
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
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: _slate)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isHighlight ? Colors.green : _brand,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

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
        const SizedBox(height: 6),
        Text('Your previous stays', style: TextStyle(color: _slate, fontSize: 13)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAE6DE)),
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
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3EFE6))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.history_rounded, color: _brand, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking['property'], style: const TextStyle(fontWeight: FontWeight.w600, color: _brand)),
                Text(booking['date'], style: TextStyle(color: _slate, fontSize: 12.5)),
              ],
            ),
          ),
          Text(booking['amount'], style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green)),
        ],
      ),
    );
  }
}