import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode, launchUrl;

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/pickers.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';
import '../shared/service_widgets.dart';

double _amount(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;


/// A new key per form, so a retry after a dropped connection can never move the money twice.
String _newReference() => 'app-${DateTime.now().microsecondsSinceEpoch}';

/// One way to move money: a title, a line of help, and what to start when it is picked.
class MoneyOption {
  const MoneyOption(this.icon, this.title, this.subtitle, this.start);

  final IconData icon;
  final String title;
  final String subtitle;
  final Future<void> Function() start;
}

/// Every form behind the wallet's money screens. The Money tab and the Overview buttons both use it, so a deposit or a
/// withdrawal offers the same gateways wherever it is started.
class MoneyFlows {
  MoneyFlows(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  /// The currency amounts are typed in: the one the person chose in Settings, USD until they do.
  String get _currency => ref.read(walletProvider).maybeWhen(data: (w) => w.defaultCurrency, orElse: () => platformCurrency);

  FieldSpec get _amountField => FieldSpec(
        'amount',
        'Amount ($_currency)',
        kind: FieldKind.number,
        required: true,
        helper: 'In your default currency. Change it under Settings.',
      );

  /// M-Pesa takes Kenyan shillings, so its forms always ask in KES, whatever the default currency is. The wallet is
  /// credited or debited the USD value.
  FieldSpec get _kesField => const FieldSpec(
        'amount',
        'Amount (KES)',
        kind: FieldKind.number,
        required: true,
        helper: 'M-Pesa is always in Kenyan shillings. Your wallet is credited the dollar value.',
      );

  void _refresh() {
    ref.invalidate(walletProvider);
    ref.invalidate(walletTransactionsProvider);
  }

  /// Opens a form, sends it, and then tells the person what the provider answered, with a link when there is one.
  Future<void> flow({
    required String title,
    String? subtitle,
    required List<FieldSpec> fields,
    required Future<Json> Function(Json values, String reference) call,
    String submit = 'Continue',
  }) async {
    final reference = _newReference();
    Json? answer;
    final ok = await showResourceForm(
      context,
      title: title,
      subtitle: subtitle,
      fields: fields,
      submitLabel: submit,
      onSubmit: (values) async {
        answer = await call(values, reference);
      },
    );
    if (!ok || !context.mounted) return;
    _refresh();
    await _showAnswer(title, answer ?? const <String, dynamic>{});
  }

  Future<void> _showAnswer(String title, Json raw) async {
    final inner = raw['data'];
    final Json data = inner is Map ? Map<String, dynamic>.from(inner) : raw;
    final success = data['success'] != false;
    final message = pick(data, <String>['message'], pick(raw, <String>['message'], success ? 'Done' : 'Not completed'));
    final code = pick(data, <String>['transactionId', 'disbursementId', 'id']);
    final isLink = code.startsWith('http');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(success ? title : 'Not completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(message),
            if (code.isNotEmpty && !isLink) ...<Widget>[
              const SizedBox(height: 12),
              const Text('Reference', style: TextStyle(fontWeight: FontWeight.w700)),
              SelectableText(code),
              const SizedBox(height: 6),
              const Text('Keep it. You need it to confirm the payment after you have paid.', style: TextStyle(fontSize: 12.5)),
            ],
          ],
        ),
        actions: <Widget>[
          if (code.isNotEmpty && !isLink) TextButton(onPressed: () => copyText(ctx, code, done: 'Reference copied'), child: const Text('Copy reference')),
          if (isLink) TextButton(onPressed: () => launchUrl(Uri.parse(code), mode: LaunchMode.externalApplication), child: const Text('Open payment page')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  List<MoneyOption> deposits() {
    final repo = ref.read(walletRepositoryProvider);
    return <MoneyOption>[

            MoneyOption(Icons.phone_iphone_rounded, 'M-Pesa', 'A prompt comes to your phone', () => flow(
                  title: 'Deposit with M-Pesa',
                  subtitle: 'Leave the phone empty to use the number saved on your wallet.',
                  fields: <FieldSpec>[_kesField, const FieldSpec('phoneNumber', 'M-Pesa phone', kind: FieldKind.phone, hint: '2547...')],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'MPESA'}),
                )),
            MoneyOption(Icons.storefront_outlined, 'M-Pesa till', 'Pay from a business till with Express Checkout', () => flow(
                  title: 'Deposit from a till',
                  subtitle: 'The prompt goes to the phone registered as the till operator.',
                  fields: <FieldSpec>[_kesField, const FieldSpec('payerTillNumber', 'Till number', required: true)],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'MPESA_TILL'}),
                )),
            MoneyOption(Icons.credit_card_rounded, 'Card', 'Charges your saved card', () => flow(
                  title: 'Deposit by card',
                  subtitle: 'Uses your default saved card. Save one under Linked accounts first.',
                  fields: <FieldSpec>[_amountField],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'STRIPE'}),
                )),
            MoneyOption(Icons.account_balance_outlined, 'PayPal', 'Approve the payment on PayPal', () => flow(
                  title: 'Deposit with PayPal',
                  fields: <FieldSpec>[_amountField],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'PAYPAL'}),
                )),
            MoneyOption(Icons.public_rounded, 'Flutterwave', 'Mobile money and cards across Africa', () => flow(
                  title: 'Deposit with Flutterwave',
                  fields: <FieldSpec>[
                    const FieldSpec('amount', 'Amount', kind: FieldKind.number, required: true, helper: 'In the money of the mobile network, shown next.'),
                    const FieldSpec('currency', 'Network currency', required: true, hint: 'GHS', helper: 'The money the mobile network uses.'),
                    const FieldSpec('flutterwaveCountryCode', 'Country dialling code', hint: '233', helper: 'For mobile money.'),
                    FieldSpec('flutterwaveMobileNetwork', 'Mobile network', hint: 'MTN', helper: 'For mobile money.'),
                    FieldSpec('flutterwavePaymentOptions', 'Checkout options', hint: 'card,banktransfer', helper: 'Leave empty to show every option.'),
                    FieldSpec('customerName', 'Your name'),
                    FieldSpec('customerPhone', 'Your phone', kind: FieldKind.phone),
                  ],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'FLUTTERWAVE'}),
                )),
            MoneyOption(Icons.currency_bitcoin_rounded, 'Crypto', 'Pay with a cryptocurrency', () => flow(
                  title: 'Deposit with crypto',
                  fields: const <FieldSpec>[
                    FieldSpec('amount', 'Amount', kind: FieldKind.number, required: true),
                    FieldSpec('nowPaymentsPriceCurrency', 'Amount is in', hint: 'usd', helper: 'The money currency the amount is priced in.'),
                    FieldSpec('currency', 'Pay with', required: true, hint: 'usdttrc20', helper: 'The cryptocurrency, for example btc or usdttrc20.'),
                  ],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'NOWPAYMENTS'}),
                )),
    ];
  }

  List<MoneyOption> sends() {
    final repo = ref.read(walletRepositoryProvider);
    final profiles = ref.read(profileRepositoryProvider);
    return <MoneyOption>[

            MoneyOption(Icons.north_east_rounded, 'Send to another wallet', 'Search for a person by name', () => flow(
                  title: 'Send money',
                  fields: <FieldSpec>[
                    userPicker(
                      profiles,
                      key: 'recipientAccountNumber',
                      label: 'Send to',
                      required: true,
                      by: PersonValue.email,
                      helper: 'Type a name, username or email. Pick the person and their wallet is filled in.',
                    ),
                    _amountField,
                    const FieldSpec('description', 'Note'),
                  ],
                  call: (v, ref) => repo.transferRaw(<String, dynamic>{...v, 'amount': _amount(v['amount']), 'reference': ref}),
                  submit: 'Send',
                )),
                ];
  }

  List<MoneyOption> withdrawals() {
    final repo = ref.read(walletRepositoryProvider);
    return <MoneyOption>[
MoneyOption(Icons.phone_iphone_rounded, 'Withdraw to M-Pesa', 'To your verified number', () => flow(
                  title: 'Withdraw to M-Pesa',
                  fields: <FieldSpec>[_kesField, const FieldSpec('remarks', 'Note')],
                  call: (v, ref) => repo.disburse(<String, dynamic>{...v, 'provider': 'MPESA', 'reference': ref}),
                  submit: 'Withdraw',
                )),
            MoneyOption(Icons.storefront_outlined, 'Pay to Pochi la Biashara', 'To any Pochi number', () => flow(
                  title: 'Pay to Pochi la Biashara',
                  fields: <FieldSpec>[
                    _kesField,
                    const FieldSpec('phoneNumber', 'Pochi phone', kind: FieldKind.phone, hint: '2547...', helper: 'Leave empty to use the number saved on your wallet.'),
                    FieldSpec('remarks', 'Note'),
                    FieldSpec('occasion', 'Occasion'),
                  ],
                  call: (v, ref) => repo.disburseToPochi(<String, dynamic>{...v, 'reference': ref}),
                  submit: 'Pay',
                )),
            MoneyOption(Icons.account_balance_outlined, 'Withdraw to PayPal', 'To a PayPal email', () => flow(
                  title: 'Withdraw to PayPal',
                  fields: <FieldSpec>[
                    _amountField,
                    const FieldSpec('destination', 'PayPal email', kind: FieldKind.email, required: true),
                  ],
                  call: (v, ref) => repo.disburse(<String, dynamic>{...v, 'provider': 'PAYPAL', 'reference': ref}),
                  submit: 'Withdraw',
                )),
            MoneyOption(Icons.account_balance_rounded, 'Withdraw to my bank', 'Through your linked Stripe account', () => flow(
                  title: 'Withdraw to my bank',
                  subtitle: 'Needs a bank linked under Linked accounts.',
                  fields: <FieldSpec>[_amountField],
                  call: (v, ref) => repo.disburse(<String, dynamic>{...v, 'provider': 'STRIPE', 'reference': ref}),
                  submit: 'Withdraw',
                )),
            MoneyOption(Icons.public_rounded, 'Withdraw with Flutterwave', 'Bank or mobile money', () => flow(
                  title: 'Withdraw with Flutterwave',
                  fields: <FieldSpec>[
                    _amountField,
                    const FieldSpec('flutterwaveTransferType', 'To', kind: FieldKind.select, required: true, options: <String, String>{'BANK': 'A bank account', 'MOBILE_MONEY': 'A mobile money number'}),
                    FieldSpec('flutterwaveAccountBank', 'Bank code or network', required: true, hint: 'MTN'),
                    FieldSpec('flutterwaveAccountNumber', 'Account or phone number', required: true),
                    FieldSpec('flutterwaveBeneficiaryName', 'Account holder'),
                    const FieldSpec('currency', 'Payout currency', hint: 'GHS', helper: 'The money the account receives. Leave empty to send the amount above.'),
                  ],
                  call: (v, ref) => repo.disburse(<String, dynamic>{...v, 'provider': 'FLUTTERWAVE', 'reference': ref}),
                  submit: 'Withdraw',
                )),
            MoneyOption(Icons.currency_bitcoin_rounded, 'Withdraw crypto', 'To a crypto address', () => flow(
                  title: 'Withdraw crypto',
                  fields: const <FieldSpec>[
                    FieldSpec('amount', 'Amount', kind: FieldKind.number, required: true),
                    FieldSpec('nowPaymentsPriceCurrency', 'Amount is in', hint: 'usd'),
                    FieldSpec('nowPaymentsCurrency', 'Send as', required: true, hint: 'usdttrc20'),
                    FieldSpec('destination', 'Address', required: true),
                  ],
                  call: (v, ref) => repo.disburse(<String, dynamic>{...v, 'provider': 'NOWPAYMENTS', 'reference': ref}),
                  submit: 'Withdraw',
                )),
    ];
  }

  List<MoneyOption> confirmations() {
    final repo = ref.read(walletRepositoryProvider);
    return <MoneyOption>[

            MoneyOption(Icons.verified_outlined, 'Confirm a card payment', 'With the payment intent id', () => flow(
                  title: 'Confirm a card payment',
                  fields: const <FieldSpec>[FieldSpec('paymentIntentId', 'Payment intent id', required: true)],
                  call: (v, _) => repo.confirmStripeDeposit(v['paymentIntentId'] as String),
                  submit: 'Confirm',
                )),
            MoneyOption(Icons.verified_outlined, 'Confirm a PayPal payment', 'With the order id', () => flow(
                  title: 'Confirm a PayPal payment',
                  fields: const <FieldSpec>[FieldSpec('orderId', 'Order id', required: true)],
                  call: (v, _) => repo.confirmPaypalDeposit(v['orderId'] as String),
                  submit: 'Confirm',
                )),
            MoneyOption(Icons.verified_outlined, 'Confirm a Flutterwave payment', 'With the transaction reference', () => flow(
                  title: 'Confirm a Flutterwave payment',
                  fields: const <FieldSpec>[FieldSpec('txRef', 'Transaction reference', required: true)],
                  call: (v, _) => repo.confirmFlutterwaveDeposit(v['txRef'] as String),
                  submit: 'Confirm',
                )),
            MoneyOption(Icons.mark_email_read_outlined, 'Verify a crypto withdrawal', 'With the code sent to you', () => flow(
                  title: 'Verify a crypto withdrawal',
                  fields: const <FieldSpec>[
                    FieldSpec('disbursementId', 'Withdrawal id', required: true),
                    FieldSpec('verificationCode', 'Verification code', required: true),
                  ],
                  call: (v, _) => repo.verifyNowPaymentsWithdrawal(v['disbursementId'] as String, v['verificationCode'] as String),
                  submit: 'Verify',
                )),
    ];
  }
}

