import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode, launchUrl;

import '../../core/network/api_exception.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';

Future<void> _open(String? url) async {
  if (url == null || url.isEmpty) return;
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Accounts linked to the wallet: saved cards, PayPal, Flutterwave and the bank linked through Stripe.
class LinkedAccountsTab extends StatelessWidget {
  const LinkedAccountsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 4,
      child: Column(
        children: <Widget>[
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Tab>[Tab(text: 'Cards'), Tab(text: 'PayPal'), Tab(text: 'Flutterwave'), Tab(text: 'Bank')],
          ),
          Expanded(child: TabBarView(children: <Widget>[_CardsView(), _PaypalView(), _FlutterwaveView(), _BankView()])),
        ],
      ),
    );
  }
}

class _CardsView extends ConsumerStatefulWidget {
  const _CardsView();

  @override
  ConsumerState<_CardsView> createState() => _CardsViewState();
}

class _CardsViewState extends ConsumerState<_CardsView> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(walletRepositoryProvider);
    String id(Json m) => pick(m, <String>['paymentMethodId', 'id']);
    void changed() {
      ref.invalidate(walletProvider);
      if (mounted) setState(() => _bump++);
    }

    return ResourceSection(
      refreshKey: _bump,
      load: repo.stripeCards,
      intro: 'Cards saved for deposits. The default card is charged first.',
      emptyTitle: 'No saved cards',
      emptyMessage: 'Start saving a card, finish on the card form, then confirm it here with the setup id.',
      emptyIcon: Icons.credit_card_rounded,
      row: RowView(
        icon: Icons.credit_card_rounded,
        title: (m) => '${pick(m, <String>['brand'], 'Card')} ending ${pick(m, <String>['last4'])}',
        status: (m) => m['isDefault'] == true || m['default'] == true ? 'DEFAULT' : null,
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Start saving a card',
          Icons.add_card_rounded,
          title: 'Start saving a card',
          confirm: 'Creates a setup on your wallet. You get a setup id and a client secret to finish on the card form.',
          run: (_, __) async {
            final r = await repo.stripeSetupIntent();
            if (!mounted) return;
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Card setup started'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('Setup id', style: TextStyle(fontWeight: FontWeight.w700)),
                    SelectableText(pick(r, <String>['setupIntentId'])),
                    const SizedBox(height: 10),
                    const Text('Client secret', style: TextStyle(fontWeight: FontWeight.w700)),
                    SelectableText(pick(r, <String>['clientSecret'])),
                  ],
                ),
                actions: <Widget>[TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
              ),
            );
          },
        ),
        ItemAction(
          'Confirm a card',
          Icons.verified_outlined,
          title: 'Confirm a saved card',
          fields: const <FieldSpec>[FieldSpec('setupIntentId', 'Setup id', required: true)],
          run: (_, v) async {
            await repo.confirmStripeSetupIntent(v['setupIntentId'] as String);
            changed();
          },
          done: 'Card saved',
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction(
          'Make default',
          Icons.star_outline_rounded,
          visible: (m) => m['isDefault'] != true && m['default'] != true,
          run: (m, _) async {
            await repo.setDefaultStripeCard(id(m));
            changed();
          },
          done: 'Default card changed',
        ),
        ItemAction(
          'Remove',
          Icons.delete_outline_rounded,
          danger: true,
          confirm: 'Remove this card from your wallet?',
          run: (m, _) async {
            await repo.removeStripeCard(id(m));
            changed();
          },
          done: 'Card removed',
        ),
      ],
    );
  }
}

class _PaypalView extends ConsumerStatefulWidget {
  const _PaypalView();

  @override
  ConsumerState<_PaypalView> createState() => _PaypalViewState();
}

