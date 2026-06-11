import 'package:flutter/material.dart';
import 'widgets/client_explore/property_details_dialog.dart';

const _brand = Color(0xFF1A3C34);
const _brandLight = Color(0xFF2D5A4F);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);
const _border = Color(0xFFEAE6DE);

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
      final titleMatch = property['title'].toString().toLowerCase().contains(_searchQuery);
      final locationMatch = property['location'].toString().toLowerCase().contains(_searchQuery);
      final typeMatch = property['type'].toString().toLowerCase().contains(_searchQuery);

      final amenitiesList = property['amenities'] as List<String>? ?? [];
      final amenitiesMatch = amenitiesList.any((a) => a.toLowerCase().contains(_searchQuery));

      return titleMatch || locationMatch || typeMatch || amenitiesMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          pinned: true,
          expandedHeight: isSmallScreen ? 90 : 110,
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 2,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 36,
                vertical: 12,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search properties, locations, or amenities...',
                        hintStyle: const TextStyle(color: _slate, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: _brand, size: 22),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: _slate, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 36,
            vertical: 20,
          ),
          sliver: filteredProperties.isEmpty
              ? const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off_rounded, size: 64, color: _slate),
                  SizedBox(height: 16),
                  Text('No properties found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _brand)),
                  SizedBox(height: 4),
                  Text('Try matching different descriptive terms', style: TextStyle(color: _slate, fontSize: 13)),
                ],
              ),
            ),
          )
              : SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisSpacing: isSmallScreen ? 16 : 24,
              crossAxisSpacing: isSmallScreen ? 16 : 24,
              mainAxisExtent: isSmallScreen ? 370 : 385,
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

// ── Enhanced Property Card ──────────────────────────────────────────────────

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

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: InkWell(
        onTap: widget.onTap,
        splashColor: _brand.withOpacity(0.03),
        highlightColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    widget.property['image'],
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
                      child: const Center(child: Icon(Icons.broken_image_rounded, color: _slate, size: 28)),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    type: MaterialType.circle,
                    color: Colors.white.withOpacity(0.9),
                    elevation: 2,
                    shadowColor: Colors.black12,
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 18,
                        color: _isFavorite ? Colors.pink : _slate,
                      ),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      splashRadius: 18,
                      onPressed: () => setState(() => _isFavorite = !_isFavorite),
                    ),
                  ),
                ),
                if (widget.property['badge'] != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _brand.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Text(
                        widget.property['badge'],
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.property['location'],
                                style: const TextStyle(color: _slate, fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  widget.property['rating'].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _brand),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.property['title'],
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: _brand, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.property['type'],
                          style: const TextStyle(color: _slate, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: (widget.property['amenities'] as List<String>? ?? ['WiFi', 'Kitchen'])
                              .take(3)
                              .map((a) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: _stone,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              a,
                              style: const TextStyle(fontSize: 10, color: _brandLight, fontWeight: FontWeight.w600),
                            ),
                          ))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          price,
                          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: _brand),
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

// ── Sample Properties Data ──────────────────────────────────────────────────

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