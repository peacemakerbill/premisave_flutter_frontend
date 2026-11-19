import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker, ImageSource;

import '../../core/config/app_config.dart';
import '../../core/network/api_exception.dart';
import '../../core/branding/social_logos.dart';
import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/developer_models.dart';
import '../../data/models/json_utils.dart';
import '../../data/repositories/developer_repository.dart';
import '../../state/developer_session.dart';
import '../../state/providers.dart';
import '../shared/hub.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';
import '../shared/service_widgets.dart';
import 'developer_admin.dart';
import 'developer_auth_page.dart';
import 'developer_business.dart';

const Map<String, String> _methodOptions = <String, String>{
  'MOBILE_MONEY': 'Mobile money',
  'CARD': 'Card',
  'BANK_TRANSFER': 'Bank transfer',
  'PAYPAL': 'PayPal',
  'CRYPTO': 'Crypto',
  'PREMISAVE_WALLET': 'Premisave wallet',
};

/// Shows a key and its secret once, with a copy button. The secret cannot be read again.
Future<void> revealKeySecret(BuildContext context, Json key, {String title = 'Your key'}) {
  final secret = pick(key, <String>['secret']);
  final id = pick(key, <String>['key']);
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
          SelectableText('Key: $id'),
          const SizedBox(height: 6),
          SelectableText('Secret: $secret'),
        ],
      ),
      actions: <Widget>[
        PButton(label: 'Copy secret', kind: PButtonKind.outline, small: true, onPressed: () => copyText(ctx, secret, done: 'Secret copied')),
        PButton(label: 'Done', small: true, onPressed: () => Navigator.of(ctx).pop()),
      ],
    ),
  );
}

/// The developer portal at /developers. Signed out it shows the sign in page, signed in it shows the portal menu.
/// Developer accounts are separate from Premisave accounts, so this has its own sign in.
class DeveloperPortalPage extends ConsumerWidget {
  const DeveloperPortalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(developerSessionProvider);
    switch (session.status) {
      case DeveloperStatus.loading:
        return const PScaffold(body: SkeletonList());
      case DeveloperStatus.signedOut:
        return const DeveloperAuthPage();
      case DeveloperStatus.signedIn:
        return _DeveloperHub(account: session.account!);
    }
  }
}

class _DeveloperHub extends ConsumerWidget {
  const _DeveloperHub({required this.account});

  final DeveloperAccount account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = account.role == 'ADMIN';
    return HubPage(
      title: 'Developers',
      actions: <Widget>[
        IconButton(tooltip: 'Back to Premisave', icon: const Icon(Icons.home_outlined), onPressed: () => context.go('/home')),
        IconButton(
          tooltip: 'Sign out of the developer portal',
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => ref.read(developerSessionProvider.notifier).signOut(),
        ),
      ],
      tabs: <HubTab>[
        HubTab('Overview', Icons.dashboard_outlined, (_) => _OverviewTab(account: account)),
        HubTab('Apps', Icons.extension_outlined, (_) => const _AppsTab()),
        HubTab('Businesses', Icons.business_center_outlined, (_) => const DeveloperBusinessesTab()),
        HubTab('Transfers', Icons.swap_horiz_rounded, (_) => const _TransfersTab()),
        HubTab('Profile', Icons.person_outline_rounded, (_) => const _ProfileTab()),
        if (isAdmin) HubTab('Admin', Icons.admin_panel_settings_outlined, (_) => const DeveloperAdminTab()),
      ],
    );
  }
}

