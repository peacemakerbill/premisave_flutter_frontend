import 'package:flutter/material.dart';
import 'widgets/client_explore/property_details_dialog.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class ClientWishlistsContent extends StatelessWidget {
  const ClientWishlistsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 36, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderSection(),
          const SizedBox(height: 28),
          const _WishlistStats(),
          const SizedBox(height: 28),
          _WishlistSection(
            title: 'Beachfront Properties',
            properties: _beachfrontWishlist,
          ),
          const SizedBox(height: 28),
          _WishlistSection(
            title: 'Mountain Getaways',
            properties: _mountainWishlist,
          ),
          const SizedBox(height: 28),
          _WishlistSection(
            title: 'City Apartments',
            properties: _cityWishlist,
          ),
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
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Wishlists',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.8),
                ),
                const SizedBox(height: 6),
                Text(
                  'Save and organize your favorite properties',
                  style: TextStyle(fontSize: 14, color: _slate),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _stone, shape: BoxShape.circle),
            child: const Icon(Icons.favorite_rounded, color: Colors.pink, size: 28),
          ),
        ],
      ),
    );
  }
}

class _WishlistStats extends StatelessWidget {
  const _WishlistStats();

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    final stats = [
      {'title': 'Total Saved', 'value': '12', 'color': Colors.pink, 'icon': Icons.favorite_rounded},
      {'title': 'Lists Created', 'value': '3', 'color': _brand, 'icon': Icons.list_rounded},
      {'title': 'Recently Viewed', 'value': '5', 'color': Colors.blue, 'icon': Icons.visibility_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Wishlist Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmall ? 2 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.75,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _gold, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat['icon'] as IconData, color: color, size: 20),
          const SizedBox(height: 10),
          Text(stat['value'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _brand)),
          Text(stat['title'] as String, style: const TextStyle(fontSize: 11.5, color: _slate)),
        ],
      ),
    );
  }
}

class _WishlistSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> properties;

  const _WishlistSection({required this.title, required this.properties});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 600;

    final crossAxisCount = isSmall ? 1 : (screenWidth > 1200 ? 4 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand)),
            TextButton(
              onPressed: () {},
              child: const Row(
                children: [
                  Text('View All'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('${properties.length} properties', style: TextStyle(fontSize: 13, color: _slate)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isSmall ? 0.75 : 0.85,
          ),
          itemCount: properties.length,
          itemBuilder: (context, index) => _WishlistPropertyCard(
            property: properties[index],
            onTap: () => _showPropertyDetails(context, properties[index]),
          ),
        ),
      ],
    );
  }

  void _showPropertyDetails(BuildContext context, Map<String, dynamic> property) {
    final enhancedProperty = Map<String, dynamic>.from(property)
      ..addAll({
        'dailyPrice': property['price'].replaceAll('/night', '').trim(),
        'monthlyPrice': '${_calculateMonthlyPrice(property['price'])} / month',
      });

    showDialog(
      context: context,
      builder: (context) => PropertyDetailsDialog(property: enhancedProperty, rentalType: 'daily'),
    );
  }

  String _calculateMonthlyPrice(String dailyPrice) {
    final priceMatch = RegExp(r'KSh\s*([\d,]+)').firstMatch(dailyPrice);
    if (priceMatch != null) {
      final priceStr = priceMatch.group(1)!.replaceAll(',', '');
      final price = double.tryParse(priceStr) ?? 0;
      final monthly = (price * 30).toInt();
      return 'KSh ${monthly.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
    }
    return 'KSh 0';
  }
}

class _WishlistPropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;

  const _WishlistPropertyCard({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAE6DE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                property['image'],
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property['title'],
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _brand),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(property['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(property['location'], style: TextStyle(fontSize: 12.5, color: _slate)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(6)),
                        child: Text(property['type'], style: TextStyle(fontSize: 11.5, color: _slate)),
                      ),
                      Text(
                        property['price'],
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _brand),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _brand,
                        side: const BorderSide(color: _brand),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Sample Data
const List<Map<String, dynamic>> _beachfrontWishlist = [
  {'image': 'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=400&auto=format&fit=crop', 'title': 'Ocean View Villa', 'location': 'Diani Beach', 'price': 'KSh 25,000 / night', 'rating': 4.88, 'type': 'Villa', 'badge': 'Beachfront'},
  {'image': 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5?w=400&auto=format&fit=crop', 'title': 'Beach House', 'location': 'Mombasa', 'price': 'KSh 18,000 / night', 'rating': 4.75, 'type': 'House', 'badge': 'Luxury'},
];

const List<Map<String, dynamic>> _mountainWishlist = [
  {'image': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=400&auto=format&fit=crop', 'title': 'Mountain Cabin', 'location': 'Mount Kenya', 'price': 'KSh 12,000 / night', 'rating': 4.95, 'type': 'Cabin', 'badge': 'Popular'},
  {'image': 'https://images.unsplash.com/photo-1513584684374-8bab748fbf90?w=400&auto=format&fit=crop', 'title': 'Forest Retreat', 'location': 'Aberdare', 'price': 'KSh 9,500 / night', 'rating': 4.82, 'type': 'Retreat', 'badge': 'Eco'},
  {'image': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400&auto=format&fit=crop', 'title': 'Hiking Lodge', 'location': 'Samburu', 'price': 'KSh 14,000 / night', 'rating': 4.90, 'type': 'Lodge', 'badge': 'Adventure'},
];

const List<Map<String, dynamic>> _cityWishlist = [
  {'image': 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=400&auto=format&fit=crop', 'title': 'Modern Apartment', 'location': 'Nairobi CBD', 'price': 'KSh 8,500 / night', 'rating': 4.92, 'type': 'Apartment', 'badge': 'Guest Favorite'},
  {'image': 'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=400&auto=format&fit=crop', 'title': 'City Studio', 'location': 'Westlands', 'price': 'KSh 6,500 / night', 'rating': 4.75, 'type': 'Studio', 'badge': 'Modern'},
  {'image': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&auto=format&fit=crop', 'title': 'Penthouse Loft', 'location': 'Kilimani', 'price': 'KSh 15,000 / night', 'rating': 4.89, 'type': 'Loft', 'badge': 'Luxury'},
];