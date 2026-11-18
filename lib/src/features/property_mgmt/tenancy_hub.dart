import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/hub.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';
import 'property_leases.dart';
import 'property_ops.dart';
import 'tenancy_screen.dart';

double _amount(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String _money(Object? v) => v is num ? formatMoney(v) : '';

/// Everything a tenant does: rent, leases, utility bills, maintenance, notices, where they lived and their profile.
class TenancyHub extends ConsumerStatefulWidget {
  const TenancyHub({super.key});

  @override
  ConsumerState<TenancyHub> createState() => _TenancyHubState();
}

class _TenancyHubState extends ConsumerState<TenancyHub> {
  bool _registering = false;

  Future<void> _register() async {
    setState(() => _registering = true);
    try {
      await ref.read(propertyRepositoryProvider).registerAsTenant();
      ref.invalidate(tenantProfileProvider);
      if (mounted) showToast(context, 'You are registered as a tenant');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(tenantProfileProvider);
    return profile.when(
      loading: () => const PScaffold(body: SkeletonList()),
      error: (e, _) => PScaffold(body: ErrorState(error: e, onRetry: () => ref.invalidate(tenantProfileProvider))),
      data: (tenant) {
        if (tenant == null) {
          return PScaffold(
            body: EmptyState(
              icon: Icons.key_rounded,
              title: 'Register as a tenant',
              message: 'Use your Premisave account to see your rent, leases and notices, and to pay rent from your wallet.',
              actionLabel: _registering ? 'Registering' : 'Register as a tenant',
              onAction: _registering ? null : _register,
            ),
          );
        }
        final id = tenant.id;
        return HubPage(
          title: 'My tenancy',
          tabs: <HubTab>[
            HubTab('Rent', Icons.payments_outlined, (_) => const TenantRentTab()),
            HubTab('Leases', Icons.description_outlined, (_) => TenantLeasesTab(tenantId: id)),
            HubTab('Bills', Icons.bolt_outlined, (_) => TenantBillsTab(tenantId: id)),
            HubTab('Maintenance', Icons.build_circle_outlined, (_) => TenantMaintenanceTab(tenantId: id)),
            HubTab('Notices', Icons.campaign_outlined, (_) => TenantNoticesTab(tenantId: id)),
            HubTab('Where I lived', Icons.key_rounded, (_) => TenantOccupancyTab(tenantId: id)),
            HubTab('Profile', Icons.badge_outlined, (_) => const TenantProfileTab()),
          ],
        );
      },
    );
  }
}

/// The tenant's leases. Each opens its schedule, payments, balance, deposit and notices, and rent is paid from here.
class TenantLeasesTab extends ConsumerStatefulWidget {
  const TenantLeasesTab({super.key, required this.tenantId});

  final String tenantId;

  @override
  ConsumerState<TenantLeasesTab> createState() => _TenantLeasesTabState();
}

class _TenantLeasesTabState extends ConsumerState<TenantLeasesTab> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    String id(Json m) => pick(m, <String>['id', 'leaseId']);
    return ResourceSection(
      load: () => repo.tenantLeases(widget.tenantId),
      detail: (m) => repo.lease(id(m)),
      emptyTitle: 'No leases yet',
      emptyMessage: 'When a landlord leases you a home, it shows here.',
      emptyIcon: Icons.description_outlined,
      row: RowView(
        icon: Icons.description_outlined,
        title: (m) {
          final p = pick(m, <String>['property.title'], 'Lease');
          final u = pick(m, <String>['rentalUnit.unitNumber']);
          return u.isEmpty ? p : '$p, unit $u';
        },
        subtitle: (m) => '${displayValue(m['startDate'])} to ${displayValue(m['endDate'])}',
        status: (m) => pick(m, <String>['status']),
        trailing: (m) => _money(m['monthlyRent']),
      ),
      itemActions: <ItemAction>[
        ItemAction(
          'Pay rent',
          Icons.payments_outlined,
          title: 'Pay rent',
          subtitle: 'Paid from your wallet.',
          visible: (m) => pick(m, <String>['status']) == 'ACTIVE',
          fields: <FieldSpec>[FieldSpec('amount', 'Amount ($platformCurrency)', kind: FieldKind.number, required: true)],
          run: (m, v) async {
            await repo.payLeaseRentRaw(id(m), _amount(v['amount']));
            ref.invalidate(rentSummaryProvider);
            ref.invalidate(walletProvider);
            ref.invalidate(walletTransactionsProvider);
          },
          done: 'Rent paid',
        ),
        ItemAction('Rent due', Icons.request_quote_outlined, title: 'Rent due', page: (m) => ResourceView(load: () => repo.leaseRentDue(id(m)))),
        ItemAction(
          'Rent schedule',
          Icons.calendar_month_outlined,
          title: 'Rent schedule',
          page: (m) => ResourceSection(
            load: () => repo.rentSchedule(id(m)),
            emptyTitle: 'No schedule yet',
            emptyIcon: Icons.calendar_month_outlined,
            row: RowView(
              icon: Icons.calendar_month_outlined,
              title: (r) => displayValue(r['dueDate'] ?? r['periodStart']),
              subtitle: (r) => pick(r, <String>['description', 'period']),
              status: (r) => pick(r, <String>['status']),
              trailing: (r) => _money(r['amount'] ?? r['amountDue']),
            ),
          ),
        ),
        ItemAction(
          'Payments',
          Icons.receipt_long_outlined,
          title: 'Rent payments',
          page: (m) => ResourceSection(
            load: () => repo.leaseRentHistory(id(m)),
            emptyTitle: 'No payments yet',
            emptyIcon: Icons.receipt_long_outlined,
            row: RowView(
              icon: Icons.receipt_long_outlined,
              title: (r) => displayValue(r['paidAt'] ?? r['paymentDate'] ?? r['createdAt']),
              subtitle: (r) => pick(r, <String>['reference', 'paymentMethod', 'description']),
              status: (r) => pick(r, <String>['status']),
              trailing: (r) => _money(r['amount']),
            ),
          ),
        ),
        ItemAction('Balance', Icons.account_balance_wallet_outlined, title: 'Rent balance', page: (m) => ResourceView(load: () => repo.leaseBalance(id(m)))),
        ItemAction('Security deposit', Icons.lock_outline_rounded, title: 'Security deposit', page: (m) => ResourceView(load: () => repo.depositForLease(id(m)), emptyMessage: 'No deposit is held for this lease.')),
        ItemAction(
          'Notices',
          Icons.campaign_outlined,
          title: 'Lease notices',
          page: (m) => ResourceSection(
            load: () => repo.noticesForLease(id(m)),
            detail: (n) => repo.notice(pick(n, <String>['id'])),
            emptyTitle: 'No notices',
            emptyIcon: Icons.campaign_outlined,
            row: noticeRow,
          ),
        ),
      ],
    );
  }
}

