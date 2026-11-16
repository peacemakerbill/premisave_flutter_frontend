import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import 'appearance_picker.dart';

/// Appearance, plus the connection details people are asked for when reporting a problem.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Appearance',
      fallbackRoute: '/account',
      body: PageBody(
        maxWidth: 960,
        children: <Widget>[
          const AppearancePicker(),
          const SectionHeader('Connection'),
          PCard(
            child: Column(
              children: <Widget>[
                InfoRow('Server', AppConfig.baseUrl, icon: Icons.dns_outlined),
                const InfoRow('Platform', AppConfig.clientPlatform, icon: Icons.phone_iphone_rounded),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Change the server with --dart-define-from-file=config/env/<name>.json when you run or build the app.',
            style: TextStyle(fontSize: 12, color: context.mutedColor),
          ),
        ],
      ),
    );
  }
}
