import '../shared/overview_tone.dart';

enum PaymentState {
  completed('Completed', OverviewTone.good),
  pending('Pending', OverviewTone.warn);

  const PaymentState(this.label, this.tone);

  final String label;
  final OverviewTone tone;
}

class FinanceTransaction {
  const FinanceTransaction({required this.title, required this.amount, required this.state, required this.at});

  final String title;
  final int amount;
  final PaymentState state;
  final DateTime at;
}

class TopClient {
  const TopClient({required this.name, required this.revenue, required this.deals});

  final String name;
  final int revenue;
  final int deals;
}

/// Finance figures. Replace [sample] with a provider once the finance service exists.
class FinanceData {
  const FinanceData({
    required this.now,
    required this.transactions,
    required this.clients,
    required this.monthlyRevenue,
    required this.pendingInvoices,
    required this.pendingInvoiceCount,
    required this.collectionDays,
    required this.netProfit,
  });

  final DateTime now;
  final List<FinanceTransaction> transactions;
  final List<TopClient> clients;

  /// Revenue in each of the last six months, oldest first.
  final List<int> monthlyRevenue;
  final int pendingInvoices;
  final int pendingInvoiceCount;
  final int collectionDays;
  final int netProfit;

  factory FinanceData.sample(DateTime now) {
    DateTime ago({int days = 0, int hours = 0}) => now.subtract(Duration(days: days, hours: hours));
    return FinanceData(
      now: now,
      transactions: <FinanceTransaction>[
        FinanceTransaction(title: 'Karen Villa sale', amount: 65000000, state: PaymentState.completed, at: ago(hours: 2)),
        FinanceTransaction(title: 'Westlands invoice', amount: 2800000, state: PaymentState.pending, at: ago(hours: 5)),
        FinanceTransaction(title: 'Lavington deposit', amount: 4500000, state: PaymentState.completed, at: ago(days: 1)),
        FinanceTransaction(title: 'Kilimani commission', amount: 920000, state: PaymentState.completed, at: ago(days: 1, hours: 3)),
      ],
      clients: const <TopClient>[
        TopClient(name: 'Karen Realty Ltd', revenue: 18400000, deals: 3),
        TopClient(name: 'Westlands Developers', revenue: 14200000, deals: 2),
        TopClient(name: 'Lavington Homes', revenue: 9800000, deals: 4),
        TopClient(name: 'Prime Estates', revenue: 7100000, deals: 5),
      ],
      monthlyRevenue: const <int>[11800000, 12900000, 14100000, 15200000, 16000000, 17000000],
      pendingInvoices: 8700000,
      pendingInvoiceCount: 12,
      collectionDays: 18,
      netProfit: 12400000,
    );
  }

  /// Revenue for the quarter, the last three months.
  int get quarterRevenue => monthlyRevenue.skip(monthlyRevenue.length - 3).fold<int>(0, (sum, v) => sum + v);

  List<FinanceTransaction> get pending => transactions.where((t) => t.state == PaymentState.pending).toList();
}
