import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/property_repository.dart';
import '../../state/providers.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';

const Map<String, String> noticeTypes = <String, String>{
  'RENT_REMINDER': 'Rent reminder',
  'LEASE_RENEWAL': 'Lease renewal',
  'EVICTION': 'Eviction',
  'MOVE_OUT': 'Move out',
  'MAINTENANCE': 'Maintenance',
  'GENERAL': 'General',
};

const Map<String, String> utilityTypes = <String, String>{
  'ELECTRICITY': 'Electricity',
  'WATER': 'Water',
  'GAS': 'Gas',
  'INTERNET': 'Internet',
  'GARBAGE': 'Garbage',
  'OTHER': 'Other',
};

/// Status chips above a list that is loaded once per status.
class StatusTabs extends StatefulWidget {
  const StatusTabs({super.key, required this.statuses, required this.builder, this.initial});

  final Map<String, String> statuses;
  final String? initial;

  /// Builds the list for one status. It is rebuilt from scratch whenever the status changes.
  final Widget Function(String status) builder;

  @override
  State<StatusTabs> createState() => _StatusTabsState();
}

class _StatusTabsState extends State<StatusTabs> {
  late String _status = widget.initial ?? widget.statuses.keys.first;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: <Widget>[
              for (final e in widget.statuses.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(e.value), selected: _status == e.key, onSelected: (_) => setState(() => _status = e.key)),
                ),
            ],
          ),
        ),
        Expanded(child: KeyedSubtree(key: ValueKey<String>(_status), child: widget.builder(_status))),
      ],
    );
  }
}

// -------------------------------------------------------------- maintenance

List<ItemAction> maintenanceActions(PropertyRepository repo) {
  String id(Json m) => pick(m, <String>['id', 'maintenanceRequestId']);
  return <ItemAction>[
    ItemAction(
      'Start work',
      Icons.play_arrow_rounded,
      visible: (m) => pick(m, <String>['status']) == 'PENDING',
      confirm: 'Mark this request as in progress.',
      run: (m, _) async {
        await repo.updateMaintenanceStatus(id(m), 'IN_PROGRESS');
      },
      done: 'Marked in progress',
    ),
    ItemAction(
      'Complete',
      Icons.check_circle_outline_rounded,
      visible: (m) => <String>{'PENDING', 'IN_PROGRESS'}.contains(pick(m, <String>['status'])),
      confirm: 'Mark this request as completed.',
      run: (m, _) async {
        await repo.updateMaintenanceStatus(id(m), 'COMPLETED');
      },
      done: 'Marked completed',
    ),
    ItemAction(
      'Assign a work order',
      Icons.engineering_outlined,
      title: 'Assign a work order',
      visible: (m) => <String>{'PENDING', 'IN_PROGRESS'}.contains(pick(m, <String>['status'])),
      fields: const <FieldSpec>[
        FieldSpec('assignedTo', 'Assigned to (user id)', required: true),
        FieldSpec('title', 'Title', required: true),
        FieldSpec('description', 'Instructions', kind: FieldKind.multiline),
      ],
      run: (m, v) async {
        await repo.createWorkOrder(<String, dynamic>{...v, 'maintenanceRequestId': id(m)});
      },
      done: 'Work order assigned',
    ),
    ItemAction(
      'Work orders',
      Icons.list_alt_rounded,
      title: 'Work orders',
      page: (m) => ResourceSection(
        load: () => repo.workOrdersForRequest(id(m)),
        emptyTitle: 'No work orders yet',
        emptyIcon: Icons.engineering_outlined,
        itemActions: workOrderActions(repo),
        row: _workOrderRow,
      ),
    ),
    ItemAction(
      'Cancel',
      Icons.cancel_outlined,
      danger: true,
      visible: (m) => <String>{'PENDING', 'IN_PROGRESS'}.contains(pick(m, <String>['status'])),
      confirm: 'Cancel this maintenance request?',
      run: (m, _) async {
        await repo.updateMaintenanceStatus(id(m), 'CANCELLED');
      },
      done: 'Request cancelled',
    ),
  ];
}

