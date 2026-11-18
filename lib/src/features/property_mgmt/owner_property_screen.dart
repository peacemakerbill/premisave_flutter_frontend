import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/property_models.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/service_widgets.dart';

/// Property management for home owners: the dashboard, properties and units, leases and maintenance.
/// Talks to the property management service.
class OwnerPropertyScreen extends ConsumerStatefulWidget {
  const OwnerPropertyScreen({super.key});

  @override
  ConsumerState<OwnerPropertyScreen> createState() => _OwnerPropertyScreenState();
}

class _OwnerPropertyScreenState extends ConsumerState<OwnerPropertyScreen> {
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
      loading: () => const SkeletonList(),
      error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(ownerProfileExistsProvider)),
      data: (yes) {
        if (!yes) {
          return EmptyState(
            icon: Icons.apartment_rounded,
            title: 'Set up property management',
            message: 'Create your owner profile from your Premisave account to manage properties, units, leases and rent.',
            actionLabel: _creating ? 'Creating' : 'Create owner profile',
            onAction: _creating ? null : _createProfile,
          );
        }
        return DefaultTabController(
          length: 4,
          child: Column(
            children: const <Widget>[
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: <Tab>[Tab(text: 'Overview'), Tab(text: 'Properties'), Tab(text: 'Leases'), Tab(text: 'Maintenance')],
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[_Overview(), _Properties(), _Leases(), _Maintenance()],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Overview extends ConsumerWidget {
  const _Overview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody<OwnerDashboard>(
      value: ref.watch(ownerDashboardProvider),
      onRetry: () => ref.invalidate(ownerDashboardProvider),
      builder: (d) => PageBody(
        onRefresh: () async => ref.invalidate(ownerDashboardProvider),
        children: <Widget>[
          ResponsiveWrap(
            minItemWidth: 150,
            children: <Widget>[
              StatTile(label: 'Properties', value: '${d.totalProperties}', icon: Icons.apartment_rounded),
              StatTile(label: 'Units', value: '${d.totalUnits}', icon: Icons.meeting_room_outlined, tint: Brand.info),
              StatTile(
                label: 'Occupied',
                value: '${d.occupiedUnits}',
                icon: Icons.key_rounded,
                tint: Brand.success,
                caption: '${(d.occupancyRate * 100).round()}% of units',
              ),
              StatTile(label: 'Active leases', value: '${d.activeLeases}', icon: Icons.description_outlined),
              StatTile(label: 'Monthly revenue', value: groupDigits(d.monthlyRevenue, decimals: 0), icon: Icons.payments_outlined, tint: Brand.success),
              StatTile(label: 'Pending maintenance', value: '${d.pendingMaintenance}', icon: Icons.build_circle_outlined, tint: Brand.warning),
            ],
          ),
          if (d.occupancy.isNotEmpty) ...<Widget>[
            const SectionHeader('Occupancy by property'),
            for (final o in d.occupancy)
              PCard(
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: Text(o.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                        Text('${o.occupiedUnits} of ${o.totalUnits} units', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: o.totalUnits == 0 ? 0 : o.occupiedUnits / o.totalUnits,
                        minHeight: 8,
                        backgroundColor: context.pal.accent.op(0.12),
                        color: context.pal.accent,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Properties extends ConsumerWidget {
  const _Properties();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody<List<PropertyModel>>(
      value: ref.watch(myPropertiesProvider),
      onRetry: () => ref.invalidate(myPropertiesProvider),
      builder: (items) => PageBody(
        maxWidth: 760,
        onRefresh: () async => ref.invalidate(myPropertiesProvider),
        children: items.isEmpty
            ? const <Widget>[SizedBox(height: 340, child: EmptyState(icon: Icons.apartment_rounded, title: 'No properties yet', message: 'Properties you register appear here with their units.'))]
            : <Widget>[
                for (final p in items)
                  PCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => showFormSheet<void>(context, title: p.title, subtitle: p.address.line, child: _UnitsList(propertyId: p.id)),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: context.pal.accent.op(0.12), borderRadius: BorderRadius.circular(context.radius(12))),
                          child: Icon(Icons.apartment_rounded, color: context.pal.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(p.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                              const SizedBox(height: 2),
                              Text('${sentence(p.propertyType)}  ·  ${p.availableUnits} of ${p.totalUnits} units free', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                            ],
                          ),
                        ),
                        if (p.verified) const StatusPill('Verified', color: Brand.success, dense: true),
                      ],
                    ),
                  ),
              ],
      ),
    );
  }
}

class _UnitsList extends ConsumerWidget {
  const _UnitsList({required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(propertyUnitsProvider(propertyId)).when(
          loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => InlineMessage(ApiException.from(e).message, kind: MessageKind.error),
          data: (units) {
            if (units.isEmpty) return const InlineMessage('This property has no units yet.');
            return Column(
              children: <Widget>[
                for (final u in units)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(u.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                                Text(
                                  <String>[if (u.floor != null) 'Floor ${u.floor}', formatMoney(u.rentAmount)].join('  ·  '),
                                  style: TextStyle(fontSize: 12.5, color: context.mutedColor),
                                ),
                              ],
                            ),
                          ),
                          StatusChip(u.status),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
  }
}

class _Leases extends ConsumerWidget {
  const _Leases();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncBody<List<LeaseModel>>(
      value: ref.watch(ownerLeasesProvider),
      onRetry: () => ref.invalidate(ownerLeasesProvider),
      builder: (items) => PageBody(
        maxWidth: 760,
        onRefresh: () async => ref.invalidate(ownerLeasesProvider),
        children: items.isEmpty
            ? const <Widget>[SizedBox(height: 340, child: EmptyState(icon: Icons.description_outlined, title: 'No leases yet'))]
            : <Widget>[for (final l in items) LeaseCard(lease: l)],
      ),
    );
  }
}

class _Maintenance extends ConsumerStatefulWidget {
  const _Maintenance();

  @override
  ConsumerState<_Maintenance> createState() => _MaintenanceState();
}

class _MaintenanceState extends ConsumerState<_Maintenance> {
  Future<void> _set(MaintenanceModel m, String status) async {
    try {
      await ref.read(propertyRepositoryProvider).setMaintenanceStatus(m.id, status);
      ref.invalidate(pendingMaintenanceProvider);
      ref.invalidate(ownerDashboardProvider);
      if (mounted) showToast(context, 'Marked ${sentence(status).toLowerCase()}');
    } catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<List<MaintenanceModel>>(
      value: ref.watch(pendingMaintenanceProvider),
      onRetry: () => ref.invalidate(pendingMaintenanceProvider),
      builder: (items) => PageBody(
        maxWidth: 760,
        onRefresh: () async => ref.invalidate(pendingMaintenanceProvider),
        children: items.isEmpty
            ? const <Widget>[SizedBox(height: 340, child: EmptyState(icon: Icons.build_circle_outlined, title: 'Nothing waiting', message: 'Maintenance requests from your tenants appear here.'))]
            : <Widget>[
                for (final m in items)
                  PCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(child: Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5))),
                            StatusChip(m.status),
                          ],
                        ),
                        if (m.description != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(m.description!, style: const TextStyle(height: 1.4))),
                        const SizedBox(height: 6),
                        Text(
                          <String>[
                            if (m.propertyTitle != null) m.propertyTitle!,
                            if (m.unitNumber != null) 'Unit ${m.unitNumber}',
                            if (m.tenantName != null) m.tenantName!,
                            timeAgo(m.createdAt),
                          ].where((e) => e.isNotEmpty).join('  ·  '),
                          style: TextStyle(fontSize: 12.5, color: context.mutedColor),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            PButton(label: 'Start work', kind: PButtonKind.outline, small: true, onPressed: () => _set(m, 'IN_PROGRESS')),
                            const SizedBox(width: 8),
                            PButton(label: 'Mark done', small: true, onPressed: () => _set(m, 'COMPLETED')),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
      ),
    );
  }
}

/// A lease as a card. Used by the owner and the tenant screens.
class LeaseCard extends StatelessWidget {
  const LeaseCard({super.key, required this.lease});

  final LeaseModel lease;

  @override
  Widget build(BuildContext context) {
    return PCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(lease.where, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5))),
              StatusChip(lease.status),
            ],
          ),
          const SizedBox(height: 8),
          KeyValueLine('Rent per month', formatMoney(lease.monthlyRent), bold: true),
          KeyValueLine('Starts', formatDate(lease.startDate)),
          KeyValueLine('Ends', formatDate(lease.endDate)),
          if (lease.securityDeposit != null) KeyValueLine('Security deposit', formatMoney(lease.securityDeposit)),
        ],
      ),
    );
  }
}
