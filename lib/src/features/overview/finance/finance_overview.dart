import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../roles/role.dart';
import '../../../state/session_controller.dart';
import '../shared/overview_widgets.dart';
import 'finance_overview_data.dart';

/// Revenue, invoices and the clients that matter most, for the finance team.
class FinanceOverview extends ConsumerWidget {
  const FinanceOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider).user;
    final data = FinanceData.sample(DateTime.now());
    return PageBody(
      bottomPadding: 48,
      children: <Widget>[
        OverviewHero(
          role: Role.finance,
          user: user,
          message: 'Revenue, invoices and collections for this quarter.',
          metrics: <OverviewMetric>[
            OverviewMetric('Revenue', overviewShortMoney(data.quarterRevenue), 'this quarter'),
            OverviewMetric('Pending invoices', overviewShortMoney(data.pendingInvoices), plural(data.pendingInvoiceCount, 'invoice')),
            OverviewMetric('Collection time', '${data.collectionDays} days', 'on average'),
            OverviewMetric('Net profit', overviewShortMoney(data.netProfit), 'this quarter'),
          ],
        ),
        OverviewBlock(title: 'Needs your attention', child: OverviewAlerts(alerts: _alerts(data))),
        OverviewColumns(
          left: OverviewBlock(title: 'Recent transactions', child: _Transactions(data: data)),
          right: OverviewBlock(title: 'Top clients', subtitle: 'By revenue this quarter', child: _Clients(data: data)),
        ),
        OverviewBlock(
          title: 'Monthly revenue',
          subtitle: 'The last six months',
          child: OverviewBarChart(values: data.monthlyRevenue, labels: overviewMonthsBack(data.now, data.monthlyRevenue.length)),
        ),
        const SizedBox(height: 22),
        const SampleDataNote(message: 'These figures are sample data. Real revenue, invoices and clients will appear here once the finance service is connected.'),
      ],
    );
  }

  List<OverviewAlert> _alerts(FinanceData data) {
    return <OverviewAlert>[
      for (final t in data.pending)
        OverviewAlert(
          icon: Icons.hourglass_top_rounded,
          tone: OverviewTone.warn,
          title: '${t.title} is pending',
          detail: '${overviewMoney(t.amount)}, waiting since ${timeAgo(t.at)}.',
        ),
    ];
  }
}

class _Transactions extends StatelessWidget {
  const _Transactions({required this.data});

  final FinanceData data;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    if (data.transactions.isEmpty) {
      return const EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No transactions yet',
        message: 'Payments received and invoices raised will appear here.',
      );
    }
    return OverviewList(
      children: <Widget>[
        for (final t in data.transactions)
          OverviewRow(
            leading: IconBadge(
              t.state == PaymentState.completed ? Icons.check_circle_outline_rounded : Icons.hourglass_top_rounded,
              size: 42,
              color: t.state.tone.color(pal),
            ),
            title: t.title,
            subtitle: timeAgo(t.at),
            trailing: OverviewTrailing(
              value: overviewShortMoney(t.amount),
              badge: StatusPill(t.state.label, color: t.state.tone.color(pal), dense: true),
            ),
          ),
      ],
    );
  }
}

class _Clients extends StatelessWidget {
  const _Clients({required this.data});

  final FinanceData data;

  @override
  Widget build(BuildContext context) {
    return OverviewList(
      children: <Widget>[
        for (final c in data.clients)
          OverviewRow(
            leading: UserAvatar(initials: initialsOf(c.name), size: 42),
            title: c.name,
            subtitle: plural(c.deals, 'deal'),
            trailing: OverviewTrailing(value: overviewShortMoney(c.revenue)),
          ),
      ],
    );
  }
}
