import 'package:flutter/material.dart';

import '../../core/widgets/widgets.dart';
import '../info/about_content.dart';
import '../info/contact_content.dart';

/// The information pages that open from the Home screen. Everything with data has its own hub: wallet, bookings,
/// listings, property management, tenancy, finance and the developer portal.
enum AppModule {
  about('About Premisave'),
  contact('Contact us');

  const AppModule(this.title);

  final String title;
}

/// Shows one of the information pages with a back arrow.
class ModulePage extends StatelessWidget {
  const ModulePage({super.key, required this.module});

  final AppModule module;

  Widget _content() {
    switch (module) {
      case AppModule.about:
        return const AboutContent();
      case AppModule.contact:
        return const ContactContent();
    }
  }

  @override
  Widget build(BuildContext context) => SubPage(title: module.title, body: _content());
}
