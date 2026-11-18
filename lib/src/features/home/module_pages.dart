import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../c2b/name_lookup_screen.dart';
import '../developer/developer_portal_screen.dart';
import '../info/about_content.dart';
import '../info/contact_content.dart';
import '../listings/bookings_screen.dart';
import '../listings/owner_listings_screen.dart';
import '../listings/wishlists_screen.dart';
import '../property_mgmt/owner_property_screen.dart';
import '../property_mgmt/tenancy_screen.dart';
import '../wallet/transactions_screen.dart';
import '../wallet/wallet_screen.dart';

enum AppModule {
  bookings('Bookings'),
  payments('Payments'),
  transactions('Transactions'),
  wishlists('Wishlists'),
  properties('Property management'),
  listings('My listings'),
  tenancy('My tenancy'),
  developer('Developer portal'),
  lookup('M-Pesa name lookup'),
  about('About Premisave'),
  contact('Contact us');

  const AppModule(this.title);

  final String title;
}

/// Shows one of the module screens with a back arrow. Bookings, payments, transactions, wishlists, property
/// management and the developer portal read live data from their own services (see `state/providers.dart`).
class ModulePage extends StatelessWidget {
  const ModulePage({super.key, required this.module});

  final AppModule module;

  Widget _content() {
    switch (module) {
      case AppModule.bookings:
        return const BookingsScreen();
      case AppModule.payments:
        return const WalletScreen();
      case AppModule.transactions:
        return const TransactionsScreen();
      case AppModule.wishlists:
        return const WishlistsScreen();
      case AppModule.properties:
        return const OwnerPropertyScreen();
      case AppModule.listings:
        return const OwnerListingsScreen();
      case AppModule.tenancy:
        return const TenancyScreen();
      case AppModule.developer:
        return const DeveloperPortalScreen();
      case AppModule.lookup:
        return const NameLookupScreen();
      case AppModule.about:
        return const AboutContent();
      case AppModule.contact:
        return const ContactContent();
    }
  }

  @override
  Widget build(BuildContext context) => SubPage(title: module.title, body: _content());
}
