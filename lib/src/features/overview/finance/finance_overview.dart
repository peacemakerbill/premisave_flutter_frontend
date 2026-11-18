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

/// Revenue, money held and payments that need a person, for the finance team. The figures come from the wallet
/// service's admin finance reports and the listing service's bookings that need review.
class FinanceOverview extends ConsumerWidget {
  const FinanceOverview({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(financeWeekProvider);
    ref.invalidate(balanceOverviewProvider);
    ref.invalidate(latestDepositsProvider);
    ref.invalidate(bookingsNeedingReviewProvider);
    await ref.read(financeWeekProvider.future).then<Object?>((v) => v, onError: (_) => null);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final week = ref.watch(financeWeekProvider);
    final balances = ref.watch(balanceOverviewProvider);
    final deposits = ref.watch(latestDepositsProvider);
    final review = ref.watch(bookingsNeedingReviewProvider);

    return PageBody(
      bottomPadding: 48,
      onRefresh: () => _refresh(ref),
      children: <Widget>[
        OverviewHero(
          role: Role.finance,
          user: user,
          message: 'Revenue, held money and payments that need a person.',
          metrics: <OverviewMetric>[
            OverviewMetric('Revenue today', overviewFigure(week, (List<DailyFinance> w) => overviewShortMoney(w.last.revenue)), 'commission and fees'),
            OverviewMetric('This week', overviewFigure(week, (List<DailyFinance> w) => overviewShortMoney(w.fold<double>(0, (s, d) => s + d.revenue))), 'revenue, 7 days'),
            OverviewMetric('Held for users', overviewFigure(balances, (BalanceOverview b) => overviewShortMoney(b.liability)), 'wallets and escrow'),
            OverviewMetric('Need review', overviewFigure(review, (({int total, List<BookingModel> items}) r) => '${r.total}'), 'bookings'),
          ],
          actions: <Widget>[
            HeroAction(label: 'Applications', icon: Icons.assignment_outlined, onPressed: () => context.go('/staff')),
            HeroAction(label: 'M-Pesa lookup', icon: Icons.person_search_outlined, filled: false, onPressed: () => context.push('/home/lookup')),
          ],
        ),
        OverviewBlock(title: 'Needs your attention', child: _Attention(week: week, balances: balances, review: review)),
        OverviewBlock(
          title: 'Revenue',
          subtitle: 'Commission on transfers and withdrawals plus payments to Premisave, last seven days',
          child: OverviewLoad<List<DailyFinance>>(
            value: week,
            onRetry: () => ref.invalidate(financeWeekProvider),
            rows: 2,
            builder: (w) => OverviewBarChart(
              values: <num>[for (final d in w) d.revenue],
              labels: <String>[for (final d in w) d.date == null ? '' : overviewWeekday(d.date!)],
            ),
          ),
        ),
        OverviewColumns(
          left: OverviewBlock(
            title: 'Latest deposits',
            subtitle: 'Across every wallet',
            child: OverviewLoad<List<AdminDeposit>>(
              value: deposits,
              onRetry: () => ref.invalidate(latestDepositsProvider),
              builder: (list) => _Deposits(deposits: list),
            ),
          ),
          right: OverviewBlock(
            title: 'Largest wallets',
            subtitle: 'By balance, for risk checks',
            child: OverviewLoad<BalanceOverview>(
              value: balances,
              onRetry: () => ref.invalidate(balanceOverviewProvider),
              builder: (b) => _Wallets(overview: b),
            ),
          ),
        ),
      ],
    );
  }
}

class _Attention extends StatelessWidget {
  const _Attention({required this.week, required this.balances, required this.review});

  final AsyncValue<List<DailyFinance>> week;
  final AsyncValue<BalanceOverview> balances;
  final AsyncValue<({int total, List<BookingModel> items})> review;

  @override
  Widget build(BuildContext context) {
    if (overviewWaiting(<AsyncValue<Object?>>[week, balances, review])) {
      return const SkeletonList(count: 2, height: 84, shrink: true, padding: EdgeInsets.symmetric(vertical: 4));
    }
    final alerts = <OverviewAlert>[];
    final r = review.valueOrNull;
    if (r != null && r.total > 0) {
      alerts.add(OverviewAlert(
        icon: Icons.fact_check_outlined,
        tone: OverviewTone.bad,
        title: '${plural(r.total, 'booking')} need review',
        detail: 'A payment or payout on them did not finish. Check each one, then retry the payout or resolve the payment.',
      ));
    }
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
          detail: 'The payment provider has not confirmed them yet.',
        ));
      }
    }
    final b = balances.valueOrNull;
    if (b != null && b.frozenWalletCount > 0) {
      alerts.add(OverviewAlert(
        icon: Icons.ac_unit_rounded,
        tone: OverviewTone.warn,
        title: '${plural(b.frozenWalletCount, 'wallet')} frozen',
        detail: '${overviewMoney(b.frozenBalance)} is locked until they are unfrozen.',
      ));
    }
    return OverviewAlerts(alerts: alerts, allClearMessage: 'All clear. No payments need your attention right now.');
  }
}

class _Deposits extends StatelessWidget {
  const _Deposits({required this.deposits});

  final List<AdminDeposit> deposits;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    if (deposits.isEmpty) {
      return const EmptyState(icon: Icons.receipt_long_outlined, title: 'No deposits yet', message: 'Money people add to their wallets will appear here.');
    }
    Color toneOf(String status) {
      switch (status) {
        case 'SUCCESS':
          return pal.good;
        case 'FAILED':
          return pal.bad;
        default:
          return pal.warn;
      }
    }

    String labelOf(String status) {
      switch (status) {
        case 'SUCCESS':
          return 'Completed';
        case 'FAILED':
          return 'Failed';
        default:
          return 'Pending';
      }
    }

    return OverviewList(
      children: <Widget>[
        for (final d in deposits)
          OverviewRow(
            leading: IconBadge(
              d.status == 'SUCCESS' ? Icons.check_circle_outline_rounded : (d.status == 'FAILED' ? Icons.error_outline_rounded : Icons.hourglass_top_rounded),
              size: 42,
              color: toneOf(d.status),
            ),
            title: 'Deposit by ${sentence(d.provider)}',
            subtitle: d.createdAt == null ? '' : timeAgo(d.createdAt),
            trailing: OverviewTrailing(
              value: overviewMoney(d.amount, d.currency),
              badge: StatusPill(labelOf(d.status), color: toneOf(d.status), dense: true),
            ),
          ),
      ],
    );
  }
}

class _Wallets extends StatelessWidget {
  const _Wallets({required this.overview});

  final BalanceOverview overview;

  @override
  Widget build(BuildContext context) {
    return OverviewList(
      header: Row(
        children: <Widget>[
          Expanded(child: OverviewFigure(label: 'Wallets', value: '${overview.walletCount}', color: context.pal.accent)),
          const SizedBox(width: 12),
          Expanded(child: OverviewFigure(label: 'Average balance', value: overviewMoney(overview.averageBalance), color: context.pal.good)),
        ],
      ),
      children: <Widget>[
        if (overview.topWallets.isEmpty)
          const OverviewRow(leading: IconBadge(Icons.account_balance_wallet_outlined, size: 42), title: 'No wallets yet'),
        for (final w in overview.topWallets)
          OverviewRow(
            leading: UserAvatar(initials: initialsOf(w.accountNumber), size: 42),
            title: w.accountNumber,
            trailing: OverviewTrailing(value: overviewMoney(w.balance)),
          ),
      ],
    );
  }
}
