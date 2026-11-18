import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/listing_models.dart';
import '../../../data/models/property_models.dart';
import '../../../roles/role.dart';
import '../../../state/providers.dart';
import '../../../state/service_providers.dart';
import '../../../state/session_controller.dart';
import '../shared/overview_widgets.dart';

/// A home owner's portfolio at a glance, read from the property management and listing services: who is renting,
/// what needs attention, which leases end soon and how the listings are doing.
class HomeOwnerOverview extends ConsumerStatefulWidget {
  const HomeOwnerOverview({super.key});

  @override
  ConsumerState<HomeOwnerOverview> createState() => _HomeOwnerOverviewState();
}

class _HomeOwnerOverviewState extends ConsumerState<HomeOwnerOverview> {
  bool _creating = false;

  Future<void> _refresh() async {
    ref.invalidate(ownerProfileExistsProvider);
    ref.invalidate(ownerDashboardProvider);
    ref.invalidate(ownerLeasesProvider);
    ref.invalidate(myListingsProvider);
    await ref.read(ownerProfileExistsProvider.future).then<Object?>((v) => v, onError: (_) => null);
  }

  Future<void> _createProfile() async {
    setState(() => _creating = true);
    try {
      await ref.read(propertyRepositoryProvider).createOwnerProfile();
      ref.invalidate(ownerProfileExistsProvider);
      ref.invalidate(ownerDashboardProvider);
      if (mounted) showToast(context, 'Your owner profile is ready');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionProvider).user;
    final exists = ref.watch(ownerProfileExistsProvider);
    final board = ref.watch(ownerDashboardProvider);
    final leases = ref.watch(ownerLeasesProvider);
    final listings = ref.watch(myListingsProvider);
    final hasProfile = exists.valueOrNull ?? false;
    final d = board.valueOrNull;

    final heroActions = <Widget>[
      HeroAction(label: 'My listings', icon: Icons.storefront_outlined, onPressed: () => context.push('/home/listings')),
      HeroAction(label: 'Properties', icon: Icons.apartment_rounded, filled: false, onPressed: () => context.push('/home/properties')),
    ];

    if (exists.hasValue && !hasProfile) {
      return PageBody(
        bottomPadding: 48,
        onRefresh: _refresh,
        children: <Widget>[
          OverviewHero(
            role: Role.homeOwner,
            user: user,
            message: 'Set up property management to see rent, occupancy and maintenance here.',
            metrics: const <OverviewMetric>[],
            actions: heroActions,
          ),
          OverviewBlock(
            title: 'Property management',
            child: EmptyState(
              icon: Icons.apartment_rounded,
              title: 'Create your owner profile',
              message: 'Your owner profile is made from your Premisave account. It lets you add properties and units, sign leases and collect rent.',
              actionLabel: _creating ? 'Creating' : 'Create owner profile',
              onAction: _creating ? null : _createProfile,
            ),
          ),
          OverviewBlock(
            title: 'Your listings',
            child: OverviewLoad<List<ListingModel>>(
              value: listings,
              onRetry: () => ref.invalidate(myListingsProvider),
              builder: (list) => _Listings(listings: list),
            ),
          ),
        ],
      );
    }

    return PageBody(
      bottomPadding: 48,
      onRefresh: _refresh,
      children: <Widget>[
        OverviewHero(
          role: Role.homeOwner,
          user: user,
          message: 'Here is how your portfolio looks today, from rent to repairs.',
          metrics: <OverviewMetric>[
            OverviewMetric('Monthly rent', overviewFigure(board, (OwnerDashboard x) => overviewShortMoney(x.monthlyRevenue)), 'from active leases'),
            OverviewMetric(
              'Occupancy',
              overviewFigure(board, (OwnerDashboard x) => '${(x.occupancyRate * 100).round()}%'),
              board.hasValue ? '${d!.occupiedUnits} of ${plural(d.totalUnits, 'unit')} let' : '',
            ),
            OverviewMetric(
              'Requests',
              overviewFigure(board, (OwnerDashboard x) => '${x.pendingMaintenance}'),
              board.hasValue ? (d!.pendingMaintenance == 0 ? 'Nothing waiting' : 'waiting for you') : '',
            ),
          ],
          actions: heroActions,
        ),
        OverviewBlock(
          title: 'Needs your attention',
          child: _Attention(board: board, leases: leases, listings: listings),
        ),
        OverviewBlock(
          title: 'Your properties',
          subtitle: board.hasValue ? '${plural(d!.totalProperties, 'property', 'properties')} in your portfolio' : null,
          child: OverviewLoad<OwnerDashboard>(
            value: board,
            onRetry: () => ref.invalidate(ownerDashboardProvider),
            builder: (x) => _Properties(data: x),
          ),
        ),
        OverviewColumns(
          left: OverviewBlock(
            title: 'Maintenance',
            subtitle: 'Requests from your tenants',
            child: OverviewLoad<OwnerDashboard>(
              value: board,
              onRetry: () => ref.invalidate(ownerDashboardProvider),
              builder: (x) => _Maintenance(requests: x.pendingRequests),
            ),
          ),
          right: OverviewBlock(
            title: 'Leases ending soon',
            child: OverviewLoad<List<LeaseModel>>(
              value: leases,
              onRetry: () => ref.invalidate(ownerLeasesProvider),
              builder: (list) => _Leases(leases: list),
            ),
          ),
        ),
        OverviewBlock(
          title: 'Your listings',
          subtitle: 'Where your places stand with the listing service',
          child: OverviewLoad<List<ListingModel>>(
            value: listings,
            onRetry: () => ref.invalidate(myListingsProvider),
            builder: (list) => _Listings(listings: list),
          ),
        ),
      ],
    );
  }
}

