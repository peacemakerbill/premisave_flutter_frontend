import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/property_models.dart';
import '../../state/service_providers.dart';
import 'property_hub.dart';
import 'property_ops.dart';

/// The owner dashboard. Every number opens the part of property management it counts, every property opens its own page,
/// and the areas that are not tabs (work orders, inspections, notices, reports, the blacklist, the profile) are in the menu
/// at the bottom.
class OwnerOverviewTab extends ConsumerWidget {
  const OwnerOverviewTab({super.key});

  void _tab(BuildContext context, int index) => DefaultTabController.maybeOf(context)?.animateTo(index);

  void _page(BuildContext context, String title, Widget body) {
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => SubPage(title: title, body: body)));
  }

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
              StatTile(label: 'Properties', value: '${d.totalProperties}', icon: Icons.apartment_rounded, onTap: () => _tab(context, 1)),
              StatTile(label: 'Units', value: '${d.totalUnits}', icon: Icons.meeting_room_outlined, tint: Brand.info, onTap: () => _tab(context, 1)),
              StatTile(
                label: 'Occupied',
                value: '${d.occupiedUnits}',
                icon: Icons.key_rounded,
                tint: Brand.success,
                caption: '${(d.occupancyRate * 100).round()}% of units',
                onTap: () => _tab(context, 1),
              ),
              StatTile(label: 'Active leases', value: '${d.activeLeases}', icon: Icons.description_outlined, onTap: () => _tab(context, 2)),
              StatTile(
                label: 'Monthly revenue',
                value: groupDigits(d.monthlyRevenue, decimals: 0),
                icon: Icons.payments_outlined,
                tint: Brand.success,
                onTap: () => _page(context, 'Reports', const ReportsTab()),
              ),
              StatTile(
                label: 'Pending maintenance',
                value: '${d.pendingMaintenance}',
                icon: Icons.build_circle_outlined,
                tint: Brand.warning,
                onTap: () => _tab(context, 4),
              ),
            ],
          ),
          if (d.pendingRequests.isNotEmpty) ...<Widget>[
            SectionHeader('Needs your attention', action: 'See all', onAction: () => _tab(context, 4)),
            MenuGroup(
              children: <Widget>[
                for (final r in d.pendingRequests.take(4))
                  MenuTile(
                    icon: Icons.build_circle_outlined,
                    tint: Brand.warning,
                    title: r.title,
                    subtitle: <String>[
                      if ((r.unitNumber ?? '').isNotEmpty) 'Unit ${r.unitNumber}',
                      if ((r.propertyTitle ?? '').isNotEmpty) r.propertyTitle!,
                      if ((r.tenantName ?? '').isNotEmpty) r.tenantName!,
                    ].join(', '),
                    onTap: () => _tab(context, 4),
                  ),
              ],
            ),
          ],
          if (d.occupancy.isNotEmpty) ...<Widget>[
            const SectionHeader('Your properties'),
            for (final o in d.occupancy)
              PCard(
                margin: const EdgeInsets.only(bottom: 10),
                onTap: o.id.isEmpty ? null : () => _page(context, o.title, PropertyDetailPage(propertyId: o.id)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: Text(o.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                        Text('${o.occupiedUnits} of ${o.totalUnits} units', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                        if (o.id.isNotEmpty) Icon(Icons.chevron_right_rounded, color: context.mutedColor),
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
          const SectionHeader('Manage'),
          MenuGroup(
            children: <Widget>[
              MenuTile(
                icon: Icons.engineering_outlined,
                title: 'Work orders',
                subtitle: 'Jobs given to technicians and vendors',
                onTap: () => _page(context, 'Work orders', const WorkOrdersTab()),
              ),
              MenuTile(
                icon: Icons.fact_check_outlined,
                title: 'Inspections',
                subtitle: 'Schedule and record inspections',
                onTap: () => _page(context, 'Inspections', const InspectionsTab()),
              ),
              MenuTile(
                icon: Icons.campaign_outlined,
                title: 'Notices',
                subtitle: 'Send reminders and announcements to tenants',
                onTap: () => _page(context, 'Notices', const NoticesTab()),
              ),
              MenuTile(
                icon: Icons.bar_chart_rounded,
                title: 'Reports',
                subtitle: 'Rent collected, arrears and occupancy',
                onTap: () => _page(context, 'Reports', const ReportsTab()),
              ),
              MenuTile(
                icon: Icons.block_outlined,
                title: 'Blacklist',
                subtitle: 'Tenants you would not rent to again',
                onTap: () => _page(context, 'Blacklist', const BlacklistTab()),
              ),
              MenuTile(
                icon: Icons.badge_outlined,
                title: 'Owner profile',
                subtitle: 'Your details and bank details for payouts',
                onTap: () => _page(context, 'Owner profile', const OwnerProfileTab()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
