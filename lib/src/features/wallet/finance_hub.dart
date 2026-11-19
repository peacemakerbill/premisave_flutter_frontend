import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/profile_repository.dart';
import '../../state/providers.dart';
import '../overview/finance/finance_overview.dart';
import '../shared/ask_then_show.dart';
import '../shared/hub.dart';
import '../shared/pickers.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';

double _amount(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String? _money(Json m) => m['amount'] is num ? formatMoney(m['amount'] as num, pick(m, <String>['currency'], platformCurrency)) : null;

/// Wallet administration for finance staff: every wallet and what moved through it, payments waiting for a decision,
/// the company's own M-Pesa operations, balances at each payment provider and exchange rates.
class FinanceHub extends StatelessWidget {
  const FinanceHub({super.key});

  @override
  Widget build(BuildContext context) {
    return HubPage(
      title: 'Finance',
      tabs: <HubTab>[
        HubTab('Overview', Icons.dashboard_outlined, (_) => const FinanceOverview()),
        HubTab('Wallets', Icons.account_balance_wallet_outlined, (_) => const AdminWalletsTab()),
        HubTab('Transactions', Icons.swap_horiz_rounded, (_) => const AdminTransactionsTab()),
        HubTab('Deposits', Icons.south_west_rounded, (_) => const AdminDepositsTab()),
        HubTab('Withdrawals', Icons.north_east_rounded, (_) => const AdminWithdrawalsTab()),
        HubTab('Payments', Icons.payments_outlined, (_) => const AdminPaymentsTab()),
        HubTab('Transfers', Icons.compare_arrows_rounded, (_) => const AdminTransfersTab()),
        HubTab('Ledger', Icons.menu_book_outlined, (_) => const AdminLedgerTab()),
        HubTab('Adjustments', Icons.tune_rounded, (_) => const AdminAdjustmentsTab()),
        HubTab('To resolve', Icons.rule_rounded, (_) => const ReconciliationTab()),
        HubTab('M-Pesa', Icons.phone_iphone_rounded, (_) => const MpesaOperationsTab()),
        HubTab('Gateways', Icons.hub_outlined, (_) => const GatewaysTab()),
        HubTab('Rates', Icons.currency_exchange_rounded, (_) => const RatesTab()),
        HubTab('Reports', Icons.bar_chart_rounded, (_) => const FinanceReportsTab()),
      ],
    );
  }
}

/// A list with a filter form above it.
class _Filtered extends StatefulWidget {
  const _Filtered({
    super.key,
    required this.filters,
    required this.load,
    required this.row,
    this.detail,
    this.itemActions = const <ItemAction>[],
    this.headerActions = const <ItemAction>[],
    this.emptyTitle = 'Nothing here',
    this.icon = Icons.receipt_long_outlined,
    this.intro,
  });

  final List<FieldSpec> filters;
  final Future<List<Json>> Function(Json filters) load;
  final RowView row;
  final Future<Json> Function(Json item)? detail;
  final List<ItemAction> itemActions;
  final List<ItemAction> headerActions;
  final String emptyTitle;
  final IconData icon;
  final String? intro;

  @override
  State<_Filtered> createState() => _FilteredState();
}

class _FilteredState extends State<_Filtered> {
  Json _f = <String, dynamic>{};
  int _bump = 0;

  Future<void> _open() async {
    await showResourceForm(
      context,
      title: 'Filter',
      submitLabel: 'Apply',
      initial: _f,
      fields: widget.filters,
      onSubmit: (v) async {
        setState(() => _f = v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _f.isNotEmpty;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: <Widget>[
              ActionChip(
                avatar: Icon(active ? Icons.filter_alt_rounded : Icons.filter_alt_outlined, size: 18),
                label: Text(active ? 'Filtered' : 'Filter'),
                onPressed: _open,
              ),
              if (active) ...<Widget>[
                const SizedBox(width: 8),
                ActionChip(label: const Text('Clear'), onPressed: () => setState(() => _f = <String, dynamic>{})),
              ],
            ],
          ),
        ),
        Expanded(
          child: ResourceSection(
            refreshKey: '$_f$_bump',
            load: () => widget.load(_f),
            detail: widget.detail,
            row: widget.row,
            intro: widget.intro,
            emptyTitle: widget.emptyTitle,
            emptyIcon: widget.icon,
            headerActions: widget.headerActions,
            itemActions: widget.itemActions,
          ),
        ),
      ],
    );
  }
}

