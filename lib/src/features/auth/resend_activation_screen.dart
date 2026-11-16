import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../state/providers.dart';
import 'auth_scaffold.dart';
import 'resend_activation_button.dart';

class ResendActivationScreen extends ConsumerStatefulWidget {
  const ResendActivationScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<ResendActivationScreen> createState() => _ResendActivationScreenState();
}

class _ResendActivationScreenState extends ConsumerState<ResendActivationScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(text: widget.email);
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
      final msg = await ref.read(authRepositoryProvider).resendActivation(_email.text);
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
          title: 'On its way',
          message: _done!,
          actions: <Widget>[
            PButton(label: 'Back to sign in', expand: true, onPressed: () => context.go('/login')),
            ResendActivationButton(email: _email.text.trim(), label: 'Send it again'),
          ],
        ),
      );
    }
    return AuthScaffold(
      title: 'Resend activation email',
      subtitle: 'Enter the email you signed up with and we will send a new activation link.',
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
            PButton(label: 'Send email', expand: true, loading: _busy, onPressed: _busy ? null : _submit),
          ],
        ),
      ),
    );
  }
}
