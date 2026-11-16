import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../roles/role.dart';
import '../../../state/session_controller.dart';
import '../shared/overview_widgets.dart';
import 'home_owner_overview_data.dart';

/// A home owner's portfolio at a glance: who is renting, what needs attention, what is due and how income is moving.
class HomeOwnerOverview extends ConsumerWidget {
  const HomeOwnerOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final data = HomeOwnerData.sample(DateTime.now());
    return PageBody(
      bottomPadding: 48,
      children: <Widget>[
        OverviewHero(
          role: Role.homeOwner,
          user: user,
          message: 'Here is how your portfolio looks today, from rent to repairs.',
          metrics: <OverviewMetric>[
            OverviewMetric('Income', overviewShortMoney(data.monthlyIncome), 'per month'),
            OverviewMetric('Occupancy', '${data.occupancyPercent}%', '${data.rentedProperties.length} of ${data.properties.length} rented'),
            OverviewMetric('Requests', '${data.openRequests}', data.urgentRequests == 0 ? 'None urgent' : '${data.urgentRequests} urgent'),
          ],
          actions: <Widget>[
            HeroAction(label: 'My application', icon: Icons.assignment_turned_in_outlined, onPressed: () => context.push('/application')),
            HeroAction(label: 'Edit profile', icon: Icons.person_outline_rounded, filled: false, onPressed: () => context.push('/account/profile/edit')),
          ],
        ),
        OverviewBlock(title: 'Needs your attention', child: OverviewAlerts(alerts: _alerts(data))),
        OverviewBlock(
          title: 'Your properties',
          subtitle: '${plural(data.properties.length, 'property', 'properties')} in your portfolio',
          child: _Properties(data: data),
        ),
        OverviewColumns(
          left: OverviewBlock(title: 'Maintenance', child: _Maintenance(data: data)),
          right: OverviewBlock(title: 'Coming up', child: _Payments(data: data)),
        ),
        OverviewBlock(
          title: 'Rental income',
          subtitle: 'Collected rent over the last six months',
          child: OverviewBarChart(values: data.history, labels: overviewMonthsBack(data.now, data.history.length)),
        ),
        const SizedBox(height: 22),
        const SampleDataNote(message: 'These figures are sample data. Your real properties, rent and maintenance will appear here once those services are connected.'),
      ],
    );
  }

  List<OverviewAlert> _alerts(HomeOwnerData data) {
    final alerts = <OverviewAlert>[];
    for (final r in data.requests.where((r) => r.status == RequestStatus.urgent)) {
      alerts.add(OverviewAlert(
        icon: Icons.priority_high_rounded,
        tone: OverviewTone.bad,
        title: '${r.title} at ${r.property}',
        detail: 'Urgent request, reported ${timeAgo(r.at)}.',
      ));
    }
    for (final p in data.properties.where((p) => !p.rented)) {
      final days = p.vacantSince == null ? 0 : data.now.difference(p.vacantSince!).inDays;
      alerts.add(OverviewAlert(
        icon: Icons.meeting_room_outlined,
        tone: OverviewTone.warn,
        title: '${p.name} is vacant',
        detail: days <= 0 ? 'Empty since today. Check the listing is ready.' : 'Empty for ${plural(days, 'day')}. Check the listing is ready.',
      ));
    }
    for (final pay in data.payments.where((p) => !p.income)) {
      if (pay.due.difference(data.now).inDays <= 5) {
        alerts.add(OverviewAlert(
          icon: Icons.event_outlined,
          tone: OverviewTone.accent,
          title: '${pay.label} due ${overviewDueIn(data.now, pay.due)}',
          detail: '${overviewMoney(pay.amount)} for ${pay.property}.',
        ));
      }
    }
    return alerts;
  }
}

class _Properties extends StatelessWidget {
  const _Properties({required this.data});

  final HomeOwnerData data;

