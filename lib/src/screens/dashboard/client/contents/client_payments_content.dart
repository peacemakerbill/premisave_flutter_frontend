import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _brandLight = Color(0xFF2D5A4F);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);
const _border = Color(0xFFEAE6DE);

class ClientPaymentsContent extends StatelessWidget {
  const ClientPaymentsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isLarge = constraints.maxWidth > 1100;

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: isLarge ? 36 : 20,
          vertical: 28,
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSection(),
                SizedBox(height: 32),
                _PaymentMethods(),
                SizedBox(height: 32),
                _RecentPayments(),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ── Premium Header Section ──────────────────────────────────────────────────

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isSmall = constraints.maxWidth < 600;

      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_brand, _brandLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _brand.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ],
        ),
        padding: EdgeInsets.all(isSmall ? 24 : 32),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payments',
                    style: TextStyle(
                      fontSize: isSmall ? 26 : 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your payment methods and structural history',
                    style: TextStyle(
                      fontSize: 14.5,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
              ),
              child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 28),
            ),
          ],
        ),
      );
    });
  }
}

// ── Fluid Payment Methods Section ───────────────────────────────────────────

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods();

  @override
  Widget build(BuildContext context) {
    final methods = [
      {'name': 'M-Pesa', 'icon': Icons.phone_android_rounded, 'color': Colors.green, 'last4': '0721', 'isDefault': true},
      {'name': 'Visa', 'icon': Icons.credit_card_rounded, 'color': Colors.blue, 'last4': '4321', 'isDefault': false},
      {'name': 'MasterCard', 'icon': Icons.credit_card_rounded, 'color': Colors.orange, 'last4': '8765', 'isDefault': false},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Saved Wallet',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.3),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _brand,
                side: const BorderSide(color: _brand, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final double cardWidth = screenWidth > 900
                ? (screenWidth - 24) / 3
                : screenWidth > 600
                ? (screenWidth - 12) / 2
                : screenWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: methods.map((method) => SizedBox(
                width: cardWidth,
                child: _PaymentMethodCard(method: method),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final Map<String, dynamic> method;
  const _PaymentMethodCard({required this.method});

  @override
  Widget build(BuildContext context) {
    final color = method['color'] as Color;
    final isDefault = method['isDefault'] as bool;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(method['icon'] as IconData, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  method['name'] as String,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: _brand),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '•••• ${method['last4']}',
                  style: const TextStyle(fontSize: 13, color: _slate, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: const Text(
                'Default',
                style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Recent Payments Section ─────────────────────────────────────────────────

class _RecentPayments extends StatelessWidget {
  const _RecentPayments();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.3),
        ),
        const SizedBox(height: 4),
        const Text(
          'Monitor secure tracking historical receipt balances',
          style: TextStyle(color: _slate, fontSize: 13, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: _payments.map((payment) => _PaymentItem(payment: payment)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Updated array matrix definitions to feature contextually current 2026 data timelines
  final List<Map<String, dynamic>> _payments = const [
    {'date': '12 Jun 2026', 'amount': 'KES 42,500', 'method': 'M-Pesa', 'status': 'Paid'},
    {'date': '04 Jun 2026', 'amount': 'KES 175,000', 'method': 'Visa', 'status': 'Paid'},
    {'date': '28 May 2026', 'amount': 'KES 25,000', 'method': 'M-Pesa', 'status': 'Pending'},
    {'date': '15 May 2026', 'amount': 'KES 32,500', 'method': 'M-Pesa', 'status': 'Paid'},
    {'date': '30 Apr 2026', 'amount': 'KES 105,000', 'method': 'MasterCard', 'status': 'Refunded'},
  ];
}

class _PaymentItem extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _PaymentItem({required this.payment});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getStatusInfo(payment['status'] as String);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF3EFE6))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  payment['date'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: _brand, fontSize: 14.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  payment['method'] as String,
                  style: const TextStyle(color: _slate, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                payment['amount'] as String,
                style: const TextStyle(fontWeight: FontWeight.w800, color: _brand, fontSize: 15),
              ),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment['status'] as String,
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
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
      case 'Paid':
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