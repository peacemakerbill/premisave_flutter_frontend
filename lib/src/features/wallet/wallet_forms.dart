import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/wallet_models.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/person_widgets.dart';
import '../shared/service_widgets.dart';

void _refreshWallet(WidgetRef ref) {
  ref.invalidate(walletProvider);
  ref.invalidate(walletTransactionsProvider);
  ref.invalidate(depositHistoryProvider);
  ref.invalidate(transferHistoryProvider);
  ref.invalidate(withdrawalHistoryProvider);
}

/// Add money from M-Pesa. The person's phone shows a prompt to enter the M-Pesa PIN.
class DepositSheet extends ConsumerStatefulWidget {
  const DepositSheet({super.key, required this.wallet});

  final WalletModel wallet;

  @override
  ConsumerState<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends ConsumerState<DepositSheet> {
  late final TextEditingController _amount = TextEditingController();
  late final TextEditingController _phone = TextEditingController(text: widget.wallet.mpesaPhoneNumber ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = parseAmount(_amount.text);
    final phone = _phone.text.trim();
    if (amount == null || amount < 1) {
      setState(() => _error = 'Enter an amount of at least 1.');
      return;
    }
    if (phone.length < 9) {
      setState(() => _error = 'Enter the M-Pesa phone number to charge, for example 254712345678.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref.read(walletRepositoryProvider).depositMpesa(amount: amount, phoneNumber: phone);
      _refreshWallet(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, r.message, error: !r.success);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PTextField(
          label: 'Amount (${widget.wallet.currency})',
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icons.payments_outlined,
          autofocus: true,
        ),
        const SizedBox(height: 14),
        PTextField(
          label: 'M-Pesa number',
          controller: _phone,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_iphone_rounded,
          helper: 'The phone gets a prompt to enter its M-Pesa PIN.',
        ),
        if (_error != null) ...<Widget>[const SizedBox(height: 14), InlineMessage(_error!, kind: MessageKind.error)],
        const SizedBox(height: 18),
        PButton(label: 'Send the prompt', icon: Icons.south_west_rounded, expand: true, loading: _busy, onPressed: _submit),
      ],
    );
  }
}

/// Send money to another Premisave wallet by its email address.
class TransferSheet extends ConsumerStatefulWidget {
  const TransferSheet({super.key, required this.wallet});

  final WalletModel wallet;

  @override
  ConsumerState<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<TransferSheet> {
  final TextEditingController _to = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _to.dispose();
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = parseAmount(_amount.text);
    final to = _to.text.trim();
    if (!to.contains('@')) {
      setState(() => _error = 'Enter the email address of the wallet to send to.');
      return;
    }
    if (amount == null) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    if (amount > widget.wallet.balance) {
      setState(() => _error = 'That is more than the ${formatMoney(widget.wallet.balance, widget.wallet.currency)} in the wallet.');
      return;
    }
    final ok = await confirmDialog(
      context,
      title: 'Send ${formatMoney(amount, widget.wallet.currency)}?',
      message: 'The money moves to $to straight away.',
      confirmLabel: 'Send',
    );
    if (!ok) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref.read(walletRepositoryProvider).transfer(amount: amount, recipient: to, description: _note.text.trim());
      _refreshWallet(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, r.message, error: !r.success);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PTextField(
          label: 'Send to (wallet email)',
          controller: _to,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.alternate_email_rounded,
          autofocus: true,
        ),
        const SizedBox(height: 14),
        PTextField(
          label: 'Amount (${widget.wallet.currency})',
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icons.payments_outlined,
          helper: 'Available: ${formatMoney(widget.wallet.balance, widget.wallet.currency)}',
        ),
        const SizedBox(height: 14),
        PTextField(label: 'Note', controller: _note, optional: true, prefixIcon: Icons.notes_rounded),
        if (_error != null) ...<Widget>[const SizedBox(height: 14), InlineMessage(_error!, kind: MessageKind.error)],
        const SizedBox(height: 18),
        PButton(label: 'Send money', icon: Icons.north_east_rounded, expand: true, loading: _busy, onPressed: _submit),
      ],
    );
  }
}

/// Move money from the wallet to the person's own M-Pesa number.
class WithdrawSheet extends ConsumerStatefulWidget {
  const WithdrawSheet({super.key, required this.wallet});

  final WalletModel wallet;