List<ItemAction> workOrderActions(PropertyRepository repo) {
  String id(Json m) => pick(m, <String>['id', 'workOrderId']);
  return <ItemAction>[
    ItemAction(
      'Start',
      Icons.play_arrow_rounded,
      visible: (m) => pick(m, <String>['status']) == 'ASSIGNED',
      confirm: 'Mark this work order as in progress.',
      run: (m, _) async {
        await repo.updateWorkOrderStatus(id(m), 'IN_PROGRESS');
      },
      done: 'Work order started',
    ),
    ItemAction(
      'Complete',
      Icons.check_circle_outline_rounded,
      visible: (m) => <String>{'ASSIGNED', 'IN_PROGRESS'}.contains(pick(m, <String>['status'])),
      confirm: 'Mark this work order as completed.',
      run: (m, _) async {
        await repo.updateWorkOrderStatus(id(m), 'COMPLETED');
      },
      done: 'Work order completed',
    ),
    ItemAction(
      'Cancel',
      Icons.cancel_outlined,
      danger: true,
      visible: (m) => <String>{'ASSIGNED', 'IN_PROGRESS'}.contains(pick(m, <String>['status'])),
      confirm: 'Cancel this work order?',
      run: (m, _) async {
        await repo.updateWorkOrderStatus(id(m), 'CANCELLED');
      },
      done: 'Work order cancelled',
    ),
  ];
}

final RowView _workOrderRow = RowView(
  icon: Icons.engineering_outlined,
  title: (m) => pick(m, <String>['title'], 'Work order'),
  subtitle: (m) => pick(m, <String>['assignedTo']).isEmpty ? '' : 'Assigned to ${pick(m, <String>['assignedTo'])}',
  status: (m) => pick(m, <String>['status']),
);

class MaintenanceTab extends ConsumerWidget {
  const MaintenanceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(propertyRepositoryProvider);
    return StatusTabs(
      statuses: const <String, String>{'PENDING': 'Pending', 'IN_PROGRESS': 'In progress', 'COMPLETED': 'Completed', 'CANCELLED': 'Cancelled'},
      builder: (status) => ResourceSection(
        load: () => repo.maintenanceRaw(status),
        detail: (m) => repo.maintenanceRequest(pick(m, <String>['id'])),
        emptyTitle: 'No requests here',
        emptyMessage: 'Requests from tenants appear here. You can also log one yourself.',
        emptyIcon: Icons.build_circle_outlined,
        row: RowView(
          icon: Icons.build_circle_outlined,
          title: (m) => pick(m, <String>['title'], 'Request'),
          subtitle: (m) => pick(m, <String>['description']),
          status: (m) => pick(m, <String>['status']),
        ),
        headerActions: <ItemAction>[
          ItemAction(
            'Log a request',
            Icons.add_rounded,
            title: 'Log a maintenance request',
            fields: const <FieldSpec>[
              FieldSpec('rentalUnitId', 'Unit id', required: true),
              FieldSpec('title', 'Title', required: true),
              FieldSpec('description', 'Description', kind: FieldKind.multiline),
            ],
            run: (_, v) async {
              await repo.createMaintenance(v);
            },
            done: 'Request logged',
          ),
        ],
        itemActions: maintenanceActions(repo),
      ),
    );
  }
}

class WorkOrdersTab extends ConsumerWidget {
  const WorkOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(propertyRepositoryProvider);
    return StatusTabs(
      statuses: const <String, String>{'ASSIGNED': 'Assigned', 'IN_PROGRESS': 'In progress', 'COMPLETED': 'Completed', 'CANCELLED': 'Cancelled'},
      builder: (status) => ResourceSection(
        load: () => repo.workOrders(status),
        detail: (m) => repo.workOrder(pick(m, <String>['id'])),
        emptyTitle: 'No work orders here',
        emptyMessage: 'Assign a work order from a maintenance request.',
        emptyIcon: Icons.engineering_outlined,
        row: _workOrderRow,
        itemActions: workOrderActions(repo),
      ),
    );
  }
}

// -------------------------------------------------------------- inspections

const List<FieldSpec> _inspectionFields = <FieldSpec>[
  FieldSpec('title', 'Title', required: true),
  FieldSpec('scheduledDate', 'Date', kind: FieldKind.date, required: true),
  FieldSpec('inspectorFullName', 'Inspector name', required: true),
  FieldSpec('inspectorPhoneNumber', 'Inspector phone', kind: FieldKind.phone, required: true),
  FieldSpec('inspectorIdNumber', 'Inspector id number'),
  FieldSpec('inspectorEmail', 'Inspector email', kind: FieldKind.email),
];

