import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/listing_models.dart';
import '../../../roles/role.dart';
import '../../../state/overview_providers.dart';
import '../../../state/service_providers.dart';
import '../../../state/session_controller.dart';
import '../shared/overview_widgets.dart';

/// A client's stays, saved places and featured properties, read from the listing service.
class ClientOverview extends ConsumerWidget {
  const ClientOverview({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(myBookingsProvider);
    ref.invalidate(myInterestsProvider);
    ref.invalidate(liveListingsProvider);
    await ref.read(myBookingsProvider.future).then<Object?>((v) => v, onError: (_) => null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final bookings = ref.watch(myBookingsProvider);
    final saved = ref.watch(myInterestsProvider);
    final live = ref.watch(liveListingsProvider);
    final now = DateTime.now();

    final stays = bookings.valueOrNull == null ? const <BookingModel>[] : _upcoming(bookings.value!, now);
    final next = stays.isEmpty ? null : _daysUntil(now, stays.first.checkIn);

    return PageBody(
      bottomPadding: 48,
      onRefresh: () => _refresh(ref),
      children: <Widget>[
        OverviewHero(
          role: Role.client,
          user: user,
          message: 'Your stays, saved places and payments in one view.',
          metrics: <OverviewMetric>[
            OverviewMetric(
              'Upcoming stays',
              overviewFigure(bookings, (List<BookingModel> _) => '${stays.length}'),
              bookings.hasValue ? (next == null ? 'Nothing booked' : (next <= 0 ? 'Next one starts today' : 'Next in ${plural(next, 'day')}')) : '',
              onTap: () => context.go('/bookings'),
            ),
            OverviewMetric('Saved places', overviewFigure(saved, (List<InterestModel> l) => '${l.length}'), 'in your wishlist', onTap: () => context.go('/bookings?tab=saved')),
            OverviewMetric(
              'Total spent',
              overviewFigure(bookings, (List<BookingModel> l) => _spent(l).value),
              bookings.hasValue ? _spent(bookings.value!).caption : '',
              onTap: () => context.go('/wallet?tab=history'),
            ),
          ],
          actions: <Widget>[
            HeroAction(label: 'Browse properties', icon: Icons.search_rounded, onPressed: () => context.go('/explore')),
            HeroAction(label: 'My bookings', icon: Icons.event_available_outlined, filled: false, onPressed: () => context.go('/bookings')),
          ],
        ),
        OverviewColumns(
          left: OverviewBlock(
            title: 'Upcoming stays',
            child: OverviewLoad<List<BookingModel>>(
              value: bookings,
              onRetry: () => ref.invalidate(myBookingsProvider),
              builder: (_) => _Stays(stays: stays),
            ),
          ),
          right: OverviewBlock(
            title: 'Quick actions',
            child: _Shortcuts(
              saved: saved.valueOrNull?.length,
              upcoming: bookings.hasValue ? stays.length : null,
            ),
          ),
        ),
        OverviewBlock(
          title: 'Featured properties',
          subtitle: 'Promoted by their owners right now',
          child: OverviewLoad<List<ListingModel>>(
            value: live,
            onRetry: () => ref.invalidate(liveListingsProvider),
            builder: (list) => _Featured(listings: list.take(8).toList()),
          ),
        ),
      ],
    );
  }

  /// Bookings that are paid or waiting for the host and have not ended yet, soonest first.
  static List<BookingModel> _upcoming(List<BookingModel> all, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final list = all.where((b) {
      if (b.status != 'CONFIRMED' && b.status != 'PENDING') return false;
      final end = b.checkOut ?? b.checkIn;
      return end != null && !DateTime(end.year, end.month, end.day).isBefore(today);
    }).toList()
      ..sort((a, b) => (a.checkIn ?? DateTime(9999)).compareTo(b.checkIn ?? DateTime(9999)));
    return list;
  }

  static int? _daysUntil(DateTime now, DateTime? date) {
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  /// What the person paid for stays that went ahead, in the currency they paid in. When bookings used more than one
  /// currency the biggest total is shown and the caption says there are others.
  static ({String value, String caption}) _spent(List<BookingModel> all) {
    final totals = <String, double>{};
    for (final b in all) {
      if (b.status != 'CONFIRMED' && b.status != 'COMPLETED') continue;
      totals[b.currency] = (totals[b.currency] ?? 0) + (b.totalAmount ?? 0);
    }
    if (totals.isEmpty) return (value: overviewShortMoney(0), caption: 'on stays');
    final top = totals.entries.reduce((a, b) => a.value >= b.value ? a : b);
    return (
      value: overviewShortMoney(top.value, top.key),
      caption: totals.length > 1 ? 'on stays, plus other currencies' : 'on stays',
    );
  }
}

class _Stays extends ConsumerWidget {
  const _Stays({required this.stays});

  final List<BookingModel> stays;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    if (stays.isEmpty) {
      return EmptyState(
        icon: Icons.event_available_outlined,
        title: 'No upcoming stays',
        message: 'Find a place you like and book it. It will show up here.',
        actionLabel: 'Browse properties',
        onAction: () => context.go('/explore'),
      );
    }
    return OverviewList(
      children: <Widget>[
        for (final b in stays.take(5))
          OverviewRow(
            leading: const IconBadge(Icons.home_outlined, size: 42),
            title: ref.watch(listingTitleProvider(b.listingId)).valueOrNull ?? 'Your stay',
            subtitle: '${formatDate(b.checkIn)} to ${formatDate(b.checkOut)}',
            trailing: OverviewTrailing(
              value: b.totalAmount == null ? '-' : overviewMoney(b.totalAmount!, b.currency),
              badge: StatusPill(b.status == 'CONFIRMED' ? 'Confirmed' : 'Waiting for host', color: b.status == 'CONFIRMED' ? pal.good : pal.warn, dense: true),
            ),
            onTap: () => context.go('/bookings'),
          ),
      ],
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.saved, required this.upcoming});

  final int? saved;
  final int? upcoming;

  @override
  Widget build(BuildContext context) {
    Widget chevron() => Icon(Icons.chevron_right_rounded, color: context.mutedColor);
    return OverviewList(
      children: <Widget>[
        OverviewRow(
          leading: const IconBadge(Icons.search_rounded, size: 42),
          title: 'Browse properties',
          subtitle: 'Find your next stay',
          trailing: chevron(),
          onTap: () => context.go('/explore'),
        ),
        OverviewRow(
          leading: const IconBadge(Icons.favorite_border_rounded, size: 42),
          title: 'My wishlist',
          subtitle: saved == null ? 'Places you saved' : plural(saved!, 'saved property', 'saved properties'),
          trailing: chevron(),
          onTap: () => context.go('/bookings'),
        ),
        OverviewRow(
          leading: const IconBadge(Icons.calendar_month_outlined, size: 42),
          title: 'Manage bookings',
          subtitle: upcoming == null ? 'Your stays' : '$upcoming upcoming',
          trailing: chevron(),
          onTap: () => context.go('/bookings'),
        ),
        OverviewRow(
          leading: const IconBadge(Icons.account_balance_wallet_outlined, size: 42),
          title: 'My wallet',
          subtitle: 'Balance, deposits and history',
          trailing: chevron(),
          onTap: () => context.go('/wallet'),
        ),
      ],
    );
  }
}

class _Featured extends StatelessWidget {
  const _Featured({required this.listings});

  final List<ListingModel> listings;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return EmptyState(
        icon: Icons.home_work_outlined,
        title: 'Nothing featured yet',
        message: 'Properties their owners promote will appear here.',
        actionLabel: 'Browse properties',
        onAction: () => context.go('/explore'),
      );
    }
    return SizedBox(
      height: 272,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: listings.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => SizedBox(width: 250, child: _FeaturedCard(listing: listings[i])),
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.listing});

  final ListingModel listing;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final cover = listing.cover;
    final price = listing.headlinePrice;
    return PCard(
      padding: EdgeInsets.zero,
      onTap: () => context.go('/explore'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 150,
            width: double.infinity,
            child: cover == null
                ? _noPhoto(pal)
                : Image.network(cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _noPhoto(pal)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(listing.place.isEmpty ? sentence(listing.category) : listing.place,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: context.mutedColor)),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    text: price == null ? 'Price on request' : formatMoney(price, listing.currency),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    children: <InlineSpan>[
                      if (price != null && listing.priceLabel.isNotEmpty)
                        TextSpan(text: ' / ${listing.priceLabel}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: context.mutedColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _noPhoto(AppPalette pal) => Container(
        color: pal.accentSoft,
        alignment: Alignment.center,
        child: Icon(Icons.home_work_outlined, size: 40, color: pal.accent.op(0.55)),
      );
}
