import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/widgets.dart';

/// Administrators: security of the whole platform. For now the audit trail, the record of sign-ins, password changes,
/// role changes and other security events, which can be filtered by kind.
class AdminSecurityScreen extends StatelessWidget {
  const AdminSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: PageBody(
        children: <Widget>[
          const PageTitle('Security'),
          const SectionHeader('Activity'),
          MenuGroup(
            children: <Widget>[
              MenuTile(
                icon: Icons.fact_check_outlined,
                title: 'Audit trail',
                subtitle: 'Sign-ins, password and role changes, storage changes and other security events across the platform',
                onTap: () => context.push('/admin/audit'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
