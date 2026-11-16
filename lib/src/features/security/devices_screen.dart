import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/security_models.dart';
import '../../state/data_providers.dart';
import 'security_widgets.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);
    return SubPage(
      title: 'Devices',
      fallbackRoute: '/account/security',
      body: AsyncBody<List<DeviceView>>(
        value: devices,
        onRetry: () => ref.invalidate(devicesProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyState(icon: Icons.devices_rounded, title: 'No devices yet', message: 'Devices you sign in from appear here.');
          }
          return PageBody(
            maxWidth: 760,
            onRefresh: () async => ref.invalidate(devicesProvider),
            children: <Widget>[
              const InlineMessage('Trusted devices skip extra checks. Only trust devices that belong to you.'),
              const SizedBox(height: 14),
              for (final d in items) ...<Widget>[
                PCard(
                  onTap: () => context.push('/account/security/devices/${d.id}'),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: Brand.info.op(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(deviceIcon(d.label, d.deviceType), color: Brand.info),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(d.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: <Widget>[
                                if (d.current) const StatusPill('This device', color: Brand.success, dense: true),
                                if (d.trusted) const StatusPill('Trusted', color: Brand.info, dense: true, icon: Icons.verified_user_outlined),
                                if (d.activeSessions > 0) StatusPill(plural(d.activeSessions, 'active session'), color: Brand.warning, dense: true),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${d.place} · last seen ${timeAgo(d.lastSeenAt)}', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: context.mutedColor),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}
