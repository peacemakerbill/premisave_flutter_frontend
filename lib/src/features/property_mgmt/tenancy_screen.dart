import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/property_models.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/service_widgets.dart';

/// Rent owed across every home, with a button to pay each one from the wallet.
class TenantRentTab extends ConsumerWidget {
  const TenantRentTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody<RentSummary>(
      value: ref.watch(rentSummaryProvider),
      onRetry: () => ref.invalidate(rentSummaryProvider),
      builder: (s) {
        final owes = s.netBalance > 0;
        return PageBody(
          maxWidth: 760,
          onRefresh: () async => ref.invalidate(rentSummaryProvider),
          children: <Widget>[
            HeroPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(owes ? 'Rent owed' : (s.netBalance < 0 ? 'Rent paid ahead' : 'Rent is up to date'), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    formatMoney(s.netBalance.abs()),
                    style: context.display(size: 32, weight: FontWeight.w800, spacing: -1, color: Brand.cream),
                  ),
                ],
              ),
            ),
            if (s.breakdown.isEmpty)
              const SizedBox(height: 260, child: EmptyState(icon: Icons.home_outlined, title: 'No rent to show', message: 'When a landlord adds you to a unit or a lease, your rent shows here.'))
            else ...<Widget>[
              const SectionHeader('By home'),
              for (final b in s.breakdown) _RentCard(balance: b),
            ],
          ],
        );
      },
    );
  }
}

class _RentCard extends ConsumerStatefulWidget {
  const _RentCard({required this.balance});

  final RentBalanceModel balance;

  @override
  ConsumerState<_RentCard> createState() => _RentCardState();
}

class _RentCardState extends ConsumerState<_RentCard> {
  bool _busy = false;

  Future<void> _pay() async {
    final b = widget.balance;
    final text = await promptDialog(
      context,
      title: 'Pay rent',
      label: 'Amount ($platformCurrency)',
      message: 'Paid from your wallet.',
      confirmLabel: 'Pay',
      required: true,
      multiline: false,
      initial: b.arrearsOwed > 0 ? b.arrearsOwed.toStringAsFixed(2) : null,
    );
    if (text == null) return;
    final amount = parseAmount(text);
    if (amount == null) {
      if (mounted) showToast(context, 'Enter an amount greater than zero.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      if (b.leaseId != null) {
        await repo.payLeaseRent(leaseId: b.leaseId!, amount: amount);
      } else if (b.rentalUnitId != null) {
        await repo.payUnitRent(rentalUnitId: b.rentalUnitId!, amount: amount);
      } else {
        throw ApiException('This rent cannot be paid from here yet.');
      }
      ref.invalidate(rentSummaryProvider);
      ref.invalidate(walletProvider);
      ref.invalidate(walletTransactionsProvider);
      if (mounted) showToast(context, 'Rent paid');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.balance;
    return PCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(b.where, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
          if (b.statusMessage != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(b.statusMessage!, style: TextStyle(fontSize: 12.5, color: context.mutedColor))),
          const SizedBox(height: 8),
          KeyValueLine('Owed', formatMoney(b.arrearsOwed), bold: b.arrearsOwed > 0),
          if (b.creditAvailable > 0) KeyValueLine('Credit', formatMoney(b.creditAvailable)),
          if (b.lastPaymentAt != null) KeyValueLine('Last payment', formatDate(b.lastPaymentAt)),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerRight, child: PButton(label: 'Pay rent', icon: Icons.payments_outlined, small: true, loading: _busy, onPressed: _pay)),
        ],
      ),
    );
  }
}

