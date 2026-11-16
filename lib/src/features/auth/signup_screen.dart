import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../state/session_controller.dart';
import 'auth_scaffold.dart';
import 'resend_activation_button.dart';
import 'password_strength_meter.dart';
import '../places/country_field.dart';
import '../places/phone_field.dart';
import 'social_buttons.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _middle = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _country = TextEditingController();
  String? _countryCode;
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _busy = false;
  bool _socialBusy = false;
  bool _agreed = false;
  String? _error;
  String? _info;
  Map<String, String> _fieldErrors = <String, String>{};
  String? _acceptedMessage;

  @override
  void dispose() {
    for (final c in <TextEditingController>[_first, _middle, _last, _email, _phone, _country, _username, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agreed) {
      setState(() => _error = 'Please accept the terms and privacy notice to continue.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
      _fieldErrors = <String, String>{};
    });
    try {
      final result = await ref.read(sessionProvider.notifier).signUp(
            firstName: _first.text,
            middleName: _middle.text.trim().isEmpty ? null : _middle.text.trim(),
            lastName: _last.text,
            email: _email.text,
            phoneNumber: _phone.text,
            password: _password.text,
            username: _username.text.trim().isEmpty ? null : _username.text.trim(),
            country: _country.text.trim().isEmpty ? null : _country.text.trim(),
          );
      if (!result.signedIn && mounted) {
        setState(() => _acceptedMessage = result.message ??
            'We sent an email to ${_email.text.trim()}. Open it to activate your account.');
      }
    } catch (e) {
      final err = ApiException.from(e);
      if (mounted) {
        setState(() {
          _error = err.fieldErrors.isEmpty ? err.message : 'Please fix the highlighted fields.';
          _fieldErrors = err.fieldErrors;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_acceptedMessage != null) {
      return AuthScaffold(
        title: 'Check your email',
        child: AuthResultView(
          icon: Icons.mark_email_read_outlined,
          title: 'Almost there',
          message: _acceptedMessage!,
          actions: <Widget>[
            PButton(label: 'Go to sign in', expand: true, onPressed: () => context.go('/login')),
            ResendActivationButton(email: _email.text.trim()),
          ],
        ),
      );
    }

    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'It takes a minute. You can become a home owner later.',
      footer: AuthFooterLink(prompt: 'Already have an account?', action: 'Sign in', onTap: () => context.go('/login')),
      child: AutofillGroup(
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (_info != null) ...<Widget>[
                InlineMessage(_info!),
                const SizedBox(height: 16),
              ],
              if (_error != null) ...<Widget>[
                InlineMessage(_error!, kind: MessageKind.error),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: PTextField(
                      label: 'First name',
                      controller: _first,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.givenName],
                      validator: (v) => Validators.required(v, 'First name'),
                      errorText: _fieldErrors['firstName'],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PTextField(
                      label: 'Last name',
                      controller: _last,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.familyName],
                      validator: (v) => Validators.required(v, 'Last name'),
                      errorText: _fieldErrors['lastName'],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PTextField(
                label: 'Middle name',
                controller: _middle,
                optional: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              PTextField(
                label: 'Email',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.email],
                prefixIcon: Icons.mail_outline_rounded,
                validator: Validators.email,
                errorText: _fieldErrors['email'],
              ),
              const SizedBox(height: 16),
              CountryField(
                controller: _country,
                optional: true,
                onCountry: (c) => setState(() => _countryCode = c?.code),
              ),
              const SizedBox(height: 16),
              PhoneField(
                controller: _phone,
                countryCode: _countryCode,
                autofillHints: const <String>[AutofillHints.telephoneNumber],
                validator: Validators.phone,
                errorText: _fieldErrors['phoneNumber'],
                helper: 'Pick your country code, then type the number.',
              ),
              const SizedBox(height: 16),
              PTextField(
                label: 'Username',
                controller: _username,
                optional: true,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.newUsername],
                prefixIcon: Icons.alternate_email_rounded,
                validator: Validators.username,
                errorText: _fieldErrors['username'],
                helper: 'Leave blank and we will pick one for you.',
              ),
              const SizedBox(height: 16),
              PTextField(
                label: 'Password',
                controller: _password,
                obscure: true,
                textInputAction: TextInputAction.next,
                autofillHints: const <String>[AutofillHints.newPassword],
                prefixIcon: Icons.lock_outline_rounded,
                validator: Validators.password,
                errorText: _fieldErrors['password'],
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
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _agreed = !_agreed),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Checkbox(value: _agreed, onChanged: (v) => setState(() => _agreed = v ?? false)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'I agree to the Terms of Service and the Privacy Notice.',
                            style: TextStyle(fontSize: 13, height: 1.4, color: context.mutedColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PButton(label: 'Create account', expand: true, loading: _busy, onPressed: (_busy || _socialBusy) ? null : _submit),
              SocialAuthButtons(
                disabled: _busy,
                onBusyChanged: (b) {
                  if (mounted) setState(() => _socialBusy = b);
                },
                onError: (m) {
                  if (mounted) setState(() => _error = m);
                },
                onNotice: (m) {
                  if (mounted) {
                    setState(() {
                      _info = m;
                      if (m != null) _error = null;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
