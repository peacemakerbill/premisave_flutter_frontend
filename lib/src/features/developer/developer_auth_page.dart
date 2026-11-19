import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/developer_models.dart';
import '../../state/developer_session.dart';
import '../../state/providers.dart';
import '../auth/auth_scaffold.dart';
import '../auth/social_buttons.dart';

/// The sign in page of the developer portal: sign in, create an account, reset a forgotten password or ask for the
/// confirmation email again. Developer accounts are separate from Premisave accounts.
class DeveloperAuthPage extends ConsumerStatefulWidget {
  const DeveloperAuthPage({super.key, this.initialTab = 0});

  /// 0 for sign in, 1 for create an account.
  final int initialTab;

  @override
  ConsumerState<DeveloperAuthPage> createState() => _DeveloperAuthPageState();
}

class _DeveloperAuthPageState extends ConsumerState<DeveloperAuthPage> {
  late int _tab = widget.initialTab;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _company = TextEditingController();
  final _country = TextEditingController(text: 'KE');
  bool _busy = false;
  bool _agree = false;
  String? _error;
  String? _info;
  bool _needsConfirmation = false;
  List<String> _providers = const <String>['google', 'facebook', 'github'];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  @override
  void dispose() {
    for (final c in <TextEditingController>[_email, _password, _first, _last, _company, _country]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Shows the social buttons the developer service has switched on.
  Future<void> _loadProviders() async {
    try {
      final res = await ref.read(developerRepositoryProvider).socialProviders();
      if (mounted && res.providers.isNotEmpty) setState(() => _providers = res.providers);
    } catch (_) {
      // The buttons stay as they are when the list cannot be loaded.
    }
  }

  /// A provider whose address already has an account is not an error: a link went to that address, so say so gently.
  Future<bool> _signInSocial(String provider) async {
    try {
      return await ref.read(developerSessionProvider.notifier).signInSocial(provider);
    } catch (e) {
      final err = ApiException.from(e);
      if (err.next != 'CONFIRM_LINK') rethrow;
      if (mounted) {
        setState(() {
          _error = null;
          _info = err.message;
        });
      }
      return false;
    }
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!email.contains('@') || password.isEmpty) {
      setState(() => _error = 'Enter your email address and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
      _needsConfirmation = false;
    });
    try {
      if (_tab == 1) {
        if (_first.text.trim().isEmpty || _last.text.trim().isEmpty) throw ApiException('Enter your first and last name.');
        if (_country.text.trim().length != 2) throw ApiException('Enter the two letter country code, for example KE.');
        if (!_agree) throw ApiException('Agree to the terms to create an account.');
        final message = await ref.read(developerRepositoryProvider).signup(
              email: email,
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              password: password,
              country: _country.text.trim().toUpperCase(),
              companyName: _company.text.trim().isEmpty ? null : _company.text.trim(),
            );
        if (mounted) {
          setState(() {
            _tab = 0;
            _info = message;
            _needsConfirmation = true;
          });
        }
      } else {
        await ref.read(developerSessionProvider.notifier).signIn(email: email, password: password);
      }
    } catch (e) {
      final err = ApiException.from(e);
      if (mounted) {
        setState(() {
          _error = err.message;
          _needsConfirmation = err.message.toLowerCase().contains('confirm') || err.message.toLowerCase().contains('verif');
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email address first, then choose Forgot password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(developerRepositoryProvider).forgotPassword(email);
      if (mounted) setState(() => _info = 'If that address has a developer account, a reset link is on its way.');
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email address first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await ref.read(developerRepositoryProvider).resendVerification(email);
      if (mounted) setState(() => _info = message);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = _tab == 1;
    return AuthScaffold(
      title: creating ? 'Create a developer account' : 'Developer sign in',
      subtitle: 'Build on Premisave payments. Developer accounts are separate from your Premisave account.',
      leading: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => context.go('/login'),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Premisave sign in'),
        ),
      ),
      footer: Text(
        'Sandbox apps need no business. A business is only needed to go live.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12.5, color: context.mutedColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 0, label: Text('Sign in'), icon: Icon(Icons.login_rounded)),
              ButtonSegment<int>(value: 1, label: Text('Create account'), icon: Icon(Icons.person_add_alt_rounded)),
            ],
            selected: <int>{_tab},
            onSelectionChanged: (v) => setState(() {
              _tab = v.first;
              _error = null;
              _info = null;
            }),
          ),
          const SizedBox(height: 20),
          if (creating) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(child: PTextField(label: 'First name', controller: _first)),
                const SizedBox(width: 12),
                Expanded(child: PTextField(label: 'Last name', controller: _last)),
              ],
            ),
            const SizedBox(height: 14),
          ],
          PTextField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.alternate_email_rounded),
          const SizedBox(height: 14),
          PTextField(label: 'Password', controller: _password, obscure: true, prefixIcon: Icons.lock_outline_rounded, onSubmitted: (_) => _submit()),
          if (creating) ...<Widget>[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: PTextField(label: 'Country code', controller: _country, maxLength: 2, helper: 'Two letters, like KE.', textCapitalization: TextCapitalization.characters),
                ),
                const SizedBox(width: 12),
                Expanded(flex: 5, child: PTextField(label: 'Company', controller: _company, optional: true)),
              ],
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _agree,
              onChanged: (v) => setState(() => _agree = v ?? false),
              title: const Text('I agree to the developer terms', style: TextStyle(fontSize: 13.5)),
            ),
          ],
          if (_error != null) ...<Widget>[const SizedBox(height: 12), InlineMessage(_error!, kind: MessageKind.error)],
          if (_info != null) ...<Widget>[const SizedBox(height: 12), InlineMessage(_info!, kind: MessageKind.success)],
          const SizedBox(height: 18),
          PButton(label: creating ? 'Create developer account' : 'Sign in', expand: true, loading: _busy, onPressed: _submit),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              if (!creating) TextButton(onPressed: _busy ? null : _forgot, child: const Text('Forgot password')) else const SizedBox.shrink(),
              if (_needsConfirmation || !creating) TextButton(onPressed: _busy ? null : _resend, child: const Text('Resend confirmation email')),
            ],
          ),
          SocialAuthButtons(
            only: _providers,
            disabled: _busy,
            onError: (m) => setState(() => _error = m),
            onNotice: (m) => setState(() => _info = m),
            onSignIn: _signInSocial,
          ),
        ],
      ),
    );
  }
}

