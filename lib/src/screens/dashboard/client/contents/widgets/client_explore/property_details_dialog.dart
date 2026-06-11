import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _brandLight = Color(0xFF2D5A4F);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);
const _border = Color(0xFFEAE6DE);

class PropertyDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> property;
  final String rentalType;

  const PropertyDetailsDialog({
    super.key,
    required this.property,
    required this.rentalType,
  });

  @override
  State<PropertyDetailsDialog> createState() => _PropertyDetailsDialogState();
}

class _PropertyDetailsDialogState extends State<PropertyDetailsDialog> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  late final List<String> _imageGallery;

  @override
  void initState() {
    super.initState();
    // Build image gallery gracefully from parameters
    final primaryImg = widget.property['image'] ?? 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800';
    _imageGallery = [
      primaryImg,
      'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800&auto=format&fit=crop',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&auto=format&fit=crop',
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.rentalType == 'daily'
        ? '${widget.property['dailyPrice'] ?? widget.property['price'] ?? 'KSh 0'} / night'
        : '${widget.property['monthlyPrice'] ?? widget.property['price'] ?? 'KSh 0'} / month';

    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.width < 380;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Column(
          children: [
            // Scrollable Content Zone
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Premium Media Carousel Gallery
                    Stack(
                      children: [
                        SizedBox(
                          height: 220,
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) => setState(() => _currentImageIndex = index),
                            itemCount: _imageGallery.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                _imageGallery[index],
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: _stone,
                                  child: const Icon(Icons.home_work_rounded, size: 44, color: _slate),
                                ),
                              );
                            },
                          ),
                        ),
                        // Indicator Counter Bubble
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentImageIndex + 1} / ${_imageGallery.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        // Close Action Trigger
                        Positioned(
                          top: 12,
                          right: 12,
                          child: CircleAvatar(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            radius: 16,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.close_rounded, size: 18, color: _brand),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                        // Featured Tag Ribbon
                        if (widget.property['badge'] != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _gold,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                (widget.property['badge'] as String).toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Navigation Thumbnail Row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: List.generate(_imageGallery.length, (index) {
                          final isSelected = _currentImageIndex == index;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 48,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: isSelected ? _gold : _border, width: isSelected ? 2 : 1),
                                image: DecorationImage(image: NetworkImage(_imageGallery[index]), fit: BoxFit.cover),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),

                    // Primary Metadata Details Stack
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.property['title'] ?? 'Stunning Rental Space',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.5),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _gold.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, color: _gold, size: 15),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${widget.property['rating'] ?? '4.8'}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _brand),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: _slate, size: 15),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.property['location'] ?? 'Nairobi, Kenya',
                                  style: const TextStyle(color: _slate, fontSize: 13, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: _border),
                          const SizedBox(height: 16),

                          // Structural Layout Features Grid Array (No fixed heights!)
                          const Text(
                            'Property Specifications',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _brand),
                          ),
                          const SizedBox(height: 10),
                          _buildAdaptiveFeaturesGrid(),

                          const SizedBox(height: 18),
                          const Text(
                            'Included Amenities',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _brand),
                          ),
                          const SizedBox(height: 10),
                          _buildAmenitiesChipsList(widget.property['amenities']),

                          const SizedBox(height: 18),
                          const Text(
                            'Stay Regulations & Host',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _brand),
                          ),
                          const SizedBox(height: 10),
                          _buildHostProfileRow(),

                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _stone.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.gavel_rounded, color: _brandLight, size: 15),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Quiet hours monitored past 10 PM. No internal smoking permitted.',
                                    style: TextStyle(fontSize: 12, color: _brand, height: 1.4),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Fixed Sticky Footer Container
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: isCompact ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: _border, width: 1.2)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, -3))
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('RATE PRICING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _slate, letterSpacing: 0.5)),
                        const SizedBox(height: 2),
                        Text(
                          price,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _brand),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.bolt_rounded, size: 16),
                        label: const Text('Book Space', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brand,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
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

  // Uses Wrap with auto alignment to handle all extreme device widths seamlessly
  Widget _buildAdaptiveFeaturesGrid() {
    return const Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      children: [
        _FeatureColumnItem(icon: Icons.king_bed_rounded, label: '3 Beds'),
        _FeatureColumnItem(icon: Icons.bathtub_rounded, label: '2 Baths'),
        _FeatureColumnItem(icon: Icons.square_foot_rounded, label: '1,200 sqft'),
        _FeatureColumnItem(icon: Icons.wifi_rounded, label: 'Free Wifi'),
      ],
    );
  }

  Widget _buildAmenitiesChipsList(dynamic amenities) {
    final List<String> items = (amenities is List) ? List<String>.from(amenities) : ['WiFi', 'Pool', 'Gym', 'Parking'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.take(4).map((amenity) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _stone.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getAmenityIcon(amenity), size: 12, color: _brandLight),
              const SizedBox(width: 4),
              Text(amenity, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _brand)),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getAmenityIcon(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('wi')) return Icons.wifi_rounded;
    if (lower.contains('pool')) return Icons.pool_rounded;
    if (lower.contains('gym') || lower.contains('fitness')) return Icons.fitness_center_rounded;
    if (lower.contains('park')) return Icons.local_parking_rounded;
    return Icons.done_all_rounded;
  }

  Widget _buildHostProfileRow() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100'),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Elena Mwangi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _brand)),
                SizedBox(height: 1),
                Text('Verified Superhost', style: TextStyle(fontSize: 10.5, color: _gold, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: _brandLight, size: 18),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.phone_outlined, color: _brandLight, size: 18),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(6),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _FeatureColumnItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureColumnItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _brand, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _slate),
          ),
        ],
      ),
    );
  }
}