List<ItemAction> _inspectionActions(PropertyRepository repo) {
  String id(Json m) => pick(m, <String>['id', 'inspectionId']);
  return <ItemAction>[
    ItemAction(
      'Complete',
      Icons.check_circle_outline_rounded,
      title: 'Complete the inspection',
      visible: (m) => pick(m, <String>['status']) == 'SCHEDULED',
      fields: const <FieldSpec>[
        FieldSpec('findings', 'Findings', kind: FieldKind.multiline, required: true),
        FieldSpec('recommendations', 'Recommendations', kind: FieldKind.multiline),
      ],
      run: (m, v) async {
        await repo.completeInspection(id(m), findings: v['findings'] as String, recommendations: v['recommendations'] as String?);
      },
      done: 'Inspection completed',
    ),
    ItemAction(
      'Cancel',
      Icons.cancel_outlined,
      danger: true,
      visible: (m) => pick(m, <String>['status']) == 'SCHEDULED',
      confirm: 'Cancel this inspection?',
      run: (m, _) async {
        await repo.cancelInspection(id(m));
      },
      done: 'Inspection cancelled',
    ),
  ];
}

final RowView _inspectionRow = RowView(
  icon: Icons.fact_check_outlined,
  title: (m) => pick(m, <String>['title'], 'Inspection'),
  subtitle: (m) => <String>[displayValue(m['scheduledDate']), pick(m, <String>['inspectorFullName'])].where((e) => e.isNotEmpty && e != 'None').join(' with '),
  status: (m) => pick(m, <String>['status']),
);

class InspectionsTab extends ConsumerWidget {
  const InspectionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(propertyRepositoryProvider);
    return StatusTabs(
      statuses: const <String, String>{'SCHEDULED': 'Scheduled', 'COMPLETED': 'Completed', 'CANCELLED': 'Cancelled'},
      builder: (status) => ResourceSection(
        load: () => repo.myInspections(status),
        detail: (m) => repo.inspection(pick(m, <String>['id'])),
        emptyTitle: 'No inspections here',
        emptyMessage: 'Schedule an inspection from a unit, or here with the unit id.',
        emptyIcon: Icons.fact_check_outlined,
        row: _inspectionRow,
        headerActions: <ItemAction>[
          ItemAction(
            'Schedule an inspection',
            Icons.add_rounded,
            title: 'Schedule an inspection',
            fields: const <FieldSpec>[FieldSpec('rentalUnitId', 'Unit id', required: true), ..._inspectionFields],
            run: (_, v) async {
              await repo.createInspection(v);
            },
            done: 'Inspection scheduled',
          ),
        ],
        itemActions: _inspectionActions(repo),
      ),
    );
  }
}

class UnitInspectionsTab extends ConsumerWidget {
  const UnitInspectionsTab({super.key, required this.unitId});

  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(propertyRepositoryProvider);
    return ResourceSection(
      load: () => repo.inspectionsForUnit(unitId),
      detail: (m) => repo.inspection(pick(m, <String>['id'])),
      emptyTitle: 'No inspections for this unit',
      emptyIcon: Icons.fact_check_outlined,
      row: _inspectionRow,
      headerActions: <ItemAction>[
        ItemAction(
          'Schedule an inspection',
          Icons.add_rounded,
          title: 'Schedule an inspection',
          fields: _inspectionFields,
          run: (_, v) async {
            await repo.createInspection(<String, dynamic>{...v, 'rentalUnitId': unitId});
          },
          done: 'Inspection scheduled',
        ),
      ],
      itemActions: _inspectionActions(repo),
    );
  }
}

// ------------------------------------------------------------------- notices

/// Notices the owner has sent to tenants, one at a time or to many, now or at a set time.
class NoticesTab extends ConsumerStatefulWidget {
  const NoticesTab({super.key});

  @override
  ConsumerState<NoticesTab> createState() => _NoticesTabState();
}

class _NoticesTabState extends ConsumerState<NoticesTab> {
  Map<String, String> _leases = const <String, String>{};
  int _bump = 0;

  @override
  void initState() {
    super.initState();
    _loadLeases();
  }