  @override
  ConsumerState<WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<WithdrawSheet> {
  final TextEditingController _amount = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = parseAmount(_amount.text);
    if (amount == null) {
      setState(() => _error = 'Enter an amount greater than zero.');
      return;
    }
    if (amount > widget.wallet.balance) {
      setState(() => _error = 'That is more than the ${formatMoney(widget.wallet.balance, widget.wallet.currency)} in the wallet.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref.read(walletRepositoryProvider).withdrawMpesa(amount: amount);
      _refreshWallet(ref);
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, r.message, error: !r.success);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = widget.wallet.mpesaPhoneNumber;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        InlineMessage(
          phone == null
              ? 'The money goes to the M-Pesa number on your wallet profile.'
              : 'The money goes to your M-Pesa number $phone. A fee may apply.',
        ),
        const SizedBox(height: 14),
        PTextField(
          label: 'Amount (${widget.wallet.currency})',
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icons.payments_outlined,
          helper: 'Available: ${formatMoney(widget.wallet.balance, widget.wallet.currency)}',
          autofocus: true,
        ),
        if (_error != null) ...<Widget>[const SizedBox(height: 14), InlineMessage(_error!, kind: MessageKind.error)],
        const SizedBox(height: 18),
        PButton(label: 'Withdraw to M-Pesa', icon: Icons.north_east_rounded, expand: true, loading: _busy, onPressed: _submit),
      ],
    );
  }
}

/// A statement for the last 7, 30 or 90 days.
class StatementSheet extends ConsumerStatefulWidget {
  const StatementSheet({super.key});

  @override
  ConsumerState<StatementSheet> createState() => _StatementSheetState();
}

class _StatementSheetState extends ConsumerState<StatementSheet> {
  int _days = 30;
  Future<WalletStatement>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final from = DateTime.now().subtract(Duration(days: _days));
    _future = ref.read(walletRepositoryProvider).statement(from: from, to: DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (final d in const <int>[7, 30, 90])
              ChoiceChip(
                label: Text('Last $d days'),
                selected: _days == d,
                onSelected: (_) => setState(() {
                  _days = d;
                  _load();
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<WalletStatement>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) {
              return InlineMessage(ApiException.from(snap.error!).message, kind: MessageKind.error);
            }
            final s = snap.data!;
            return PCard(
              child: Column(
                children: <Widget>[
                  KeyValueLine('Opening balance', formatMoney(s.openingBalance)),
                  KeyValueLine('Money in', formatMoney(s.totalCredits)),
                  KeyValueLine('Money out', formatMoney(s.totalDebits)),
                  const Divider(),
                  KeyValueLine('Closing balance', formatMoney(s.closingBalance), bold: true),
                  KeyValueLine('Entries', '${s.transactions.length}'),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// One row of wallet activity.
class ActivityRow extends StatelessWidget {
  const ActivityRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.credit,
    required this.status,
    this.icon,
    this.leading,
    this.onTap,
  });

  /// A picture to put in front, in place of the arrow, for example the person on the other side.
  final Widget? leading;
  final VoidCallback? onTap;
  final String title;
  final String subtitle;
  final String amount;
  final bool credit;
  final String status;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tint = credit ? Brand.success : Brand.danger;
    return PCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          leading ??
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: tint.op(0.12), borderRadius: BorderRadius.circular(context.radius(12))),
                child: Icon(icon ?? (credit ? Icons.south_west_rounded : Icons.north_east_rounded), color: tint, size: 20),
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: context.mutedColor)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text('${credit ? '+' : '-'}$amount', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: tint)),
              const SizedBox(height: 4),
              StatusChip(status),
            ],
          ),
        ],
      ),
    );
  }
}

String activityTitle(WalletTransaction t) => t.description ?? sentence(t.type);

/// Everything about one line of activity: who was on the other side with their picture, the account, the reference and
/// the reason when it failed.
void showActivityDetail(BuildContext context, WalletTransaction t) {
  final person = PersonRef(id: t.counterpartyId, email: t.counterpartyEmail, name: t.counterpartyName);
  showFormSheet<void>(
    context,
    title: activityTitle(t),
    subtitle: whenLabel(t.createdAt),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (person.isKnown) PersonCard(person, role: t.isCredit ? 'Received from' : 'Sent to'),
        Align(alignment: Alignment.centerLeft, child: StatusChip(t.status)),
        const SizedBox(height: 12),
        KeyValueLine(t.isCredit ? 'Money in' : 'Money out', formatMoney(t.amount, t.currency), bold: true),
        KeyValueLine('Kind', sentence(t.type)),
        if (t.provider != null && t.provider!.isNotEmpty) KeyValueLine('Through', sentence(t.provider)),
        if (t.account != null && t.account!.isNotEmpty) KeyValueLine('Account', t.account!),
        if (t.reference != null && t.reference!.isNotEmpty) KeyValueLine('Reference', t.reference!),
        if (t.failureReason != null && t.failureReason!.isNotEmpty) KeyValueLine('Reason', t.failureReason!),
      ],
    ),
  );
}
