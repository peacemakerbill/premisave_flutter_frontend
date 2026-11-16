import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/branding/premisave_logo.dart';
import '../../state/session_controller.dart';

/// Plays the animated logo, then sends the person to the right place.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: PremisaveSplash(
        onFinished: () {
          if (!context.mounted) return;
          final signedIn = ref.read(sessionProvider).isSignedIn;
          context.go(signedIn ? '/home' : '/welcome');
        },
      ),
    );
  }
}
