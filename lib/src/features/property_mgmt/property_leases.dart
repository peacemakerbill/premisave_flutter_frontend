import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../data/repositories/property_repository.dart';
import '../../state/providers.dart';
import '../shared/ask_then_show.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';
import 'property_ops.dart';

double _amount(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

String _money(Object? v) => v is num ? formatMoney(v) : '';

// ------------------------------------------------------------------- leases

class LeasesTab extends ConsumerStatefulWidget {
  const LeasesTab({super.key});

  @override
  ConsumerState<LeasesTab> createState() => _LeasesTabState();
}

class _LeasesTabState extends ConsumerState<LeasesTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final PropertyRepository repo = ref.read(propertyRepositoryProvider);
    String id(Json m) => pick(m, <String>['id', 'leaseId']);
    void changed() {
      if (mounted) setState(() => _bump++);
    }

    return ResourceSection(
      refreshKey: _bump,
      load: repo.ownerLeasesRaw,
      detail: (m) => repo.lease(id(m)),
      emptyTitle: 'No leases yet',
      emptyMessage: 'Lease a unit to a tenant to start collecting rent.',
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
      headerActions: <ItemAction>[
        ItemAction(
          'Create a lease',
          Icons.add_rounded,
          title: 'Create a lease',
          fields: const <FieldSpec>[
            FieldSpec('tenantId', 'Tenant id', required: true, helper: 'The tenant registers from the Tenancy menu. Copy their id from their profile.'),
            FieldSpec('rentalUnitId', 'Unit id', helper: 'Leave empty to lease a whole property.'),
            FieldSpec('propertyId', 'Property id', helper: 'Only for a whole property.'),
            FieldSpec('startDate', 'Starts', kind: FieldKind.date, required: true),
            FieldSpec('endDate', 'Ends', kind: FieldKind.date, required: true),
            FieldSpec('monthlyRent', 'Rent per month (USD)', kind: FieldKind.number, required: true),
            FieldSpec('securityDeposit', 'Security deposit (USD)', kind: FieldKind.number),
          ],
          run: (_, v) async {
            await repo.createLease(v);
            changed();
          },
          done: 'Lease created',
        ),
      ],
      itemActions: <ItemAction>[
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
          'Rent history',
          Icons.receipt_long_outlined,
          title: 'Rent history',
          page: (m) => ResourceSection(
            load: () => repo.leaseRentHistory(id(m)),
            emptyTitle: 'No payments yet',
            emptyIcon: Icons.receipt_long_outlined,
            row: _paymentRow,
          ),
        ),
        ItemAction('Rent due', Icons.request_quote_outlined, title: 'Rent due', page: (m) => ResourceView(load: () => repo.leaseRentDue(id(m)))),
        ItemAction('Balance', Icons.account_balance_wallet_outlined, title: 'Rent balance', page: (m) => ResourceView(load: () => repo.leaseBalance(id(m)))),
        ItemAction('Security deposit', Icons.lock_outline_rounded, title: 'Security deposit', page: (m) => LeaseDepositPage(leaseId: id(m))),
        ItemAction('Notices', Icons.campaign_outlined, title: 'Lease notices', page: (m) => LeaseNoticesPage(leaseId: id(m))),
        ItemAction(
          'Edit',
          Icons.edit_outlined,
          title: 'Edit lease',
          initialFromItem: true,
          fields: const <FieldSpec>[
            FieldSpec('endDate', 'Ends', kind: FieldKind.date),
            FieldSpec('status', 'Status', kind: FieldKind.select, options: <String, String>{
              'DRAFT': 'Draft',
              'ACTIVE': 'Active',
              'RENEWED': 'Renewed',
              'TERMINATED': 'Terminated',
              'EXPIRED': 'Expired',
              'EVICTED': 'Evicted',
            }),
          ],
          run: (m, v) async {
            await repo.updateLease(id(m), v);
            changed();
          },
          done: 'Lease saved',
        ),
        ItemAction(
          'Move in',
          Icons.login_rounded,
          confirm: 'Record that the tenant has moved in.',
          run: (m, _) async {
            await repo.moveInViaLease(id(m));
            changed();
          },
          done: 'Move in recorded',
        ),
        ItemAction(
          'Move out',
          Icons.logout_rounded,
          confirm: 'Record that the tenant has moved out.',
          run: (m, _) async {
            await repo.moveOutViaLease(id(m));
            changed();
          },
          done: 'Move out recorded',
        ),
        ItemAction(
          'Terminate',
          Icons.gpp_bad_outlined,
          danger: true,
          visible: (m) => pick(m, <String>['status']) == 'ACTIVE',
          confirm: 'End this lease now. Rent stops accruing.',
          run: (m, _) async {
            await repo.terminateLease(id(m));
            changed();
          },
          done: 'Lease terminated',
        ),
      ],
    );
  }
}