FieldSpec _userFilter(ProfileRepository profiles) =>
    userPicker(profiles, label: 'User', helper: 'Search by name, username or email.', clearable: true);
const Map<String, String> _statuses = <String, String>{'PENDING': 'Pending', 'SUCCESS': 'Successful', 'FAILED': 'Failed'};
const Map<String, String> _providers = <String, String>{
  'MPESA': 'M-Pesa',
  'MPESA_TILL': 'M-Pesa till',
  'STRIPE': 'Stripe',
  'PAYPAL': 'PayPal',
  'FLUTTERWAVE': 'Flutterwave',
  'NOWPAYMENTS': 'Crypto',
};

RowView _flowRow(IconData icon) => RowView(
      icon: icon,
      title: (m) {
        final what = sentence(pick(m, <String>['provider', 'type', 'service', 'direction'], 'Record'));
        final who = pick(m, <String>['userName', 'userId', 'senderUserId', 'description']);
        return who.isEmpty ? what : '$what, $who';
      },
      subtitle: (m) => displayValue(m['createdAt'] ?? m['timestamp']),
      status: (m) => pick(m, <String>['status']),
      trailing: _money,
    );

// ------------------------------------------------------------------ wallets

class AdminWalletsTab extends ConsumerStatefulWidget {
  const AdminWalletsTab({super.key});

  @override
  ConsumerState<AdminWalletsTab> createState() => _AdminWalletsTabState();
}