/// Every way to put money in, take money out and settle a payment that was made on a provider's own page.
class MoneyTab extends ConsumerWidget {
  const MoneyTab({super.key});

  Widget _group(List<MoneyOption> options) => MenuGroup(
        children: <Widget>[for (final o in options) MenuTile(icon: o.icon, title: o.title, subtitle: o.subtitle, onTap: o.start)],
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flows = MoneyFlows(context, ref);
    return PageBody(
      maxWidth: 760,
      children: <Widget>[
        const SectionHeader('Deposit'),
        _group(flows.deposits()),
        const SectionHeader('Send and withdraw'),
        _group(<MoneyOption>[...flows.sends(), ...flows.withdrawals()]),
        const SectionHeader('After you have paid'),
        _group(flows.confirmations()),
      ],
    );
  }
}

/// A pop-up in the middle of the screen that lists every gateway for a deposit or a withdrawal. Picking one closes the
/// pop-up and opens that gateway's form.
Future<void> showMoneyChooser(BuildContext context, {required String title, String? subtitle, required List<MoneyOption> options}) async {
  final picked = await showCenteredSheet<MoneyOption>(
    context: context,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: ctx.display(size: 20, weight: FontWeight.w800)),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(subtitle, style: TextStyle(fontSize: 13.5, height: 1.4, color: ctx.mutedColor)),
            ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                for (final o in options)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(o.icon, color: ctx.pal.accent),
                    title: Text(o.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(o.subtitle, style: TextStyle(color: ctx.mutedColor, fontSize: 12.5)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(ctx).pop(o),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  if (picked != null && context.mounted) await picked.start();
}
