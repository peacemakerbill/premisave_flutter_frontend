import 'package:flutter/material.dart';
import 'widgets/client_explore/property_details_dialog.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class ClientExploreContent extends StatefulWidget {
  const ClientExploreContent({super.key});

  @override
  State<ClientExploreContent> createState() => _ClientExploreContentState();
}

class _ClientExploreContentState extends State<ClientExploreContent> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredProperties {
    if (_searchQuery.isEmpty) return _sampleProperties;

    return _sampleProperties.where((property) {
      return property['title'].toLowerCase().contains(_searchQuery) ||
          property['location'].toLowerCase().contains(_searchQuery) ||
          property['type'].toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;
    final crossAxisCount = screenWidth < 600 ? 2 : screenWidth < 1200 ? 3 : 4;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          pinned: true,
          expandedHeight: isSmallScreen ? 100 : 110,
          backgroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 20 : 36,
                vertical: 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEAE6DE)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search properties, locations, or amenities...',
                        hintStyle: TextStyle(color: _slate),
                        prefixIcon: const Icon(Icons.search_rounded, color: _brand),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 36),
          sliver: filteredProperties.isEmpty
              ? const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No properties found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text('Try different keywords', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
              : SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isSmallScreen ? 12 : 16,
              mainAxisSpacing: isSmallScreen ? 16 : 20,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
                  (context, index) => PropertyCard(
                property: filteredProperties[index],
                rentalType: 'daily',
                onTap: () => _showPropertyDetails(context, filteredProperties[index]),
              ),
              childCount: filteredProperties.length,
            ),
          ),
        ),
      ],
    );
  }

  void _showPropertyDetails(BuildContext context, Map<String, dynamic> property) {
    showDialog(
      context: context,
      builder: (context) => PropertyDetailsDialog(property: property, rentalType: 'daily'),
    );
  }
}

// Enhanced Property Card
class PropertyCard extends StatefulWidget {
  final Map<String, dynamic> property;
  final String rentalType;
  final VoidCallback onTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.rentalType,
    required this.onTap,
  });

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final price = '${widget.property['dailyPrice']}/night';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAE6DE)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    widget.property['image'],
                    height: 172,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () => setState(() => _isFavorite = !_isFavorite),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: _isFavorite ? Colors.pink : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                if (widget.property['badge'] != null)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Text(
                        widget.property['badge'],
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _brand),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.property['location'],
                          style: TextStyle(color: _slate, fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                          const SizedBox(width: 3),
                          Text(widget.property['rating'].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.property['title'],
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600, color: _brand),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(widget.property['type'], style: TextStyle(color: _slate, fontSize: 13)),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (widget.property['amenities'] as List<String>? ?? ['WiFi', 'Kitchen'])
                        .take(3)
                        .map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _stone,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(a, style: const TextStyle(fontSize: 10.5, color: _slate)),
                    ))
                        .toList(),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    price,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _brand),
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

// Enhanced Sample Properties
final List<Map<String, dynamic>> _sampleProperties = [
  {
    'image': 'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800&auto=format&fit=crop',
    'title': 'Modern Apartment in Nairobi CBD',
    'location': 'Nairobi, Kenya',
    'dailyPrice': 'KSh 8,500',
    'rating': 4.92,
    'type': 'Apartment',
    'badge': 'Guest favorite',
    'amenities': ['WiFi', 'Pool', 'Gym', 'Parking'],
  },
  {
    'image': 'https://images.unsplash.com/photo-1518780664697-55e3ad937233?w=800&auto=format&fit=crop',
    'title': 'Luxury Villa with Ocean View',
    'location': 'Mombasa, Kenya',
    'dailyPrice': 'KSh 25,000',
    'rating': 4.88,
    'type': 'Villa',
    'badge': 'Trending',
    'amenities': ['Beach Access', 'Pool', 'Kitchen', 'Balcony'],
  },
  {
    'image': 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800&auto=format&fit=crop',
    'title': 'Cozy Cabin in the Mountains',
    'location': 'Mount Kenya',
    'dailyPrice': 'KSh 12,000',
    'rating': 4.95,
    'type': 'Cabin',
    'badge': 'Popular',
    'amenities': ['Fireplace', 'Hiking', 'WiFi'],
  },
  {
    'image': 'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=800&auto=format&fit=crop',
    'title': 'City Center Studio Apartment',
    'location': 'Nairobi West',
    'dailyPrice': 'KSh 6,500',
    'rating': 4.75,
    'type': 'Studio',
    'amenities': ['WiFi', 'Kitchenette'],
  },
  {
    'image': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&auto=format&fit=crop',
    'title': 'Penthouse Loft with City View',
    'location': 'Kilimani, Nairobi',
    'dailyPrice': 'KSh 15,000',
    'rating': 4.89,
    'type': 'Loft',
    'badge': 'Luxury',
    'amenities': ['Terrace', 'Gym', 'Parking'],
  },
];