class _PaypalViewState extends ConsumerState<_PaypalView> {
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
      load: repo.paypalAccount,
      intro: 'Link a PayPal account to deposit from it and withdraw to it.',
      actions: <ItemAction>[
        ItemAction(
          'Link PayPal',
          Icons.link_rounded,
          visible: (m) => m['linked'] != true && m['connected'] != true,
          confirm: 'PayPal opens in your browser. Approve it there, then come back and confirm with the setup id.',
          run: (_, __) async {
            final r = await repo.paypalLink();
            await _open(pick(r, <String>['approveUrl']));
            if (!mounted) return;
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Approve on PayPal'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text('After you approve, choose Confirm the link and enter this setup id.'),
                    const SizedBox(height: 10),
                    SelectableText(pick(r, <String>['setupTokenId'])),
                  ],
                ),
                actions: <Widget>[TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
              ),
            );
          },
        ),
        ItemAction(
          'Confirm the link',
          Icons.verified_outlined,
          title: 'Confirm the PayPal link',
          visible: (m) => m['linked'] != true && m['connected'] != true,
          fields: const <FieldSpec>[FieldSpec('setupTokenId', 'Setup id', required: true)],
          run: (_, v) async {
            await repo.paypalLinkConfirm(v['setupTokenId'] as String);
            changed();
          },
          done: 'PayPal linked',
        ),
        ItemAction(
          'Disconnect',
          Icons.link_off_rounded,
          danger: true,
          visible: (m) => m['linked'] == true || m['connected'] == true,
          confirm: 'Unlink PayPal from your wallet. This does not revoke access on PayPal.',
          run: (_, __) async {
            await repo.paypalDisconnect();
            changed();
          },
          done: 'PayPal disconnected',
        ),
      ],
    );
  }
}

class _FlutterwaveView extends ConsumerStatefulWidget {
  const _FlutterwaveView();

  @override
  ConsumerState<_FlutterwaveView> createState() => _FlutterwaveViewState();
}

class _FlutterwaveViewState extends ConsumerState<_FlutterwaveView> {
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
      load: repo.flutterwaveAccount,
      intro: 'Link a Flutterwave customer to your wallet.',
      actions: <ItemAction>[
        ItemAction(
          'Start linking',
          Icons.link_rounded,
          confirm: 'Registers your wallet for linking. Then enter the Flutterwave customer details.',
          run: (_, __) async {
            await repo.flutterwaveLink();
          },
          done: 'Linking started',
        ),
        ItemAction(
          'Enter the customer details',
          Icons.verified_outlined,
          title: 'Link Flutterwave',
          visible: (m) => m['linked'] != true,
          fields: const <FieldSpec>[
            FieldSpec('customerId', 'Customer id', required: true),
            FieldSpec('paymentMethodId', 'Payment method id'),
            FieldSpec('network', 'Mobile network'),
            FieldSpec('phone', 'Phone', kind: FieldKind.phone),
          ],
          run: (_, v) async {
            await repo.flutterwaveLinkConfirm(v);
            changed();
          },
          done: 'Flutterwave linked',
        ),
        ItemAction(
          'Unlink',
          Icons.link_off_rounded,
          danger: true,
          visible: (m) => m['linked'] == true,
          confirm: 'Unlink Flutterwave from your wallet?',
          run: (_, __) async {
            await repo.flutterwaveUnlink();
            changed();
          },
          done: 'Flutterwave unlinked',
        ),
      ],
    );
  }
}

class _BankView extends ConsumerStatefulWidget {
  const _BankView();

  @override
  ConsumerState<_BankView> createState() => _BankViewState();
}

class _BankViewState extends ConsumerState<_BankView> {
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
      load: repo.stripeConnectAccount,
      intro: 'A bank account linked through Stripe, used to withdraw to your bank.',
      actions: <ItemAction>[
        ItemAction(
          'Link a bank',
          Icons.account_balance_rounded,
          confirm: 'Stripe opens in your browser to collect your bank details. The link works once.',
          run: (_, __) async {
            final r = await repo.stripeConnectLink();
            await _open(pick(r, <String>['onboardingUrl', 'url']));
          },
        ),
        ItemAction(
          'Refresh the link',
          Icons.refresh_rounded,
          confirm: 'Get a new link if the first one expired.',
          run: (_, __) async {
            final r = await repo.stripeConnectRefresh();
            await _open(pick(r, <String>['onboardingUrl', 'url']));
          },
        ),
        ItemAction(
          'Unlink',
          Icons.link_off_rounded,
          danger: true,
          visible: (m) => m['linked'] == true,
          confirm: 'Unlink the bank from your wallet?',
          run: (_, __) async {
            await repo.stripeConnectUnlink();
            changed();
          },
          done: 'Bank unlinked',
        ),
      ],
    );
  }
}

// ------------------------------------------------------- consents, merchants

