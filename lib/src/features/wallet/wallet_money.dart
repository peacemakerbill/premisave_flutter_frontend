import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' show LaunchMode, launchUrl;

import '../../core/widgets/widgets.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';
import '../shared/service_widgets.dart';

double _amount(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

const FieldSpec _amountField = FieldSpec('amount', 'Amount', kind: FieldKind.number, required: true, helper: 'In the currency of your wallet.');

/// A new key per form, so a retry after a dropped connection can never move the money twice.
String _newReference() => 'app-${DateTime.now().microsecondsSinceEpoch}';

/// Every way to put money in, take money out and settle a payment that was made on a provider's own page.
class MoneyTab extends ConsumerStatefulWidget {
  const MoneyTab({super.key});

  @override
  ConsumerState<MoneyTab> createState() => _MoneyTabState();
}

class _MoneyTabState extends ConsumerState<MoneyTab> {
  void _refresh() {
    ref.invalidate(walletProvider);
    ref.invalidate(walletTransactionsProvider);
  }

  /// Opens a form, sends it, and then tells the person what the provider answered, with a link when there is one.
  Future<void> _flow({
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
    if (!ok || !mounted) return;
    _refresh();
    await _showAnswer(title, answer ?? const <String, dynamic>{});
  }

  Future<void> _showAnswer(String title, Json raw) async {
    final inner = raw['data'];
    final Json data = inner is Map ? Map<String, dynamic>.from(inner) : raw;
    final success = data['success'] != false;
    final message = pick(data, <String>['message'], pick(raw, <String>['message'], success ? 'Done' : 'Not completed'));
    final ref = pick(data, <String>['transactionId', 'disbursementId', 'id']);
    final isLink = ref.startsWith('http');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(success ? title : 'Not completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(message),
            if (ref.isNotEmpty && !isLink) ...<Widget>[
              const SizedBox(height: 12),
              const Text('Reference', style: TextStyle(fontWeight: FontWeight.w700)),
              SelectableText(ref),
              const SizedBox(height: 6),
              const Text('Keep it. You need it to confirm the payment after you have paid.', style: TextStyle(fontSize: 12.5)),
            ],
          ],
        ),
        actions: <Widget>[
          if (ref.isNotEmpty && !isLink) TextButton(onPressed: () => copyText(ctx, ref, done: 'Reference copied'), child: const Text('Copy reference')),
          if (isLink) TextButton(onPressed: () => launchUrl(Uri.parse(ref), mode: LaunchMode.externalApplication), child: const Text('Open payment page')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) => MenuTile(icon: icon, title: title, subtitle: subtitle, onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(walletRepositoryProvider);
    return PageBody(
      maxWidth: 760,
      children: <Widget>[
        const SectionHeader('Deposit'),
        MenuGroup(
          children: <Widget>[
            _tile(Icons.phone_iphone_rounded, 'M-Pesa', 'A prompt comes to your phone', () => _flow(
                  title: 'Deposit with M-Pesa',
                  subtitle: 'Leave the phone empty to use the number saved on your wallet.',
                  fields: const <FieldSpec>[_amountField, FieldSpec('phoneNumber', 'M-Pesa phone', kind: FieldKind.phone, hint: '254712345678')],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'MPESA'}),
                )),
            _tile(Icons.storefront_outlined, 'M-Pesa till', 'Pay from a business till with Express Checkout', () => _flow(
                  title: 'Deposit from a till',
                  subtitle: 'The prompt goes to the phone registered as the till operator.',
                  fields: const <FieldSpec>[_amountField, FieldSpec('payerTillNumber', 'Till number', required: true)],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'MPESA_TILL'}),
                )),
            _tile(Icons.credit_card_rounded, 'Card', 'Charges your saved card', () => _flow(
                  title: 'Deposit by card',
                  subtitle: 'Uses your default saved card. Save one under Linked accounts first.',
                  fields: const <FieldSpec>[_amountField, FieldSpec('currency', 'Currency', hint: 'USD')],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'STRIPE'}),
                )),
            _tile(Icons.account_balance_outlined, 'PayPal', 'Approve the payment on PayPal', () => _flow(
                  title: 'Deposit with PayPal',
                  fields: const <FieldSpec>[_amountField, FieldSpec('currency', 'Currency', hint: 'USD')],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'PAYPAL'}),
                )),
            _tile(Icons.public_rounded, 'Flutterwave', 'Mobile money and cards across Africa', () => _flow(
                  title: 'Deposit with Flutterwave',
                  fields: const <FieldSpec>[
                    _amountField,
                    FieldSpec('currency', 'Currency', hint: 'USD'),
                    FieldSpec('flutterwaveCountryCode', 'Country dialling code', hint: '233', helper: 'For mobile money.'),
                    FieldSpec('flutterwaveMobileNetwork', 'Mobile network', hint: 'MTN', helper: 'For mobile money.'),
                    FieldSpec('flutterwavePaymentOptions', 'Checkout options', hint: 'card,banktransfer', helper: 'Leave empty to show every option.'),
                    FieldSpec('customerName', 'Your name'),
                    FieldSpec('customerPhone', 'Your phone', kind: FieldKind.phone),
                  ],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'FLUTTERWAVE'}),
                )),
            _tile(Icons.currency_bitcoin_rounded, 'Crypto', 'Pay with a cryptocurrency', () => _flow(
                  title: 'Deposit with crypto',
                  fields: const <FieldSpec>[
                    FieldSpec('amount', 'Amount', kind: FieldKind.number, required: true),
                    FieldSpec('nowPaymentsPriceCurrency', 'Amount is in', hint: 'usd', helper: 'The money currency the amount is priced in.'),
                    FieldSpec('currency', 'Pay with', required: true, hint: 'usdttrc20', helper: 'The cryptocurrency, for example btc or usdttrc20.'),
                  ],
                  call: (v, _) => repo.deposit(<String, dynamic>{...v, 'provider': 'NOWPAYMENTS'}),
                )),
          ],
        ),
        const SectionHeader('Send and withdraw'),
        MenuGroup(
          children: <Widget>[
            _tile(Icons.north_east_rounded, 'Send to another wallet', 'By the email of their wallet', () => _flow(
                  title: 'Send money',
                  fields: const <FieldSpec>[
                    FieldSpec('recipientAccountNumber', 'Recipient wallet email', kind: FieldKind.email, required: true),
                    _amountField,
                    FieldSpec('description', 'Note'),
                  ],
                  call: (v, ref) => repo.transferRaw(<String, dynamic>{...v, 'amount': _amount(v['amount']), 'reference': ref}),
                  submit: 'Send',
                )),
            _tile(Icons.phone_iphone_rounded, 'Withdraw to M-Pesa', 'To your verified number', () => _flow(
                  title: 'Withdraw to M-Pesa',
                  fields: const <FieldSpec>[_amountField, FieldSpec('remarks', 'Note')],
                  call: (v, ref) => repo.disburse(<String, dynamic>{...v, 'provider': 'MPESA', 'reference': ref}),
                  submit: 'Withdraw',
                )),
            _tile(Icons.storefront_outlined, 'Pay to Pochi la Biashara', 'To any Pochi number', () => _flow(
                  title: 'Pay to Pochi la Biashara',
                  fields: const <FieldSpec>[
                    _amountField,
                    FieldSpec('phoneNumber', 'Pochi phone', kind: FieldKind.phone, hint: '254712345678', helper: 'Leave empty to use the number saved on your wallet.'),
                    FieldSpec('remarks', 'Note'),
                    FieldSpec('occasion', 'Occasion'),
                  ],
                  call: (v, ref) => repo.disburseToPochi(<String, dynamic>{...v, 'reference': ref}),
                  submit: 'Pay',
                )),
            _tile(Icons.account_balance_outlined, 'Withdraw to PayPal', 'To a PayPal email', () => _flow(
                  title: 'Withdraw to PayPal',
                  fields: const <FieldSpec>[
                    _amountField,
                    FieldSpec('destination', 'PayPal email', kind: FieldKind.email, required: true),
                    FieldSpec('currency', 'Currency', hint: 'USD'),
                  ],
                  call: (v, ref) => repo.disburse(<String, dynamic>{...v, 'provider': 'PAYPAL', 'reference': ref}),
                  submit: 'Withdraw',
                )),
            _tile(Icons.account_balance_rounded, 'Withdraw to my bank', 'Through your linked Stripe account', () => _flow(
                  title: 'Withdraw to my bank',
                  subtitle: 'Needs a bank linked under Linked accounts.',
                  fields: const <FieldSpec>[_amountField, FieldSpec('currency', 'Currency', hint: 'USD')],
                  call: (v, ref) => repo.disburse(<String, dynamic>{...v, 'provider': 'STRIPE', 'reference': ref}),
                  submit: 'Withdraw',
                )),
            _tile(Icons.public_rounded, 'Withdraw with Flutterwave', 'Bank or mobile money', () => _flow(
                  title: 'Withdraw with Flutterwave',
                  fields: const <FieldSpec>[
                    _amountField,
                    FieldSpec('flutterwaveTransferType', 'To', kind: FieldKind.select, required: true, options: <String, String>{'BANK': 'A bank account', 'MOBILE_MONEY': 'A mobile money number'}),
                    FieldSpec('flutterwaveAccountBank', 'Bank code or network', required: true, hint: 'MTN'),
                    FieldSpec('flutterwaveAccountNumber', 'Account or phone number', required: true),
                    FieldSpec('flutterwaveBeneficiaryName', 'Account holder'),
                    FieldSpec('currency', 'Currency', hint: 'USD'),
                  ],
                  call: (v, ref) => repo.disburse(<String, dynamic>{...v, 'provider': 'FLUTTERWAVE', 'reference': ref}),
                  submit: 'Withdraw',
                )),
            _tile(Icons.currency_bitcoin_rounded, 'Withdraw crypto', 'To a crypto address', () => _flow(
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
          ],
        ),
        const SectionHeader('After you have paid'),
        MenuGroup(
          children: <Widget>[
            _tile(Icons.verified_outlined, 'Confirm a card payment', 'With the payment intent id', () => _flow(
                  title: 'Confirm a card payment',
                  fields: const <FieldSpec>[FieldSpec('paymentIntentId', 'Payment intent id', required: true)],
                  call: (v, _) => repo.confirmStripeDeposit(v['paymentIntentId'] as String),
                  submit: 'Confirm',
                )),
            _tile(Icons.verified_outlined, 'Confirm a PayPal payment', 'With the order id', () => _flow(
                  title: 'Confirm a PayPal payment',
                  fields: const <FieldSpec>[FieldSpec('orderId', 'Order id', required: true)],
                  call: (v, _) => repo.confirmPaypalDeposit(v['orderId'] as String),
                  submit: 'Confirm',
                )),
            _tile(Icons.verified_outlined, 'Confirm a Flutterwave payment', 'With the transaction reference', () => _flow(
                  title: 'Confirm a Flutterwave payment',
                  fields: const <FieldSpec>[FieldSpec('txRef', 'Transaction reference', required: true)],
                  call: (v, _) => repo.confirmFlutterwaveDeposit(v['txRef'] as String),
                  submit: 'Confirm',
                )),
            _tile(Icons.mark_email_read_outlined, 'Verify a crypto withdrawal', 'With the code sent to you', () => _flow(
                  title: 'Verify a crypto withdrawal',
                  fields: const <FieldSpec>[
                    FieldSpec('disbursementId', 'Withdrawal id', required: true),
                    FieldSpec('verificationCode', 'Verification code', required: true),
                  ],
                  call: (v, _) => repo.verifyNowPaymentsWithdrawal(v['disbursementId'] as String, v['verificationCode'] as String),
                  submit: 'Verify',
                )),
          ],
        ),
      ],
    );
  }
}