final RowView _paymentRow = RowView(
  icon: Icons.receipt_long_outlined,
  title: (m) => displayValue(m['paidAt'] ?? m['paymentDate'] ?? m['createdAt']),
  subtitle: (m) => pick(m, <String>['reference', 'paymentMethod', 'description']),
  status: (m) => pick(m, <String>['status']),
  trailing: (m) => _money(m['amount']),
);

/// The security deposit of a lease: what is held, and the forms to hold, check and refund it.
class LeaseDepositPage extends ConsumerStatefulWidget {
  const LeaseDepositPage({super.key, required this.leaseId});

  final String leaseId;

  @override
  ConsumerState<LeaseDepositPage> createState() => _LeaseDepositPageState();
}

class _LeaseDepositPageState extends ConsumerState<LeaseDepositPage> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    final id = widget.leaseId;
    return ResourceView(
      refreshKey: _bump,
      load: () => repo.depositForLease(id),
      emptyMessage: 'No deposit has been held for this lease.',
      actions: <ItemAction>[
        ItemAction(
          'Hold a deposit',
          Icons.lock_outline_rounded,
          title: 'Hold a security deposit',
          fields: const <FieldSpec>[FieldSpec('amount', 'Amount (USD)', kind: FieldKind.number, required: true)],
          run: (_, v) async {
            await repo.holdDeposit(<String, dynamic>{'leaseId': id, 'amount': _amount(v['amount'])});
            if (mounted) setState(() => _bump++);
          },
          done: 'Deposit held',
        ),
        ItemAction(
          'Can I refund this much',
          Icons.help_outline_rounded,
          title: 'Check a refund',
          page: (_) => AskThenShow(
            intro: 'See whether an amount can be refunded now and what would be left.',
            fields: const <FieldSpec>[FieldSpec('amount', 'Amount (USD)', kind: FieldKind.number, required: true)],
            submitLabel: 'Check',
            fetch: (v) => repo.checkLeaseRefund(id, _amount(v['amount'])),
          ),
        ),
        ItemAction(
          'Refund',
          Icons.undo_rounded,
          title: 'Refund the deposit',
          fields: const <FieldSpec>[
            FieldSpec('amount', 'Amount (USD)', kind: FieldKind.number, required: true),
            FieldSpec('reason', 'Reason', kind: FieldKind.multiline),
          ],
          run: (_, v) async {
            await repo.refundDeposit(<String, dynamic>{'leaseId': id, 'amount': _amount(v['amount']), 'reason': v['reason']});
            if (mounted) setState(() => _bump++);
          },
          done: 'Deposit refunded',
        ),
      ],
    );
  }
}

/// The notices sent on one lease, and a form to send another.
class LeaseNoticesPage extends ConsumerStatefulWidget {
  const LeaseNoticesPage({super.key, required this.leaseId});

  final String leaseId;

  @override
  ConsumerState<LeaseNoticesPage> createState() => _LeaseNoticesPageState();
}