/// Utility bills, unpaid first. A bill is paid from the wallet.
class TenantBillsTab extends ConsumerStatefulWidget {
  const TenantBillsTab({super.key, required this.tenantId});

  final String tenantId;

  @override
  ConsumerState<TenantBillsTab> createState() => _TenantBillsTabState();
}

class _TenantBillsTabState extends ConsumerState<TenantBillsTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    String id(Json m) => pick(m, <String>['id', 'billId']);
    return StatusTabs(
      statuses: const <String, String>{'UNPAID': 'Unpaid', 'ALL': 'All bills'},
      builder: (which) => ResourceSection(
        refreshKey: '$which$_bump',
        load: () => which == 'UNPAID' ? repo.outstandingBills(widget.tenantId) : repo.billsForTenant(widget.tenantId),
        detail: (m) => repo.bill(id(m)),
        emptyTitle: which == 'UNPAID' ? 'Nothing to pay' : 'No bills yet',
        emptyMessage: 'Water, electricity and other bills from your landlord show here.',
        emptyIcon: Icons.bolt_outlined,
        row: RowView(
          icon: Icons.bolt_outlined,
          title: (m) => sentence(pick(m, <String>['utilityType'], 'Bill')),
          subtitle: (m) => 'Due ${displayValue(m['dueDate'] ?? m['billingPeriodEnd'])}',
          status: (m) => pick(m, <String>['status']),
          trailing: (m) => _money(m['amount'] ?? m['totalAmount']),
        ),
        itemActions: <ItemAction>[
          ItemAction(
            'Pay',
            Icons.payments_outlined,
            title: 'Pay this bill',
            subtitle: 'Paid from your wallet.',
            visible: (m) => pick(m, <String>['status']) != 'PAID',
            fields: <FieldSpec>[FieldSpec('amount', 'Amount ($platformCurrency)', kind: FieldKind.number, required: true)],
            run: (m, v) async {
              await repo.payBill(id(m), _amount(v['amount']));
              ref.invalidate(walletProvider);
              ref.invalidate(walletTransactionsProvider);
              if (mounted) setState(() => _bump++);
            },
            done: 'Bill paid',
          ),
        ],
      ),
    );
  }
}

