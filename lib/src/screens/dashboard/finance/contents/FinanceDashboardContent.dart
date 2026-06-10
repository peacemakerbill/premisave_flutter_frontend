import 'package:flutter/material.dart';

class FinanceDashboardContent extends StatelessWidget {
  const FinanceDashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth >= 768;
      return SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: isWide ? 36 : 20, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            const SizedBox(height: 28),
            _KpiRow(isWide: isWide),
            const SizedBox(height: 28),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _RecentTransactions()),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _CashFlowChart()),
                ],
              )
            else ...[
              _RecentTransactions(),
              const SizedBox(height: 20),
              _CashFlowChart(),
            ],
            const SizedBox(height: 20),
            _TopClients(),
          ],
        ),
      );
    });
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Finance',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A3C34),
                    letterSpacing: -0.8)),
            SizedBox(height: 3),
            Text('June 2025  ·  Q2',
                style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500)),
          ],
        ),
        _Chip(label: 'Live', dot: true),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool dot;
  const _Chip({required this.label, this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: Color(0xFF22C55E), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A))),
        ],
      ),
    );
  }
}

// ── KPI Row ──────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final bool isWide;
  const _KpiRow({required this.isWide});

  static const _kpis = [
    _KpiData('Total Revenue', 'KES 48.2M', '↑ 12% vs last Q', Icons.trending_up_rounded, true),
    _KpiData('Pending Invoices', 'KES 8.7M', '12 invoices', Icons.pending_outlined, false),
    _KpiData('Avg Collection', '18 days', '↓ 3 days', Icons.schedule_outlined, true),
    _KpiData('Net Profit', 'KES 12.4M', '↑ 8%', Icons.account_balance_wallet_outlined, true),
  ];

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        children: _kpis
            .map((k) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: k == _kpis.last ? 0 : 14),
            child: _KpiCard(data: k),
          ),
        ))
            .toList(),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 148,
      ),
      itemCount: _kpis.length,
      itemBuilder: (_, i) => _KpiCard(data: _kpis[i]),
    );
  }
}

class _KpiData {
  final String label, value, sub;
  final IconData icon;
  final bool positive;
  const _KpiData(this.label, this.value, this.sub, this.icon, this.positive);
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: Color(0xFFC9A84C), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(data.icon, size: 18, color: const Color(0xFF1A3C34)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: data.positive
                      ? const Color(0xFFECFDF3)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(data.positive ? '↑' : '↓',
                    style: TextStyle(
                        fontSize: 11,
                        color: data.positive
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(data.value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A3C34),
                  letterSpacing: -0.8),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(data.label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(data.sub,
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Recent Transactions ─────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  static const _transactions = [
    _Transaction('Karen Villa Sale', 'KES 65M', 'Completed', '2h ago', 0xFFECFDF3, 0xFF22C55E),
    _Transaction('Westlands Invoice', 'KES 2.8M', 'Pending', '5h ago', 0xFFFFFBEB, 0xFFF59E0B),
    _Transaction('Lavington Deposit', 'KES 4.5M', 'Completed', 'Yesterday', 0xFFECFDF3, 0xFF22C55E),
    _Transaction('Kilimani Commission', 'KES 920K', 'Completed', 'Yesterday', 0xFFECFDF3, 0xFF22C55E),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Recent Transactions',
      trailing: 'View all',
      child: Column(
        children: _transactions
            .map((t) => _TransactionRow(transaction: t, last: t == _transactions.last))
            .toList(),
      ),
    );
  }
}

class _Transaction {
  final String title, amount, status, time;
  final int bg, fg;
  const _Transaction(this.title, this.amount, this.status, this.time, this.bg, this.fg);
}

class _TransactionRow extends StatelessWidget {
  final _Transaction transaction;
  final bool last;
  const _TransactionRow({required this.transaction, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.payment_outlined,
                    size: 18, color: Color(0xFF1A3C34)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(transaction.title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A3C34)),
                        maxLines: 1),
                    Text(transaction.time,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF9CA3AF))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(transaction.amount,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A3C34))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(transaction.bg),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(transaction.status,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(transaction.fg))),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(height: 1, color: Color(0xFFF3EFE6), thickness: 1),
      ],
    );
  }
}

// ── Cash Flow ───────────────────────────────────────────────────────────────

class _CashFlowChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Cash Flow',
      trailing: 'This quarter',
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Cash Flow Chart Placeholder\n(Integrate fl_chart or similar)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
      ),
    );
  }
}

// ── Top Clients ─────────────────────────────────────────────────────────────

class _TopClients extends StatelessWidget {
  static const _clients = [
    _Client('Karen Realty Ltd', 'KES 18.4M', 3),
    _Client('Westlands Developers', 'KES 14.2M', 2),
    _Client('Lavington Homes', 'KES 9.8M', 4),
    _Client('Nairobi Prime Estates', 'KES 7.1M', 5),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'Top Clients',
      trailing: 'This quarter',
      child: Column(
        children: _clients
            .map((c) => _ClientRow(client: c, last: c == _clients.last))
            .toList(),
      ),
    );
  }
}

class _Client {
  final String name, revenue;
  final int deals;
  const _Client(this.name, this.revenue, this.deals);
}

class _ClientRow extends StatelessWidget {
  final _Client client;
  final bool last;
  const _ClientRow({required this.client, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFF5F0E8),
                child: Text(client.name[0],
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A3C34))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(client.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3C34))),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(client.revenue,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A3C34))),
                  Text('${client.deals} deals',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(height: 1, color: Color(0xFFF3EFE6), thickness: 1),
      ],
    );
  }
}

// ── Shared Section ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final String? trailing;
  final Widget child;
  const _Section({required this.title, this.trailing, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A3C34),
                      letterSpacing: -0.2)),
              if (trailing != null)
                Text(trailing!,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFC9A84C),
                        fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(color: Color(0xFFF3EFE6)),
          child,
        ],
      ),
    );
  }
}