class _AdminWalletsTabState extends ConsumerState<AdminWalletsTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(walletRepositoryProvider);
    String uid(Json m) => pick(m, <String>['userId', 'id']);
    void changed() {
      if (mounted) setState(() => _bump++);
    }

    return _Filtered(
      key: ValueKey<int>(_bump),
      filters: const <FieldSpec>[FieldSpec('query', 'Search by name or email')],
      load: (f) {
        final q = (f['query'] as String?) ?? '';
        return q.isEmpty ? repo.adminWallets() : repo.searchWallets(q);
      },
      detail: (m) => repo.adminWallet(uid(m)),
      emptyTitle: 'No wallets found',
      icon: Icons.account_balance_wallet_outlined,
      row: RowView(
        icon: Icons.account_balance_wallet_outlined,
        title: (m) => pick(m, <String>['accountNumber', 'email', 'userName', 'userId'], 'Wallet'),
        subtitle: (m) => pick(m, <String>['userName', 'fullName']),
        status: (m) => m['frozen'] == true ? 'FROZEN' : null,
        trailing: (m) => m['balance'] is num ? formatMoney(m['balance'] as num, pick(m, <String>['currency'], platformCurrency)) : null,
      ),
      itemActions: <ItemAction>[
        ItemAction(
          'Credit',
          Icons.add_circle_outline_rounded,
          title: 'Credit this wallet',
          subtitle: 'Adds money and records the reason in the audit trail.',
          fields: const <FieldSpec>[
            FieldSpec('amount', 'Amount', kind: FieldKind.number, required: true),
            FieldSpec('reason', 'Reason', kind: FieldKind.multiline, required: true),
            FieldSpec('reference', 'Reference'),
          ],
          run: (m, v) async {
            await repo.creditWallet(uid(m), <String, dynamic>{...v, 'amount': _amount(v['amount'])});
            changed();
          },
          done: 'Wallet credited',
        ),
        ItemAction(
          'Debit',
          Icons.remove_circle_outline_rounded,
          danger: true,
          title: 'Debit this wallet',
          subtitle: 'Removes money and records the reason in the audit trail.',
          fields: const <FieldSpec>[
            FieldSpec('amount', 'Amount', kind: FieldKind.number, required: true),
            FieldSpec('reason', 'Reason', kind: FieldKind.multiline, required: true),
            FieldSpec('reference', 'Reference'),
          ],
          run: (m, v) async {
            await repo.debitWallet(uid(m), <String, dynamic>{...v, 'amount': _amount(v['amount'])});
            changed();
          },
          done: 'Wallet debited',
        ),
        ItemAction(
          'Freeze',
          Icons.lock_outline_rounded,
          danger: true,
          visible: (m) => m['frozen'] != true,
          confirm: 'No money can move in or out of this wallet until it is unfrozen.',
          run: (m, _) async {
            await repo.adminFreeze(uid(m));
            changed();
          },
          done: 'Wallet frozen',
        ),
        ItemAction(
          'Unfreeze',
          Icons.lock_open_rounded,
          visible: (m) => m['frozen'] == true,
          confirm: 'Let money move in and out of this wallet again.',
          run: (m, _) async {
            await repo.adminUnfreeze(uid(m));
            changed();
          },
          done: 'Wallet unfrozen',
        ),
        ItemAction(
          'Transactions',
          Icons.swap_horiz_rounded,
          title: 'Transactions',
          page: (m) => ResourceSection(
            load: () => repo.adminTransactions(userId: uid(m)),
            emptyTitle: 'No transactions',
            row: _flowRow(Icons.swap_horiz_rounded),
          ),
        ),
        ItemAction(
          'Adjustments',
          Icons.tune_rounded,
          title: 'Adjustments',
          page: (m) => ResourceSection(
            load: () => repo.adminAdjustments(userId: uid(m)),
            emptyTitle: 'No adjustments',
            row: _flowRow(Icons.tune_rounded),
          ),
        ),
        ItemAction(
          'Ledger',
          Icons.menu_book_outlined,
          title: 'Ledger',
          page: (m) => ResourceSection(
            load: () => repo.financeLedger(userId: uid(m)),
            emptyTitle: 'No ledger entries',
            row: _flowRow(Icons.menu_book_outlined),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- lists of money

class AdminTransactionsTab extends ConsumerWidget {
  const AdminTransactionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(walletRepositoryProvider);
    return _Filtered(
      filters: <FieldSpec>[
        _userFilter(ref.read(profileRepositoryProvider)),
        FieldSpec('type', 'Kind', kind: FieldKind.select, clearable: true, options: <String, String>{
          'DEPOSIT': 'Deposit',
          'WITHDRAWAL': 'Withdrawal',
          'TRANSFER': 'Transfer',
          'PAYMENT': 'Payment',
          'REFUND': 'Refund',
          'DISBURSEMENT': 'Disbursement',
        }),
        FieldSpec('status', 'Status', kind: FieldKind.select, clearable: true, options: <String, String>{'PENDING': 'Pending', 'COMPLETED': 'Completed', 'FAILED': 'Failed', 'CANCELLED': 'Cancelled'}),
      ],
      load: (f) => repo.adminTransactions(userId: f['userId'] as String?, type: f['type'] as String?, status: f['status'] as String?),
      detail: (m) => repo.adminTransaction(pick(m, <String>['id', 'transactionId'])),
      row: _flowRow(Icons.swap_horiz_rounded),
    );
  }
}

class AdminDepositsTab extends ConsumerWidget {
  const AdminDepositsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(walletRepositoryProvider);
    return _Filtered(
      filters: <FieldSpec>[
        _userFilter(ref.read(profileRepositoryProvider)),
        FieldSpec('status', 'Status', kind: FieldKind.select, clearable: true, options: _statuses),
        FieldSpec('provider', 'Provider', kind: FieldKind.select, clearable: true, options: _providers),
      ],
      load: (f) => repo.financeDeposits(userId: f['userId'] as String?, status: f['status'] as String?, provider: f['provider'] as String?),
      row: _flowRow(Icons.south_west_rounded),
    );
  }
}

class AdminWithdrawalsTab extends ConsumerWidget {
  const AdminWithdrawalsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(walletRepositoryProvider);
    return _Filtered(
      filters: <FieldSpec>[
        _userFilter(ref.read(profileRepositoryProvider)),
        FieldSpec('status', 'Status', kind: FieldKind.select, clearable: true, options: _statuses),
        FieldSpec('provider', 'Provider', kind: FieldKind.select, clearable: true, options: _providers),
      ],
      load: (f) => repo.financeDisbursements(userId: f['userId'] as String?, status: f['status'] as String?, provider: f['provider'] as String?),
      row: _flowRow(Icons.north_east_rounded),
    );
  }
}

class AdminPaymentsTab extends ConsumerWidget {
  const AdminPaymentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(walletRepositoryProvider);
    return _Filtered(filters: const <FieldSpec>[], load: (_) => repo.financePayments(), row: _flowRow(Icons.payments_outlined));
  }
}

