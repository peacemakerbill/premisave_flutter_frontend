import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/listing_models.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';

/// Wishlists: the listings the person showed interest in. [asOwner] shows the leads on the person's own listings.
class WishlistsScreen extends ConsumerWidget {
  const WishlistsScreen({super.key, this.asOwner = false});

  final bool asOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = asOwner ? receivedInterestsProvider : myInterestsProvider;
    return AsyncBody<List<InterestModel>>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      builder: (items) => PageBody(
        maxWidth: 760,
        onRefresh: () async => ref.invalidate(provider),
        children: items.isEmpty
            ? <Widget>[
                SizedBox(
                  height: 340,
                  child: EmptyState(
                    icon: Icons.favorite_border_rounded,
                    title: asOwner ? 'No leads yet' : 'Nothing saved yet',
                    message: asOwner
                        ? 'People who show interest in your listings appear here.'
                        : 'Tap "I\'m interested" on a rental, lease or sale in Explore and it is saved here.',
                  ),
                ),
              ]
            : <Widget>[for (final i in items) _InterestCard(interest: i, asOwner: asOwner)],
      ),
    );
  }
}

class _InterestCard extends ConsumerWidget {
  const _InterestCard({required this.interest, required this.asOwner});

  final InterestModel interest;
  final bool asOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: Brand.danger.op(0.12), borderRadius: BorderRadius.circular(context.radius(12))),
            child: const Icon(Icons.favorite_rounded, color: Brand.danger, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(interest.listingTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                if (asOwner && interest.customerName != null)
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text('From ${interest.customerName}', style: TextStyle(fontSize: 12.5, color: context.mutedColor))),
                if (interest.message != null)
                  Padding(padding: const EdgeInsets.only(top: 6), child: Text(interest.message!, style: const TextStyle(fontSize: 13.5, height: 1.4))),
                const SizedBox(height: 6),
                Text(timeAgo(interest.createdAt), style: TextStyle(fontSize: 12, color: context.mutedColor)),
              ],
            ),
          ),
          if (!asOwner)
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close_rounded),
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: 'Remove from wishlist?',
                  message: 'The owner will no longer see your interest in this listing.',
                  confirmLabel: 'Remove',
                  danger: true,
                );
                if (!ok) return;
                try {
                  await ref.read(listingRepositoryProvider).cancelInterest(interest.id);
                  ref.invalidate(myInterestsProvider);
                  if (context.mounted) showToast(context, 'Removed');
                } catch (e) {
                  if (context.mounted) showApiError(context, e);
                }
              },
            ),
        ],
      ),
    );
  }
}
