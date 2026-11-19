import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/property_repository.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/hub.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';
import 'owner_property_screen.dart';
import 'property_leases.dart';
import 'property_ops.dart';
import 'property_pickers.dart';

const Map<String, String> propertyTypes = <String, String>{
  'APARTMENT': 'Apartment',
  'HOUSE': 'House',
  'VILLA': 'Villa',
  'STUDIO': 'Studio',
  'DUPLEX': 'Duplex',
  'BUNGALOW': 'Bungalow',
  'TOWNHOUSE': 'Townhouse',
  'PENTHOUSE': 'Penthouse',
  'COTTAGE': 'Cottage',
  'MAISONETTE': 'Maisonette',
  'LAND': 'Land',
  'FARM': 'Farm',
  'WAREHOUSE': 'Warehouse',
  'COMMERCIAL': 'Commercial',
  'OFFICE': 'Office',
  'SHOP': 'Shop',
  'HOTEL': 'Hotel',
  'HOSTEL': 'Hostel',
  'PARKING': 'Parking',
  'EVENT_SPACE': 'Event space',
  'OTHER': 'Other',
};

const Map<String, String> registrationTypes = <String, String>{
  'TITLE_DEED': 'Title deed',
  'LR_NUMBER': 'LR number',
  'LEASE_CERTIFICATE': 'Lease certificate',
  'OTHER': 'Other',
};

const Map<String, String> unitStatuses = <String, String>{
  'VACANT': 'Vacant',
  'OCCUPIED': 'Occupied',
  'MAINTENANCE': 'Under maintenance',
  'RESERVED': 'Reserved',
  'UNAVAILABLE': 'Unavailable',
};

/// Property management for home owners. Every feature of the property service has its own menu: properties and their
/// units, leases, tenants, maintenance, work orders, inspections, notices, reports, the blacklist and the owner profile.
class OwnerPropertyHub extends ConsumerStatefulWidget {
  const OwnerPropertyHub({super.key});

  @override
  ConsumerState<OwnerPropertyHub> createState() => _OwnerPropertyHubState();
}

class _OwnerPropertyHubState extends ConsumerState<OwnerPropertyHub> {
  bool _creating = false;

  Future<void> _createProfile() async {
    setState(() => _creating = true);
    try {
      await ref.read(propertyRepositoryProvider).createOwnerProfile();
      ref.invalidate(ownerProfileExistsProvider);
      if (mounted) showToast(context, 'Your owner profile is ready');
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exists = ref.watch(ownerProfileExistsProvider);
    return exists.when(
      loading: () => const PScaffold(body: SkeletonList()),
      error: (e, _) => PScaffold(body: ErrorState(error: e, onRetry: () => ref.invalidate(ownerProfileExistsProvider))),
      data: (yes) {
        if (!yes) {
          return PScaffold(
            body: EmptyState(
              icon: Icons.apartment_rounded,
              title: 'Set up property management',
              message: 'Create your owner profile from your Premisave account to manage properties, units, leases and rent.',
              actionLabel: _creating ? 'Creating' : 'Create owner profile',
              onAction: _creating ? null : _createProfile,
            ),
          );
        }
        return HubPage(
          title: 'Property management',
          tabs: <HubTab>[
            HubTab('Overview', Icons.dashboard_outlined, (_) => const OwnerOverviewTab()),
            HubTab('Properties', Icons.apartment_rounded, (_) => const PropertiesTab()),
            HubTab('Leases', Icons.description_outlined, (_) => const LeasesTab()),
            HubTab('Tenants', Icons.groups_outlined, (_) => const TenantsTab()),
            HubTab('Maintenance', Icons.build_circle_outlined, (_) => const MaintenanceTab()),
          ],
        );
      },
    );
  }
}

// --------------------------------------------------------------- properties

class PropertiesTab extends ConsumerStatefulWidget {
  const PropertiesTab({super.key});

  @override
  ConsumerState<PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends ConsumerState<PropertiesTab> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final PropertyRepository repo = ref.read(propertyRepositoryProvider);
    String id(Json m) => pick(m, <String>['id', 'propertyId']);
    return ResourceSection(
      refreshKey: _bump,
      load: () => repo.propertiesRaw(),
      emptyTitle: 'No properties yet',
      emptyMessage: 'Add a property, then add its units and lease them.',
      emptyIcon: Icons.apartment_rounded,
      onOpen: (context, item) async {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => SubPage(title: pick(item, <String>['title'], 'Property'), body: PropertyDetailPage(propertyId: id(item)))),
        );
        if (mounted) setState(() => _bump++);
      },
      row: RowView(
        icon: Icons.apartment_rounded,
        title: (m) => pick(m, <String>['title'], 'Property'),
        subtitle: (m) => <String>[sentence(pick(m, <String>['propertyType'])), pick(m, <String>['address.city'])].where((e) => e.isNotEmpty).join(' in '),
        trailing: (m) {
          final total = m['totalUnits'];
          return total is num && total > 0 ? '${total.toInt()} units' : null;
        },
        status: (m) => m['isActive'] == false || m['active'] == false ? 'INACTIVE' : null,
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Add a property',
          Icons.add_home_work_outlined,
          title: 'Add a property',
          fields: propertyFields(),
          run: (_, v) async {
            await repo.createProperty(v);
            if (mounted) setState(() => _bump++);
          },
          done: 'Property added',
        ),
      ],
    );
  }
}