/// The homes the tenant has lived in and when they moved in and out.
class TenantOccupancyTab extends ConsumerWidget {
  const TenantOccupancyTab({super.key, required this.tenantId});

  final String tenantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(propertyRepositoryProvider);
    return ResourceSection(
      load: () => repo.tenantOccupancyHistory(tenantId),
      emptyTitle: 'No history yet',
      emptyMessage: 'Your move in and move out records show here.',
      emptyIcon: Icons.key_rounded,
      row: RowView(
        icon: Icons.key_rounded,
        title: (m) => pick(m, <String>['property.title', 'propertyTitle', 'rentalUnitId'], 'Home'),
        subtitle: (m) => '${displayValue(m['moveInDate'] ?? m['startDate'])} to ${m['moveOutDate'] == null && m['endDate'] == null ? 'now' : displayValue(m['moveOutDate'] ?? m['endDate'])}',
        status: (m) => pick(m, <String>['status']),
      ),
    );
  }
}

/// The tenant profile on the property service.
class TenantProfileTab extends ConsumerStatefulWidget {
  const TenantProfileTab({super.key});

  @override
  ConsumerState<TenantProfileTab> createState() => _TenantProfileTabState();
}

class _TenantProfileTabState extends ConsumerState<TenantProfileTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    return ResourceView(
      refreshKey: _bump,
      load: repo.tenantProfile,
      intro: 'Your tenant profile. Landlords see these details on your lease.',
      actions: <ItemAction>[
        ItemAction(
          'Edit profile',
          Icons.edit_outlined,
          title: 'Edit tenant profile',
          initialFromItem: true,
          fields: const <FieldSpec>[
            FieldSpec('fullName', 'Full name'),
            FieldSpec('phoneNumber', 'Phone', kind: FieldKind.phone),
            FieldSpec('email', 'Email', kind: FieldKind.email),
            FieldSpec('occupation', 'Occupation'),
          ],
          run: (_, v) async {
            await repo.updateMyTenantProfile(v);
            ref.invalidate(tenantProfileProvider);
            if (mounted) setState(() => _bump++);
          },
          done: 'Profile saved',
        ),
        ItemAction(
          'Sync with Premisave',
          Icons.sync_rounded,
          confirm: 'Copy your latest Premisave account details to the property service.',
          run: (_, __) async {
            await repo.syncTenant();
            if (mounted) setState(() => _bump++);
          },
          done: 'Profile synced',
        ),
        ItemAction('Sync status', Icons.info_outline_rounded, title: 'Sync status', page: (_) => ResourceView(load: repo.tenantSyncStatus)),
      ],
    );
  }
}