class _LeaseNoticesPageState extends ConsumerState<LeaseNoticesPage> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    return ResourceSection(
      refreshKey: _bump,
      load: () => repo.noticesForLease(widget.leaseId),
      detail: (m) => repo.notice(pick(m, <String>['id'])),
      emptyTitle: 'No notices yet',
      emptyIcon: Icons.campaign_outlined,
      row: noticeRow,
      headerActions: <ItemAction>[
        ItemAction(
          'Send a notice',
          Icons.send_rounded,
          title: 'Send a notice to this tenant',
          fields: const <FieldSpec>[
            FieldSpec('noticeType', 'Kind of notice', kind: FieldKind.select, required: true, options: noticeTypes),
            FieldSpec('title', 'Title', required: true),
            FieldSpec('content', 'Message', kind: FieldKind.multiline, required: true),
          ],
          run: (_, v) async {
            await repo.sendLeaseNotice(leaseId: widget.leaseId, noticeType: v['noticeType'] as String, title: v['title'] as String, content: v['content'] as String);
            if (mounted) setState(() => _bump++);
          },
          done: 'Notice sent',
        ),
      ],
    );
  }
}

final RowView noticeRow = RowView(
  icon: Icons.campaign_outlined,
  title: (m) => pick(m, <String>['title'], 'Notice'),
  subtitle: (m) => pick(m, <String>['content', 'message']),
  status: (m) => pick(m, <String>['noticeType']),
);

// ------------------------------------------------------------------ tenants

/// The tenants on your leases, a lookup by tenant id, and registration of a tenant by the owner.
class TenantsTab extends ConsumerStatefulWidget {
  const TenantsTab({super.key});

  @override
  ConsumerState<TenantsTab> createState() => _TenantsTabState();
}

class _TenantsTabState extends ConsumerState<TenantsTab> {
  int _bump = 0;