/// Where the confirmation email lands. Reads the code from the link and confirms the address.
class DeveloperVerifyEmailPage extends ConsumerStatefulWidget {
  const DeveloperVerifyEmailPage({super.key, this.token});

  final String? token;

  @override
  ConsumerState<DeveloperVerifyEmailPage> createState() => _DeveloperVerifyEmailPageState();
}

class _DeveloperVerifyEmailPageState extends ConsumerState<DeveloperVerifyEmailPage> {
  String? _message;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _verify();
  }

  Future<void> _verify() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _busy = false;
        _error = 'This link has no confirmation code. Open the link from the email again, or ask for a new email.';
      });
      return;
    }
    try {
      final m = await ref.read(developerRepositoryProvider).verifyEmail(token);
      if (mounted) {
        setState(() {
          _message = m;
          _busy = false;
        });
        ref.read(developerSessionProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiException.from(e).message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Confirm your email',
      subtitle: 'Developer portal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_busy) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          if (_message != null) InlineMessage(_message!, kind: MessageKind.success),
          if (_error != null) InlineMessage(_error!, kind: MessageKind.error),
          const SizedBox(height: 18),
          PButton(label: 'Go to developer sign in', expand: true, onPressed: () => context.go('/developers')),
        ],
      ),
    );
  }
}

/// Where the "join Facebook to your account" email lands. Reads the code from the link and joins the provider account.
/// It signs nobody in: the person goes back and signs in with the provider, which now goes straight in.
class DeveloperLinkProviderPage extends ConsumerStatefulWidget {
  const DeveloperLinkProviderPage({super.key, this.token});

  final String? token;

  @override
  ConsumerState<DeveloperLinkProviderPage> createState() => _DeveloperLinkProviderPageState();
}

class _DeveloperLinkProviderPageState extends ConsumerState<DeveloperLinkProviderPage> {
  String? _message;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _link();
  }

  Future<void> _link() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _busy = false;
        _error = 'This link has no code. Open the link from the email again, or sign in with the provider to get a new email.';
      });
      return;
    }
    try {
      final provider = await ref.read(developerRepositoryProvider).confirmProviderLink(token);
      final label = providerLabel(provider);
      if (mounted) {
        setState(() {
          _message = '$label is now linked to your developer account. Go back and sign in with $label.';
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiException.from(e).message;
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Link your sign in',
      subtitle: 'Developer portal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_busy) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          if (_message != null) InlineMessage(_message!, kind: MessageKind.success),
          if (_error != null) InlineMessage(_error!, kind: MessageKind.error),
          const SizedBox(height: 18),
          PButton(label: 'Go to developer sign in', expand: true, onPressed: () => context.go('/developers')),
        ],
      ),
    );
  }
}

/// Where the reset link in the email lands. Asks for a new password and sends it with the code from the link.
class DeveloperResetPasswordPage extends ConsumerStatefulWidget {
  const DeveloperResetPasswordPage({super.key, this.token});

  final String? token;

  @override
  ConsumerState<DeveloperResetPasswordPage> createState() => _DeveloperResetPasswordPageState();
}

class _DeveloperResetPasswordPageState extends ConsumerState<DeveloperResetPasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _done;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final token = widget.token;
    if (token == null || token.isEmpty) {
      setState(() => _error = 'This link has no reset code. Open the link from the email again, or ask for a new one.');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = 'Use at least 8 characters.');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'The two passwords are not the same.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final m = await ref.read(developerRepositoryProvider).resetPassword(token: token, newPassword: _password.text);
      if (mounted) setState(() => _done = m);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Choose a new password',
      subtitle: 'Developer portal',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (_done == null) ...<Widget>[
            PTextField(label: 'New password', controller: _password, obscure: true, prefixIcon: Icons.lock_outline_rounded),
            const SizedBox(height: 14),
            PTextField(label: 'Repeat the password', controller: _confirm, obscure: true, prefixIcon: Icons.lock_outline_rounded, onSubmitted: (_) => _save()),
          ],
          if (_error != null) ...<Widget>[const SizedBox(height: 12), InlineMessage(_error!, kind: MessageKind.error)],
          if (_done != null) InlineMessage(_done!, kind: MessageKind.success),
          const SizedBox(height: 18),
          if (_done == null)
            PButton(label: 'Change password', expand: true, loading: _busy, onPressed: _save)
          else
            PButton(label: 'Go to developer sign in', expand: true, onPressed: () => context.go('/developers')),
        ],
      ),
    );
  }
}
