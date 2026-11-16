import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../theme/palette.dart';

/// Round profile picture that falls back to initials.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.initials, this.imageUrl, this.size = 44, this.ring = false});

  final String initials;
  final String? imageUrl;
  final double size;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.mediaUrl(imageUrl);
    final fallback = _Initials(initials: initials, size: size);
    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? fallback
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
                loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
              ),
      ),
    );
    if (!ring) return avatar;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, color: context.pal.accent),
      child: avatar,
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.pal.hero,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: context.pal.dark ? context.pal.accent : context.pal.accentInk,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