  Future<void> _loadLeases() async {
    try {
      final rows = await ref.read(propertyRepositoryProvider).ownerLeasesRaw();
      final options = <String, String>{};
      for (final l in rows) {
        final id = pick(l, <String>['id']);
        if (id.isEmpty) continue;
        final unit = pick(l, <String>['rentalUnit.unitNumber']);
        final where = pick(l, <String>['property.title'], 'Lease');
        options[id] = unit.isEmpty ? where : '$where, unit $unit';
      }
      if (mounted) setState(() => _leases = options);
    } catch (_) {
      // The form still works with a unit id when the leases cannot be loaded.
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    return ResourceSection(
      refreshKey: _bump,
      load: repo.myBulkNotices,
      detail: (m) => repo.bulkNotice(pick(m, <String>['id'])),
      intro: 'Notices go out by email. Leave the time empty to send now.',
      emptyTitle: 'No notices sent',
      emptyMessage: 'Send a rent reminder or a general notice to your tenants.',
      emptyIcon: Icons.campaign_outlined,
      row: RowView(
        icon: Icons.campaign_outlined,
        title: (m) => pick(m, <String>['title'], 'Notice'),
        subtitle: (m) => sentence(pick(m, <String>['noticeType'])),
        status: (m) => pick(m, <String>['status']),
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Send a notice',
          Icons.send_rounded,
          title: 'Send a notice',
          fields: <FieldSpec>[
            FieldSpec('noticeType', 'Kind of notice', kind: FieldKind.select, required: true, options: noticeTypes),
            const FieldSpec('title', 'Title', required: true),
            const FieldSpec('content', 'Message', kind: FieldKind.multiline, required: true),
            if (_leases.isNotEmpty) FieldSpec('leaseIds', 'Tenants (by lease)', kind: FieldKind.multiSelect, required: true, options: _leases),
            if (_leases.isEmpty) const FieldSpec('rentalUnitIds', 'Unit ids, separated by commas', required: true),
            const FieldSpec('scheduledAt', 'Send at', kind: FieldKind.dateTime, helper: 'Leave empty to send now.'),
          ],
          run: (_, v) async {
            final body = <String, dynamic>{...v, 'channels': <String>['EMAIL']};
            final units = body['rentalUnitIds'];
            if (units is String) {
              body['rentalUnitIds'] = units.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            }
            await repo.sendBulkNotice(body);
            if (mounted) setState(() => _bump++);
          },
          done: 'Notice sent',
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction(
          'Cancel',
          Icons.cancel_outlined,
          danger: true,
          visible: (m) => pick(m, <String>['status']) == 'SCHEDULED' || pick(m, <String>['status']) == 'PENDING',
          confirm: 'Cancel this notice before it is sent?',
          run: (m, _) async {
            await repo.cancelBulkNotice(pick(m, <String>['id']));
            if (mounted) setState(() => _bump++);
          },
          done: 'Notice cancelled',
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- reports

class ReportsTab extends ConsumerStatefulWidget {
  const ReportsTab({super.key});

  @override
  ConsumerState<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends ConsumerState<ReportsTab> {
  late DateTime _start = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _end = DateTime.now();
  int _bump = 0;

  Future<void> _pick(bool start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
      _bump++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: <Widget>[
        const BlockTitle('Occupancy'),
        _ReportBlock(key: ValueKey<String>('occ$_bump'), load: repo.occupancyReport),
        const SizedBox(height: 16),
        const BlockTitle('Revenue'),
        Row(
          children: <Widget>[
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(true), icon: const Icon(Icons.event_rounded, size: 18), label: Text('From ${formatDate(_start)}'))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton.icon(onPressed: () => _pick(false), icon: const Icon(Icons.event_rounded, size: 18), label: Text('To ${formatDate(_end)}'))),
          ],
        ),
        const SizedBox(height: 10),
        _ReportBlock(key: ValueKey<String>('rev$_bump'), load: () => repo.revenueReport(_start, _end)),
      ],
    );
  }
}

/// One report: the numbers as label and value rows, with the error and a retry when the call fails.
class _ReportBlock extends StatefulWidget {
  const _ReportBlock({super.key, required this.load});

  final Future<Json> Function() load;

  @override
  State<_ReportBlock> createState() => _ReportBlockState();
}

class _ReportBlockState extends State<_ReportBlock> {
  late Future<Json> _future = widget.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Json>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SkeletonList(count: 1, height: 90, shrink: true);
        }
        if (snap.hasError) return ErrorState(error: snap.error!, onRetry: () => setState(() => _future = widget.load()));
        final data = snap.data ?? <String, dynamic>{};
        return PCard(child: data.isEmpty ? const Text('Nothing to report for this period.') : MapDetail(data));
      },
    );
  }
}

