import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/brand.dart';
import '../../core/theme/palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/developer_models.dart';
import '../../state/developer_session.dart';
import '../../state/providers.dart';
import '../../state/service_providers.dart';
import '../shared/service_widgets.dart';

/// The developer portal: sign in to the developer service, then manage apps and API keys.
/// Developer accounts are separate from Premisave accounts, so this screen has its own sign in.
class DeveloperPortalScreen extends ConsumerWidget {
  const DeveloperPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(developerSessionProvider);
    switch (session.status) {
      case DeveloperStatus.loading:
        return const SkeletonList();
      case DeveloperStatus.signedOut:
        return const _SignInPanel();
      case DeveloperStatus.signedIn:
        return _AppsPanel(account: session.account!);
    }
  }
}

class _SignInPanel extends ConsumerStatefulWidget {
  const _SignInPanel();

  @override
  ConsumerState<_SignInPanel> createState() => _SignInPanelState();
}

class _SignInPanelState extends ConsumerState<_SignInPanel> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _first = TextEditingController();
  final TextEditingController _last = TextEditingController();
  final TextEditingController _country = TextEditingController(text: 'KE');
  bool _create = false;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _first.dispose();
    _last.dispose();
    _country.dispose();
    super.dispose();
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
    });
    try {
      if (_create) {
        if (_first.text.trim().isEmpty || _last.text.trim().isEmpty) {
          throw ApiException('Enter your first and last name.');
        }
        final message = await ref.read(developerRepositoryProvider).signup(
              email: email,
              firstName: _first.text.trim(),
              lastName: _last.text.trim(),
              password: password,
              country: _country.text.trim().toUpperCase(),
            );
        if (mounted) {
          setState(() {
            _create = false;
            _info = message;
          });
        }
      } else {
        await ref.read(developerSessionProvider.notifier).signIn(email: email, password: password);
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      maxWidth: 520,
      children: <Widget>[
        const PageTitle('Developer portal', subtitle: 'Build on Premisave payments. Developer accounts are separate from your Premisave account.'),
        const SizedBox(height: 12),
        PCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_create) ...<Widget>[
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
              if (_create) ...<Widget>[
                const SizedBox(height: 14),
                PTextField(label: 'Country code', controller: _country, maxLength: 2, helper: 'Two letters, for example KE.', textCapitalization: TextCapitalization.characters),
              ],
              if (_error != null) ...<Widget>[const SizedBox(height: 14), InlineMessage(_error!, kind: MessageKind.error)],
              if (_info != null) ...<Widget>[const SizedBox(height: 14), InlineMessage(_info!, kind: MessageKind.success)],
              const SizedBox(height: 18),
              PButton(label: _create ? 'Create developer account' : 'Sign in', expand: true, loading: _busy, onPressed: _submit),
              const SizedBox(height: 8),
              Center(
                child: PButton(
                  label: _create ? 'I already have an account' : 'Create a developer account',
                  kind: PButtonKind.text,
                  small: true,
                  onPressed: () => setState(() {
                    _create = !_create;
                    _error = null;
                  }),
                ),
              ),
            ],
          ),
        ),
        ServiceDownHint('Developer service', AppConfig.developerUrl),
      ],
    );
  }
}

class _AppsPanel extends ConsumerWidget {
  const _AppsPanel({required this.account});

