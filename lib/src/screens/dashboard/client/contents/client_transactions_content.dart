import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);
const _border = Color(0xFFEAE6DE);

class ClientTransactionsContent extends StatefulWidget {
  const ClientTransactionsContent({super.key});

  @override
  State<ClientTransactionsContent> createState() => _ClientTransactionsContentState();
}

class _ClientTransactionsContentState extends State<ClientTransactionsContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _expandedTransactionId;

  // Updated dataset: All dates set to 2026
  final List<Map<String, dynamic>> _allTransactions = const [
    {
      'id': '#TRX-001',
      'property': 'Modern Apartment',
      'date': '12 Jun 2026',
      'amount': 'KES 42,500',
      'status': 'Completed',
      'paymentMethod': 'M-Pesa',
      'methodIcon': Icons.phone_android_rounded,
      'breakdown': {'Base Price': 'KES 38,000', 'Service Fee': 'KES 2,500', 'VAT (16%)': 'KES 2,000'},
    },
    {
      'id': '#TRX-002',
      'property': 'Luxury Villa',
      'date': '10 Jun 2026',
      'amount': 'KES 175,000',
      'status': 'Completed',
      'paymentMethod': 'Visa Card ending *4421',
      'methodIcon': Icons.credit_card_rounded,
      'breakdown': {'Base Price': 'KES 160,000', 'Service Fee': 'KES 5,000', 'VAT (16%)': 'KES 10,000'},
    },
    {
      'id': '#TRX-003',
      'property': 'Mountain Cabin',
      'date': '05 Jun 2026',
      'amount': 'KES 60,000',
      'status': 'Pending',
      'paymentMethod': 'Bank Transfer',
      'methodIcon': Icons.account_balance_rounded,
      'estRelease': 'Within 24 Hours',
      'breakdown': {'Base Price': 'KES 54,000', 'Service Fee': 'KES 2,000', 'VAT (16%)': 'KES 4,000'},
    },
    {
      'id': '#TRX-004',
      'property': 'City Studio',
      'date': '28 May 2026',
      'amount': 'KES 32,500',
      'status': 'Completed',
      'paymentMethod': 'M-Pesa',
      'methodIcon': Icons.phone_android_rounded,
      'breakdown': {'Base Price': 'KES 29,000', 'Service Fee': 'KES 1,500', 'VAT (16%)': 'KES 2,000'},
    },
    {
      'id': '#TRX-005',
      'property': 'Beach House',
      'date': '15 Apr 2026',
      'amount': 'KES 105,000',
      'status': 'Refunded',
      'paymentMethod': 'Mastercard ending *8891',
      'methodIcon': Icons.credit_card_rounded,
      'breakdown': {'Refunded Amount': 'KES 105,000', 'Cancellation Fee': 'KES 0'},
    },
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_searchQuery.isEmpty) return _allTransactions;
    return _allTransactions.where((txn) {
      final propertyMatch = (txn['property'] as String).toLowerCase().contains(_searchQuery);
      final idMatch = (txn['id'] as String).toLowerCase().contains(_searchQuery);
      final statusMatch = (txn['status'] as String).toLowerCase().contains(_searchQuery);
      final methodMatch = (txn['paymentMethod'] as String).toLowerCase().contains(_searchQuery);
      return propertyMatch || idMatch || statusMatch || methodMatch;
    }).toList();
  }

  void _toggleExpand(String id) {
    setState(() {
      _expandedTransactionId = _expandedTransactionId == id ? null : id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 36, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _HeaderSection(),
          const SizedBox(height: 24),
          const _TransactionStats(),
          const SizedBox(height: 24),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: _slate, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13.5, color: _brand),
                    decoration: const InputDecoration(
                      hintText: 'Search ledger records...',
                      hintStyle: TextStyle(color: _slate, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, color: _slate, size: 16),
                    onPressed: () => _searchController.clear(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _RecentTransactions(
            transactions: _filteredTransactions,
            expandedId: _expandedTransactionId,
            onExpandToggle: _toggleExpand,
          ),
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 380;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.6),
                ),
                const SizedBox(height: 4),
                Text(
                  'View payment history and breakdowns',
                  style: TextStyle(fontSize: 13, color: _slate, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          if (!isSmall) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: _stone, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_rounded, color: _brand, size: 22),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionStats extends StatelessWidget {
  const _TransactionStats();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    int crossAxisCount = 2;
    double childAspectRatio = 1.45;

    if (width >= 1200) {
      crossAxisCount = 5;
      childAspectRatio = 1.35;
    } else if (width >= 900) {
      crossAxisCount = 4;
      childAspectRatio = 1.3;
    } else if (width >= 650) {
      crossAxisCount = 3;
      childAspectRatio = 1.4;
    } else if (width <= 360) {
      crossAxisCount = 2;
      childAspectRatio = 1.25;
    }

    final stats = [
      {'title': 'Total Gross Spent', 'value': 'KES 450,000', 'color': Colors.green.shade700, 'icon': Icons.payments_rounded},
      {'title': 'This Month Payments', 'value': 'KES 85,000', 'color': Colors.blue.shade700, 'icon': Icons.calendar_month_rounded},
      {'title': 'Pending Escrow', 'value': 'KES 25,000', 'color': Colors.orange.shade700, 'icon': Icons.pending_rounded},
      {'title': 'Refunded Capital', 'value': 'KES 105,000', 'color': Colors.red.shade700, 'icon': Icons.assignment_return_rounded},
      {'title': 'Average Order Value', 'value': 'KES 90,000', 'color': Colors.purple.shade700, 'icon': Icons.analytics_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Financial Highlights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: childAspectRatio,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border.withOpacity(0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(6)),
            child: Icon(stat['icon'] as IconData, color: color, size: 18),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat['value'] as String,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  stat['title'] as String,
                  style: TextStyle(fontSize: 10.5, color: _slate, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String? expandedId;
  final Function(String) onExpandToggle;

  const _RecentTransactions({
    required this.transactions,
    required this.expandedId,
    required this.onExpandToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaction Ledger Logs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _brand)),
            const SizedBox(height: 4),
            Text(
              transactions.isEmpty ? 'No results found' : 'Showing ${transactions.length} record(s) • Tap to expand details',
              style: TextStyle(fontSize: 12, color: _slate),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 36, color: _slate.withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text(
                  'No matching statements discovered',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _brand),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                separatorBuilder: (context, idx) => const Divider(height: 1, color: Color(0xFFF3EFE6)),
                itemBuilder: (context, idx) {
                  final txn = transactions[idx];
                  return _TransactionRowItem(
                    transaction: txn,
                    isExpanded: expandedId == txn['id'],
                    onTap: () => onExpandToggle(txn['id'] as String),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('Export PDF Bundle', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _brand,
              side: const BorderSide(color: _brand, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionRowItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final bool isExpanded;
  final VoidCallback onTap;

  const _TransactionRowItem({
    required this.transaction,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(transaction['status'] as String);
    final color = statusInfo.$1;
    final icon = statusInfo.$2;
    final breakdown = transaction['breakdown'] as Map<String, String>;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
            color: isExpanded ? _stone.withOpacity(0.2) : Colors.transparent,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),

                // Content area wrapping left elements to prevent pushing layout
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['property'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: _brand, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            transaction['id'] as String,
                            style: const TextStyle(fontSize: 11.5, color: _slate, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          Container(width: 2.5, height: 2.5, decoration: const BoxDecoration(color: _slate, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Icon(transaction['methodIcon'] as IconData, size: 12, color: _slate),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              transaction['paymentMethod'] as String,
                              style: const TextStyle(fontSize: 11.5, color: _slate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right-aligned column holding metric targets safely
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction['amount'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w800, color: _brand, fontSize: 13.5),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          transaction['date'] as String,
                          style: const TextStyle(fontSize: 11, color: _slate, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: _slate,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        if (isExpanded)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(48, 4, 14, 16),
            color: _stone.withOpacity(0.15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 1, color: Color(0xFFEAE6DE)),
                const SizedBox(height: 12),
                const Text(
                  'Itemized Invoice Breakdown',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _brand, letterSpacing: 0.2),
                ),
                const SizedBox(height: 6),
                ...breakdown.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontSize: 12, color: _slate)),
                      Text(entry.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _brand)),
                    ],
                  ),
                )),
                if (transaction['status'] == 'Pending' && transaction.containsKey('estRelease')) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Estimated Escrow Settlement Window: ${transaction['estRelease']}',
                          style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: _gold,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.print_rounded, size: 13),
                    label: const Text('Print Receipt Copy', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  (Color, IconData) _getStatusInfo(String status) {
    switch (status) {
      case 'Completed':
        return (Colors.green.shade700, Icons.check_circle_rounded);
      case 'Pending':
        return (Colors.orange.shade700, Icons.pending_rounded);
      case 'Refunded':
        return (Colors.red.shade700, Icons.reply_rounded);
      default:
        return (Colors.grey.shade600, Icons.help_outline_rounded);
    }
  }
}