import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../state/session_controller.dart';
import 'auth_scaffold.dart';

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
  String? _social;
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

  Future<void> _socialSignIn(String provider) async {
    setState(() {
      _social = provider;
      _error = null;
    });
    try {
      final controller = ref.read(sessionProvider.notifier);
      if (provider == 'google') {
        await controller.signInWithGoogle();
      } else {
        await controller.signInWithFacebook();
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _social = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = ref.watch(sessionProvider.select((s) => s.notice));
    final busy = _busy || _social != null;

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
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  Expanded(child: Divider(color: context.borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with', style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                  ),
                  Expanded(child: Divider(color: context.borderColor)),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SocialButton(
                      label: 'Google',
                      glyph: 'G',
                      glyphColor: const Color(0xFFDB4437),
                      loading: _social == 'google',
                      onPressed: busy ? null : () => _socialSignIn('google'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SocialButton(
                      label: 'Facebook',
                      glyph: 'f',
                      glyphColor: const Color(0xFF1877F2),
                      loading: _social == 'facebook',
                      onPressed: busy ? null : () => _socialSignIn('facebook'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.glyph,
    required this.glyphColor,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final String glyph;
  final Color glyphColor;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.borderColor, width: 1.4),
          backgroundColor: context.surfaceColor,
          foregroundColor: context.inkColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(glyph, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: glyphColor)),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
      ),
    );
  }
}