class _Attention extends StatelessWidget {
  const _Attention({required this.board, required this.leases, required this.listings});

  final AsyncValue<OwnerDashboard> board;
  final AsyncValue<List<LeaseModel>> leases;
  final AsyncValue<List<ListingModel>> listings;

  @override
  Widget build(BuildContext context) {
    if (overviewWaiting(<AsyncValue<Object?>>[board, leases, listings])) {
      return const SkeletonList(count: 2, height: 84, shrink: true, padding: EdgeInsets.symmetric(vertical: 4));
    }
    final alerts = <OverviewAlert>[];
    final d = board.valueOrNull;
    if (d != null) {
      if (d.pendingMaintenance > 0) {
        alerts.add(OverviewAlert(
          icon: Icons.build_circle_outlined,
          tone: OverviewTone.warn,
          title: '${plural(d.pendingMaintenance, 'maintenance request')} waiting',
          detail: 'Open Properties, then Maintenance to start or finish them.',
        ));
      }
      final vacant = d.totalUnits - d.occupiedUnits;
      if (vacant > 0) {
        alerts.add(OverviewAlert(
          icon: Icons.meeting_room_outlined,
          tone: OverviewTone.accent,
          title: '${plural(vacant, 'unit')} vacant',
          detail: 'Make sure each has a listing so tenants can find it.',
        ));
      }
    }
    final now = DateTime.now();
    for (final l in leases.valueOrNull ?? const <LeaseModel>[]) {
      final end = l.endDate;
      if (l.status != 'ACTIVE' || end == null) continue;
      final days = end.difference(now).inDays;
      if (days >= 0 && days <= 60) {
        alerts.add(OverviewAlert(
          icon: Icons.event_outlined,
          tone: OverviewTone.accent,
          title: '${l.where} ends ${overviewDueIn(now, end)}',
          detail: 'Lease ends on ${formatDate(end)}. Talk to the tenant about renewing.',
        ));
      }
    }
    final ls = listings.valueOrNull ?? const <ListingModel>[];
    final rejected = ls.where((l) => l.status == 'REJECTED').length;
    final pending = ls.where((l) => l.status == 'PENDING').length;
    if (rejected > 0) {
      alerts.add(OverviewAlert(
        icon: Icons.report_gmailerrorred_outlined,
        tone: OverviewTone.bad,
        title: '${plural(rejected, 'listing')} rejected',
        detail: 'Open My listings to see which ones, then fix and resubmit them.',
      ));
    }
    if (pending > 0) {
      alerts.add(OverviewAlert(
        icon: Icons.hourglass_top_rounded,
        tone: OverviewTone.warn,
        title: '${plural(pending, 'listing')} awaiting approval',
        detail: 'A reviewer has not approved them yet, so the public cannot see them.',
      ));
    }
    return OverviewAlerts(alerts: alerts);
  }
}

class _Properties extends StatelessWidget {
  const _Properties({required this.data});

  final OwnerDashboard data;

  @override
  Widget build(BuildContext context) {
    if (data.occupancy.isEmpty) {
      return EmptyState(
        icon: Icons.home_work_outlined,
        title: 'No properties yet',
        message: 'Properties you add appear here with their units and how many are let.',
        actionLabel: 'Add a property',
        onAction: () => context.push('/home/properties'),
      );
    }
    return ResponsiveWrap(
      minItemWidth: 270,
      spacing: 14,
      maxColumns: 3,
      children: <Widget>[for (final p in data.occupancy) _PropertyCard(item: p)],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.item});

