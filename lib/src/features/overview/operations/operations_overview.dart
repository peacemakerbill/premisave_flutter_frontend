import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/listing_models.dart';
import '../../../data/models/wallet_models.dart';
import '../../../roles/role.dart';
import '../../../state/overview_providers.dart';
import '../../../state/session_controller.dart';
import '../shared/overview_widgets.dart';

/// What is live on the platform and how money is moving, for the operations team. Listings come from the listing
/// service and the payment figures from the wallet service's daily finance report.
class OperationsOverview extends ConsumerWidget {
  const OperationsOverview({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(liveListingsProvider);
    ref.invalidate(financeWeekProvider);
    await ref.read(financeWeekProvider.future).then<Object?>((v) => v, onError: (_) => null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final live = ref.watch(liveListingsProvider);
    final week = ref.watch(financeWeekProvider);
    final today = week.valueOrNull == null ? null : week.value!.last;

    return PageBody(
      bottomPadding: 48,
      onRefresh: () => _refresh(ref),
      children: <Widget>[
        OverviewHero(
          role: Role.operations,
          user: user,
          message: 'Live listings and today\'s payments across the platform.',
          metrics: <OverviewMetric>[
            OverviewMetric('Live listings', overviewFigure(live, (List<ListingModel> l) => '${l.length}'), 'visible to the public'),
            OverviewMetric('Payments today', overviewFigure(week, (List<DailyFinance> w) => '${w.last.transactionCount}'), 'deposits, withdrawals, transfers'),
            OverviewMetric('Waiting', overviewFigure(week, (List<DailyFinance> w) => '${w.last.pending}'), 'with a payment provider'),
            OverviewMetric('Failed', overviewFigure(week, (List<DailyFinance> w) => '${w.last.failed}'), 'today'),
          ],
          actions: <Widget>[
            HeroAction(label: 'Applications', icon: Icons.assignment_outlined, onPressed: () => context.go('/staff')),
            HeroAction(label: 'M-Pesa lookup', icon: Icons.person_search_outlined, filled: false, onPressed: () => context.push('/home/lookup')),
          ],
        ),
        OverviewBlock(title: 'Needs your attention', child: _Attention(live: live, week: week)),
        OverviewColumns(
          left: OverviewBlock(
            title: 'Newest listings',
            subtitle: 'Promoted listings the public can see',
            child: OverviewLoad<List<ListingModel>>(
              value: live,
              onRetry: () => ref.invalidate(liveListingsProvider),
              builder: (list) => _Listings(listings: list),
            ),
          ),
          right: OverviewBlock(
            title: 'Money today',
            subtitle: 'From the wallet service',
            child: OverviewLoad<List<DailyFinance>>(
              value: week,
              onRetry: () => ref.invalidate(financeWeekProvider),
              builder: (w) => _Today(day: w.last),
            ),
          ),
        ),
        OverviewBlock(
          title: 'Listings by category',
          child: OverviewLoad<List<ListingModel>>(
            value: live,
            onRetry: () => ref.invalidate(liveListingsProvider),
            builder: (list) => _Categories(listings: list),
          ),
        ),
        OverviewBlock(
          title: 'Payments per day',
          subtitle: 'The last seven days',
          child: OverviewLoad<List<DailyFinance>>(
            value: week,
            onRetry: () => ref.invalidate(financeWeekProvider),
            rows: 2,
            builder: (w) => OverviewBarChart(
              values: <num>[for (final d in w) d.transactionCount],
              labels: <String>[for (final d in w) d.date == null ? '' : overviewWeekday(d.date!)],
              tooltip: (n) => plural(n.toInt(), 'payment'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Attention extends StatelessWidget {
  const _Attention({required this.live, required this.week});

  final AsyncValue<List<ListingModel>> live;
  final AsyncValue<List<DailyFinance>> week;

  @override
  Widget build(BuildContext context) {
    if (overviewWaiting(<AsyncValue<Object?>>[live, week])) {
      return const SkeletonList(count: 2, height: 84, shrink: true, padding: EdgeInsets.symmetric(vertical: 4));
    }
    final alerts = <OverviewAlert>[];
    final w = week.valueOrNull;
    if (w != null) {
      final today = w.last;
      if (today.failed > 0) {
        alerts.add(OverviewAlert(
          icon: Icons.error_outline_rounded,
          tone: OverviewTone.bad,
          title: '${plural(today.failed, 'payment')} failed today',
          detail: '${today.failedDeposits} deposits and ${today.failedDisbursements} withdrawals did not go through.',
        ));
      }
      if (today.pending > 0) {
        alerts.add(OverviewAlert(
          icon: Icons.hourglass_top_rounded,
          tone: OverviewTone.warn,
          title: '${plural(today.pending, 'payment')} still waiting',
          detail: 'The payment provider has not confirmed them yet. Check again later.',
        ));
      }
    }
    final l = live.valueOrNull;
    if (l != null && l.isEmpty) {
      alerts.add(const OverviewAlert(
        icon: Icons.home_work_outlined,
        tone: OverviewTone.warn,
        title: 'No listings are visible to the public',
        detail: 'Owners need to promote a listing before it shows in search.',
      ));
    }
    return OverviewAlerts(alerts: alerts);
  }
}

class _Listings extends StatelessWidget {
  const _Listings({required this.listings});

  final List<ListingModel> listings;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const EmptyState(
        icon: Icons.home_work_outlined,
        title: 'No live listings',
        message: 'Promoted listings will appear here.',
      );
    }
    return OverviewList(
      children: <Widget>[
        for (final l in listings.take(6))
          OverviewRow(
            leading: const IconBadge(Icons.home_work_outlined, size: 42),
            title: l.title,
            subtitle: <String>[sentence(l.category), if (l.place.isNotEmpty) l.place, if (l.createdAt != null) 'listed ${timeAgo(l.createdAt)}'].join(', '),
            trailing: OverviewTrailing(
              value: l.headlinePrice == null ? '-' : overviewShortMoney(l.headlinePrice!, l.currency),
              caption: l.priceLabel.isEmpty ? null : 'per ${l.priceLabel}',
            ),
          ),
      ],
    );
  }
}

class _Today extends StatelessWidget {
  const _Today({required this.day});

  final DailyFinance day;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    Widget row(IconData icon, String title, int count, double total, Color color) => OverviewRow(
          leading: IconBadge(icon, size: 42, color: color),
          title: title,
          subtitle: plural(count, 'payment'),
          trailing: OverviewTrailing(value: overviewShortMoney(total)),
        );
    return OverviewList(
      children: <Widget>[
        row(Icons.south_west_rounded, 'Deposits', day.depositCount, day.depositTotal, pal.good),
        row(Icons.north_east_rounded, 'Withdrawals', day.disbursementCount, day.disbursementTotal, pal.warn),
        row(Icons.swap_horiz_rounded, 'Transfers', day.transferCount, day.transferTotal, pal.accent),
        row(Icons.receipt_long_outlined, 'Payments to Premisave', day.paymentCount, day.paymentTotal, pal.accent),
      ],
    );
  }
}

class _Categories extends StatelessWidget {
  const _Categories({required this.listings});

  final List<ListingModel> listings;

  @override
  Widget build(BuildContext context) {
    if (listings.isEmpty) {
      return const EmptyState(icon: Icons.category_outlined, title: 'Nothing to count yet', message: 'Live listings are grouped by category here.');
    }
    final counts = <String, int>{};
    for (final l in listings) {
      counts[l.category] = (counts[l.category] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return OverviewList(
      children: <Widget>[
        for (final e in entries)
          OverviewRow(
            leading: const IconBadge(Icons.category_outlined, size: 42),
            title: e.key.isEmpty ? 'Other' : sentence(e.key),
            subtitle: '${(e.value * 100 / listings.length).round()}% of live listings',
            trailing: OverviewTrailing(value: '${e.value}'),
          ),
      ],
    );
  }
}