/// The details of a property, in the order a person fills them in. Used to add one and to edit it. The street box searches
/// places and fills in the city, state, postal code and map position.
List<FieldSpec> propertyFields({bool editing = false}) => <FieldSpec>[
      const FieldSpec('title', 'Name of the property', required: true, hint: 'Sunrise Apartments'),
      const FieldSpec('propertyType', 'Type', kind: FieldKind.select, required: true, options: propertyTypes),
      const FieldSpec('description', 'Description', kind: FieldKind.multiline, hint: 'What the property offers, its surroundings, parking and so on'),
      ...addressFields(),
      const FieldSpec('address.landmark', 'Landmark', hint: 'Near the main market'),
      const FieldSpec('registrationType', 'Registration document', kind: FieldKind.select, required: true, options: registrationTypes),
      const FieldSpec('registrationNumber', 'Registration number', required: true),
      if (editing) const FieldSpec('isActive', 'Active', kind: FieldKind.toggle, helper: 'An inactive property is kept but not offered for new leases.'),
    ];

/// One property on a screen of its own: its details with edit and delete, its units and who lives in them.
class PropertyDetailPage extends ConsumerStatefulWidget {
  const PropertyDetailPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends ConsumerState<PropertyDetailPage> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final PropertyRepository repo = ref.read(propertyRepositoryProvider);
    final id = widget.propertyId;
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          const TabBar(tabs: <Tab>[Tab(text: 'Details'), Tab(text: 'Units'), Tab(text: 'Occupants')]),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                ResourceView(
                  refreshKey: _bump,
                  load: () => repo.property(id),
                  actions: <ItemAction>[
                    ItemAction(
                      'Edit',
                      Icons.edit_outlined,
                      title: 'Edit property',
                      initialFromItem: true,
                      fields: propertyFields(editing: true),
                      run: (_, v) async {
                        await repo.updateProperty(id, v);
                        if (mounted) setState(() => _bump++);
                      },
                      done: 'Property saved',
                    ),
                    ItemAction(
                      'Delete',
                      Icons.delete_outline_rounded,
                      danger: true,
                      confirm: 'The property is deleted. A property with active leases cannot be deleted.',
                      run: (_, __) async {
                        await repo.deleteProperty(id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      done: 'Property deleted',
                    ),
                  ],
                ),
                UnitsPage(propertyId: id),
                OccupancyPage.property(propertyId: id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------- units

/// The units of one property.
class UnitsPage extends ConsumerStatefulWidget {
  const UnitsPage({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends ConsumerState<UnitsPage> {
  @override
  Widget build(BuildContext context) {
    final PropertyRepository repo = ref.read(propertyRepositoryProvider);
    String id(Json m) => pick(m, <String>['id', 'rentalUnitId']);
    return ResourceSection(
      load: () => repo.unitsRaw(widget.propertyId),
      emptyTitle: 'No units yet',
      emptyMessage: 'Add the apartments, rooms or shops that can be rented.',
      emptyIcon: Icons.meeting_room_outlined,
      onOpen: (context, item) => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => SubPage(title: 'Unit ${pick(item, <String>['unitNumber'], '')}'.trim(), body: UnitDetailPage(unitId: id(item)))),
      ),
      row: RowView(
        icon: Icons.meeting_room_outlined,
        title: (m) => 'Unit ${pick(m, <String>['unitNumber'], '-')}',
        subtitle: (m) => pick(m, <String>['floor']).isEmpty ? '' : 'Floor ${pick(m, <String>['floor'])}',
        status: (m) => pick(m, <String>['status']),
        trailing: (m) {
          final v = m['rentAmount'];
          return v is num ? formatMoney(v.toDouble()) : null;
        },
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Add a unit',
          Icons.add_rounded,
          title: 'Add a unit',
          fields: _unitFields,
          run: (_, v) async {
            await repo.createUnit(widget.propertyId, v);
          },
          done: 'Unit added',
        ),
      ],
    );
  }
}

const List<FieldSpec> _unitFields = <FieldSpec>[
  FieldSpec('unitNumber', 'Unit number', hint: 'A1'),
  FieldSpec('floor', 'Floor'),
  FieldSpec('rentAmount', 'Rent per month (USD)', kind: FieldKind.number, required: true),
  FieldSpec('securityDeposit', 'Security deposit (USD)', kind: FieldKind.number),
  FieldSpec('depositRequired', 'A deposit is required', kind: FieldKind.toggle),
  FieldSpec('status', 'Status', kind: FieldKind.select, options: unitStatuses),
];

/// One unit with a menu for everything about it: details, who lives in it, rent, meters and bills, maintenance,
/// inspections and the security deposit.
class UnitDetailPage extends ConsumerStatefulWidget {
  const UnitDetailPage({super.key, required this.unitId});

  final String unitId;

  @override
  ConsumerState<UnitDetailPage> createState() => _UnitDetailPageState();
}

class _UnitDetailPageState extends ConsumerState<UnitDetailPage> {
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final PropertyRepository repo = ref.read(propertyRepositoryProvider);
    final id = widget.unitId;
    return DefaultTabController(
      length: 7,
      child: Column(
        children: <Widget>[
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Tab>[Tab(text: 'Details'), Tab(text: 'Occupancy'), Tab(text: 'Rent'), Tab(text: 'Meters'), Tab(text: 'Bills'), Tab(text: 'Maintenance'), Tab(text: 'Inspections')],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                ResourceView(
                  refreshKey: _bump,
                  load: () => repo.unit(id),
                  actions: <ItemAction>[
                    ItemAction(
                      'Edit',
                      Icons.edit_outlined,
                      title: 'Edit unit',
                      initialFromItem: true,
                      fields: _unitFields,
                      run: (_, v) async {
                        await repo.updateUnit(id, v);
                        setState(() => _bump++);
                      },
                      done: 'Unit saved',
                    ),
                    ItemAction(
                      'Delete',
                      Icons.delete_outline_rounded,
                      danger: true,
                      confirm: 'The unit is deleted. A unit with an active lease cannot be deleted.',
                      run: (_, __) async {
                        await repo.deleteUnit(id);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                      done: 'Unit deleted',
                    ),
                  ],
                ),
                OccupancyPage.unit(unitId: id),
                UnitRentTab(unitId: id),
                MetersTab(unitId: id),
                BillsTab(unitId: id),
                ResourceSection(
                  load: () => repo.maintenanceForUnit(id),
                  emptyTitle: 'No maintenance requests',
                  emptyIcon: Icons.build_circle_outlined,
                  row: _maintenanceRow,
                  itemActions: maintenanceActions(repo, ref.read(profileRepositoryProvider)),
                ),
                UnitInspectionsTab(unitId: id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Who lives in a property or a unit now, and who did before. Move in and move out are recorded here.
class OccupancyPage extends ConsumerWidget {
  const OccupancyPage.unit({super.key, required String this.unitId}) : propertyId = null;

  const OccupancyPage.property({super.key, required String this.propertyId}) : unitId = null;

  final String? unitId;
  final String? propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PropertyRepository repo = ref.read(propertyRepositoryProvider);
    final unit = unitId;
    return ResourceSection(
      load: () => unit != null ? repo.unitOccupancyHistory(unit) : repo.propertyOccupancyHistory(propertyId!),
      intro: 'Move in and move out records, newest first.',
      emptyTitle: 'No occupancy yet',
      emptyIcon: Icons.key_rounded,
      row: RowView(
        icon: Icons.key_rounded,
        title: (m) => pick(m, <String>['tenantName', 'tenant.fullName', 'tenantId'], 'Tenant'),
        subtitle: (m) => '${displayValue(m['moveInDate'] ?? m['startDate'])} to ${m['moveOutDate'] == null && m['endDate'] == null ? 'now' : displayValue(m['moveOutDate'] ?? m['endDate'])}',
        status: (m) => pick(m, <String>['status']),
      ),
      headerActions: <ItemAction>[
        if (unit != null) ...<ItemAction>[
          ItemAction(
            'Move in',
            Icons.login_rounded,
            title: 'Record a move in',
            subtitle: 'For a tenant who has no lease on this unit.',
            fields: <FieldSpec>[tenantPicker(repo, required: true)],
            run: (_, v) async {
              await repo.moveInDirect(unit, v['tenantId'] as String);
            },
            done: 'Move in recorded',
          ),
          ItemAction(
            'Move out',
            Icons.logout_rounded,
            title: 'Record a move out',
            fields: <FieldSpec>[
              FieldSpec(
                'tenantId',
                'Who is moving out',
                kind: FieldKind.picker,
                required: true,
                loader: () async {
                  final history = await repo.unitOccupancyHistory(unit);
                  return <PickOption>[
                    for (final h in history)
                      if (h['moveOutDate'] == null && pick(h, <String>['tenantId']).isNotEmpty)
                        PickOption(pick(h, <String>['tenantId']), pick(h, <String>['tenant.fullName'], 'Tenant'), description: pick(h, <String>['tenant.phoneNumber'])),
                  ];
                },
              ),
            ],
            run: (_, v) async {
              await repo.moveOutDirect(unit, v['tenantId'] as String);
            },
            done: 'Move out recorded',
          ),
        ],
      ],
    );
  }
}

final RowView _maintenanceRow = RowView(
  icon: Icons.build_circle_outlined,
  title: (m) => pick(m, <String>['title'], 'Request'),
  subtitle: (m) => <String>[
    pick(m, <String>['rentalUnit.unitNumber']).isEmpty ? '' : 'Unit ${pick(m, <String>['rentalUnit.unitNumber'])}',
    pick(m, <String>['description']),
  ].where((e) => e.isNotEmpty).join(', '),
  status: (m) => pick(m, <String>['status']),
);