  final PropertyOccupancy item;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final full = item.totalUnits > 0 && item.occupiedUnits >= item.totalUnits;
    final empty = item.occupiedUnits == 0;
    final color = item.totalUnits == 0 ? pal.ink3 : (full ? pal.good : (empty ? pal.warn : pal.accent));
    final fraction = item.totalUnits == 0 ? 0.0 : (item.occupiedUnits / item.totalUnits).clamp(0.0, 1.0);
    return PCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800))),
              const SizedBox(width: 8),
              StatusPill(item.totalUnits == 0 ? 'No units' : (full ? 'Full' : (empty ? 'Vacant' : 'Partly let')), color: color, dense: true),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: fraction, minHeight: 8, color: color, backgroundColor: color.op(0.15)),
          ),
          const SizedBox(height: 10),
          Text('${item.occupiedUnits} of ${plural(item.totalUnits, 'unit')} let', style: TextStyle(fontSize: 13, color: context.mutedColor)),
        ],
      ),
    );
  }
}

class _Maintenance extends StatelessWidget {
  const _Maintenance({required this.requests});

  final List<MaintenanceModel> requests;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    if (requests.isEmpty) {
      return const EmptyState(
        icon: Icons.build_circle_outlined,
        title: 'No requests waiting',
        message: 'Repairs your tenants ask for will be listed here.',
      );
    }
    return OverviewList(
      children: <Widget>[
        for (final r in requests.take(6))
          OverviewRow(
            leading: IconBadge(Icons.build_outlined, size: 42, color: pal.warn),
            title: r.title,
            subtitle: <String?>[r.propertyTitle, r.unitNumber == null ? null : 'unit ${r.unitNumber}', r.createdAt == null ? null : timeAgo(r.createdAt)]
                .whereType<String>()
                .join(', '),
            trailing: StatusPill(sentence(r.status), color: pal.warn, dense: true),
            onTap: () => context.push('/home/properties'),
          ),
      ],
    );
  }
}

class _Leases extends StatelessWidget {
  const _Leases({required this.leases});

  final List<LeaseModel> leases;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final active = leases.where((l) => l.status == 'ACTIVE' && l.endDate != null).toList()
      ..sort((a, b) => a.endDate!.compareTo(b.endDate!));
    if (active.isEmpty) {
      return const EmptyState(
        icon: Icons.description_outlined,
        title: 'No active leases',
        message: 'Leases you sign with tenants will be listed here with their end dates.',
      );
    }
    return OverviewList(
      children: <Widget>[
        for (final l in active.take(5))
          OverviewRow(
            leading: OverviewDateBox(l.endDate!),
            title: l.where,
            subtitle: 'Ends ${overviewDueIn(DateTime.now(), l.endDate!)}',
            trailing: l.monthlyRent == null
                ? null
                : OverviewTrailing(value: overviewMoney(l.monthlyRent!), caption: 'per month', color: pal.good),
            onTap: () => context.push('/home/properties'),
          ),
      ],
    );
  }
}

class _Listings extends StatelessWidget {
  const _Listings({required this.listings});

  final List<ListingModel> listings;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    if (listings.isEmpty) {
      return EmptyState(
        icon: Icons.storefront_outlined,
        title: 'No listings yet',
        message: 'Create a listing so people can find and book your place.',
        actionLabel: 'Create a listing',
        onAction: () => context.push('/home/listings'),
      );
    }
    Color toneOf(String? s) {
      switch (s) {
        case 'REJECTED':
          return pal.bad;
        case 'PENDING':
          return pal.warn;
        default:
          return pal.good;
      }
    }

    return OverviewList(
      children: <Widget>[
        for (final l in listings.take(5))
          OverviewRow(
            leading: const IconBadge(Icons.storefront_outlined, size: 42),
            title: l.title,
            subtitle: <String>[sentence(l.category), if (l.place.isNotEmpty) l.place].join(', '),
            trailing: OverviewTrailing(
              value: l.headlinePrice == null ? '-' : overviewMoney(l.headlinePrice!, l.currency),
              badge: StatusPill(l.status == null ? 'Live' : sentence(l.status), color: toneOf(l.status), dense: true),
            ),
            onTap: () => context.push('/home/listings'),
          ),
      ],
    );
  }
}