  Future<List<Json>> _load(PropertyRepository repo) async {
    final leases = await repo.ownerLeasesRaw();
    final ids = <String>{for (final l in leases) pick(l, <String>['tenantId'])}..remove('');
    final out = <Json>[];
    for (final id in ids) {
      try {
        out.add(await repo.tenant(id));
      } catch (_) {
        out.add(<String, dynamic>{'id': id, 'fullName': 'Tenant $id'});
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    String id(Json m) => pick(m, <String>['id', 'tenantId']);
    return ResourceSection(
      refreshKey: _bump,
      load: () => _load(repo),
      detail: (m) => repo.tenant(id(m)),
      intro: 'People who have a lease with you.',
      emptyTitle: 'No tenants yet',
      emptyMessage: 'Tenants appear here once you lease them a unit.',
      emptyIcon: Icons.groups_outlined,
      row: RowView(
        icon: Icons.person_outline_rounded,
        title: (m) => pick(m, <String>['fullName'], 'Tenant'),
        subtitle: (m) => <String>[pick(m, <String>['phoneNumber']), pick(m, <String>['email'])].where((e) => e.isNotEmpty).join('  '),
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Find a tenant by id',
          Icons.search_rounded,
          title: 'Find a tenant',
          page: (_) => AskThenShow(
            fields: const <FieldSpec>[FieldSpec('id', 'Tenant id', required: true)],
            submitLabel: 'Find',
            fetch: (v) => repo.tenant(v['id'] as String),
          ),
        ),
        ItemAction(
          'Register a tenant',
          Icons.person_add_alt_1_outlined,
          title: 'Register a tenant',
          fields: const <FieldSpec>[
            FieldSpec('fullName', 'Full name', required: true),
            FieldSpec('phoneNumber', 'Phone', kind: FieldKind.phone, required: true),
            FieldSpec('email', 'Email', kind: FieldKind.email, required: true),
            FieldSpec('idNumber', 'Id number'),
            FieldSpec('currentAddress.street', 'Street'),
            FieldSpec('currentAddress.city', 'City'),
            FieldSpec('currentAddress.country', 'Country'),
          ],
          run: (_, v) async {
            await repo.registerTenant(v);
            if (mounted) setState(() => _bump++);
          },
          done: 'Tenant registered',
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction('Leases', Icons.description_outlined, title: 'Leases', page: (m) => _tenantList(repo.tenantLeases(id(m)), Icons.description_outlined, 'No leases')),
        ItemAction('Balance', Icons.account_balance_wallet_outlined, title: 'Rent balance', page: (m) => ResourceView(load: () => repo.tenantBalanceSummary(id(m)))),
        ItemAction('Utility bills', Icons.bolt_outlined, title: 'Utility bills', page: (m) => _tenantList(repo.billsForTenant(id(m)), Icons.bolt_outlined, 'No bills')),
        ItemAction('Notices', Icons.campaign_outlined, title: 'Notices', page: (m) => _tenantList(repo.noticesForTenant(id(m)), Icons.campaign_outlined, 'No notices', row: noticeRow)),
        ItemAction('Where they lived', Icons.key_rounded, title: 'Occupancy history', page: (m) => _tenantList(repo.tenantOccupancyHistory(id(m)), Icons.key_rounded, 'No occupancy yet')),
        ItemAction(
          'Blacklist',
          Icons.block_outlined,
          danger: true,
          title: 'Blacklist this tenant',
          fields: const <FieldSpec>[
            FieldSpec('reason', 'Reason', kind: FieldKind.multiline, required: true),
            FieldSpec('notes', 'Notes', kind: FieldKind.multiline),
          ],
          run: (m, v) async {
            await repo.blacklistTenant(tenantId: id(m), reason: v['reason'] as String, notes: v['notes'] as String?);
          },
          done: 'Tenant blacklisted',
        ),
      ],
    );
  }

  Widget _tenantList(Future<List<Json>> future, IconData icon, String empty, {RowView? row}) {
    return ResourceSection(
      load: () => future,
      emptyTitle: empty,
      emptyIcon: icon,
      row: row ??
          RowView(
            icon: icon,
            title: (m) => pick(m, <String>['title', 'property.title', 'tenantName', 'utilityType', 'id'], 'Record'),
            subtitle: (m) => pick(m, <String>['description', 'startDate', 'moveInDate', 'billingPeriodEnd']),
            status: (m) => pick(m, <String>['status']),
            trailing: (m) => _money(m['amount'] ?? m['totalAmount'] ?? m['monthlyRent']),
          ),
    );
  }
}

// -------------------------------------------------------- unit rent, meters, bills

/// Rent of one unit: what is due, the payment history, and the security deposit held for a tenant of the unit.
class UnitRentTab extends ConsumerStatefulWidget {
  const UnitRentTab({super.key, required this.unitId});

  final String unitId;

  @override
  ConsumerState<UnitRentTab> createState() => _UnitRentTabState();
}

class _UnitRentTabState extends ConsumerState<UnitRentTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    final unit = widget.unitId;
    return ResourceSection(
      refreshKey: _bump,
      load: () => repo.unitRentHistory(unit),
      emptyTitle: 'No rent payments yet',
      emptyIcon: Icons.receipt_long_outlined,
      row: _paymentRow,
      headerActions: <ItemAction>[
        ItemAction('Rent due', Icons.request_quote_outlined, title: 'Rent due', page: (_) => ResourceView(load: () => repo.unitRentDue(unit))),
        ItemAction(
          'Rent due for a tenant',
          Icons.person_search_outlined,
          title: 'Rent due for a tenant',
          page: (_) => AskThenShow(
            fields: const <FieldSpec>[FieldSpec('tenantId', 'Tenant id', required: true)],
            submitLabel: 'Show',
            fetch: (v) => repo.unitRentDue(unit, tenantId: v['tenantId'] as String),
          ),
        ),
        ItemAction(
          'Balance for a tenant',
          Icons.account_balance_wallet_outlined,
          title: 'Balance for a tenant',
          page: (_) => AskThenShow(
            fields: const <FieldSpec>[FieldSpec('tenantId', 'Tenant id', required: true)],
            submitLabel: 'Show',
            fetch: (v) => repo.unitBalanceForTenant(unit, v['tenantId'] as String),
          ),
        ),
        ItemAction(
          'Deposit for a tenant',
          Icons.lock_outline_rounded,
          title: 'Security deposit',
          page: (_) => AskThenShow(
            fields: const <FieldSpec>[FieldSpec('tenantId', 'Tenant id', required: true)],
            submitLabel: 'Show',
            fetch: (v) => repo.depositForUnitTenant(unit, v['tenantId'] as String),
          ),
        ),
        ItemAction(
          'Hold a deposit',
          Icons.lock_clock_outlined,
          title: 'Hold a security deposit',
          fields: const <FieldSpec>[
            FieldSpec('tenantId', 'Tenant id', required: true),
            FieldSpec('amount', 'Amount (USD)', kind: FieldKind.number, required: true),
          ],
          run: (_, v) async {
            await repo.holdDeposit(<String, dynamic>{'rentalUnitId': unit, 'tenantId': v['tenantId'], 'amount': _amount(v['amount'])});
          },
          done: 'Deposit held',
        ),
        ItemAction(
          'Check a refund',
          Icons.help_outline_rounded,
          title: 'Check a refund',
          page: (_) => AskThenShow(
            fields: const <FieldSpec>[
              FieldSpec('tenantId', 'Tenant id', required: true),
              FieldSpec('amount', 'Amount (USD)', kind: FieldKind.number, required: true),
            ],
            submitLabel: 'Check',
            fetch: (v) => repo.checkUnitRefund(unit, v['tenantId'] as String, _amount(v['amount'])),
          ),
        ),
        ItemAction(
          'Refund a deposit',
          Icons.undo_rounded,
          title: 'Refund a deposit',
          fields: const <FieldSpec>[
            FieldSpec('tenantId', 'Tenant id', required: true),
            FieldSpec('amount', 'Amount (USD)', kind: FieldKind.number, required: true),
            FieldSpec('reason', 'Reason', kind: FieldKind.multiline),
          ],
          run: (_, v) async {
            await repo.refundDeposit(<String, dynamic>{'rentalUnitId': unit, 'tenantId': v['tenantId'], 'amount': _amount(v['amount']), 'reason': v['reason']});
          },
          done: 'Deposit refunded',
        ),
        ItemAction(
          'Send a notice',
          Icons.campaign_outlined,
          title: 'Send a notice',
          fields: const <FieldSpec>[
            FieldSpec('tenantId', 'Tenant id', helper: 'Leave empty to notify everyone in the unit.'),
            FieldSpec('noticeType', 'Kind of notice', kind: FieldKind.select, required: true, options: noticeTypes),
            FieldSpec('title', 'Title', required: true),
            FieldSpec('content', 'Message', kind: FieldKind.multiline, required: true),
          ],
          run: (_, v) async {
            final tenant = v['tenantId'] as String?;
            await repo.sendUnitNotice(
              rentalUnitId: unit,
              tenantId: tenant == null || tenant.isEmpty ? null : tenant,
              noticeType: v['noticeType'] as String,
              title: v['title'] as String,
              content: v['content'] as String,
            );
          },
          done: 'Notice sent',
        ),
      ],
    );
  }
}

