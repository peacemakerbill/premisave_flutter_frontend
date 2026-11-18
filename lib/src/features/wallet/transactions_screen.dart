import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../state/service_providers.dart';
import 'wallet_forms.dart';

/// Transactions: everything that moved through the wallet, split by kind. Talks to the wallet service.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Tab>[Tab(text: 'All activity'), Tab(text: 'Deposits'), Tab(text: 'Transfers'), Tab(text: 'Withdrawals')],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                _ActivityTab(),
                _DepositsTab(),
                _TransfersTab(),
                _WithdrawalsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody(
      value: ref.watch(walletTransactionsProvider),
      onRetry: () => ref.invalidate(walletTransactionsProvider),
      builder: (items) => PageBody(
        maxWidth: 760,
        onRefresh: () async => ref.invalidate(walletTransactionsProvider),
        children: items.isEmpty
            ? const <Widget>[SizedBox(height: 320, child: EmptyState(icon: Icons.receipt_long_outlined, title: 'No activity yet', message: 'Deposits, payments and transfers show up here.'))]
            : <Widget>[
                for (final t in items)
                  ActivityRow(
                    title: activityTitle(t),
                    subtitle: whenLabel(t.createdAt),
                    amount: formatMoney(t.amount, t.currency),
                    credit: t.isCredit,
                    status: t.status,
                  ),
              ],
      ),
    );
  }
}

class _DepositsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody(
      value: ref.watch(depositHistoryProvider),
      onRetry: () => ref.invalidate(depositHistoryProvider),
      builder: (items) => PageBody(
        maxWidth: 760,
        onRefresh: () async => ref.invalidate(depositHistoryProvider),
        children: items.isEmpty
            ? const <Widget>[SizedBox(height: 320, child: EmptyState(icon: Icons.south_west_rounded, title: 'No deposits yet'))]
            : <Widget>[
                for (final d in items)
                  ActivityRow(
                    title: 'Deposit with ${sentence(d.provider)}',
                    subtitle: d.failureReason ?? whenLabel(d.createdAt),
                    amount: formatMoney(d.amount, d.currency),
                    credit: true,
                    status: d.status,
                  ),
              ],
      ),
    );
  }
}

class _TransfersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody(
      value: ref.watch(transferHistoryProvider),
      onRetry: () => ref.invalidate(transferHistoryProvider),
      builder: (items) => PageBody(
        maxWidth: 760,
        onRefresh: () async => ref.invalidate(transferHistoryProvider),
        children: items.isEmpty
            ? const <Widget>[SizedBox(height: 320, child: EmptyState(icon: Icons.swap_horiz_rounded, title: 'No transfers yet'))]
            : <Widget>[
                for (final t in items)
                  ActivityRow(
                    title: t.received ? 'From ${t.senderEmail ?? 'a wallet'}' : 'To ${t.recipientEmail ?? 'a wallet'}',
                    subtitle: t.failureReason ?? (t.description ?? whenLabel(t.createdAt)),
                    amount: formatMoney(t.amount, t.currency),
                    credit: t.received,
                    status: t.status,
                    icon: Icons.swap_horiz_rounded,
                  ),
              ],
      ),
    );
  }
}

class _WithdrawalsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody(
      value: ref.watch(withdrawalHistoryProvider),
      onRetry: () => ref.invalidate(withdrawalHistoryProvider),
      builder: (items) => PageBody(
        maxWidth: 760,
        onRefresh: () async => ref.invalidate(withdrawalHistoryProvider),
        children: items.isEmpty
            ? const <Widget>[SizedBox(height: 320, child: EmptyState(icon: Icons.north_east_rounded, title: 'No withdrawals yet'))]
            : <Widget>[
                for (final d in items)
                  ActivityRow(
                    title: 'Withdrawal to ${sentence(d.provider)}',
                    subtitle: d.failureReason ?? (d.destination ?? whenLabel(d.createdAt)),
                    amount: formatMoney(d.amount, d.currency),
                    credit: false,
                    status: d.status,
                  ),
              ],
      ),
    );
  }
}