class AdminTransfersTab extends ConsumerWidget {
  const AdminTransfersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(walletRepositoryProvider);
    return _Filtered(filters: const <FieldSpec>[], load: (_) => repo.financeTransfers(), row: _flowRow(Icons.compare_arrows_rounded));
  }
}

class AdminLedgerTab extends ConsumerWidget {
  const AdminLedgerTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(walletRepositoryProvider);
    return _Filtered(
      filters: <FieldSpec>[_userFilter(ref.read(profileRepositoryProvider)), const FieldSpec('type', 'Kind')],
      load: (f) => repo.financeLedger(userId: f['userId'] as String?, type: f['type'] as String?),
      row: _flowRow(Icons.menu_book_outlined),
    );
  }
}

class AdminAdjustmentsTab extends ConsumerWidget {
  const AdminAdjustmentsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(walletRepositoryProvider);
    return _Filtered(
      filters: <FieldSpec>[_userFilter(ref.read(profileRepositoryProvider))],
      load: (f) => repo.adminAdjustments(userId: f['userId'] as String?),
      row: _flowRow(Icons.tune_rounded),
    );
  }
}

// ------------------------------------------------------------ reconciliation

/// How long a pending item has been waiting, in words.
String _waiting(Object? minutes) {
  final m = minutes is num ? minutes.toInt() : int.tryParse('$minutes') ?? 0;
  if (m < 60) return plural(m, 'minute');
  if (m < 60 * 48) return plural(m ~/ 60, 'hour');
  return plural(m ~/ (60 * 24), 'day');
}

/// Where staff decide what to do with money that is stuck or did not go through. It has two lists:
///
/// Pending: deposits, withdrawals and M-Pesa refunds that have not been confirmed. Approving completes the payment and
/// rejecting closes it, and both ask for confirmation first. Nothing happens automatically.
///
/// Failed: attempts that failed in the last 30 days. A failed attempt did not move money, so nothing here is approved. When a
/// customer says they paid, staff check with the provider and, if the money did arrive, credit the wallet. That credit is
/// recorded with a reason and the staff member's name, like any manual adjustment.
class ReconciliationTab extends ConsumerStatefulWidget {
  const ReconciliationTab({super.key});

  @override
  ConsumerState<ReconciliationTab> createState() => _ReconciliationTabState();
}

class _ReconciliationTabState extends ConsumerState<ReconciliationTab> {
  int _bump = 0;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(walletRepositoryProvider);
    String id(Json m) => pick(m, <String>['id']);
    String kind(Json m) => pick(m, <String>['entityType']).toUpperCase();
    bool isDeposit(Json m) => kind(m) == 'DEPOSIT';
    bool isDisbursement(Json m) => kind(m) == 'DISBURSEMENT';
    bool isReversal(Json m) => kind(m) == 'MPESA_REVERSAL';
    bool isMpesaCheck(Json m) => kind(m).startsWith('MPESA_') && !isReversal(m);
    void changed() {
      if (mounted) setState(() => _bump++);
    }

