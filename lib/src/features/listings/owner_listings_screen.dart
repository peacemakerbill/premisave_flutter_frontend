import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/listing_models.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import 'bookings_screen.dart';
import 'explore_screen.dart';
import 'listing_form.dart';
import 'listing_widgets.dart';
import '../shared/service_widgets.dart';
import 'wishlists_screen.dart';

/// For home owners: their listings, the stays booked on them and the people interested in them.
class OwnerListingsScreen extends ConsumerWidget {
  const OwnerListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Tab>[Tab(text: 'My listings'), Tab(text: 'Bookings received'), Tab(text: 'Leads')],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _MyListings(),
                BookingsScreen(asOwner: true),
                WishlistsScreen(asOwner: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyListings extends ConsumerWidget {
  const _MyListings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody<List<ListingModel>>(
      value: ref.watch(myListingsProvider),
      onRetry: () => ref.invalidate(myListingsProvider),
      builder: (items) => PageBody(
        onRefresh: () async => ref.invalidate(myListingsProvider),
        children: items.isEmpty
            ? <Widget>[
                SizedBox(
                  height: 340,
                  child: EmptyState(
                    icon: Icons.home_work_outlined,
                    title: 'No listings yet',
                    message: 'Listings you publish are reviewed by Premisave and then appear in Explore.',
                    actionLabel: 'Create a listing',
                    onAction: () => _create(context),
                  ),
                ),
              ]
            : <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: PButton(label: 'Create a listing', icon: Icons.add_rounded, small: true, onPressed: () => _create(context)),
                ),
                const SizedBox(height: 14),
                ResponsiveWrap(
                  minItemWidth: 280,
                  children: <Widget>[
                    for (final l in items)
                      ListingCard(
                        listing: l,
                        onTap: () => showFormSheet<void>(context, title: l.title, child: ListingDetail(listing: l, readOnly: true)),
                        trailing: l.status == 'ARCHIVED'
                            ? TextButton(
                                onPressed: () => _toggle(context, ref, l, archive: false),
                                child: const Text('Unarchive'),
                              )
                            : TextButton(
                                onPressed: () => _toggle(context, ref, l, archive: true),
                                child: const Text('Archive'),
                              ),
                      ),
                  ],
                ),
              ],
      ),
    );
  }

  void _create(BuildContext context) => showFormSheet<void>(
        context,
        title: 'Create a listing',
        subtitle: 'Premisave reviews a new listing before the public can see it.',
        child: const ListingFormSheet(),
      );

  Future<void> _toggle(BuildContext context, WidgetRef ref, ListingModel l, {required bool archive}) async {
    try {
      final repo = ref.read(listingRepositoryProvider);
      if (archive) {
        await repo.archive(l.id);
      } else {
        await repo.unarchive(l.id);
      }
      ref.invalidate(myListingsProvider);
      if (context.mounted) showToast(context, archive ? 'Listing archived' : 'Listing restored');
    } catch (e) {
      if (context.mounted) showApiError(context, e);
    }
  }
}
