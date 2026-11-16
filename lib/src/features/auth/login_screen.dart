import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../state/session_controller.dart';
import 'auth_scaffold.dart';
import 'social_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _socialBusy = false;
  String? _error;
  bool _needsVerification = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _needsVerification = false;
    });
    try {
      await ref.read(sessionProvider.notifier).signIn(email: _email.text, password: _password.text);
      // The router sends a signed-in user to the home screen.
    } catch (e) {
      final err = ApiException.from(e);
      final m = err.message.toLowerCase();
      if (mounted) {
        setState(() {
          _error = err.message;
          _needsVerification = m.contains('verif') || m.contains('activat');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(sessionProvider.select((s) => s.notice));
    final busy = _busy || _socialBusy;

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue to Premisave.',
      footer: AuthFooterLink(
        prompt: 'New to Premisave?',
        action: 'Create an account',
        onTap: () => context.go('/signup'),
      ),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (notice != null) ...<Widget>[
                InlineMessage(notice),
                const SizedBox(height: 16),
              ],
              if (_error != null) ...<Widget>[
                InlineMessage(
                  _error!,
                  kind: MessageKind.error,
                  actionLabel: _needsVerification ? 'Resend the activation email' : null,
                  onAction: _needsVerification
                      ? () => context.go('/resend-activation?email=${Uri.encodeQueryComponent(_email.text.trim())}')
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              PTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.email],
                prefixIcon: Icons.mail_outline_rounded,
                validator: Validators.email,
                enabled: !busy,
              ),
              const SizedBox(height: 16),
              PTextField(
                label: 'Password',
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.done,
                autofillHints: const <String>[AutofillHints.password],
                prefixIcon: Icons.lock_outline_rounded,
                validator: (v) => Validators.required(v, 'Password'),
                onSubmitted: (_) => _signIn(),
                enabled: !busy,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: busy ? null : () => context.go('/forgot-password'),
                  child: const Text('Forgot password?', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 4),
              PButton(label: 'Sign in', expand: true, loading: _busy, onPressed: busy ? null : _signIn),
              SocialAuthButtons(
                disabled: _busy,
                onBusyChanged: (b) {
                  if (mounted) setState(() => _socialBusy = b);
                },
                onError: (m) {
                  if (mounted) setState(() => _error = m);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
