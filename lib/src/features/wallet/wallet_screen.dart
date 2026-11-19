import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/masking.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/wallet_models.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/service_widgets.dart';
import '../shared/person_widgets.dart';
import 'wallet_forms.dart';
import 'wallet_money.dart';

/// Payments: the balance of the wallet, the ways to move money, and the latest activity. Talks to the wallet service.
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  bool _opening = false;

  Future<void> _refresh() async {
    ref.invalidate(walletProvider);
    ref.invalidate(walletTransactionsProvider);
  }

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
      loading: () => const SkeletonList(),
      error: (e, _) {
        final err = ApiException.from(e);
        if (err.isNotFound) {
          return EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'No wallet yet',
            message: 'Open your wallet to deposit, pay for bookings and rent, and send money.',
            actionLabel: _opening ? 'Opening' : 'Open my wallet',
            onAction: _opening ? null : _openWallet,
          );
        }
        return ErrorState(error: e, onRetry: _refresh);
      },
      data: (w) => _WalletBody(wallet: w, onRefresh: _refresh),
    );
  }
}

class _WalletBody extends ConsumerWidget {
  const _WalletBody({required this.wallet, required this.onRefresh});

  final WalletModel wallet;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(walletTransactionsProvider);
    return PageBody(
      maxWidth: 860,
      onRefresh: onRefresh,
      children: <Widget>[
        HeroPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(child: Text('Wallet balance', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
                  if (wallet.frozen) const StatusPill('Frozen', color: Brand.gold, icon: Icons.lock_outline_rounded),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                formatMoney(wallet.balance, wallet.currency),
                style: context.display(size: 34, weight: FontWeight.w800, spacing: -1, color: Brand.cream),
              ),
              if (wallet.defaultCurrencyBalance != null && wallet.defaultCurrency != wallet.currency)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('About ${formatMoney(wallet.defaultCurrencyBalance, wallet.defaultCurrency)}', style: const TextStyle(fontSize: 13.5)),
                ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => copyText(context, wallet.accountNumber, done: 'Wallet email copied'),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.alternate_email_rounded, size: 16),
                    const SizedBox(width: 6),
                    Flexible(child: Text(wallet.accountNumber, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (wallet.frozen)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: InlineMessage('This wallet is frozen, so money cannot be moved. Contact support to have it unlocked.', kind: MessageKind.warning),
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            PButton(
              label: 'Deposit',
              icon: Icons.add_rounded,
              onPressed: wallet.frozen
                  ? null
                  : () => showMoneyChooser(context, title: 'Deposit', subtitle: 'Choose how you want to add money.', options: MoneyFlows(context, ref).deposits()),
            ),
            PButton(
              label: 'Send',
              icon: Icons.north_east_rounded,
              kind: PButtonKind.outline,
              onPressed: wallet.frozen ? null : () => MoneyFlows(context, ref).sends().first.start(),
            ),
            PButton(
              label: 'Withdraw',
              icon: Icons.south_west_rounded,
              kind: PButtonKind.outline,
              onPressed: wallet.frozen
                  ? null
                  : () => showMoneyChooser(context, title: 'Withdraw', subtitle: 'Choose where the money goes.', options: MoneyFlows(context, ref).withdrawals()),
            ),
          ],
        ),
        const SectionHeader('Payment methods'),
        MenuGroup(
          children: <Widget>[
            MenuTile(
              icon: Icons.phone_iphone_rounded,
              title: 'M-Pesa',
              subtitle: wallet.mpesaPhoneNumber == null ? 'No number on the wallet yet' : maskPhone(wallet.mpesaPhoneNumber),
              trailing: const SizedBox.shrink(),
            ),
            if (wallet.pochiPhoneNumber != null)
              MenuTile(icon: Icons.storefront_outlined, title: 'Pochi la Biashara', subtitle: maskPhone(wallet.pochiPhoneNumber), trailing: const SizedBox.shrink()),
            MenuTile(
              icon: Icons.credit_card_rounded,
              title: 'Card',
              subtitle: wallet.hasSavedCard ? '${wallet.cardBrand ?? 'Card'} ending ${wallet.cardLast4 ?? ''}' : 'No card saved',
              trailing: const SizedBox.shrink(),
            ),
            MenuTile(
              icon: Icons.account_balance_outlined,
              title: 'PayPal',
              subtitle: wallet.paypalEmail == null ? 'Not connected' : maskEmail(wallet.paypalEmail),
              trailing: const SizedBox.shrink(),
            ),
          ],
        ),
        SectionHeader(
          'Recent activity',
          action: 'See all',
          onAction: () => DefaultTabController.maybeOf(context)?.animateTo(2),
        ),
        activity.when(
          loading: () => const SkeletonList(count: 3, height: 64, shrink: true, padding: EdgeInsets.zero),
          error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(walletTransactionsProvider)),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyState(icon: Icons.receipt_long_outlined, title: 'Nothing yet', message: 'Deposits, payments and transfers show up here.');
            }
            return Column(
              children: <Widget>[
                for (final t in items.take(5))
                  ActivityRow(
                    title: activityTitle(t),
                    subtitle: whenLabel(t.createdAt),
                    amount: formatMoney(t.amount, t.currency),
                    credit: t.isCredit,
                    status: t.status,
                    leading: (t.counterpartyId ?? t.counterpartyEmail) == null
                        ? null
                        : PersonAvatar(PersonRef(id: t.counterpartyId, email: t.counterpartyEmail, name: t.counterpartyName), size: 40),
                    onTap: () => showActivityDetail(context, t),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: PButton(
            label: 'Statement',
            icon: Icons.description_outlined,
            kind: PButtonKind.text,
            small: true,
            onPressed: () => showFormSheet<void>(context, title: 'Statement', subtitle: 'Money in and out for a period.', child: const StatementSheet()),
          ),
        ),
      ],
    );
  }
}
