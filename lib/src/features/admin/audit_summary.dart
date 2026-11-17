import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/audit_labels.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/security_models.dart';
import '../../state/data_providers.dart';
import '../security/security_widgets.dart';

/// What happened on the platform in the last day: totals, problems to look at, and the most common events.
/// Tapping a figure opens the audit trail on the matching events.
class AuditSummaryStrip extends ConsumerWidget {
  const AuditSummaryStrip({super.key, this.hours = 24});

  final int hours;

  String get _period => hours == 24 ? 'the last 24 hours' : 'the last ${plural(hours, 'hour')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(auditSummaryProvider(hours));
    return value.when(
      loading: () => const SkeletonList(count: 2, height: 92, shrink: true, padding: EdgeInsets.symmetric(vertical: 6)),
      error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(auditSummaryProvider(hours))),
      data: (s) => _Body(summary: s, period: _period),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.summary, required this.period});

  final AuditSummary summary;
  final String period;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final attention = s.warning + s.critical;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ResponsiveWrap(
          minItemWidth: 150,
          maxColumns: 4,
          children: <Widget>[
            StatTile(
              label: 'Events',
              value: '${s.total}',
              icon: Icons.fact_check_outlined,
              caption: attention == 0 ? 'Nothing needs attention' : '$attention need attention',
              tint: attention == 0 ? Brand.info : Brand.warning,
              onTap: () => context.push('/admin/audit'),
            ),
            StatTile(
              label: 'Failed sign ins',
              value: '${s.failedSignIns}',
              icon: Icons.block_rounded,
              caption: 'Of ${plural(s.signIns + s.failedSignIns, 'attempt')}',
              tint: s.failedSignIns == 0 ? Brand.success : Brand.danger,
              onTap: () => context.push('/admin/audit?type=SIGN_IN_FAILED'),
            ),
            StatTile(
              label: 'Accounts locked',
              value: '${s.lockouts}',
              icon: Icons.lock_outline_rounded,
              caption: s.lockouts == 0 ? 'None locked' : 'After repeated failures',
              tint: s.lockouts == 0 ? Brand.success : Brand.danger,
              onTap: () => context.push('/admin/audit?type=ACCOUNT_LOCKED'),
            ),
            StatTile(
              label: 'Staff changes',
              value: '${s.adminChanges}',
              icon: Icons.admin_panel_settings_outlined,
              caption: 'Accounts, roles and settings',
              tint: Brand.info,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '${plural(s.people, 'person', 'people')} and ${plural(s.addresses, 'address', 'addresses')} in $period.',
          style: TextStyle(fontSize: 12.5, color: context.mutedColor),
        ),
        if (s.topTypes.isNotEmpty) ...<Widget>[
          const SectionHeader('Most common events'),
          MenuGroup(
            children: <Widget>[
              for (final t in s.topTypes.take(5))
                MenuTile(
                  icon: eventIcon(t.key),
                  title: auditLabel(t.key).title,
                  subtitle: auditLabel(t.key).category,
                  trailing: Text('${t.count}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  onTap: () => context.push('/admin/audit?type=${Uri.encodeComponent(t.key)}'),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
