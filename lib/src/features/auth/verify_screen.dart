import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/widgets/widgets.dart';
import '../../state/providers.dart';
import 'auth_scaffold.dart';

/// Opened from the activation email: /verify?token=... (or /verify/<token>).
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key, this.token});

  final String? token;

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _manual = TextEditingController();
  bool _busy = false;
  String? _success;
  String? _error;

  @override
  void initState() {
    super.initState();
    final t = widget.token;
    if (t != null && t.isNotEmpty) {
      _busy = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _verify(t));
    }
  }

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _verify(String token) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final msg = await ref.read(authRepositoryProvider).verify(token.trim());
      if (mounted) setState(() => _success = msg);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_busy) {
      body = const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: LoadingState(label: 'Verifying your account'));
    } else if (_success != null) {
      body = AuthResultView(
        icon: Icons.verified_rounded,
        title: 'You are verified',
        message: _success!,
        actions: <Widget>[PButton(label: 'Sign in', expand: true, onPressed: () => context.go('/login'))],
      );
    } else if (_error != null) {
      body = AuthResultView(
        success: false,
        icon: Icons.link_off_rounded,
        title: 'That link did not work',
        message: '$_error You can ask for a new activation email.',
        actions: <Widget>[
          PButton(label: 'Send a new email', expand: true, onPressed: () => context.go('/resend-activation')),
          PButton(label: 'Back to sign in', kind: PButtonKind.outline, expand: true, onPressed: () => context.go('/login')),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PTextField(label: 'Verification code from your email', controller: _manual, prefixIcon: Icons.pin_outlined),
          const SizedBox(height: 18),
          PButton(
            label: 'Verify account',
            onPressed: () {
              if (_manual.text.trim().isNotEmpty) _verify(_manual.text);
            },
          ),
        ],
      );
    }
    return AuthScaffold(title: 'Verify your account', child: body);
  }
}
