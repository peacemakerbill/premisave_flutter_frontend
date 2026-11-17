import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../bookings/bookings_content.dart';
import '../info/about_content.dart';
import '../info/contact_content.dart';
import '../payments/payments_content.dart';
import '../transactions/transactions_content.dart';
import '../wishlists/wishlists_content.dart';

enum AppModule {
  bookings('Bookings'),
  payments('Payments'),
  transactions('Transactions'),
  wishlists('Wishlists'),
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
        return const BookingsContent();
      case AppModule.payments:
        return const PaymentsContent();
      case AppModule.transactions:
        return const TransactionsContent();
      case AppModule.wishlists:
        return const WishlistsContent();
      case AppModule.about:
        return const AboutContent();
      case AppModule.contact:
        return const ContactContent();
    }
  }

  @override
  Widget build(BuildContext context) => SubPage(title: module.title, body: _content());
}
