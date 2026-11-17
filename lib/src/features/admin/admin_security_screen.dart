import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';
import '../../state/data_providers.dart';
import 'audit_summary.dart';

/// Administrators: security of the whole platform. A summary of the last day, then the audit trail with the record of
/// sign-ins, account and role changes, applications and settings.
class AdminSecurityScreen extends ConsumerWidget {
  const AdminSecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: PageBody(
        onRefresh: () async => ref.invalidate(auditSummaryProvider(24)),
        children: <Widget>[
          const PageTitle('Security'),
          const SectionHeader('Last 24 hours', padding: EdgeInsets.only(top: 6, bottom: 12)),
          const AuditSummaryStrip(),
          const SectionHeader('Activity'),
          MenuGroup(
            children: <Widget>[
              MenuTile(
                icon: Icons.fact_check_outlined,
                title: 'Audit trail',
                subtitle: 'Who did what, from which device and address: sign-ins, account and role changes, applications and settings',
                onTap: () => context.push('/admin/audit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
