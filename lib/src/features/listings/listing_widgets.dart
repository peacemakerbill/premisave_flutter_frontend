import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/listing_models.dart';
import '../shared/service_widgets.dart';

/// A listing image path from the listing service as a full address. Absolute links pass through unchanged.
String? listingImageUrl(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final p = path.trim();
  if (p.startsWith('http://') || p.startsWith('https://') || p.startsWith('data:')) return p;
  return '${AppConfig.listingUrl}${p.startsWith('/') ? p : '/$p'}';
}

String categoryLabel(String category) {
  switch (category) {
    case 'SHORT_TERM_RENTAL':
      return 'Short stay';
    case 'LONG_TERM_RENTAL':
      return 'Long term rental';
    case 'LAND_SALE':
      return 'Land for sale';
    case 'HOUSE_SALE':
      return 'House for sale';
    case 'LEASE':
      return 'Lease';
    default:
      return category.isEmpty ? 'Listing' : category;
  }
}

/// "USD 120 / night", or just the amount for a sale.
String priceLine(ListingModel l) {
  final p = l.headlinePrice;
  if (p == null) return 'Price on request';
  final unit = l.priceLabel;
  return unit.isEmpty ? formatMoney(p, l.currency) : '${formatMoney(p, l.currency)} / $unit';
}

/// The picture of a listing, or a quiet placeholder when it has none.
class ListingPicture extends StatelessWidget {
  const ListingPicture(this.url, {super.key, this.aspect = 1.6});

  final String? url;
  final double aspect;

  @override
  Widget build(BuildContext context) {
    final full = listingImageUrl(url);
    final placeholder = Container(
      color: context.pal.accent.op(0.08),
      child: Center(child: Icon(Icons.home_work_outlined, size: 40, color: context.pal.accent.op(0.5))),
    );
    return AspectRatio(
      aspectRatio: aspect,
      child: full == null
          ? placeholder
          : Image.network(
              full,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => placeholder,
              loadingBuilder: (context, child, progress) => progress == null ? child : placeholder,
            ),
    );
  }
}

/// A listing as a card in the Explore grid.
class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, this.onTap, this.trailing});

  final ListingModel listing;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return PCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              ListingPicture(listing.cover),
              if (listing.promoted)
                const Positioned(left: 10, top: 10, child: StatusPill('Featured', color: Brand.gold, dense: true)),
              if (listing.status != null) Positioned(right: 10, top: 10, child: StatusChip(listing.status!)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(categoryLabel(listing.category), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.pal.accent)),
                const SizedBox(height: 4),
                Text(listing.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.25)),
                if (listing.place.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.place_outlined, size: 14, color: context.mutedColor),
                        const SizedBox(width: 3),
                        Flexible(child: Text(listing.place, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: context.mutedColor))),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(child: Text(priceLine(listing), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800))),
                    if (trailing != null) trailing!,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
