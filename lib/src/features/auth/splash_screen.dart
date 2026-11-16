import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/branding/premisave_logo.dart';
import '../../core/theme/palette.dart';
import '../../state/session_controller.dart';

/// Plays the animated logo, then sends the person to the right place.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.pal.hero,
      body: PremisaveSplash(
        background: context.pal.hero,
        skyline: Color.alphaBlend(Colors.white.withValues(alpha: 0.08), context.pal.hero),
        onFinished: () {
          if (!context.mounted) return;
          final signedIn = ref.read(sessionProvider).isSignedIn;
          context.go(signedIn ? '/home' : '/welcome');
        },
      ),
    );
  }
}