// ------------------------------------------------------------------ overview

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab({required this.account});

  final DeveloperAccount account;

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  late Future<({List<Json> apps, List<Json> businesses, List<Json> transfers})> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<({List<Json> apps, List<Json> businesses, List<Json> transfers})> _load() async {
    final DeveloperRepository repo = ref.read(developerRepositoryProvider);
    final apps = await repo.appsRaw();
    final businesses = await repo.businesses();
    final transfers = await repo.transfers();
    return (apps: apps, businesses: businesses, transfers: transfers);
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return PageBody(
      maxWidth: 820,
      onRefresh: () async {
        setState(() {
          _future = _load();
        });
      },
      children: <Widget>[
        PageTitle('Hello ${account.fullName}', subtitle: 'Build on Premisave payments.'),
        if (!account.emailVerified)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: InlineMessage(
              'Confirm your email address to add a business and go live. Sandbox apps work without it.',
              kind: MessageKind.warning,
              actionLabel: 'Send the email again',
              onAction: () => attempt(context, () => ref.read(developerRepositoryProvider).resendMyVerification(), done: 'Confirmation email sent'),
            ),
          ),
        const SizedBox(height: 8),
        FutureBuilder<({List<Json> apps, List<Json> businesses, List<Json> transfers})>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const SkeletonList(count: 2, height: 90, shrink: true);
            if (snap.hasError) return ErrorState(error: snap.error!, onRetry: () => setState(() {
              _future = _load();
            }));
            final d = snap.data!;
            final sandbox = d.apps.where((a) => pick(a, <String>['environment']).toLowerCase() == 'sandbox').length;
            final pendingTransfers = d.transfers.where((t) => pick(t, <String>['status']) == 'PENDING').length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ResponsiveWrap(
                  minItemWidth: 170,
                  children: <Widget>[
                    StatTile(label: 'Apps', value: '${d.apps.length}', icon: Icons.extension_outlined, caption: '$sandbox sandbox'),
                    StatTile(label: 'Businesses', value: '${d.businesses.length}', icon: Icons.business_center_outlined),
                    StatTile(label: 'Transfers waiting', value: '$pendingTransfers', icon: Icons.swap_horiz_rounded),
                  ],
                ),
                const BlockTitle('Get started'),
                MenuGroup(
                  children: <Widget>[
                    MenuTile(
                      icon: Icons.science_outlined,
                      title: 'Create a sandbox app',
                      subtitle: 'No business needed. You get an API key to test with straight away.',
                      onTap: () => _createSandbox(context),
                    ),
                    MenuTile(
                      icon: Icons.business_center_outlined,
                      title: 'Add a business',
                      subtitle: 'Needed to take real payments. Its application is reviewed before you go live.',
                      onTap: () => DefaultTabController.of(context).animateTo(2),
                    ),
                    MenuTile(
                      icon: Icons.phone_iphone_rounded,
                      title: 'Test merchant numbers',
                      subtitle: 'Numbers that behave in a known way in the sandbox.',
                      onTap: () => Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(builder: (_) => SubPage(title: 'Test merchant numbers', body: _testNumbers(ref))),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        ServiceDownHint('Developer service', AppConfig.developerUrl),
      ],
    );
  }

  Future<void> _createSandbox(BuildContext context) async {
    await showResourceForm(
      context,
      title: 'Create a sandbox app',
      subtitle: 'For testing. It needs no business.',
      fields: _newAppFields(sandbox: true),
      submitLabel: 'Create app',
      onSubmit: (v) => _submitNewApp(context, ref, v, sandbox: true),
    );
  }
}

Widget _testNumbers(WidgetRef ref) => ResourceView(
      load: () => ref.read(developerRepositoryProvider).testMerchantNumbers(),
      intro: 'Use one of these as the merchant number of a sandbox app to see how payments behave.',
    );

List<FieldSpec> _newAppFields({required bool sandbox}) => <FieldSpec>[
      const FieldSpec('name', 'App name', required: true, maxLength: 120),
      const FieldSpec('description', 'Description', kind: FieldKind.multiline, maxLength: 500),
      const FieldSpec('callbackUrl', 'Callback address', kind: FieldKind.text, hint: 'https://example.com/payments/callback', helper: 'Where payment results are sent. https only, except plain http in the sandbox.'),
      const FieldSpec('merchantNumber', 'Merchant number', helper: 'Optional. In the sandbox a test number is used when you leave it empty.'),
      if (!sandbox) const FieldSpec('businessId', 'Business', required: true, helper: 'The id of an approved business from the Businesses menu.'),
      const FieldSpec('enabledMethods', 'Payment methods', kind: FieldKind.multiSelect, options: _methodOptions),
    ];

/// Creates an app and shows the first key when the service issued one.
Future<void> _submitNewApp(BuildContext context, WidgetRef ref, Json v, {required bool sandbox}) async {
  final created = await ref.read(developerRepositoryProvider).createAppRaw(<String, dynamic>{
    ...v,
    'environment': sandbox ? 'sandbox' : 'production',
  });
  final key = asMap(created['apiKey']);
  if (context.mounted && key.isNotEmpty) await revealKeySecret(context, key, title: 'Your first API key');
}

// --------------------------------------------------------------------- apps

class _AppsTab extends ConsumerStatefulWidget {
  const _AppsTab();

  @override
  ConsumerState<_AppsTab> createState() => _AppsTabState();
}

class _AppsTabState extends ConsumerState<_AppsTab> {
  String? _env;
  int _bump = 0;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(developerRepositoryProvider);
    return Column(
      children: <Widget>[
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: <Widget>[
              for (final e in const <String?, String>{null: 'All', 'sandbox': 'Sandbox', 'production': 'Live'}.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(e.value), selected: _env == e.key, onSelected: (_) => setState(() => _env = e.key)),
                ),
            ],
          ),
        ),
        Expanded(
          child: ResourceSection(
            refreshKey: '$_env$_bump',
            load: () => repo.appsRaw(environment: _env),
            onOpen: (context, item) => Navigator.of(context)
                .push<void>(MaterialPageRoute<void>(builder: (_) => SubPage(title: pick(item, <String>['name'], 'App'), body: DeveloperAppPage(appId: pick(item, <String>['appId'])))))
                .then((_) => setState(() => _bump++)),
            emptyTitle: 'No apps yet',
            emptyMessage: 'Create a sandbox app to get an API key and start testing. No business is needed.',
            emptyIcon: Icons.extension_outlined,
            row: RowView(
              icon: Icons.extension_outlined,
              title: (m) => pick(m, <String>['name'], 'App'),
              subtitle: (m) => '${pick(m, <String>['environment']).toLowerCase() == 'sandbox' ? 'Sandbox' : 'Live'}  ${pick(m, <String>['merchantNumber'])}'.trim(),
              status: (m) => pick(m, <String>['status']),
            ),
            headerActions: <ItemAction>[
              ItemAction(
                'New sandbox app',
                Icons.science_outlined,
                title: 'Create a sandbox app',
                subtitle: 'For testing. It needs no business.',
                fields: _newAppFields(sandbox: true),
                run: (_, v) => _submitNewApp(context, ref, v, sandbox: true),
                done: 'App created',
              ),
              ItemAction(
                'New live app',
                Icons.rocket_launch_outlined,
                title: 'Create a live app',
                subtitle: 'Needs a business whose application was approved.',
                fields: _newAppFields(sandbox: false),
                run: (_, v) => _submitNewApp(context, ref, v, sandbox: false),
                done: 'App created',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One app: its settings with every action, and its API keys.
class DeveloperAppPage extends ConsumerStatefulWidget {
  const DeveloperAppPage({super.key, required this.appId});

  final String appId;

  @override
  ConsumerState<DeveloperAppPage> createState() => _DeveloperAppPageState();
}

class _DeveloperAppPageState extends ConsumerState<DeveloperAppPage> {
  int _bump = 0;

  void _reload() => setState(() => _bump++);

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(developerRepositoryProvider);
    final id = widget.appId;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: <Widget>[
          const TabBar(tabs: <Tab>[Tab(text: 'Details'), Tab(text: 'API keys')]),
          Expanded(
            child: TabBarView(
              children: <Widget>[
                ResourceView(
                  refreshKey: _bump,
                  load: () => repo.app(id),
                  actions: <ItemAction>[
                    ItemAction(
                      'Edit',
                      Icons.edit_outlined,
                      title: 'Edit app',
                      initialFromItem: true,
                      fields: const <FieldSpec>[
                        FieldSpec('name', 'App name', maxLength: 120),
                        FieldSpec('description', 'Description', kind: FieldKind.multiline, maxLength: 500, clearable: true),
                        FieldSpec('callbackUrl', 'Callback address', clearable: true),
                        FieldSpec('enabledMethods', 'Payment methods', kind: FieldKind.multiSelect, options: _methodOptions),
                        FieldSpec('limits.singleTransactionUsd', 'Largest single payment (USD)', kind: FieldKind.number),
                        FieldSpec('limits.dailyVolumeUsd', 'Daily volume (USD)', kind: FieldKind.number),
                        FieldSpec('limits.monthlyVolumeUsd', 'Monthly volume (USD)', kind: FieldKind.number),
                        FieldSpec('limits.dailyPayoutCount', 'Payouts a day', kind: FieldKind.integer),
                      ],
                      run: (_, v) async {
                        await repo.updateApp(id, v);
                      },
                      done: 'App saved',
                    ),
                    ItemAction(
                      'Suspend',
                      Icons.pause_circle_outline_rounded,
                      danger: true,
                      confirm: 'Its keys stop working until you reactivate the app.',
                      run: (_, __) => repo.suspendApp(id),
                      done: 'App suspended',
                      visible: (m) => pick(m, <String>['status']) == 'ACTIVE',
                    ),
                    ItemAction(
                      'Reactivate',
                      Icons.play_circle_outline_rounded,
                      run: (_, __) => repo.reactivateApp(id),
                      done: 'App reactivated',
                      visible: (m) => pick(m, <String>['status']) == 'SUSPENDED',
                    ),
                    ItemAction(
                      'Transfer',
                      Icons.swap_horiz_rounded,
                      title: 'Transfer this app',
                      subtitle: 'Hands the app to another developer. A 6 digit code is emailed to confirm it.',
                      fields: const <FieldSpec>[FieldSpec('toEmail', 'Their email address', kind: FieldKind.email, required: true)],
                      run: (_, v) async {
                        await repo.transferApp(id, v['toEmail'] as String);
                      },
                      done: 'Transfer started. Check the Transfers menu for the code.',
                    ),
                  ],
                ),
                _KeysSection(appId: id, key: ValueKey<int>(_bump), onChanged: _reload),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KeysSection extends ConsumerWidget {
  const _KeysSection({super.key, required this.appId, required this.onChanged});

  final String appId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(developerRepositoryProvider);
    return ResourceSection(
      load: () => repo.keysRaw(appId),
      intro: 'A secret is shown once, when a key is created or rotated.',
      emptyTitle: 'No keys yet',
      emptyMessage: 'Create a key to call the API from this app.',
      emptyIcon: Icons.vpn_key_outlined,
      row: RowView(
        icon: Icons.vpn_key_outlined,
        title: (m) => pick(m, <String>['label'], 'Key'),
        subtitle: (m) => '${pick(m, <String>['key'])}  ends ${pick(m, <String>['secretEndsWith'])}',
        status: (m) => pick(m, <String>['status']),
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'New key',
          Icons.add_rounded,
          title: 'New key',
          fields: const <FieldSpec>[FieldSpec('label', 'Label', maxLength: 60, helper: 'Optional, to tell keys apart.')],
          run: (_, v) async {
            final k = await repo.createKeyRaw(appId, label: v['label'] as String?);
            if (context.mounted) await revealKeySecret(context, k, title: 'New key');
          },
          done: 'Key created',
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction(
          'Rotate',
          Icons.autorenew_rounded,
          confirm: 'The old secret stops working and a new one is shown once.',
          visible: (m) => pick(m, <String>['status']) == 'ACTIVE',
          run: (m, _) async {
            final k = await repo.rotateKeyRaw(appId, pick(m, <String>['key']));
            if (context.mounted) await revealKeySecret(context, k, title: 'Rotated key');
          },
          done: 'Key rotated',
        ),
        ItemAction(
          'Revoke',
          Icons.block_outlined,
          danger: true,
          confirm: 'Anything using this key stops working.',
          visible: (m) => pick(m, <String>['status']) == 'ACTIVE',
          run: (m, _) => repo.revokeKey(appId, pick(m, <String>['key'])),
          done: 'Key revoked',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- transfers

class _TransfersTab extends ConsumerWidget {
  const _TransfersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(developerRepositoryProvider);
    String id(Json m) => pick(m, <String>['transferId']);
    return ResourceSection(
      load: () => repo.transfers(),
      detail: (m) => repo.transfer(id(m)),
      intro: 'Apps and businesses handed to you or by you. A transfer is finished with the 6 digit code that is emailed.',
      emptyTitle: 'No transfers',
      emptyMessage: 'Transfer an app from its page, or claim a business by its merchant number.',
      emptyIcon: Icons.swap_horiz_rounded,
      row: RowView(
        icon: Icons.swap_horiz_rounded,
        title: (m) => pick(m, <String>['app.name', 'business.name'], 'Transfer'),
        subtitle: (m) => '${sentence(pick(m, <String>['direction']))}  ${pick(m, <String>['to', 'from'])}'.trim(),
        status: (m) => pick(m, <String>['status']),
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Claim a business',
          Icons.how_to_reg_outlined,
          title: 'Claim a business',
          subtitle: 'Enter the merchant number the business was created under. A code is emailed to its owner.',
          fields: const <FieldSpec>[FieldSpec('merchantNumber', 'Merchant number', required: true, maxLength: 40)],
          run: (_, v) async {
            await repo.claimBusiness(v['merchantNumber'] as String);
          },
          done: 'Claim started',
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction(
          'Enter code',
          Icons.pin_outlined,
          title: 'Confirm the transfer',
          fields: const <FieldSpec>[FieldSpec('otp', '6 digit code', kind: FieldKind.text, required: true, maxLength: 6)],
          run: (m, v) async {
            await repo.confirmTransfer(id(m), v['otp'] as String);
          },
          done: 'Transfer confirmed',
          visible: (m) => pick(m, <String>['status']) == 'PENDING',
        ),
        ItemAction(
          'Send the code again',
          Icons.mark_email_unread_outlined,
          run: (m, _) async {
            await repo.resendTransferCode(id(m));
          },
          done: 'A new code was emailed',
          visible: (m) => pick(m, <String>['status']) == 'PENDING',
        ),
        ItemAction(
          'Cancel',
          Icons.close_rounded,
          danger: true,
          confirm: 'The transfer is called off and its code stops working.',
          run: (m, _) async {
            await repo.cancelTransfer(id(m));
          },
          done: 'Transfer cancelled',
          visible: (m) => pick(m, <String>['status']) == 'PENDING',
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- sign in methods

/// Google, Facebook and GitHub accounts joined to this developer account, with Connect and Disconnect for each. A
/// connected provider signs in to this account directly, whatever address it uses.
class _ConnectionsView extends ConsumerStatefulWidget {
  const _ConnectionsView();

  @override
  ConsumerState<_ConnectionsView> createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends ConsumerState<_ConnectionsView> {
  static const List<String> _all = <String>['google', 'facebook', 'github'];

  DeveloperConnections? _data;
  String? _error;
  String? _busy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await ref.read(developerRepositoryProvider).connections();
      if (mounted) {
        setState(() {
          _data = d;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e).message);
    }
  }

  Future<void> _connect(String provider) async {
    setState(() => _busy = provider);
    try {
      final d = await ref.read(developerSessionProvider.notifier).connectSocial(provider);
      if (d != null && mounted) {
        setState(() {
          _data = d;
          _error = null;
        });
        showToast(context, '${providerLabel(provider)} connected');
      }
    } catch (e) {
      if (mounted) showApiError(context, ApiException.from(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _disconnect(String provider) async {
    final label = providerLabel(provider);
    final yes = await confirmDialog(
      context,
      title: 'Disconnect $label',
      message: '$label will no longer sign in to this account. You can connect it again later.',
      confirmLabel: 'Disconnect',
      danger: true,
    );
    if (!yes || !mounted) return;
    setState(() => _busy = provider);
    try {
      final d = await ref.read(developerRepositoryProvider).disconnect(provider);
      if (mounted) {
        setState(() => _data = d);
        showToast(context, '$label disconnected');
      }
    } catch (e) {
      if (mounted) showApiError(context, ApiException.from(e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _logo(String provider) {
    switch (provider) {
      case 'google':
        return const SocialLogo.google();
      case 'facebook':
        return const SocialLogo.facebook();
      default:
        return SocialLogo.github(color: context.inkColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (_error != null && data == null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: InlineMessage(_error!, kind: MessageKind.error)));
    }
    if (data == null) return const Center(child: CircularProgressIndicator());
    final shown = _all.where((p) => data.available.contains(p) || data.of(p) != null).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(
          'Connect Google, Facebook or GitHub to sign in with one tap. The address of the account you connect does not '
          'have to match the one here.',
          style: TextStyle(fontSize: 13.5, color: context.mutedColor, height: 1.4),
        ),
        const SizedBox(height: 14),
        for (final p in shown) ...<Widget>[
          PCard(
            child: Row(
              children: <Widget>[
                _logo(p),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(providerLabel(p), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text(
                        data.of(p) == null
                            ? 'Not connected'
                            : [
                                'Connected',
                                if (data.of(p)!.email != null) data.of(p)!.email!,
                                if (data.of(p)!.linkedAt != null) formatDate(data.of(p)!.linkedAt),
                              ].join(' · '),
                        style: TextStyle(fontSize: 12.5, color: context.mutedColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                if (data.of(p) == null)
                  PButton(label: 'Connect', small: true, kind: PButtonKind.outline, loading: _busy == p, onPressed: _busy == null ? () => _connect(p) : null)
                else
                  PButton(label: 'Disconnect', small: true, kind: PButtonKind.text, loading: _busy == p, onPressed: _busy == null ? () => _disconnect(p) : null),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (!data.hasPassword && data.connections.length < 2 && data.connections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'This account has no password, so its only way in is ${providerLabel(data.connections.first.provider)}. Set a '
              'password under Change password before disconnecting it.',
              style: TextStyle(fontSize: 12.5, color: context.mutedColor, height: 1.4),
            ),
          ),
      ],
    );
  }
}

// ------------------------------------------------------------------ profile

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  int _bump = 0;

  void _reload() {
    setState(() => _bump++);
    ref.read(developerSessionProvider.notifier).refresh();
  }

  Future<void> _pickPicture() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88, maxWidth: 1200);
    if (picked == null) return;
    final Uint8List bytes = await picked.readAsBytes();
    final lower = picked.name.toLowerCase();
    final type = lower.endsWith('.png') ? 'image/png' : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
    if (!mounted) return;
    final ok = await attempt(context, () => ref.read(developerRepositoryProvider).uploadPicture(bytes, contentType: type), done: 'Picture updated');
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(developerRepositoryProvider);
    return ResourceView(
      refreshKey: _bump,
      load: () => repo.profile(),
      hidden: const <String>{'profilePictureUrl', 'businessIds', 'hasPassword', 'profileComplete'},
      summary: (data) => PCard(
        child: Row(
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundImage: pick(data, <String>['profilePictureUrl']).isEmpty ? null : NetworkImage(pick(data, <String>['profilePictureUrl'])),
              child: pick(data, <String>['profilePictureUrl']).isEmpty ? const Icon(Icons.person_outline_rounded) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(pick(data, <String>['fullName', 'email']), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(pick(data, <String>['email']), style: TextStyle(fontSize: 13, color: context.mutedColor)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      PButton(label: 'Change picture', icon: Icons.photo_camera_outlined, small: true, kind: PButtonKind.outline, onPressed: _pickPicture),
                      if (pick(data, <String>['profilePictureUrl']).isNotEmpty)
                        PButton(
                          label: 'Remove',
                          small: true,
                          kind: PButtonKind.text,
                          onPressed: () async {
                            final ok = await attempt(context, () => repo.removePicture(), done: 'Picture removed');
                            if (ok) _reload();
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: <ItemAction>[
        ItemAction(
          'Edit profile',
          Icons.edit_outlined,
          title: 'Edit profile',
          initialFromItem: true,
          fields: const <FieldSpec>[
            FieldSpec('firstName', 'First name', maxLength: 60),
            FieldSpec('middleName', 'Middle name', maxLength: 60, clearable: true),
            FieldSpec('lastName', 'Last name', maxLength: 60),
            FieldSpec('username', 'Username', maxLength: 40, helper: 'Checked for you before it is saved.'),
            FieldSpec('country', 'Country', kind: FieldKind.countryCode),
            FieldSpec('phoneNumber', 'Phone number', kind: FieldKind.phone, maxLength: 24, clearable: true),
            FieldSpec('companyName', 'Company', maxLength: 160, clearable: true),
            FieldSpec(
              'addressLine1',
              'Address line 1',
              kind: FieldKind.address,
              clearable: true,
              countryKey: 'country',
              fills: <String, String>{'street': 'addressLine1', 'city': 'city', 'state': 'stateOrRegion', 'postcode': 'postalCode'},
            ),
            FieldSpec('addressLine2', 'Address line 2', maxLength: 120, clearable: true),
            FieldSpec('city', 'City', maxLength: 80, clearable: true),
            FieldSpec('stateOrRegion', 'State or region', maxLength: 80, clearable: true),
            FieldSpec('postalCode', 'Postal code', maxLength: 16, clearable: true),
            FieldSpec('timezone', 'Time zone', hint: 'Africa/Nairobi', maxLength: 64, clearable: true),
            FieldSpec('marketingOptIn', 'Send me product news', kind: FieldKind.toggle),
          ],
          run: (item, v) async {
            final name = v['username'];
            if (name is String && name.isNotEmpty && name != item['username']) {
              final free = await repo.usernameAvailable(name);
              if (!free) throw ApiException('That username is taken. Try another.');
            }
            await repo.updateProfile(v);
            _reload();
          },
          done: 'Profile saved',
        ),
        ItemAction(
          'Change password',
          Icons.lock_reset_rounded,
          title: 'Change password',
          subtitle: 'Accounts made with Google, Facebook or GitHub can leave the current password empty to set one.',
          fields: const <FieldSpec>[
            FieldSpec('currentPassword', 'Current password', kind: FieldKind.password),
            FieldSpec('newPassword', 'New password', kind: FieldKind.password, required: true, maxLength: 128),
          ],
          run: (_, v) => repo.changePassword(currentPassword: v['currentPassword'] as String?, newPassword: v['newPassword'] as String),
          done: 'Password changed',
        ),
        ItemAction(
          'Sign in methods',
          Icons.link_rounded,
          title: 'Sign in methods',
          page: (_) => const _ConnectionsView(),
        ),
        ItemAction(
          'Send confirmation email',
          Icons.mark_email_read_outlined,
          run: (_, __) => repo.resendMyVerification(),
          done: 'Confirmation email sent',
          visible: (m) => m['emailVerified'] != true,
        ),
        ItemAction(
          'Test merchant numbers',
          Icons.phone_iphone_rounded,
          title: 'Test merchant numbers',
          page: (_) => _testNumbers(ref),
        ),
        ItemAction(
          'Sign out everywhere',
          Icons.devices_other_rounded,
          danger: true,
          confirm: 'Every session of this developer account on every device is ended, including this one.',
          run: (_, __) async {
            await repo.logoutAll();
            await ref.read(developerSessionProvider.notifier).signOut();
          },
          done: 'Signed out everywhere',
        ),
      ],
    );
  }
}