  @override
  Widget build(BuildContext context) {
    if (data.properties.isEmpty) {
      return const EmptyState(
        icon: Icons.home_work_outlined,
        title: 'No properties yet',
        message: 'Properties you list will appear here with their rent and tenancy.',
      );
    }
    return ResponsiveWrap(
      minItemWidth: 270,
      spacing: 14,
      maxColumns: 3,
      children: <Widget>[for (final p in data.properties) _PropertyCard(property: p, now: data.now)],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({required this.property, required this.now});

  final OwnerProperty property;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final rented = property.rented;
    final days = property.vacantSince == null ? 0 : now.difference(property.vacantSince!).inDays;
    final detail = rented
        ? 'Lease ends ${formatDate(property.leaseEnds)}'
        : (days <= 0 ? 'Vacant since today' : 'Vacant for ${plural(days, 'day')}');
    return PCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 92,
            width: double.infinity,
            color: pal.accentSoft,
            child: Stack(
              children: <Widget>[
                Center(child: Icon(Icons.home_work_outlined, size: 42, color: pal.accent.op(0.55))),
                Positioned(
                  top: 12,
                  right: 12,
                  child: StatusPill(rented ? 'Rented' : 'Vacant', color: rented ? pal.good : pal.warn, dense: true),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(property.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(property.kind, style: TextStyle(fontSize: 13, color: context.mutedColor)),
                const SizedBox(height: 14),
                Divider(height: 1, color: context.borderColor),
                const SizedBox(height: 14),
                Text(rented ? 'Monthly rent' : 'Listed rent', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: overviewMoney(property.rent),
                    style: context.display(size: 19, weight: FontWeight.w800, spacing: -0.4),
                    children: <InlineSpan>[
                      TextSpan(
                        text: '  per month',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, letterSpacing: 0, color: context.mutedColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Icon(rented ? Icons.event_available_outlined : Icons.schedule_rounded, size: 16, color: context.mutedColor),
                    const SizedBox(width: 7),
                    Expanded(child: Text(detail, style: TextStyle(fontSize: 13, color: context.mutedColor))),
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

class _Maintenance extends StatelessWidget {
  const _Maintenance({required this.data});

  final HomeOwnerData data;

  String _when(OwnerRequest r) {
    switch (r.status) {
      case RequestStatus.scheduled:
        return 'Scheduled for ${formatDate(r.at)}';
      case RequestStatus.done:
        return 'Finished ${timeAgo(r.at)}';
      case RequestStatus.urgent:
      case RequestStatus.open:
        return 'Reported ${timeAgo(r.at)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    if (data.requests.isEmpty) {
      return const EmptyState(
        icon: Icons.build_circle_outlined,
        title: 'No maintenance requests',
        message: 'Repairs and inspections for your properties will be tracked here.',
      );
    }
    return OverviewList(
      children: <Widget>[
        for (final r in data.requests)
          OverviewRow(
            leading: IconBadge(r.icon, size: 42, color: r.status.tone.color(pal)),
            title: r.title,
            subtitle: '${r.property}. ${_when(r)}',
            trailing: StatusPill(r.status.label, color: r.status.tone.color(pal), dense: true),
          ),
      ],
    );
  }
}

class _Payments extends StatelessWidget {
  const _Payments({required this.data});

  final HomeOwnerData data;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final items = List<OwnerPayment>.of(data.payments)..sort((a, b) => a.due.compareTo(b.due));
    return OverviewList(
      header: Row(
        children: <Widget>[
          Expanded(child: OverviewFigure(label: 'Money in', value: overviewMoney(data.expectedIn), color: pal.good)),
          const SizedBox(width: 12),
          Expanded(child: OverviewFigure(label: 'Money out', value: overviewMoney(data.expectedOut), color: pal.bad)),
        ],
      ),
      children: <Widget>[
        for (final p in items)
          OverviewRow(
            leading: OverviewDateBox(p.due),
            title: p.label,
            subtitle: p.property,
            trailing: OverviewTrailing(
              value: '${p.income ? '+' : '−'}${overviewMoney(p.amount)}',
              color: p.income ? pal.good : pal.bad,
            ),
          ),
      ],
    );
  }
}
