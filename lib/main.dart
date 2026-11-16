import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'src/core/theme/app_theme.dart';
import 'src/core/widgets/theme_reveal.dart';
import 'src/data/social_auth_service.dart';
import 'src/router/app_router.dart';
import 'src/state/appearance_controller.dart';
import 'src/state/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Restore the saved look and session before the first frame so the app never flashes the wrong theme
  // and the router starts on the right screen.
  final container = ProviderContainer();
  await container.read(appearanceProvider.notifier).load();
  await SocialAuthService.init();
  await container.read(sessionProvider.notifier).bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const PremisaveApp(),
    ),
  );
}

class PremisaveApp extends ConsumerStatefulWidget {
  const PremisaveApp({super.key});

  @override
  ConsumerState<PremisaveApp> createState() => _PremisaveAppState();
}

class _PremisaveAppState extends ConsumerState<PremisaveApp> {
  final GlobalKey<ThemeRevealState> _reveal = GlobalKey<ThemeRevealState>();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  /// T steps to the next theme and Shift+T to the previous one, as in the console.
  /// Ignored while typing in a field or when another modifier key is held.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.keyT) return false;
    final keys = HardwareKeyboard.instance;
    if (keys.isControlPressed || keys.isMetaPressed || keys.isAltPressed) return false;
    final focus = FocusManager.instance.primaryFocus?.context;
    if (focus != null && (focus.widget is EditableText || focus.findAncestorWidgetOfExactType<EditableText>() != null)) {
      return false;
    }
    final step = keys.isShiftPressed ? -1 : 1;
    final notifier = ref.read(appearanceProvider.notifier);
    final reveal = _reveal.currentState;
    if (reveal != null) {
      reveal.run(null, () => notifier.cycleTheme(step));
    } else {
      notifier.cycleTheme(step);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final look = ref.watch(appearanceProvider);
    final palette = look.palette;
    return MaterialApp.router(
      title: 'Premisave',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forAppearance(look, device: Brightness.light),
      darkTheme: AppTheme.forAppearance(look, device: Brightness.dark),
      themeMode: palette == null ? ThemeMode.system : (palette.dark ? ThemeMode.dark : ThemeMode.light),
      themeAnimationDuration: Duration.zero,
      routerConfig: router,
      builder: (context, child) => ThemeReveal(key: _reveal, child: child ?? const SizedBox.shrink()),
    );
  }
}