  final DeveloperAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(developerAppsProvider);
    return PageBody(
      maxWidth: 820,
      onRefresh: () async => ref.invalidate(developerAppsProvider),
      children: <Widget>[
        PageTitle(
          'Developer portal',
          subtitle: account.fullName,
          trailing: PButton(
            label: 'Sign out',
            kind: PButtonKind.text,
            small: true,
            onPressed: () => ref.read(developerSessionProvider.notifier).signOut(),
          ),
        ),
        if (!account.emailVerified)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: InlineMessage('Confirm your email address to unlock production apps.', kind: MessageKind.warning),
          ),
        SectionHeader(
          'Your apps',
          action: 'New app',
          onAction: () => showFormSheet<void>(context, title: 'New app', subtitle: 'A sandbox app is for testing. Production needs approval.', child: const _NewAppForm()),
        ),
        apps.when(
          loading: () => const SkeletonList(count: 2, height: 90, shrink: true, padding: EdgeInsets.zero),
          error: (e, _) => ErrorState(error: e, onRetry: () => ref.invalidate(developerAppsProvider)),
          data: (items) {
            if (items.isEmpty) {
              return const SizedBox(height: 280, child: EmptyState(icon: Icons.code_rounded, title: 'No apps yet', message: 'Create a sandbox app to get API keys and start testing.'));
            }
            return Column(
              children: <Widget>[
                for (final a in items)
                  PCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => showFormSheet<void>(context, title: a.name, subtitle: a.appId, child: _AppDetail(app: a)),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: context.pal.accent.op(0.12), borderRadius: BorderRadius.circular(context.radius(12))),
                          child: Icon(Icons.extension_outlined, color: context.pal.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(a.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
                              Text(a.description ?? 'Created ${formatDate(a.createdAt)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                            ],
                          ),
                        ),
                        StatusPill(a.isSandbox ? 'Sandbox' : 'Production', color: a.isSandbox ? Brand.info : Brand.success, dense: true),
                        const SizedBox(width: 6),
                        StatusChip(a.status),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _NewAppForm extends ConsumerStatefulWidget {
  const _NewAppForm();

  @override
  ConsumerState<_NewAppForm> createState() => _NewAppFormState();
}

class _NewAppFormState extends ConsumerState<_NewAppForm> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _callback = TextEditingController();
  String _environment = 'sandbox';
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _callback.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Give the app a name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(developerRepositoryProvider).createApp(
            name: _name.text.trim(),
            environment: _environment,
            description: _description.text.trim(),
            callbackUrl: _callback.text.trim(),
          );
      ref.invalidate(developerAppsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showToast(context, 'App created. Open it to create a key.');
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PTextField(label: 'Name', controller: _name, autofocus: true),
        const SizedBox(height: 14),
        PSelectField<String>(
          label: 'Environment',
          value: _environment,
          options: const <PChoice<String>>[PChoice<String>('sandbox', 'Sandbox'), PChoice<String>('production', 'Production')],
          onChanged: (v) => setState(() => _environment = v ?? 'sandbox'),
        ),
        const SizedBox(height: 14),
        PTextField(label: 'Description', controller: _description, optional: true),
        const SizedBox(height: 14),
        PTextField(label: 'Callback URL', controller: _callback, optional: true, keyboardType: TextInputType.url, helper: 'Where payment results are sent.'),
        if (_error != null) ...<Widget>[const SizedBox(height: 14), InlineMessage(_error!, kind: MessageKind.error)],
        const SizedBox(height: 18),
        PButton(label: 'Create app', expand: true, loading: _busy, onPressed: _create),
      ],
    );
  }
}

class _AppDetail extends ConsumerWidget {
  const _AppDetail({required this.app});

  final DeveloperApp app;

  Future<void> _reveal(BuildContext context, ApiKeyModel key, String title) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const InlineMessage('Store this secret now. It cannot be shown again.', kind: MessageKind.warning),
            const SizedBox(height: 12),
            SelectableText('Key: ${key.key}'),
            const SizedBox(height: 6),
            SelectableText('Secret: ${key.secret ?? ''}'),
          ],
        ),
        actions: <Widget>[
          PButton(label: 'Copy secret', kind: PButtonKind.outline, small: true, onPressed: () => copyText(ctx, key.secret ?? '', done: 'Secret copied')),
          PButton(label: 'Done', small: true, onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(developerKeysProvider(app.appId));
    final repo = ref.read(developerRepositoryProvider);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
        ref.invalidate(developerKeysProvider(app.appId));
      } catch (e) {
        if (context.mounted) showApiError(context, e);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        KeyValueLine('Environment', app.isSandbox ? 'Sandbox' : 'Production'),
        KeyValueLine('Status', sentence(app.status)),
        if (app.merchantNumber != null) KeyValueLine('Merchant number', app.merchantNumber!),
        if (app.callbackUrl != null) KeyValueLine('Callback', app.callbackUrl!),
        if (app.enabledMethods.isNotEmpty) KeyValueLine('Methods', app.enabledMethods.map(sentence).join(', ')),
        Row(
          children: <Widget>[
            const Expanded(child: SectionHeader('API keys', padding: EdgeInsets.only(top: 18, bottom: 8))),
            PButton(
              label: 'New key',
              icon: Icons.add_rounded,
              small: true,
              onPressed: () => run(() async {
                final k = await repo.createKey(app.appId);
                if (context.mounted) await _reveal(context, k, 'New key');
              }),
            ),
          ],
        ),
        keys.when(
          loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
          error: (e, _) => InlineMessage(ApiException.from(e).message, kind: MessageKind.error),
          data: (items) {
            if (items.isEmpty) return const InlineMessage('This app has no keys yet.');
            return Column(
              children: <Widget>[
                for (final k in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(child: Text(k.label ?? 'Key', style: const TextStyle(fontWeight: FontWeight.w800))),
                              StatusChip(k.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          InkWell(
                            onTap: () => copyText(context, k.key, done: 'Key copied'),
                            child: Text(k.key, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                          ),
                          if (k.secretEndsWith != null) Text('Secret ends with ${k.secretEndsWith}', style: TextStyle(fontSize: 12, color: context.mutedColor)),
                          if (!k.revoked)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  PButton(
                                    label: 'Rotate',
                                    kind: PButtonKind.outline,
                                    small: true,
                                    onPressed: () async {
                                      final ok = await confirmDialog(context, title: 'Rotate this key?', message: 'The old secret stops working and a new one is shown once.', confirmLabel: 'Rotate');
                                      if (!ok) return;
                                      await run(() async {
                                        final rotated = await repo.rotateKey(app.appId, k.key);
                                        if (context.mounted) await _reveal(context, rotated, 'Rotated key');
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  PButton(
                                    label: 'Revoke',
                                    kind: PButtonKind.danger,
                                    small: true,
                                    onPressed: () async {
                                      final ok = await confirmDialog(context, title: 'Revoke this key?', message: 'Anything using it stops working.', confirmLabel: 'Revoke', danger: true);
                                      if (!ok) return;
                                      await run(() => repo.revokeKey(app.appId, k.key));
                                    },
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
