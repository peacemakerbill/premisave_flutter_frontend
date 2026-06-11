import 'package:flutter/material.dart';
import 'widgets/client_explore/property_details_dialog.dart';

const _brand = Color(0xFF1A3C34);
const _brandLight = Color(0xFF2D5A4F);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);
const _border = Color(0xFFEAE6DE);

class ClientWishlistsContent extends StatelessWidget {
  const ClientWishlistsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isLarge = constraints.maxWidth > 1100;

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
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
                const SizedBox(height: 32),
                const _WishlistStats(),
                const SizedBox(height: 36),
                _WishlistSection(
                  title: 'Beachfront Properties',
                  properties: _beachfrontWishlist,
                ),
                const SizedBox(height: 32),
                _WishlistSection(
                  title: 'Mountain Getaways',
                  properties: _mountainWishlist,
                ),
                const SizedBox(height: 32),
                _WishlistSection(
                  title: 'City Apartments',
                  properties: _cityWishlist,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ── Premium Header Section ──────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 600;

      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_brand, _brandLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _brand.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        padding: EdgeInsets.all(isSmall ? 24 : 32),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Wishlists',
                    style: TextStyle(
                      fontSize: isSmall ? 26 : 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Save and organize your favorite dream spaces',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.pink, size: 28),
            ),
          ],
        ),
      );
    });
  }
}

// ── Fluid Wishlist Stats ─────────────────────────────────────────────────────

class _WishlistStats extends StatelessWidget {
  const _WishlistStats();

  static const stats = [
    {'title': 'Total Saved', 'value': '12', 'color': Colors.pink, 'icon': Icons.favorite_rounded},
    {'title': 'Lists Created', 'value': '3', 'color': _brand, 'icon': Icons.list_rounded},
    {'title': 'Recently Viewed', 'value': '5', 'color': Colors.blue, 'icon': Icons.visibility_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wishlist Overview',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.3),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final double itemWidth = screenWidth > 900
                ? (screenWidth - 24) / 3
                : screenWidth > 600
                ? (screenWidth - 24) / 3
                : (screenWidth - 12) / 2;

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(stat['icon'] as IconData, color: color, size: 20),
              ),
              Container(
                width: 14,
                height: 3,
                decoration: const BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            stat['value'] as String,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _brand, height: 1.1),
          ),
          const SizedBox(height: 3),
          Text(
            stat['title'] as String,
            style: const TextStyle(fontSize: 12.5, color: _slate, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ── Dynamic Wishlist Section ─────────────────────────────────────────────────

class _WishlistSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> properties;

  const _WishlistSection({required this.title, required this.properties});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${properties.length} curated spaces saved',
                    style: const TextStyle(fontSize: 13, color: _slate, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: _brandLight,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 15),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 340,
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            mainAxisExtent: 395, // Clean defensive vertical blueprint budget to handle text variations
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

// ── Enhanced Wishlist Property Card ──────────────────────────────────────────

class _WishlistPropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;

  const _WishlistPropertyCard({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: _brand.withOpacity(0.04),
        highlightColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    property['image'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: _stone,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(_brandLight),
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: _stone,
                      child: const Center(child: Icon(Icons.broken_image_rounded, color: _slate, size: 26)),
                    ),
                  ),
                ),
                if (property['badge'] != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: _brand.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Text(
                        property['badge'],
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                property['title'],
                                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _brand, height: 1.25),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                  const SizedBox(width: 2),
                                  Text(
                                    property['rating'].toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: _brand),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: _slate),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                property['location'],
                                style: const TextStyle(fontSize: 12.5, color: _slate, fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: _stone, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                property['type'],
                                style: const TextStyle(fontSize: 11, color: _brandLight, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                property['price'],
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _brand),
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
                              side: const BorderSide(color: _brand, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('View Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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