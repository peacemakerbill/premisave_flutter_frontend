import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../roles/role.dart';
import '../../../state/session_controller.dart';
import '../../properties/widgets/property_details_dialog.dart';
import '../shared/overview_widgets.dart';
import 'client_overview_data.dart';

/// A client's stays, saved places and shortcuts into the rest of the app.
class ClientOverview extends ConsumerWidget {
  const ClientOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final data = ClientData.sample(DateTime.now());
    final next = data.daysToNextStay;
    return PageBody(
      bottomPadding: 48,
      children: <Widget>[
        OverviewHero(
          role: Role.client,
          user: user,
          message: 'Your stays, saved places and payments in one view.',
          metrics: <OverviewMetric>[
            OverviewMetric(
              'Upcoming stays',
              '${data.stays.length}',
              next == null ? 'Nothing booked' : (next <= 0 ? 'Next one starts today' : 'Next in ${plural(next, 'day')}'),
            ),
            OverviewMetric('Saved places', '${data.savedCount}', 'in your wishlists'),
            OverviewMetric('Total spent', overviewShortMoney(data.totalSpent), 'on stays'),
          ],
          actions: <Widget>[
            HeroAction(label: 'Browse properties', icon: Icons.search_rounded, onPressed: () => context.go('/explore')),
            HeroAction(label: 'My bookings', icon: Icons.event_available_outlined, filled: false, onPressed: () => context.push('/home/bookings')),
          ],
        ),
        OverviewColumns(
          left: OverviewBlock(title: 'Upcoming stays', child: _Stays(data: data)),
          right: OverviewBlock(title: 'Quick actions', child: _Shortcuts(data: data)),
        ),
        OverviewBlock(
          title: 'Trending properties',
          subtitle: 'Popular with other guests right now',
          child: _Trending(data: data),
        ),
        const SizedBox(height: 22),
        const SampleDataNote(message: 'These figures are sample data. Your real bookings, saved places and payments will appear here once those services are connected.'),
      ],
    );
  }
}

class _Stays extends StatelessWidget {
  const _Stays({required this.data});

  final ClientData data;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    if (data.stays.isEmpty) {
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
        for (final s in data.stays)
          OverviewRow(
            leading: const IconBadge(Icons.home_outlined, size: 42),
            title: s.property,
            subtitle: '${s.place}, ${plural(s.nights, 'night')}\n${formatDate(s.start)} to ${formatDate(s.end)}',
            trailing: OverviewTrailing(
              value: overviewMoney(s.total),
              badge: StatusPill('Confirmed', color: pal.good, dense: true),
            ),
          ),
      ],
    );
  }
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.data});

  final ClientData data;

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
          title: 'My wishlists',
          subtitle: plural(data.savedCount, 'saved property', 'saved properties'),
          trailing: chevron(),
          onTap: () => context.push('/home/wishlists'),
        ),
        OverviewRow(
          leading: const IconBadge(Icons.calendar_month_outlined, size: 42),
          title: 'Manage bookings',
          subtitle: '${data.stays.length} upcoming',
          trailing: chevron(),
          onTap: () => context.push('/home/bookings'),
        ),
      ],
    );
  }
}

class _Trending extends StatelessWidget {
  const _Trending({required this.data});

  final ClientData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 272,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: data.trending.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => SizedBox(width: 250, child: _TrendingCard(property: data.trending[i])),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.property});

  final TrendingProperty property;

  void _open(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => PropertyDetailsDialog(
        property: <String, dynamic>{
          'title': property.title,
          'location': property.location,
          'dailyPrice': overviewMoney(property.nightly),
          'monthlyPrice': overviewMoney(property.nightly * 30),
          'rating': property.rating,
          'image': property.image,
          'type': 'Villa',
          'badge': 'Trending',
        },
        rentalType: 'daily',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return PCard(
      padding: EdgeInsets.zero,
      onTap: () => _open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 150,
            width: double.infinity,
            child: Image.network(
              property.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: pal.accentSoft,
                alignment: Alignment.center,
                child: Icon(Icons.home_work_outlined, size: 40, color: pal.accent.op(0.55)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(property.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(property.location, style: TextStyle(fontSize: 13, color: context.mutedColor)),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: overviewMoney(property.nightly),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                          children: <InlineSpan>[
                            TextSpan(text: ' / night', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: context.mutedColor)),
                          ],
                        ),
                      ),
                    ),
                    Icon(Icons.star_rounded, size: 17, color: pal.warn),
                    const SizedBox(width: 3),
                    Text('${property.rating}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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
