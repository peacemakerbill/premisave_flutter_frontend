import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/widgets.dart';
import '../../data/models/user_model.dart';
import '../../state/session_controller.dart';
import '../modules/client/client_bookings_content.dart';
import '../modules/client/client_dashboard_content.dart';
import '../modules/client/client_messages_content.dart';
import '../modules/client/client_payments_content.dart';
import '../modules/client/client_transactions_content.dart';
import '../modules/client/client_wishlists_content.dart';
import '../modules/finance/finance_overview.dart';
import '../modules/home_owner/home_owner_overview.dart';
import '../modules/operations/operations_overview.dart';
import '../modules/shared/about_content.dart';
import '../modules/shared/contact_content.dart';
import '../modules/support/support_overview.dart';

enum AppModule {
  bookings('Bookings'),
  payments('Payments'),
  transactions('Transactions'),
  wishlists('Wishlists'),
  messages('Messages'),
  about('About Premisave'),
  contact('Contact us');

  const AppModule(this.title);

  final String title;
}

/// Shows one of the existing module screens with a back arrow.
/// These screens still use sample data: they belong to services other than the auth service.
class ModulePage extends StatelessWidget {
  const ModulePage({super.key, required this.module});

  final AppModule module;

  Widget _content() {
    switch (module) {
      case AppModule.bookings:
        return const ClientBookingsContent();
      case AppModule.payments:
        return const ClientPaymentsContent();
      case AppModule.transactions:
        return const ClientTransactionsContent();
      case AppModule.wishlists:
        return const ClientWishlistsContent();
      case AppModule.messages:
        return const ClientMessagesContent();
      case AppModule.about:
        return const AboutContent();
      case AppModule.contact:
        return const ContactContent();
    }
  }

  @override
  Widget build(BuildContext context) => SubPage(title: module.title, body: _content());
}

/// The role's overview dashboard (sample data until the matching services exist).
class RoleOverviewPage extends ConsumerWidget {
  const RoleOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(sessionProvider.select((s) => s.role));
    Widget body;
    switch (role) {
      case Role.client:
        body = const ClientDashboardContent();
        break;
      case Role.homeOwner:
        body = const HomeOwnerDashboardContent();
        break;
      case Role.finance:
        body = const FinanceDashboardContent();
        break;
      case Role.operations:
        body = const OperationsDashboardContent();
        break;
      case Role.support:
        body = const SupportDashboardContent();
        break;
      case Role.admin:
        body = const EmptyState(
          icon: Icons.dashboard_outlined,
          title: 'No overview yet',
          message: 'Use the Applications and Users tabs to manage the platform.',
        );
        break;
    }
    return SubPage(title: '${role.label} overview', body: body);
  }
}