/// Payments that apps and businesses ask your wallet to make. You approve, decline or revoke each one.
class ConsentsTab extends ConsumerStatefulWidget {
  const ConsentsTab({super.key});

  @override
  ConsumerState<ConsentsTab> createState() => _ConsentsTabState();
}

class _ConsentsTabState extends ConsumerState<ConsentsTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(walletRepositoryProvider);
    String id(Json m) => pick(m, <String>['id']);
    void changed() {
      ref.invalidate(walletProvider);
      ref.invalidate(walletTransactionsProvider);
      if (mounted) setState(() => _bump++);
    }

    return ResourceSection(
      refreshKey: _bump,
      load: () async {
        try {
          return await repo.consents();
        } on ApiException catch (e) {
          // The wallet service answers 404 when payment requests are not switched on (COMMERCIAL_PREMISAVE_ENABLED).
          if (e.isNotFound) return <Map<String, dynamic>>[];
          rethrow;
        }
      },
      intro: 'A business can ask to charge your wallet. Nothing is taken until you approve.',
      emptyTitle: 'No requests',
      emptyMessage: 'Payment requests from businesses show here.',
      emptyIcon: Icons.fact_check_outlined,
      row: RowView(
        icon: Icons.fact_check_outlined,
        title: (m) => pick(m, <String>['merchant', 'merchantName'], 'Payment request'),
        subtitle: (m) => pick(m, <String>['description', 'kind']),
        status: (m) => pick(m, <String>['status']),
        trailing: (m) {
          final text = pick(m, <String>['amountUsd', 'maxPerChargeUsd']);
          final value = double.tryParse(text);
          return value == null ? null : formatMoney(value);
        },
      ),
      itemActions: <ItemAction>[
        ItemAction(
          'Approve',
          Icons.check_circle_outline_rounded,
          visible: (m) => pick(m, <String>['status']) == 'PENDING',
          confirm: 'Allow this payment from your wallet?',
          run: (m, _) async {
            await repo.approveConsent(id(m));
            changed();
          },
          done: 'Approved',
        ),
        ItemAction(
          'Decline',
          Icons.cancel_outlined,
          danger: true,
          visible: (m) => pick(m, <String>['status']) == 'PENDING',
          confirm: 'Decline this payment request?',
          run: (m, _) async {
            await repo.declineConsent(id(m));
            changed();
          },
          done: 'Declined',
        ),
        ItemAction(
          'Revoke',
          Icons.block_rounded,
          danger: true,
          visible: (m) => pick(m, <String>['status']) == 'APPROVED',
          confirm: 'Take back the permission you gave?',
          run: (m, _) async {
            await repo.revokeConsent(id(m));
            changed();
          },
          done: 'Revoked',
        ),
      ],
    );
  }
}

/// Business applications for payment accepting and the merchant numbers that came out of them.
class MerchantTab extends ConsumerWidget {
  const MerchantTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(walletRepositoryProvider);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          const TabBar(tabs: <Tab>[Tab(text: 'Applications'), Tab(text: 'Merchant numbers')]),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                ResourceSection(
                  load: repo.merchantApplications,
                  detail: (m) => repo.merchantApplication(pick(m, <String>['applicationId', 'id'])),
                  intro: 'Applications to accept payments. Start one from the Developers portal.',
                  emptyTitle: 'No applications',
                  emptyIcon: Icons.storefront_outlined,
                  row: RowView(
                    icon: Icons.storefront_outlined,
                    title: (m) => pick(m, <String>['businessName', 'tradingName', 'name'], 'Application'),
                    subtitle: (m) => <String>[sentence(pick(m, <String>['status'])), pick(m, <String>['country'])].where((e) => e.isNotEmpty).join(' - '),
                    status: (m) => pick(m, <String>['status']),
                  ),
                ),
                ResourceSection(
                  load: repo.merchantNumbers,
                  emptyTitle: 'No merchant numbers',
                  emptyIcon: Icons.pin_outlined,
                  row: RowView(
                    icon: Icons.pin_outlined,
                    title: (m) => pick(m, <String>['merchantNumber', 'number', 'shortcode', 'tillNumber'], 'Number'),
                    subtitle: (m) => pick(m, <String>['businessName', 'type', 'description']),
                    status: (m) => pick(m, <String>['status']),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
