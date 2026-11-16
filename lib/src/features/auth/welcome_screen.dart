import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/branding/premisave_logo.dart';
import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/palette.dart';

/// First screen for signed-out visitors.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    return Scaffold(
      backgroundColor: context.pal.hero,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const PremisaveLogo(width: 240, onDark: true, animate: false),
                  SizedBox(height: wide ? 64 : 44),
                  const Text(
                    'Rent, host and manage property in one place.',
                    style: TextStyle(fontSize: 38, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -1.4, color: Brand.cream),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Premisave connects verified home owners with people looking for a place to live, wherever you are.',
                    style: TextStyle(fontSize: 16, height: 1.55, color: Brand.cream.op(0.75)),
                  ),
                  const SizedBox(height: 36),
                  PButton(label: 'Create an account', kind: PButtonKind.accent, expand: true, onPressed: () => context.go('/signup')),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => context.go('/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Brand.cream,
                        side: BorderSide(color: Brand.cream.op(0.45), width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontFamily: Brand.fontFamily, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      child: const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: <Widget>[
                      Icon(Icons.lock_outline_rounded, size: 16, color: Brand.cream.op(0.6)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your sessions and devices are protected and visible to you.',
                          style: TextStyle(fontSize: 12.5, color: Brand.cream.op(0.6)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
