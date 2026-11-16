import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/social_models.dart';
import '../../data/models/user_model.dart';
import '../../roles/role.dart';

/// One person in a list: avatar, name and a line of detail.
class PersonTile extends StatelessWidget {
  const PersonTile({
    super.key,
    required this.id,
    required this.name,
    required this.initials,
    this.picture,
    this.subtitle,
    this.trailing,
  });

  factory PersonTile.fromUser(UserModel u) => PersonTile(
        id: u.id,
        name: u.displayName,
        initials: u.initials,
        picture: u.profilePictureUrl,
        subtitle: <String>[u.role.label, if (u.country.isNotEmpty) u.country].join(' · '),
      );

  factory PersonTile.fromEntry(DirectoryEntry e) => PersonTile(
        id: e.id,
        name: e.name,
        initials: e.initials,
        picture: e.picture,
        subtitle: <String>[
          if (e.role != null) Role.parse(e.role).label,
          if (e.country != null) e.country!,
        ].join(' · '),
      );

  final String id;
  final String name;
  final String initials;
  final String? picture;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: id.isEmpty ? null : () => context.push('/people/$id'),
      child: Row(
        children: <Widget>[
          UserAvatar(initials: initials, imageUrl: picture, size: 46),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
              ],
            ),
          ),
          trailing ?? Icon(Icons.chevron_right_rounded, color: context.mutedColor),
        ],
      ),
    );
  }
}

/// Star row for showing or choosing a rating.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 18, this.onChanged});

  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: onChanged == null ? null : () => onChanged!(i),
            child: Padding(
              padding: EdgeInsets.only(right: onChanged == null ? 1 : 4),
              child: Icon(
                i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i <= rating ? Brand.gold : context.mutedColor.op(0.5),
              ),
            ),
          ),
      ],
    );
  }
}
