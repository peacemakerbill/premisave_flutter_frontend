import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/widgets/widgets.dart';
import '../../state/theme_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return SubPage(
      title: 'Appearance',
      fallbackRoute: '/account',
      body: PageBody(
        maxWidth: 560,
        children: <Widget>[
          const SectionHeader('Theme', padding: EdgeInsets.only(top: 8, bottom: 12)),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Light')),
                ButtonSegment<ThemeMode>(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Auto')),
                ButtonSegment<ThemeMode>(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Dark')),
              ],
              selected: <ThemeMode>{mode},
              onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ),
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
            'Change the server with --dart-define=BASE_URL=https://your-server when you run or build the app.',
            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