/// Meter readings of one unit. A reading can be turned into a utility bill.
class MetersTab extends ConsumerStatefulWidget {
  const MetersTab({super.key, required this.unitId});

  final String unitId;

  @override
  ConsumerState<MetersTab> createState() => _MetersTabState();
}

class _MetersTabState extends ConsumerState<MetersTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    String id(Json m) => pick(m, <String>['id', 'meterReadingId']);
    void changed() {
      if (mounted) setState(() => _bump++);
    }

    return ResourceSection(
      refreshKey: _bump,
      load: () => repo.readingsForUnit(widget.unitId),
      detail: (m) => repo.reading(id(m)),
      emptyTitle: 'No readings yet',
      emptyMessage: 'Record the meter, then bill the tenant for what they used.',
      emptyIcon: Icons.speed_rounded,
      row: RowView(
        icon: Icons.speed_rounded,
        title: (m) => '${sentence(pick(m, <String>['meterType']))} meter',
        subtitle: (m) => 'Reading ${displayValue(m['currentReading'])}, ${displayValue(m['readingDate'] ?? m['createdAt'])}',
        trailing: (m) => m['consumption'] == null ? null : '${displayValue(m['consumption'])} used',
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Record a reading',
          Icons.add_rounded,
          title: 'Record a meter reading',
          fields: const <FieldSpec>[
            FieldSpec('meterType', 'Meter', kind: FieldKind.select, required: true, options: <String, String>{'ELECTRICITY': 'Electricity', 'WATER': 'Water'}),
            FieldSpec('currentReading', 'Reading now', kind: FieldKind.number, required: true),
          ],
          run: (_, v) async {
            await repo.recordReading(rentalUnitId: widget.unitId, meterType: v['meterType'] as String, currentReading: _amount(v['currentReading']));
            changed();
          },
          done: 'Reading recorded',
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction(
          'Bill this reading',
          Icons.receipt_outlined,
          title: 'Bill from this reading',
          fields: const <FieldSpec>[FieldSpec('ratePerUnit', 'Price per unit (USD)', kind: FieldKind.number, helper: 'Leave empty to use the standard rate.')],
          run: (m, v) async {
            final rate = v['ratePerUnit'];
            await repo.billFromReading(id(m), ratePerUnit: rate == null ? null : _amount(rate));
          },
          done: 'Bill created',
        ),
      ],
    );
  }
}

