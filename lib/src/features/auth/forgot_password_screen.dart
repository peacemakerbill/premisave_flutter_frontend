import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../state/providers.dart';
import 'auth_scaffold.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _done;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final msg = await ref.read(authRepositoryProvider).forgotPassword(_email.text);
      if (mounted) setState(() => _done = msg);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done != null) {
      return AuthScaffold(
        title: 'Check your email',
        child: AuthResultView(
          icon: Icons.mark_email_read_outlined,
          title: 'Reset link sent',
          message: _done!,
          actions: <Widget>[
            PButton(label: 'I have a reset code', expand: true, onPressed: () => context.go('/reset-password')),
            PButton(label: 'Back to sign in', kind: PButtonKind.outline, expand: true, onPressed: () => context.go('/login')),
          ],
        ),
      );
    }
    return AuthScaffold(
      title: 'Forgot your password?',
      subtitle: 'Enter your email and we will send a link to choose a new one.',
      footer: AuthFooterLink(prompt: 'Remembered it?', action: 'Sign in', onTap: () => context.go('/login')),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_error != null) ...<Widget>[InlineMessage(_error!, kind: MessageKind.error), const SizedBox(height: 16)],
            PTextField(
              label: 'Email',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              validator: Validators.email,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            PButton(label: 'Send reset link', expand: true, loading: _busy, onPressed: _busy ? null : _submit),
          ],
        ),
      ),
    );
  }
}
