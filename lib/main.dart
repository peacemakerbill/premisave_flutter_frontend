import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'src/app.dart';
import 'src/providers/auth/auth_provider.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await container.read(authProvider.notifier).checkAuthStatus();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: PremisaveApp(scaffoldMessengerKey: scaffoldMessengerKey),
    ),
  );
}