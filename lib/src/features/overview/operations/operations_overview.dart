import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../roles/role.dart';
import '../../../state/session_controller.dart';
import '../shared/overview_widgets.dart';
import 'operations_overview_data.dart';

/// Listings, deals and agent results, for the operations team.
class OperationsOverview extends ConsumerWidget {
  const OperationsOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final data = OperationsData.sample(DateTime.now());
    return PageBody(
      bottomPadding: 48,
      children: <Widget>[
        OverviewHero(
          role: Role.operations,
          user: user,
          message: 'Listings, offers and agent results across the platform.',
          metrics: <OverviewMetric>[
            OverviewMetric('Active listings', '${data.activeListings}', 'on the market'),
            OverviewMetric('Deals closed', '${data.dealsClosed}', 'this quarter'),
            OverviewMetric('Revenue', overviewShortMoney(data.revenue), 'this quarter'),
            OverviewMetric('Days on market', '${data.daysOnMarket}', 'on average'),
          ],
        ),
        OverviewBlock(title: 'Needs your attention', child: OverviewAlerts(alerts: _alerts(data))),
        OverviewColumns(
          left: OverviewBlock(title: 'Recent listings', child: _Listings(data: data)),
          right: OverviewBlock(title: 'Activity', child: _Activity(data: data)),
        ),
        OverviewBlock(title: 'Agent performance', subtitle: 'Deals and revenue this quarter', child: _Agents(data: data)),
        const SizedBox(height: 22),
        const SampleDataNote(message: 'These figures are sample data. Real listings, offers and agent results will appear here once the listing service is connected.'),
      ],
    );
  }

  List<OverviewAlert> _alerts(OperationsData data) {
    final alerts = <OverviewAlert>[];
    for (final l in data.listings.where((l) => l.status == ListingStatus.underOffer)) {
      alerts.add(OverviewAlert(
        icon: Icons.local_offer_outlined,
        tone: OverviewTone.warn,
        title: '${l.name} is under offer',
        detail: 'Follow up with the buyer. Listed ${plural(data.daysListed(l), 'day')} ago.',
      ));
    }
    for (final l in data.listings.where((l) => l.status == ListingStatus.forSale && data.daysListed(l) > data.daysOnMarket)) {
      alerts.add(OverviewAlert(
        icon: Icons.schedule_rounded,
        tone: OverviewTone.accent,
        title: '${l.name} is slow to sell',
        detail: 'On the market for ${plural(data.daysListed(l), 'day')}, above the ${data.daysOnMarket} day average. Consider a price review.',
      ));
    }
    return alerts;
  }
}

class _Listings extends StatelessWidget {
  const _Listings({required this.data});

  final OperationsData data;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    if (data.listings.isEmpty) {
      return const EmptyState(
        icon: Icons.home_work_outlined,
        title: 'No listings yet',
        message: 'Published listings will appear here.',
      );
    }
    return OverviewList(
      children: <Widget>[
        for (final l in data.listings)
          OverviewRow(
            leading: const IconBadge(Icons.home_work_outlined, size: 42),
            title: l.name,
            subtitle: '${l.place}. Listed ${timeAgo(l.listedAt)}',
            trailing: OverviewTrailing(
              value: overviewShortMoney(l.price),
              badge: StatusPill(l.status.label, color: l.status.tone.color(pal), dense: true),
            ),
          ),
      ],
    );
  }
}

class _Activity extends StatelessWidget {
  const _Activity({required this.data});

  final OperationsData data;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return OverviewList(
      children: <Widget>[
        for (final e in data.events)
          OverviewRow(
            leading: IconBadge(e.icon, size: 42, color: e.tone.color(pal)),
            title: e.title,
            subtitle: e.detail,
            trailing: Text(timeAgo(e.at), style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
          ),
      ],
    );
  }
}

class _Agents extends StatelessWidget {
  const _Agents({required this.data});

  final OperationsData data;

  @override
  Widget build(BuildContext context) {
    return OverviewList(
      children: <Widget>[
        for (final a in data.agents)
          OverviewRow(
            leading: UserAvatar(initials: initialsOf(a.name), size: 42),
            title: a.name,
            subtitle: a.role,
            trailing: OverviewTrailing(value: overviewShortMoney(a.revenue), caption: plural(a.deals, 'deal')),
          ),
      ],
    );
  }
}
