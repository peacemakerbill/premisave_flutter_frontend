import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class ClientTransactionsContent extends StatelessWidget {
  const ClientTransactionsContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 36, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderSection(),
          const SizedBox(height: 28),
          const _TransactionStats(),
          const SizedBox(height: 28),
          const _RecentTransactions(),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.8),
                ),
                const SizedBox(height: 6),
                Text(
                  'View all your payment history',
                  style: TextStyle(fontSize: 14, color: _slate),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _stone, shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: _brand, size: 28),
          ),
        ],
      ),
    );
  }
}

class _TransactionStats extends StatelessWidget {
  const _TransactionStats();

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 600;

    final stats = [
      {'title': 'Total Spent', 'value': 'KES 450,000', 'color': Colors.green, 'icon': Icons.payments_rounded},
      {'title': 'This Month', 'value': 'KES 85,000', 'color': Colors.blue, 'icon': Icons.calendar_month_rounded},
      {'title': 'Pending', 'value': 'KES 25,000', 'color': Colors.orange, 'icon': Icons.pending_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transaction Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isSmall ? 2 : 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.75,
          ),
          itemCount: stats.length,
          itemBuilder: (context, index) => _StatCard(stat: stats[index]),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Map<String, dynamic> stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final color = stat['color'] as Color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: const Border(left: BorderSide(color: _gold, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat['icon'] as IconData, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            stat['value'] as String,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _brand),
          ),
          Text(
            stat['title'] as String,
            style: const TextStyle(fontSize: 11.5, color: _slate),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 8),
        Text('Last 5 transactions', style: TextStyle(fontSize: 13, color: _slate)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAE6DE)),
          ),
          child: Column(
            children: _transactions.map((txn) => _TransactionItem(transaction: txn)).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download Statement'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _brand,
              side: const BorderSide(color: _brand),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  final List<Map<String, dynamic>> _transactions = const [
    {'id': '#TRX-001', 'property': 'Modern Apartment', 'date': '15 Dec 2024', 'amount': 'KES 42,500', 'status': 'Completed'},
    {'id': '#TRX-002', 'property': 'Luxury Villa', 'date': '10 Dec 2024', 'amount': 'KES 175,000', 'status': 'Completed'},
    {'id': '#TRX-003', 'property': 'Mountain Cabin', 'date': '5 Dec 2024', 'amount': 'KES 60,000', 'status': 'Pending'},
    {'id': '#TRX-004', 'property': 'City Studio', 'date': '28 Nov 2024', 'amount': 'KES 32,500', 'status': 'Completed'},
    {'id': '#TRX-005', 'property': 'Beach House', 'date': '15 Nov 2024', 'amount': 'KES 105,000', 'status': 'Refunded'},
  ];
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  const _TransactionItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getStatusInfo(transaction['status'] as String);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3EFE6))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction['property'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: _brand)),
                Text(transaction['id'] as String, style: TextStyle(fontSize: 12.5, color: _slate)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(transaction['amount'] as String, style: const TextStyle(fontWeight: FontWeight.w700, color: _brand)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  transaction['status'] as String,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (Color color, IconData icon) _getStatusInfo(String status) {
    switch (status) {
      case 'Completed':
        return (Colors.green, Icons.check_circle_rounded);
      case 'Pending':
        return (Colors.orange, Icons.pending_rounded);
      case 'Refunded':
        return (Colors.red, Icons.reply_rounded);
      default:
        return (Colors.grey, Icons.help_outline_rounded);
    }
  }
}