/// Utility bills of one unit: create one by hand, see what is unpaid, and record a payment.
class BillsTab extends ConsumerStatefulWidget {
  const BillsTab({super.key, required this.unitId});

  final String unitId;

  @override
  ConsumerState<BillsTab> createState() => _BillsTabState();
}

class _BillsTabState extends ConsumerState<BillsTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    String id(Json m) => pick(m, <String>['id', 'billId']);
    void changed() {
      if (mounted) setState(() => _bump++);
    }

    return ResourceSection(
      refreshKey: _bump,
      load: () => repo.billsForUnit(widget.unitId),
      detail: (m) => repo.bill(id(m)),
      emptyTitle: 'No bills yet',
      emptyIcon: Icons.bolt_outlined,
      row: RowView(
        icon: Icons.bolt_outlined,
        title: (m) => sentence(pick(m, <String>['utilityType'], 'Bill')),
        subtitle: (m) => 'Due ${displayValue(m['dueDate'] ?? m['billingPeriodEnd'])}',
        status: (m) => pick(m, <String>['status']),
        trailing: (m) => _money(m['amount'] ?? m['totalAmount']),
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Create a bill',
          Icons.add_rounded,
          title: 'Create a utility bill',
          fields: const <FieldSpec>[
            FieldSpec('utilityType', 'Utility', kind: FieldKind.select, required: true, options: utilityTypes),
            FieldSpec('amount', 'Amount (USD)', kind: FieldKind.number, required: true),
            FieldSpec('billingPeriodStart', 'Period starts', kind: FieldKind.dateTime),
            FieldSpec('billingPeriodEnd', 'Period ends', kind: FieldKind.dateTime),
          ],
          run: (_, v) async {
            await repo.generateBill(<String, dynamic>{...v, 'rentalUnitId': widget.unitId});
            changed();
          },
          done: 'Bill created',
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction(
          'Record a payment',
          Icons.payments_outlined,
          title: 'Pay this bill',
          visible: (m) => pick(m, <String>['status']) != 'PAID',
          fields: const <FieldSpec>[FieldSpec('amount', 'Amount (USD)', kind: FieldKind.number, required: true)],
          run: (m, v) async {
            await repo.payBill(id(m), _amount(v['amount']));
            changed();
          },
          done: 'Payment recorded',
        ),
      ],
    );
  }
}
