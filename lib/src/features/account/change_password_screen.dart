import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../state/providers.dart';
import '../auth/password_strength_meter.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
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
      final msg = await ref.read(profileRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
            confirmPassword: _confirm.text,
          );
      if (!mounted) return;
      showToast(context, msg);
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/account');
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubPage(
      title: 'Change password',
      fallbackRoute: '/account',
      body: PageBody(
        maxWidth: 520,
        children: <Widget>[
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const InlineMessage('Use a password you do not use anywhere else. You will stay signed in on this device.'),
                const SizedBox(height: 18),
                if (_error != null) ...<Widget>[InlineMessage(_error!, kind: MessageKind.error), const SizedBox(height: 16)],
                PTextField(
                  label: 'Current password',
                  controller: _current,
                  obscure: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) => Validators.required(v, 'Current password'),
                ),
                const SizedBox(height: 16),
                PTextField(
                  label: 'New password',
                  controller: _new,
                  obscure: true,
                  prefixIcon: Icons.lock_reset_rounded,
                  validator: Validators.password,
                  onChanged: (_) => setState(() {}),
                ),
                PasswordStrengthMeter(password: _new.text),
                const SizedBox(height: 16),
                PTextField(
                  label: 'Confirm new password',
                  controller: _confirm,
                  obscure: true,
                  prefixIcon: Icons.lock_reset_rounded,
                  validator: Validators.matches(() => _new.text),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 22),
                PButton(label: 'Update password', expand: true, loading: _busy, onPressed: _busy ? null : _submit),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
