import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({super.key, this.imageUrl, this.radius = 40, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: const Color(0xFF2A5446),
        backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
            ? CachedNetworkImageProvider(imageUrl!) as ImageProvider
            : null,
        child: (imageUrl == null || imageUrl!.isEmpty)
            ? Icon(Icons.person_rounded, size: radius * 0.75, color: const Color(0xFF9DC4B8))
            : null,
      ),
    );
  }
}