// ----------------------------------------------------------------- blacklist

class BlacklistTab extends ConsumerStatefulWidget {
  const BlacklistTab({super.key});

  @override
  ConsumerState<BlacklistTab> createState() => _BlacklistTabState();
}

class _BlacklistTabState extends ConsumerState<BlacklistTab> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    String tenantOf(Json m) => pick(m, <String>['tenantId', 'tenant.id', 'id']);
    return ResourceSection(
      load: repo.blacklist,
      intro: 'Tenants you have blacklisted. Other owners can see the reason.',
      emptyTitle: 'Nobody is blacklisted',
      emptyIcon: Icons.block_outlined,
      row: RowView(
        icon: Icons.block_outlined,
        title: (m) => pick(m, <String>['tenantName', 'tenant.fullName', 'tenantId'], 'Tenant'),
        subtitle: (m) => pick(m, <String>['reason']),
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Blacklist a tenant',
          Icons.block_outlined,
          title: 'Blacklist a tenant',
          fields: const <FieldSpec>[
            FieldSpec('tenantId', 'Tenant id', required: true),
            FieldSpec('reason', 'Reason', kind: FieldKind.multiline, required: true),
            FieldSpec('notes', 'Notes', kind: FieldKind.multiline),
          ],
          run: (_, v) async {
            await repo.blacklistTenant(tenantId: v['tenantId'] as String, reason: v['reason'] as String, notes: v['notes'] as String?);
          },
          done: 'Tenant blacklisted',
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction(
          'Remove from the list',
          Icons.undo_rounded,
          confirm: 'Remove this tenant from the blacklist?',
          run: (m, _) => repo.removeFromBlacklist(tenantOf(m)),
          done: 'Removed from the blacklist',
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- owner profile

class OwnerProfileTab extends ConsumerStatefulWidget {
  const OwnerProfileTab({super.key});

  @override
  ConsumerState<OwnerProfileTab> createState() => _OwnerProfileTabState();
}

class _OwnerProfileTabState extends ConsumerState<OwnerProfileTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(propertyRepositoryProvider);
    return ResourceView(
      refreshKey: _bump,
      load: repo.ownerProfile,
      intro: 'Your owner profile on the property service.',
      actions: <ItemAction>[
        ItemAction(
          'Edit profile',
          Icons.edit_outlined,
          title: 'Edit owner profile',
          initialFromItem: true,
          fields: const <FieldSpec>[
            FieldSpec('fullName', 'Full name'),
            FieldSpec('phoneNumber', 'Phone', kind: FieldKind.phone),
            FieldSpec('email', 'Email', kind: FieldKind.email),
            FieldSpec('address.street', 'Street'),
            FieldSpec('address.city', 'City'),
            FieldSpec('address.state', 'State or county'),
            FieldSpec('address.country', 'Country'),
            FieldSpec('address.postalCode', 'Postal code'),
          ],
          run: (m, v) async {
            await repo.updateOwner(pick(m, <String>['id']), v);
            if (mounted) setState(() => _bump++);
          },
          done: 'Profile saved',
        ),
        ItemAction(
          'Bank details',
          Icons.account_balance_outlined,
          title: 'Bank details for payouts',
          initialFromItem: true,
          fields: const <FieldSpec>[
            FieldSpec('bankDetails.bankName', 'Bank name'),
            FieldSpec('bankDetails.accountName', 'Account name'),
            FieldSpec('bankDetails.accountNumber', 'Account number'),
            FieldSpec('bankDetails.branchCode', 'Branch code'),
          ],
          run: (m, v) async {
            await repo.updateOwner(pick(m, <String>['id']), v);
            if (mounted) setState(() => _bump++);
          },
          done: 'Bank details saved',
        ),
        ItemAction(
          'Sync with Premisave',
          Icons.sync_rounded,
          confirm: 'Copy your latest Premisave account details to the property service.',
          run: (_, __) async {
            await repo.syncOwner();
            if (mounted) setState(() => _bump++);
          },
          done: 'Profile synced',
        ),
        ItemAction(
          'Sync status',
          Icons.info_outline_rounded,
          title: 'Sync status',
          page: (_) => ResourceView(load: repo.ownerSyncStatus),
        ),
        ItemAction(
          'Service health',
          Icons.monitor_heart_outlined,
          title: 'Service health',
          page: (_) => ResourceView(load: repo.dependencies),
        ),
      ],
    );
  }
}
