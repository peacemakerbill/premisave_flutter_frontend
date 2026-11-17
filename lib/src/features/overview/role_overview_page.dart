import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../roles/role.dart';
import '../../roles/role_registry.dart';
import '../../state/session_controller.dart';
import 'admin/admin_overview.dart';
import 'client/client_overview.dart';
import 'finance/finance_overview.dart';
import 'home_owner/home_owner_overview.dart';
import 'operations/operations_overview.dart';
import 'support/support_overview.dart';

/// The overview for the signed in role. This is the only place that decides which dashboard a role gets.
/// To add a role, build its overview in its own folder here and add one case below.
class RoleOverviewPage extends ConsumerWidget {
  const RoleOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(sessionProvider.select((s) => s.role));
    return SubPage(title: role.overviewTitle, body: _bodyFor(role));
  }

  Widget _bodyFor(Role role) {
    switch (role) {
      case Role.client:
        return const ClientOverview();
      case Role.homeOwner:
        return const HomeOwnerOverview();
      case Role.finance:
        return const FinanceOverview();
      case Role.operations:
        return const OperationsOverview();
      case Role.support:
        return const SupportOverview();
      case Role.admin:
        return const AdminOverview();
    }
  }
}
