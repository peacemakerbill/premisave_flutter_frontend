import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../state/providers.dart';
import 'auth_scaffold.dart';
import 'password_strength_meter.dart';

enum TokenPasswordMode { reset, adminInvitation }

/// Choose a new password using a one-time token from an email.
/// Used for password reset and for activating a pre-provisioned administrator account.
class TokenPasswordScreen extends ConsumerStatefulWidget {
  const TokenPasswordScreen({super.key, required this.mode, this.token});

  final TokenPasswordMode mode;
  final String? token;

  @override
  ConsumerState<TokenPasswordScreen> createState() => _TokenPasswordScreenState();
}

class _TokenPasswordScreenState extends ConsumerState<TokenPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _token = TextEditingController(text: widget.token);
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _done;

  bool get _isInvite => widget.mode == TokenPasswordMode.adminInvitation;

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final msg = _isInvite
          ? await repo.acceptAdminInvitation(token: _token.text, newPassword: _password.text, confirmPassword: _confirm.text)
          : await repo.resetPassword(token: _token.text, newPassword: _password.text, confirmPassword: _confirm.text);
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
        title: _isInvite ? 'Account activated' : 'Password updated',
        child: AuthResultView(
          icon: Icons.check_circle_outline_rounded,
          title: _isInvite ? 'Welcome aboard' : 'All set',
          message: _done!,
          actions: <Widget>[PButton(label: 'Sign in', expand: true, onPressed: () => context.go('/login'))],
        ),
      );
    }

    final hasToken = (widget.token ?? '').isNotEmpty;
    return AuthScaffold(
      title: _isInvite ? 'Activate your administrator account' : 'Choose a new password',
      subtitle: _isInvite
          ? 'Set the password you will use to sign in. The link works once.'
          : 'Pick a password you have not used before.',
      footer: AuthFooterLink(prompt: 'Back to', action: 'Sign in', onTap: () => context.go('/login')),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_error != null) ...<Widget>[InlineMessage(_error!, kind: MessageKind.error), const SizedBox(height: 16)],
            if (!hasToken) ...<Widget>[
              PTextField(
                label: _isInvite ? 'Invitation code' : 'Reset code',
                controller: _token,
                prefixIcon: Icons.pin_outlined,
                validator: (v) => Validators.required(v, 'The code from your email'),
              ),
              const SizedBox(height: 16),
            ],
            PTextField(
              label: 'New password',
              controller: _password,
              obscure: true,
              textInputAction: TextInputAction.next,
              prefixIcon: Icons.lock_outline_rounded,
              validator: Validators.password,
              onChanged: (_) => setState(() {}),
            ),
            PasswordStrengthMeter(password: _password.text),
            const SizedBox(height: 16),
            PTextField(
              label: 'Confirm password',
              controller: _confirm,
              obscure: true,
              textInputAction: TextInputAction.done,
              prefixIcon: Icons.lock_outline_rounded,
              validator: Validators.matches(() => _password.text),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 22),
            PButton(
              label: _isInvite ? 'Activate account' : 'Update password',
              expand: true,
              loading: _busy,
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
