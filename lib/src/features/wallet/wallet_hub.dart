import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/ask_then_show.dart';
import '../shared/hub.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';
import 'wallet_accounts.dart';
import 'wallet_money.dart';
import 'wallet_screen.dart';

/// The wallet with a menu for each part of it: balance, money in and out, history, statements, linked accounts, payment
/// requests, merchant applications and settings.
class WalletHub extends ConsumerStatefulWidget {
  const WalletHub({super.key});

  @override
  ConsumerState<WalletHub> createState() => _WalletHubState();
}

class _WalletHubState extends ConsumerState<WalletHub> {
  bool _opening = false;

  Future<void> _openWallet() async {
    setState(() => _opening = true);
    try {
      await ref.read(walletRepositoryProvider).createWallet();
      ref.invalidate(walletProvider);
      if (mounted) showToast(context, 'Your wallet is ready');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    return wallet.when(
      loading: () => const PScaffold(body: SkeletonList()),
      error: (e, _) {
        if (ApiException.from(e).isNotFound) {
          return PScaffold(
            body: EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No wallet yet',
              message: 'Open your wallet to deposit, pay for bookings and rent, and send money.',
              actionLabel: _opening ? 'Opening' : 'Open my wallet',
              onAction: _opening ? null : _openWallet,
            ),
          );
        }
        return PScaffold(body: ErrorState(error: e, onRetry: () => ref.invalidate(walletProvider)));
      },
      data: (_) => HubPage(
        title: 'Wallet',
        tabs: <HubTab>[
          HubTab('Overview', Icons.account_balance_wallet_outlined, (_) => const WalletScreen()),
          HubTab('Money', Icons.swap_vert_rounded, (_) => const MoneyTab()),
          HubTab('History', Icons.receipt_long_outlined, (_) => const HistoryTab()),
          HubTab('Statement', Icons.description_outlined, (_) => const StatementTab()),
          HubTab('Linked accounts', Icons.link_rounded, (_) => const LinkedAccountsTab()),
          HubTab('Requests', Icons.fact_check_outlined, (_) => const ConsentsTab()),
          HubTab('Merchant', Icons.storefront_outlined, (_) => const MerchantTab()),
          HubTab('Settings', Icons.settings_outlined, (_) => const WalletSettingsTab()),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ history

enum _Kind { all, deposits, withdrawals, transfers, payments }

const Map<_Kind, String> _kindNames = <_Kind, String>{
  _Kind.all: 'All activity',
  _Kind.deposits: 'Deposits',
  _Kind.withdrawals: 'Withdrawals',
  _Kind.transfers: 'Transfers',
  _Kind.payments: 'Payments',
};

/// Everything the wallet did, by kind, with filters for status and dates.
class HistoryTab extends ConsumerStatefulWidget {
  const HistoryTab({super.key});

  @override
  ConsumerState<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends ConsumerState<HistoryTab> {
  _Kind _kind = _Kind.all;
  String? _status;
  DateTime? _from;
  DateTime? _to;

  Future<List<Json>> _load() {
    final repo = ref.read(walletRepositoryProvider);
    switch (_kind) {
      case _Kind.all:
        return repo.transactionRows();
      case _Kind.deposits:
        return repo.depositRows(status: _status, from: _from, to: _to);
      case _Kind.withdrawals:
        return repo.withdrawalRows(status: _status, from: _from, to: _to);
      case _Kind.transfers:
        return repo.transferRows(status: _status, from: _from, to: _to);
      case _Kind.payments:
        return repo.paymentRows(status: _status, from: _from, to: _to);
    }
  }

  Future<void> _filter() async {
    await showResourceForm(
      context,
      title: 'Filter',
      subtitle: 'Applies to deposits, withdrawals, transfers and payments.',
      submitLabel: 'Apply',
      initial: <String, dynamic>{
        'status': _status,
        'from': _from?.toIso8601String().substring(0, 10),
        'to': _to?.toIso8601String().substring(0, 10),
      },
      fields: const <FieldSpec>[
        FieldSpec('status', 'Status', kind: FieldKind.select, clearable: true, options: <String, String>{'PENDING': 'Pending', 'SUCCESS': 'Successful', 'FAILED': 'Failed'}),
        FieldSpec('from', 'From', kind: FieldKind.date, clearable: true),
        FieldSpec('to', 'To', kind: FieldKind.date, clearable: true),
      ],
      onSubmit: (v) async {
        String? text(Object? x) => x is String && x.isNotEmpty ? x : null;
        setState(() {
          _status = text(v['status']);
          _from = text(v['from']) == null ? null : DateTime.tryParse(text(v['from'])!);
          _to = text(v['to']) == null ? null : DateTime.tryParse(text(v['to'])!);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _status != null || _from != null || _to != null;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: <Widget>[
              for (final e in _kindNames.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(e.value), selected: _kind == e.key, onSelected: (_) => setState(() => _kind = e.key)),
                ),
              ActionChip(
                avatar: Icon(filtered ? Icons.filter_alt_rounded : Icons.filter_alt_outlined, size: 18),
                label: Text(filtered ? 'Filtered' : 'Filter'),
                onPressed: _kind == _Kind.all ? null : _filter,
              ),
            ],
          ),
        ),
        Expanded(
          child: ResourceSection(
            refreshKey: '$_kind$_status$_from$_to',
            load: _load,
            emptyTitle: 'Nothing here',
            emptyMessage: 'Money that moves in and out of the wallet shows here.',
            emptyIcon: Icons.receipt_long_outlined,
            row: RowView(
              icon: Icons.receipt_long_outlined,
              title: (m) {
                final what = sentence(pick(m, <String>['type', 'provider', 'service', 'direction'], 'Activity'));
                final who = pick(m, <String>['description', 'recipientName', 'counterparty', 'destination']);
                return who.isEmpty ? what : '$what, $who';
              },
              subtitle: (m) => displayValue(m['createdAt'] ?? m['timestamp'] ?? m['date']),
              status: (m) => pick(m, <String>['status']),
              trailing: (m) => m['amount'] is num ? formatMoney(m['amount'] as num, pick(m, <String>['currency'], platformCurrency)) : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- statement

/// Money in and out over a period, from the server.
class StatementTab extends ConsumerWidget {
  const StatementTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(walletRepositoryProvider);
    return AskThenShow(
      intro: 'Choose a period to see what moved in and out of your wallet.',
      submitLabel: 'Show statement',
      fields: const <FieldSpec>[
        FieldSpec('fromDate', 'From', kind: FieldKind.date, required: true),
        FieldSpec('toDate', 'To', kind: FieldKind.date),
        FieldSpec('type', 'Kind', kind: FieldKind.select, clearable: true, options: <String, String>{
          'DEPOSIT': 'Deposits',
          'WITHDRAWAL': 'Withdrawals',
          'TRANSFER': 'Transfers',
          'PAYMENT': 'Payments',
          'REFUND': 'Refunds',
        }),
      ],
      fetch: repo.statementData,
    );
  }
}

// ----------------------------------------------------------------- settings

/// Freeze the wallet, and the numbers and email that deposits and withdrawals use by default.
class WalletSettingsTab extends ConsumerStatefulWidget {
  const WalletSettingsTab({super.key});

  @override
  ConsumerState<WalletSettingsTab> createState() => _WalletSettingsTabState();
}

class _WalletSettingsTabState extends ConsumerState<WalletSettingsTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(walletRepositoryProvider);
    void changed() {
      ref.invalidate(walletProvider);
      if (mounted) setState(() => _bump++);
    }

    return ResourceView(
      refreshKey: _bump,
      load: repo.balanceInfo,
      intro: 'Your balance and the defaults the wallet uses.',
      actions: <ItemAction>[
        ItemAction(
          'Freeze wallet',
          Icons.lock_outline_rounded,
          danger: true,
          visible: (m) => m['frozen'] != true,
          confirm: 'No money can move in or out until you unfreeze the wallet.',
          run: (_, __) async {
            await repo.freeze();
            changed();
          },
          done: 'Wallet frozen',
        ),
        ItemAction(
          'Unfreeze wallet',
          Icons.lock_open_rounded,
          visible: (m) => m['frozen'] == true,
          confirm: 'Let money move in and out of the wallet again.',
          run: (_, __) async {
            await repo.unfreeze();
            changed();
          },
          done: 'Wallet unfrozen',
        ),
        ItemAction(
          'M-Pesa number',
          Icons.phone_iphone_rounded,
          title: 'M-Pesa number',
          subtitle: 'Used for deposits when you do not type a number.',
          fields: const <FieldSpec>[FieldSpec('phone', 'Phone', kind: FieldKind.phone, required: true, hint: '254712345678')],
          run: (_, v) async {
            await repo.updateMpesaPhone(v['phone'] as String);
            changed();
          },
          done: 'M-Pesa number saved',
        ),
        ItemAction(
          'Pochi number',
          Icons.storefront_outlined,
          title: 'Pochi la Biashara number',
          fields: const <FieldSpec>[FieldSpec('phone', 'Phone', kind: FieldKind.phone, required: true, hint: '254712345678')],
          run: (_, v) async {
            await repo.updatePochiPhone(v['phone'] as String);
            changed();
          },
          done: 'Pochi number saved',
        ),
        ItemAction(
          'PayPal email',
          Icons.alternate_email_rounded,
          title: 'PayPal email',
          fields: const <FieldSpec>[FieldSpec('email', 'Email', kind: FieldKind.email, required: true)],
          run: (_, v) async {
            await repo.updatePaypalEmail(v['email'] as String);
            changed();
          },
          done: 'PayPal email saved',
        ),
      ],
    );
  }
}