/// Maintenance requests raised by the tenant, and a form to raise another.
class TenantMaintenanceTab extends ConsumerWidget {
  const TenantMaintenanceTab({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tenantMaintenanceProvider(tenantId);
    final leases = ref.watch(tenantLeasesProvider(tenantId)).maybeWhen(data: (l) => l, orElse: () => <LeaseModel>[]);
    final units = leases.where((l) => l.rentalUnitId != null).toList();
    return AsyncBody<List<MaintenanceModel>>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      builder: (items) => PageBody(
        maxWidth: 760,
        onRefresh: () async => ref.invalidate(provider),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: PButton(
              label: 'New request',
              icon: Icons.add_rounded,
              small: true,
              onPressed: units.isEmpty
                  ? () => showToast(context, 'You need a lease on a unit before you can raise a request.', error: true)
                  : () => showFormSheet<void>(
                        context,
                        title: 'Maintenance request',
                        subtitle: 'Tell your landlord what needs fixing.',
                        child: _RequestForm(units: units, tenantId: tenantId),
                      ),
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const SizedBox(height: 280, child: EmptyState(icon: Icons.build_circle_outlined, title: 'No requests yet'))
          else
            for (final m in items)
              PCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(children: <Widget>[Expanded(child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5))), StatusChip(m.status)]),
                    if (m.description != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(m.description!, style: const TextStyle(height: 1.4))),
                    const SizedBox(height: 6),
                    Text(timeAgo(m.createdAt), style: TextStyle(fontSize: 12, color: context.mutedColor)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _RequestForm extends ConsumerStatefulWidget {
  const _RequestForm({required this.units, required this.tenantId});

  final List<LeaseModel> units;
  final String tenantId;

  @override
  ConsumerState<_RequestForm> createState() => _RequestFormState();
}

class _RequestFormState extends ConsumerState<_RequestForm> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _details = TextEditingController();
  late String _unitId = widget.units.first.rentalUnitId!;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Give the request a short title.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(propertyRepositoryProvider).requestMaintenance(
            rentalUnitId: _unitId,
            title: _title.text.trim(),
            description: _details.text.trim(),
          );
      ref.invalidate(tenantMaintenanceProvider(widget.tenantId));
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, 'Request sent to your landlord');
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
        if (widget.units.length > 1) ...<Widget>[
          PSelectField<String>(
            label: 'Home',
            value: _unitId,
            options: <PChoice<String>>[for (final l in widget.units) PChoice<String>(l.rentalUnitId!, l.where)],
            onChanged: (v) => setState(() => _unitId = v ?? _unitId),
          ),
          const SizedBox(height: 14),
        ],
        PTextField(label: 'Title', controller: _title, hint: 'Leaking kitchen tap', autofocus: true),
        const SizedBox(height: 14),
        PTextField(label: 'Details', controller: _details, optional: true, maxLines: 4, minLines: 3),
        if (_error != null) ...<Widget>[const SizedBox(height: 14), InlineMessage(_error!, kind: MessageKind.error)],
        const SizedBox(height: 18),
        PButton(label: 'Send request', icon: Icons.send_rounded, expand: true, loading: _busy, onPressed: _send),
      ],
    );
  }
}

/// Notices from the landlord.
class TenantNoticesTab extends ConsumerWidget {
  const TenantNoticesTab({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tenantNoticesProvider(tenantId);
    return AsyncBody<List<NoticeModel>>(
      value: ref.watch(provider),
      onRetry: () => ref.invalidate(provider),
      builder: (items) => PageBody(
        maxWidth: 760,
        onRefresh: () async => ref.invalidate(provider),
        children: items.isEmpty
            ? const <Widget>[SizedBox(height: 340, child: EmptyState(icon: Icons.campaign_outlined, title: 'No notices', message: 'Notices from your landlord appear here.'))]
            : <Widget>[
                for (final n in items)
                  PCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(children: <Widget>[Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5))), StatusPill(sentence(n.noticeType), dense: true, color: Brand.info)]),
                        if (n.content != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(n.content!, style: const TextStyle(height: 1.45))),
                        const SizedBox(height: 6),
                        Text(whenLabel(n.sentAt), style: TextStyle(fontSize: 12, color: context.mutedColor)),
                      ],
                    ),
                  ),
              ],
      ),
    );
  }
}
