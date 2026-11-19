import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/currencies.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/masking.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/ask_then_show.dart';
import '../shared/hub.dart';
import '../shared/person_widgets.dart';
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
            hidden: const <String>{'counterpartyId', 'counterpartyName'},
            row: RowView(
              icon: Icons.receipt_long_outlined,
              leading: (context, m) => walletRowLeading(context, m, Icons.receipt_long_outlined),
              header: walletRowHeader,
              title: (m) {
                final what = sentence(pick(m, <String>['type', 'provider', 'service', 'direction'], 'Activity'));
                final who = pick(m, <String>['description', 'recipientName', 'counterparty', 'destination']);
                return who.isEmpty ? what : who;
              },
              subtitle: (m) => <String>[
                sentence(pick(m, <String>['type'])),
                displayValue(m['createdAt'] ?? m['timestamp'] ?? m['date']),
              ].where((e) => e.isNotEmpty).join(' - '),
              status: (m) => pick(m, <String>['status']),
              trailing: (m) {
                if (m['amount'] is! num) return null;
                final sign = pick(m, <String>['direction']) == 'IN' ? '+' : (pick(m, <String>['direction']) == 'OUT' ? '-' : '');
                return '$sign${formatMoney(m['amount'] as num, pick(m, <String>['currency'], platformCurrency))}';
              },
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

/// The wallet's currency, the numbers and email that deposits and withdrawals use, and freezing the wallet. A saved number
/// is shown shortened. Opening it to change it puts the saved value in the box, and when nothing is saved the box shows
/// only its label and a hint.
class WalletSettingsTab extends ConsumerStatefulWidget {
  const WalletSettingsTab({super.key});

  @override
  ConsumerState<WalletSettingsTab> createState() => _WalletSettingsTabState();
}

class _WalletSettingsTabState extends ConsumerState<WalletSettingsTab> {
  late Future<Json> _future;

  WalletRepository get _repo => ref.read(walletRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _future = _repo.walletRaw();
  }

  void _reload() {
    ref.invalidate(walletProvider);
    if (mounted) setState(() => _future = _repo.walletRaw());
  }

  Future<void> _edit({
    required String title,
    String? subtitle,
    required FieldSpec field,
    required String? current,
    required Future<void> Function(String value) save,
    required String done,
  }) async {
    final ok = await showResourceForm(
      context,
      title: title,
      subtitle: subtitle,
      fields: <FieldSpec>[field],
      initial: <String, dynamic>{field.key: current},
      onSubmit: (v) => save(v[field.key] as String),
    );
    if (ok && mounted) {
      showToast(context, done);
      _reload();
    }
  }

  Future<void> _chooseCurrency(String current) async {
    final ok = await showResourceForm(
      context,
      title: 'Default currency',
      subtitle: 'Amounts you type for deposits and withdrawals are in this currency. Your balance is always kept in US dollars. The system default is $platformCurrency.',
      fields: <FieldSpec>[
        FieldSpec(
          'currency',
          'Currency',
          kind: FieldKind.picker,
          required: true,
          initial: current,
          loader: () async => <PickOption>[for (final c in currencyChoices) PickOption(c.code, '${c.code}, ${c.name}')],
        ),
      ],
      onSubmit: (v) => _repo.updateDefaultCurrency(v['currency'] as String),
    );
    if (ok && mounted) {
      showToast(context, 'Default currency saved');
      _reload();
    }
  }

  Future<void> _setFrozen(bool freeze) async {
    final yes = await confirmDialog(
      context,
      title: freeze ? 'Freeze wallet' : 'Unfreeze wallet',
      message: freeze ? 'No money can move in or out until you unfreeze the wallet.' : 'Let money move in and out of the wallet again.',
      confirmLabel: freeze ? 'Freeze' : 'Unfreeze',
      danger: freeze,
    );
    if (!yes || !mounted) return;
    final ok = await attempt(context, () => freeze ? _repo.freeze() : _repo.unfreeze(), done: freeze ? 'Wallet frozen' : 'Wallet unfrozen');
    if (ok) _reload();
  }

  static String _currencyName(String code) {
    for (final c in currencyChoices) {
      if (c.code == code) return '${c.code}, ${c.name}';
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: 720,
      onRefresh: () async => _reload(),
      children: <Widget>[
        FutureBuilder<Json>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const SkeletonList(count: 3, height: 64, shrink: true);
            if (snap.hasError) return ErrorState(error: snap.error!, onRetry: _reload);
            final w = snap.data ?? <String, dynamic>{};
            String text(String k) => pick(w, <String>[k]);
            final currency = pick(w, <String>['defaultCurrency'], platformCurrency);
            final frozen = w['frozen'] == true || w['isFrozen'] == true;
            final mpesa = text('mpesaPhoneNumber');
            final pochi = text('pochiPhoneNumber');
            final paypal = text('paypalEmail');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SectionHeader('Currency', padding: EdgeInsets.only(top: 4, bottom: 12)),
                MenuGroup(
                  children: <Widget>[
                    MenuTile(
                      icon: Icons.currency_exchange_rounded,
                      title: 'Default currency',
                      subtitle: _currencyName(currency),
                      onTap: () => _chooseCurrency(currency),
                    ),
                  ],
                ),
                const SectionHeader('Payout and deposit details'),
                MenuGroup(
                  children: <Widget>[
                    MenuTile(
                      icon: Icons.phone_iphone_rounded,
                      title: 'M-Pesa number',
                      subtitle: mpesa.isEmpty ? 'Not set' : maskPhone(mpesa),
                      onTap: () => _edit(
                        title: 'M-Pesa number',
                        subtitle: 'Used for deposits when you do not type a number, and for withdrawals to M-Pesa.',
                        field: const FieldSpec('mpesaPhoneNumber', 'M-Pesa phone', kind: FieldKind.phone, required: true, hint: '2547...'),
                        current: mpesa.isEmpty ? null : mpesa,
                        save: _repo.updateMpesaPhone,
                        done: 'M-Pesa number saved',
                      ),
                    ),
                    MenuTile(
                      icon: Icons.storefront_outlined,
                      title: 'Pochi la Biashara number',
                      subtitle: pochi.isEmpty ? 'Not set' : maskPhone(pochi),
                      onTap: () => _edit(
                        title: 'Pochi la Biashara number',
                        subtitle: 'Used for payments to your Pochi account.',
                        field: const FieldSpec('pochiPhoneNumber', 'Pochi phone', kind: FieldKind.phone, required: true, hint: '2547...'),
                        current: pochi.isEmpty ? null : pochi,
                        save: _repo.updatePochiPhone,
                        done: 'Pochi number saved',
                      ),
                    ),
                    MenuTile(
                      icon: Icons.alternate_email_rounded,
                      title: 'PayPal email',
                      subtitle: paypal.isEmpty ? 'Not set' : maskEmail(paypal),
                      onTap: () => _edit(
                        title: 'PayPal email',
                        subtitle: 'PayPal withdrawals are sent to this address.',
                        field: const FieldSpec('paypalEmail', 'Email', kind: FieldKind.email, required: true, hint: 'name@...'),
                        current: paypal.isEmpty ? null : paypal,
                        save: _repo.updatePaypalEmail,
                        done: 'PayPal email saved',
                      ),
                    ),
                  ],
                ),
                const SectionHeader('Security'),
                MenuGroup(
                  children: <Widget>[
                    MenuTile(
                      icon: frozen ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                      title: frozen ? 'Unfreeze wallet' : 'Freeze wallet',
                      subtitle: frozen ? 'The wallet is frozen. No money can move.' : 'Stops money moving in or out until you unfreeze it.',
                      onTap: () => _setFrozen(!frozen),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