    return Column(
      children: <Widget>[
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(label: const Text('Pending'), selected: !_failed, onSelected: (_) => setState(() => _failed = false)),
              ),
              ChoiceChip(label: const Text('Failed, last 30 days'), selected: _failed, onSelected: (_) => setState(() => _failed = true)),
            ],
          ),
        ),
        Expanded(
          child: ResourceSection(
            refreshKey: '$_failed$_bump',
            load: _failed ? () => repo.failedItems() : repo.pendingItems,
            intro: _failed
                ? 'These did not go through, so no money moved. If a customer says they paid, check with the provider first. If the money did arrive, credit their wallet.'
                : 'These are not confirmed yet. Check with the provider, then approve to complete one or reject to close it. Nothing is approved on its own.',
            emptyTitle: _failed ? 'Nothing failed' : 'Nothing to resolve',
            emptyMessage: _failed ? 'No payment failed in the last 30 days.' : 'Every payment has reached a final state.',
            emptyIcon: Icons.rule_rounded,
            hidden: const <String>{'actionCode', 'resolvableViaApi', 'minutesPending', 'entityType', 'userId'},
            row: RowView(
              icon: _failed ? Icons.error_outline_rounded : Icons.hourglass_top_rounded,
              title: (m) => pick(m, <String>['displaySummary'], sentence(kind(m))),
              subtitle: (m) {
                final who = pick(m, <String>['customer']);
                final when = _failed ? timeAgo(DateTime.tryParse(pick(m, <String>['createdAt']))) : 'waiting ${_waiting(m['minutesPending'])}';
                return <String>[if (who.isNotEmpty) who, when].join('\n');
              },
              status: (m) => _failed ? 'FAILED' : 'PENDING',
              trailing: _money,
            ),
            itemActions: <ItemAction>[
              ItemAction(
                'Approve',
                Icons.check_circle_outline_rounded,
                visible: (m) => !_failed && (isDeposit(m) || isDisbursement(m) || isReversal(m)),
                confirm: 'Approve only after you have checked with the provider that the money really moved. '
                    'This completes the payment now and cannot be undone.',
                run: (m, _) async {
                  if (isDeposit(m)) {
                    await repo.approveDeposit(id(m));
                  } else if (isDisbursement(m)) {
                    await repo.approveDisbursement(id(m));
                  } else {
                    await repo.approveReversal(id(m));
                  }
                  changed();
                },
                done: 'Approved',
              ),
              ItemAction(
                'Reject',
                Icons.cancel_outlined,
                danger: true,
                title: 'Reject this payment',
                subtitle: 'The payment is closed as failed. Say why, so the customer and your team can see it.',
                visible: (m) => !_failed && (isDeposit(m) || isDisbursement(m) || isReversal(m)),
                fields: const <FieldSpec>[FieldSpec('reason', 'Reason', kind: FieldKind.multiline, required: true)],
                run: (m, v) async {
                  if (isDeposit(m)) {
                    await repo.rejectDeposit(id(m), v['reason'] as String);
                  } else if (isDisbursement(m)) {
                    await repo.rejectDisbursement(id(m), v['reason'] as String);
                  } else {
                    await repo.rejectReversal(id(m), v['reason'] as String);
                  }
                  changed();
                },
                done: 'Rejected',
              ),
              ItemAction(
                'Mark as checked',
                Icons.done_all_rounded,
                visible: (m) => !_failed && isMpesaCheck(m),
                subtitle: 'This was only a check and no money was involved. It leaves the list.',
                fields: const <FieldSpec>[FieldSpec('note', 'Note', kind: FieldKind.multiline)],
                run: (m, v) async {
                  await repo.closeOperation(id(m), note: (v['note'] as String?));
                  changed();
                },
                done: 'Marked as checked',
              ),
              ItemAction(
                'Credit the customer',
                Icons.add_circle_outline_rounded,
                title: 'Credit the customer',
                subtitle: 'Only when the provider confirms the money arrived. The credit is recorded with your name and this reason.',
                visible: (m) => _failed && (isDeposit(m) || isDisbursement(m)) && pick(m, <String>['userId']).isNotEmpty,
                initialFromItem: true,
                fields: const <FieldSpec>[
                  FieldSpec('amount', 'Amount', kind: FieldKind.number, required: true),
                  FieldSpec('reason', 'Reason', kind: FieldKind.multiline, required: true, hint: 'For example: confirmed with the provider on the day'),
                ],
                run: (m, v) async {
                  await repo.creditWallet(pick(m, <String>['userId']), <String, dynamic>{
                    'amount': _amount(v['amount']),
                    'reason': '${v['reason']} (${pick(m, <String>['displaySummary'])}, ref ${pick(m, <String>['reference'])})',
                    'reference': pick(m, <String>['reference']),
                  });
                  changed();
                },
                done: 'Wallet credited',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- M-Pesa

class MpesaOperationsTab extends ConsumerStatefulWidget {
  const MpesaOperationsTab({super.key});

  @override
  ConsumerState<MpesaOperationsTab> createState() => _MpesaOperationsTabState();
}

class _MpesaOperationsTabState extends ConsumerState<MpesaOperationsTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(walletRepositoryProvider);
    String id(Json m) => pick(m, <String>['conversationId', 'id']);
    void changed() {
      if (mounted) setState(() => _bump++);
    }

    return _Filtered(
      key: ValueKey<int>(_bump),
      intro: 'Operations run from the company M-Pesa account: balance checks, status queries, reversals and payouts.',
      filters: const <FieldSpec>[
        FieldSpec('type', 'Kind', kind: FieldKind.select, clearable: true, options: <String, String>{
          'ACCOUNT_BALANCE': 'Account balance',
          'TRANSACTION_STATUS': 'Transaction status',
          'REVERSAL': 'Reversal',
          'B2POCHI': 'Pochi payout',
        }),
        FieldSpec('status', 'Status', kind: FieldKind.select, clearable: true, options: _statuses),
      ],
      load: (f) => repo.mpesaOperations(type: f['type'] as String?, status: f['status'] as String?),
      detail: (m) => repo.mpesaOperation(id(m)),
      icon: Icons.phone_iphone_rounded,
      row: RowView(
        icon: Icons.phone_iphone_rounded,
        title: (m) => sentence(pick(m, <String>['type', 'operationType'], 'Operation')),
        subtitle: (m) => displayValue(m['createdAt']),
        status: (m) => pick(m, <String>['status']),
        trailing: _money,
      ),
      headerActions: <ItemAction>[
        ItemAction('Account balance', Icons.account_balance_outlined, title: 'Account balance', page: (_) => _Query(load: repo.mpesaBalanceQuery, button: 'Ask M-Pesa for the balance')),
        ItemAction(
          'Transaction status',
          Icons.manage_search_rounded,
          title: 'Transaction status',
          page: (_) => AskThenShow(
            fields: const <FieldSpec>[
              FieldSpec('transactionId', 'M-Pesa receipt number', required: true),
              FieldSpec('originalConversationId', 'Conversation id'),
              FieldSpec('remarks', 'Note'),
            ],
            submitLabel: 'Query',
            fetch: repo.mpesaTransactionStatus,
          ),
        ),
        ItemAction(
          'Reverse a payment',
          Icons.undo_rounded,
          danger: true,
          title: 'Reverse a payment',
          fields: const <FieldSpec>[
            FieldSpec('transactionId', 'M-Pesa receipt number', required: true),
            FieldSpec('amount', 'Amount', kind: FieldKind.number, required: true),
            FieldSpec('remarks', 'Reason', required: true),
          ],
          run: (_, v) async {
            await repo.mpesaReversal(<String, dynamic>{...v, 'amount': _amount(v['amount'])});
            changed();
          },
          done: 'Reversal requested',
        ),
        ItemAction(
          'Register C2B links',
          Icons.link_rounded,
          title: 'Register C2B links',
          page: (_) => _Query(load: repo.mpesaC2bRegisterUrls, button: 'Register the links with Safaricom'),
        ),
        ItemAction(
          'Simulate a C2B payment',
          Icons.science_outlined,
          title: 'Simulate a C2B payment',
          subtitle: 'Sandbox only.',
          page: (_) => AskThenShow(
            intro: 'Pretends a customer paid the Pay Bill. The bill reference must be the M-Pesa number saved on a wallet.',
            fields: const <FieldSpec>[
              FieldSpec('billRefNumber', 'Bill reference', required: true, hint: '254712345678'),
              FieldSpec('amount', 'Amount', hint: '100'),
              FieldSpec('msisdn', 'Paying phone', kind: FieldKind.phone, hint: '254705912645'),
            ],
            submitLabel: 'Simulate',
            fetch: repo.mpesaC2bSimulate,
          ),
        ),
        ItemAction('Register pull', Icons.cloud_download_outlined, confirm: 'Register the company shortcode for pulling transactions.', run: (_, __) async {
          await repo.mpesaPullRegister();
        }, done: 'Pull registered'),
        ItemAction(
          'Pull transactions',
          Icons.cloud_sync_outlined,
          title: 'Pull transactions',
          page: (_) => AskThenShow(
            fields: const <FieldSpec>[
              FieldSpec('startDate', 'From', kind: FieldKind.dateTime, required: true),
              FieldSpec('endDate', 'To', kind: FieldKind.dateTime, required: true),
              FieldSpec('offsetValue', 'Start at', kind: FieldKind.integer),
            ],
            submitLabel: 'Pull',
            fetch: repo.mpesaPullQuery,
          ),
        ),
        ItemAction(
          'Pay to Pochi',
          Icons.storefront_outlined,
          title: 'Pay to Pochi la Biashara',
          fields: const <FieldSpec>[
            FieldSpec('phoneNumber', 'Pochi phone', kind: FieldKind.phone, required: true),
            FieldSpec('amount', 'Amount', kind: FieldKind.number, required: true),
            FieldSpec('remarks', 'Note'),
            FieldSpec('occasion', 'Occasion'),
          ],
          run: (_, v) async {
            await repo.adminPayPochi(<String, dynamic>{...v, 'amount': _amount(v['amount'])});
            changed();
          },
          done: 'Payment sent',
        ),
        ItemAction(
          'Pay a business',
          Icons.business_rounded,
          title: 'Pay a business (B2B)',
          fields: const <FieldSpec>[
            FieldSpec('receiverShortcode', 'Business shortcode', required: true),
            FieldSpec('amount', 'Amount', kind: FieldKind.number, required: true),
            FieldSpec('commandId', 'Kind of payment', hint: 'BusinessPayBill'),
            FieldSpec('accountReference', 'Account reference'),
            FieldSpec('remarks', 'Note'),
            FieldSpec('verifyRecipient', 'Verify the recipient first', kind: FieldKind.toggle),
          ],
          run: (_, v) async {
            await repo.adminPayB2B(<String, dynamic>{...v, 'amount': _amount(v['amount'])});
            changed();
          },
          done: 'Payment sent',
        ),
        ItemAction(
          'Look up a business',
          Icons.badge_outlined,
          title: 'Look up a business',
          page: (_) => AskThenShow(
            fields: const <FieldSpec>[
              FieldSpec('identifierType', 'Identifier type', required: true, hint: '4', helper: '1 is MSISDN, 2 is a till, 4 is a shortcode.'),
              FieldSpec('identifier', 'Identifier', required: true),
            ],
            submitLabel: 'Look up',
            fetch: repo.adminQueryOrgInfo,
          ),
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction(
          'Approve reversal',
          Icons.check_circle_outline_rounded,
          visible: (m) => pick(m, <String>['status']).contains('PENDING') && pick(m, <String>['type', 'operationType']).contains('REVERSAL'),
          confirm: 'Send this reversal to M-Pesa.',
          run: (m, _) async {
            await repo.approveReversal(id(m));
            changed();
          },
          done: 'Reversal approved',
        ),
        ItemAction(
          'Reject reversal',
          Icons.cancel_outlined,
          danger: true,
          title: 'Reject this reversal',
          visible: (m) => pick(m, <String>['status']).contains('PENDING') && pick(m, <String>['type', 'operationType']).contains('REVERSAL'),
          fields: const <FieldSpec>[FieldSpec('reason', 'Reason', kind: FieldKind.multiline, required: true)],
          run: (m, v) async {
            await repo.rejectReversal(id(m), v['reason'] as String);
            changed();
          },
          done: 'Reversal rejected',
        ),
        ItemAction(
          'Close',
          Icons.done_all_rounded,
          title: 'Close this operation',
          fields: const <FieldSpec>[FieldSpec('note', 'Note')],
          run: (m, v) async {
            await repo.closeOperation(id(m), note: v['note'] as String?);
            changed();
          },
          done: 'Operation closed',
        ),
      ],
    );
  }
}

/// A page with one button that asks the server a question and shows the answer.
class _Query extends StatelessWidget {
  const _Query({required this.load, required this.button});

  final Future<Json> Function() load;
  final String button;

  @override
  Widget build(BuildContext context) {
    return AskThenShow(fields: const <FieldSpec>[], submitLabel: button, fetch: (_) => load());
  }
}

// ---------------------------------------------------------------- gateways

/// What the company holds with each payment provider, live and as last saved.
class GatewaysTab extends ConsumerStatefulWidget {
  const GatewaysTab({super.key});

  @override
  ConsumerState<GatewaysTab> createState() => _GatewaysTabState();
}

class _GatewaysTabState extends ConsumerState<GatewaysTab> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.read(walletRepositoryProvider);
    const providers = <String, String>{'stripe': 'Stripe', 'paypal': 'PayPal', 'flutterwave': 'Flutterwave', 'nowpayments': 'Crypto', 'mpesa': 'M-Pesa'};
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          const TabBar(tabs: <Tab>[Tab(text: 'Live'), Tab(text: 'Saved')]),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                ResourceView(
                  load: repo.gatewayBalances,
                  intro: 'Asks every provider now. M-Pesa answers a little later, so check Saved.',
                  actions: <ItemAction>[
                    for (final e in providers.entries)
                      ItemAction(e.value, Icons.account_balance_outlined, title: '${e.value} balance', page: (_) => ResourceView(load: () => repo.gatewayBalance(e.key))),
                  ],
                ),
                ResourceSection(
                  load: repo.savedGatewayBalances,
                  intro: 'The last balance saved for each provider.',
                  emptyTitle: 'No saved balances',
                  emptyIcon: Icons.hub_outlined,
                  row: RowView(
                    icon: Icons.account_balance_outlined,
                    title: (m) => sentence(pick(m, <String>['provider'], 'Provider')),
                    subtitle: (m) => displayValue(m['lastUpdated']),
                    status: (m) => pick(m, <String>['status']),
                  ),
                  itemActions: <ItemAction>[
                    ItemAction(
                      'History',
                      Icons.history_rounded,
                      title: 'Saved balances',
                      page: (m) => ResourceSection(
                        load: () => repo.savedGatewayHistory(pick(m, <String>['provider']).toLowerCase()),
                        emptyTitle: 'No history',
                        row: RowView(
                          icon: Icons.history_rounded,
                          title: (r) => displayValue(r['lastUpdated'] ?? r['fetchedAt']),
                          subtitle: (r) => pick(r, <String>['message']),
                          status: (r) => pick(r, <String>['status']),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- rates

class RatesTab extends ConsumerStatefulWidget {
  const RatesTab({super.key});

  @override
  ConsumerState<RatesTab> createState() => _RatesTabState();
}

class _RatesTabState extends ConsumerState<RatesTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(walletRepositoryProvider);
    return ResourceSection(
      refreshKey: _bump,
      load: repo.exchangeRates,
      intro: 'Rates the wallet uses to convert between currencies.',
      emptyTitle: 'No rates yet',
      emptyMessage: 'Fetch the latest rates to fill this list.',
      emptyIcon: Icons.currency_exchange_rounded,
      row: RowView(
        icon: Icons.currency_exchange_rounded,
        title: (m) => '${pick(m, <String>['baseCurrency', 'base'])} to ${pick(m, <String>['targetCurrency', 'quoteCurrency', 'currency', 'target'])}',
        subtitle: (m) => displayValue(m['updatedAt'] ?? m['fetchedAt'] ?? m['date']),
        trailing: (m) => displayValue(m['rate']),
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Fetch the latest',
          Icons.sync_rounded,
          title: 'Fetch the latest rates',
          fields: const <FieldSpec>[FieldSpec('base', 'Base currency', required: true, hint: 'USD')],
          run: (_, v) async {
            await repo.fetchExchangeRates(v['base'] as String);
            if (mounted) setState(() => _bump++);
          },
          done: 'Rates updated',
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- reports

class FinanceReportsTab extends ConsumerWidget {
  const FinanceReportsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(walletRepositoryProvider);
    return DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          const TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: <Tab>[Tab(text: 'Summary'), Tab(text: 'Finance'), Tab(text: 'Balances'), Tab(text: 'Daily')]),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                ResourceView(load: repo.adminSummary, intro: 'Everything the wallet service holds and has moved.'),
                ResourceView(load: repo.financeSummary, intro: 'Totals by provider and kind.'),
                ResourceView(load: repo.adminBalanceOverview, intro: 'Balances across every wallet.'),
                AskThenShow(
                  intro: 'Money movement for one day.',
                  fields: const <FieldSpec>[FieldSpec('date', 'Day', kind: FieldKind.date, required: true)],
                  submitLabel: 'Show',
                  fetch: (v) => repo.adminDaily(DateTime.parse(v['date'] as String)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
