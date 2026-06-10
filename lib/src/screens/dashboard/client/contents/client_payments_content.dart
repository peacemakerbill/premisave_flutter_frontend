import 'package:flutter/material.dart';

const _brand = Color(0xFF1A3C34);
const _gold = Color(0xFFC9A84C);
const _stone = Color(0xFFF5F0E8);
const _slate = Color(0xFF6B7280);

class ClientPaymentsContent extends StatelessWidget {
  const ClientPaymentsContent({super.key});

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
          const _PaymentMethods(),
          const SizedBox(height: 28),
          const _RecentPayments(),
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
                  'Payments',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _brand, letterSpacing: -0.8),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your payment methods and history',
                  style: TextStyle(fontSize: 14, color: _slate),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _stone, shape: BoxShape.circle),
            child: const Icon(Icons.credit_card_rounded, color: _brand, size: 28),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethods extends StatelessWidget {
  const _PaymentMethods();

  @override
  Widget build(BuildContext context) {
    final methods = [
      {'name': 'M-Pesa', 'icon': Icons.phone_android_rounded, 'color': Colors.green, 'last4': '0721'},
      {'name': 'Visa', 'icon': Icons.credit_card_rounded, 'color': Colors.blue, 'last4': '4321'},
      {'name': 'MasterCard', 'icon': Icons.credit_card_rounded, 'color': Colors.orange, 'last4': '8765'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 16),
        ...methods.map((method) => _PaymentMethodCard(method: method)).toList(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Payment Method'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _brand,
            side: const BorderSide(color: _brand),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE6DE)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(method['icon'] as IconData, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(method['name'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _brand)),
                Text('•••• ${method['last4']}', style: TextStyle(fontSize: 13, color: _slate)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Default',
              style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentPayments extends StatelessWidget {
  const _RecentPayments();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _brand)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAE6DE)),
          ),
          child: Column(
            children: _payments.map((payment) => _PaymentItem(payment: payment)).toList(),
          ),
        ),
      ],
    );
  }

  final List<Map<String, dynamic>> _payments = const [
    {'date': '15 Dec 2024', 'amount': 'KES 42,500', 'method': 'M-Pesa', 'status': 'Paid'},
    {'date': '10 Dec 2024', 'amount': 'KES 175,000', 'method': 'Visa', 'status': 'Paid'},
    {'date': '5 Dec 2024', 'amount': 'KES 25,000', 'method': 'M-Pesa', 'status': 'Pending'},
    {'date': '28 Nov 2024', 'amount': 'KES 32,500', 'method': 'M-Pesa', 'status': 'Paid'},
    {'date': '15 Nov 2024', 'amount': 'KES 105,000', 'method': 'MasterCard', 'status': 'Refunded'},
  ];
}

class _PaymentItem extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _PaymentItem({required this.payment});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getStatusInfo(payment['status'] as String);

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
                Text(payment['date'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: _brand)),
                Text(payment['method'] as String, style: TextStyle(color: _slate, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(payment['amount'] as String, style: const TextStyle(fontWeight: FontWeight.w700, color: _brand)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  payment['status'] as String,
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