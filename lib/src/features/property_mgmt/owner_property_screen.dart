import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/property_models.dart';
import '../../state/service_providers.dart';
/// The owner dashboard: totals, revenue and occupancy by property. Talks to the property management service.
class OwnerOverviewTab extends ConsumerWidget {
  const OwnerOverviewTab({super.key});

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
