import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/repositories/developer_repository.dart';
import '../../state/providers.dart';
import '../shared/resource_form.dart';
import '../shared/resource_view.dart';
import 'developer_portal.dart';

/// Everything an administrator of the developer service can do: the numbers, every developer, every app, every
/// transfer and the audit trail. Shown only to developer accounts with the ADMIN role.
class DeveloperAdminTab extends StatelessWidget {
  const DeveloperAdminTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 6,
      child: Column(
        children: <Widget>[
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Tab>[Tab(text: 'Stats'), Tab(text: 'Developers'), Tab(text: 'Administrators'), Tab(text: 'All apps'), Tab(text: 'Transfers'), Tab(text: 'Audit')],
          ),
          Expanded(
            child: TabBarView(
              children: <Widget>[_Stats(), _Developers(), _Administrators(), _AllApps(), _AllTransfers(), _Audit()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResourceView(load: () => ref.read(developerRepositoryProvider).adminStats());
}

class _Administrators extends ConsumerWidget {
  const _Administrators();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResourceSection(
      load: () => ref.read(developerRepositoryProvider).adminAdministrators(),
      emptyTitle: 'No administrators',
      emptyIcon: Icons.admin_panel_settings_outlined,
      row: _developerRow,
    );
  }
}

final RowView _developerRow = RowView(
  icon: Icons.person_outline_rounded,
  title: (m) => pick(m, <String>['fullName', 'email'], 'Developer'),
  subtitle: (m) => '${pick(m, <String>['email'])}  ${pick(m, <String>['role'])}',
  status: (m) => pick(m, <String>['status']),
);

class _Developers extends ConsumerStatefulWidget {
  const _Developers();

  @override
  ConsumerState<_Developers> createState() => _DevelopersState();
}

class _DevelopersState extends ConsumerState<_Developers> {
  final _q = TextEditingController();
  String _query = '';
  String? _status;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DeveloperRepository repo = ref.read(developerRepositoryProvider);
    String id(Json m) => pick(m, <String>['developerId']);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: <Widget>[
              Expanded(child: PTextField(label: 'Search by name or email', controller: _q, optional: true, prefixIcon: Icons.search_rounded, onSubmitted: (v) => setState(() => _query = v.trim()))),
              const SizedBox(width: 10),
              PButton(label: 'Search', small: true, onPressed: () => setState(() => _query = _q.text.trim())),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: <Widget>[
              for (final e in const <String?, String>{null: 'All', 'ACTIVE': 'Active', 'DISABLED': 'Disabled'}.entries)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(label: Text(e.value), selected: _status == e.key, onSelected: (_) => setState(() => _status = e.key)),
                ),
            ],
          ),
        ),
        Expanded(
          child: ResourceSection(
            refreshKey: '$_query$_status',
            load: () => repo.adminDevelopers(q: _query.isEmpty ? null : _query, status: _status),
            detail: (m) => repo.adminDeveloper(id(m)),
            emptyTitle: 'No developers found',
            emptyIcon: Icons.groups_outlined,
            row: _developerRow,
            headerActions: <ItemAction>[
              ItemAction(
                'Add a developer',
                Icons.person_add_alt_rounded,
                title: 'Add a developer',
                fields: const <FieldSpec>[
                  FieldSpec('email', 'Email', kind: FieldKind.email, required: true),
                  FieldSpec('firstName', 'First name', required: true, maxLength: 60),
                  FieldSpec('middleName', 'Middle name', maxLength: 60),
                  FieldSpec('lastName', 'Last name', required: true, maxLength: 60),
                  FieldSpec('country', 'Country', kind: FieldKind.countryCode),
                  FieldSpec('phoneNumber', 'Phone number', kind: FieldKind.phone, maxLength: 24),
                  FieldSpec('companyName', 'Company', maxLength: 160),
                  FieldSpec('role', 'Role', kind: FieldKind.select, options: <String, String>{'DEVELOPER': 'Developer', 'ADMIN': 'Administrator'}),
                  FieldSpec('sendInvite', 'Email them an invitation', kind: FieldKind.toggle, initial: true),
                ],
                run: (_, v) async {
                  await repo.adminCreateDeveloper(v);
                },
                done: 'Developer added',
              ),
            ],
            itemActions: <ItemAction>[
              ItemAction(
                'Edit',
                Icons.edit_outlined,
                title: 'Edit developer',
                initialFromItem: true,
                fields: const <FieldSpec>[
                  FieldSpec('firstName', 'First name', maxLength: 60),
                  FieldSpec('middleName', 'Middle name', maxLength: 60, clearable: true),
                  FieldSpec('lastName', 'Last name', maxLength: 60),
                  FieldSpec('username', 'Username', maxLength: 40),
                  FieldSpec('country', 'Country', kind: FieldKind.countryCode),
                  FieldSpec('phoneNumber', 'Phone number', kind: FieldKind.phone, maxLength: 24, clearable: true),
                  FieldSpec('companyName', 'Company', maxLength: 160, clearable: true),
                  FieldSpec('city', 'City', maxLength: 80, clearable: true),
                  FieldSpec('timezone', 'Time zone', maxLength: 64, clearable: true),
                ],
                run: (m, v) async {
                  await repo.adminUpdateDeveloper(id(m), v);
                },
                done: 'Developer saved',
              ),
              ItemAction(
                'Change email',
                Icons.alternate_email_rounded,
                title: 'Change email address',
                initialFromItem: true,
                fields: const <FieldSpec>[
                  FieldSpec('email', 'Email', kind: FieldKind.email, required: true),
                  FieldSpec('verified', 'Count it as confirmed', kind: FieldKind.toggle),
                ],
                run: (m, v) => repo.adminSetDeveloperEmail(id(m), v['email'] as String, verified: v['verified'] as bool?),
                done: 'Email changed',
              ),
              ItemAction(
                'Confirm email',
                Icons.mark_email_read_outlined,
                confirm: 'Counts the email address as confirmed without the link.',
                visible: (m) => m['emailVerified'] != true,
                run: (m, _) => repo.adminVerifyDeveloperEmail(id(m)),
                done: 'Email confirmed',
              ),
              ItemAction(
                'Change role',
                Icons.badge_outlined,
                title: 'Change role',
                fields: const <FieldSpec>[
                  FieldSpec('role', 'Role', kind: FieldKind.select, required: true, options: <String, String>{'DEVELOPER': 'Developer', 'ADMIN': 'Administrator'}),
                ],
                run: (m, v) => repo.adminSetDeveloperRole(id(m), v['role'] as String),
                done: 'Role changed',
              ),
              ItemAction(
                'Disable',
                Icons.block_outlined,
                danger: true,
                title: 'Disable account',
                fields: const <FieldSpec>[FieldSpec('reason', 'Reason', maxLength: 300)],
                visible: (m) => pick(m, <String>['status']) == 'ACTIVE',
                run: (m, v) => repo.adminSetDeveloperStatus(id(m), 'DISABLED', reason: v['reason'] as String?),
                done: 'Account disabled',
              ),
              ItemAction(
                'Enable',
                Icons.check_circle_outline_rounded,
                visible: (m) => pick(m, <String>['status']) == 'DISABLED',
                run: (m, _) => repo.adminSetDeveloperStatus(id(m), 'ACTIVE'),
                done: 'Account enabled',
              ),
              ItemAction('Unlock', Icons.lock_open_rounded, confirm: 'Clears the failed sign in lock.', run: (m, _) => repo.adminUnlockDeveloper(id(m)), done: 'Account unlocked'),
              ItemAction('Sign out everywhere', Icons.devices_other_rounded, confirm: 'Ends every session of this developer.', run: (m, _) => repo.adminSignOutDeveloper(id(m)), done: 'Sessions ended'),
              ItemAction('Send password reset', Icons.lock_reset_rounded, confirm: 'Emails them a link to choose a new password.', run: (m, _) => repo.adminSendPasswordReset(id(m)), done: 'Reset email sent'),
              ItemAction(
                'Apps',
                Icons.extension_outlined,
                title: 'Apps of this developer',
                page: (m) => ResourceSection(
                  load: () => repo.adminDeveloperApps(id(m)),
                  emptyTitle: 'No apps',
                  emptyIcon: Icons.extension_outlined,
                  row: _appRow,
                ),
              ),
              ItemAction(
                'Businesses',
                Icons.business_center_outlined,
                title: 'Businesses of this developer',
                page: (m) => _DeveloperBusinesses(developerId: id(m)),
              ),
              ItemAction(
                'Delete',
                Icons.delete_outline_rounded,
                danger: true,
                confirm: 'The developer account is deleted.',
                run: (m, _) => repo.adminDeleteDeveloper(id(m)),
                done: 'Developer deleted',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final RowView _appRow = RowView(
  icon: Icons.extension_outlined,
  title: (m) => pick(m, <String>['name'], 'App'),
  subtitle: (m) => '${pick(m, <String>['environment'])}  ${pick(m, <String>['appId'])}',
  status: (m) => pick(m, <String>['status']),
);

class _DeveloperBusinesses extends ConsumerStatefulWidget {
  const _DeveloperBusinesses({required this.developerId});

  final String developerId;

  @override
  ConsumerState<_DeveloperBusinesses> createState() => _DeveloperBusinessesState();
}

class _DeveloperBusinessesState extends ConsumerState<_DeveloperBusinesses> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.read(developerRepositoryProvider);
    return ResourceSection(
      load: () => repo.adminDeveloperBusinesses(widget.developerId),
      emptyTitle: 'No businesses',
      emptyIcon: Icons.business_center_outlined,
      row: RowView(
        icon: Icons.business_center_outlined,
        title: (m) => pick(m, <String>['name'], 'Business'),
        subtitle: (m) => '${pick(m, <String>['access'])}  ${pick(m, <String>['merchantNumber'])}',
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Share a business',
          Icons.share_outlined,
          title: 'Share a business with this developer',
          fields: const <FieldSpec>[FieldSpec('businessId', 'Business id', required: true)],
          run: (_, v) => repo.adminShareBusiness(widget.developerId, v['businessId'] as String),
          done: 'Business shared',
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction(
          'Stop sharing',
          Icons.link_off_rounded,
          danger: true,
          confirm: 'The developer loses access to this business.',
          run: (m, _) => repo.adminUnshareBusiness(widget.developerId, pick(m, <String>['businessId'])),
          done: 'Sharing stopped',
          visible: (m) => pick(m, <String>['access']) == 'SHARED',
        ),
      ],
    );
  }
}

class _AllApps extends ConsumerStatefulWidget {
  const _AllApps();

  @override
  ConsumerState<_AllApps> createState() => _AllAppsState();
}

class _AllAppsState extends ConsumerState<_AllApps> {
  String? _env;
  String? _status;

  @override
  Widget build(BuildContext context) {
    final DeveloperRepository repo = ref.read(developerRepositoryProvider);
    String id(Json m) => pick(m, <String>['appId']);
    return Column(
      children: <Widget>[
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: <Widget>[
              for (final e in const <String?, String>{null: 'Any environment', 'sandbox': 'Sandbox', 'production': 'Live'}.entries)
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(e.value), selected: _env == e.key, onSelected: (_) => setState(() => _env = e.key))),
              for (final e in const <String?, String>{null: 'Any status', 'ACTIVE': 'Active', 'SUSPENDED': 'Suspended'}.entries)
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(e.value), selected: _status == e.key, onSelected: (_) => setState(() => _status = e.key))),
            ],
          ),
        ),
        Expanded(
          child: ResourceSection(
            refreshKey: '$_env$_status',
            load: () => repo.adminApps(environment: _env, status: _status),
            detail: (m) => repo.adminApp(id(m)),
            emptyTitle: 'No apps found',
            emptyIcon: Icons.extension_outlined,
            row: _appRow,
            itemActions: <ItemAction>[
              ItemAction(
                'Edit',
                Icons.edit_outlined,
                title: 'Edit app',
                initialFromItem: true,
                fields: const <FieldSpec>[
                  FieldSpec('name', 'App name', maxLength: 120),
                  FieldSpec('description', 'Description', kind: FieldKind.multiline, maxLength: 500, clearable: true),
                  FieldSpec('callbackUrl', 'Callback address', clearable: true),
                  FieldSpec('limits.singleTransactionUsd', 'Largest single payment (USD)', kind: FieldKind.number),
                  FieldSpec('limits.dailyVolumeUsd', 'Daily volume (USD)', kind: FieldKind.number),
                  FieldSpec('limits.monthlyVolumeUsd', 'Monthly volume (USD)', kind: FieldKind.number),
                ],
                run: (m, v) async {
                  await repo.adminUpdateApp(id(m), v);
                },
                done: 'App saved',
              ),
              ItemAction(
                'Suspend',
                Icons.pause_circle_outline_rounded,
                danger: true,
                title: 'Suspend app',
                fields: const <FieldSpec>[FieldSpec('reason', 'Reason', maxLength: 300)],
                visible: (m) => pick(m, <String>['status']) == 'ACTIVE',
                run: (m, v) => repo.adminSetAppStatus(id(m), 'SUSPENDED', reason: v['reason'] as String?),
                done: 'App suspended',
              ),
              ItemAction(
                'Reactivate',
                Icons.play_circle_outline_rounded,
                visible: (m) => pick(m, <String>['status']) == 'SUSPENDED',
                run: (m, _) => repo.adminSetAppStatus(id(m), 'ACTIVE'),
                done: 'App reactivated',
              ),
              ItemAction(
                'Change owner',
                Icons.swap_horiz_rounded,
                title: 'Change owner',
                fields: <FieldSpec>[
                  FieldSpec(
                    'developerId',
                    'New owner',
                    kind: FieldKind.picker,
                    required: true,
                    helper: 'Search developers by name or email.',
                    searcher: (q) async => <PickOption>[
                      for (final d in await repo.adminDevelopers(q: q))
                        if (pick(d, <String>['id', 'developerId']).isNotEmpty)
                          PickOption(pick(d, <String>['id', 'developerId']), pick(d, <String>['fullName', 'email'], 'Developer'), description: pick(d, <String>['email'])),
                    ],
                  ),
                ],
                run: (m, v) => repo.adminSetAppOwner(id(m), v['developerId'] as String),
                done: 'Owner changed',
              ),
              ItemAction('API keys', Icons.vpn_key_outlined, title: 'API keys', page: (m) => _AdminKeys(appId: id(m))),
              ItemAction(
                'Delete',
                Icons.delete_outline_rounded,
                danger: true,
                confirm: 'The app and its keys are deleted.',
                run: (m, _) => repo.adminDeleteApp(id(m)),
                done: 'App deleted',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminKeys extends ConsumerWidget {
  const _AdminKeys({required this.appId});

  final String appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DeveloperRepository repo = ref.read(developerRepositoryProvider);
    return ResourceSection(
      load: () => repo.adminKeys(appId),
      emptyTitle: 'No keys',
      emptyIcon: Icons.vpn_key_outlined,
      row: RowView(
        icon: Icons.vpn_key_outlined,
        title: (m) => pick(m, <String>['label'], 'Key'),
        subtitle: (m) => pick(m, <String>['key']),
        status: (m) => pick(m, <String>['status']),
      ),
      headerActions: <ItemAction>[
        ItemAction(
          'Issue a key',
          Icons.add_rounded,
          title: 'Issue a key',
          fields: const <FieldSpec>[FieldSpec('label', 'Label', maxLength: 60)],
          run: (_, v) async {
            final k = await repo.adminIssueKey(appId, label: v['label'] as String?);
            if (context.mounted) await revealKeySecret(context, k, title: 'New key');
          },
          done: 'Key issued',
        ),
        ItemAction(
          'Revoke all',
          Icons.block_outlined,
          danger: true,
          confirm: 'Every key of this app stops working.',
          run: (_, __) => repo.adminRevokeAllKeys(appId),
          done: 'All keys revoked',
        ),
      ],
      itemActions: <ItemAction>[
        ItemAction(
          'Rotate',
          Icons.autorenew_rounded,
          confirm: 'The old secret stops working and a new one is shown once.',
          visible: (m) => pick(m, <String>['status']) == 'ACTIVE',
          run: (m, _) async {
            final k = await repo.adminRotateKey(appId, pick(m, <String>['key']));
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
          run: (m, _) => repo.adminRevokeKey(appId, pick(m, <String>['key'])),
          done: 'Key revoked',
        ),
      ],
    );
  }
}

class _AllTransfers extends ConsumerStatefulWidget {
  const _AllTransfers();

  @override
  ConsumerState<_AllTransfers> createState() => _AllTransfersState();
}

class _AllTransfersState extends ConsumerState<_AllTransfers> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final DeveloperRepository repo = ref.read(developerRepositoryProvider);
    String id(Json m) => pick(m, <String>['transferId']);
    return Column(
      children: <Widget>[
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: <Widget>[
              for (final e in const <String?, String>{null: 'All', 'PENDING': 'Pending', 'COMPLETED': 'Completed', 'CANCELLED': 'Cancelled', 'EXPIRED': 'Expired'}.entries)
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(e.value), selected: _status == e.key, onSelected: (_) => setState(() => _status = e.key))),
            ],
          ),
        ),
        Expanded(
          child: ResourceSection(
            refreshKey: _status,
            load: () => repo.adminTransfers(status: _status),
            detail: (m) => repo.adminTransfer(id(m)),
            emptyTitle: 'No transfers',
            emptyIcon: Icons.swap_horiz_rounded,
            row: RowView(
              icon: Icons.swap_horiz_rounded,
              title: (m) => pick(m, <String>['app.name', 'business.name'], 'Transfer'),
              subtitle: (m) => '${pick(m, <String>['type'])}  ${pick(m, <String>['from'])} to ${pick(m, <String>['to'])}',
              status: (m) => pick(m, <String>['status']),
            ),
            itemActions: <ItemAction>[
              ItemAction(
                'Cancel',
                Icons.close_rounded,
                danger: true,
                confirm: 'The transfer is called off.',
                visible: (m) => pick(m, <String>['status']) == 'PENDING',
                run: (m, _) => repo.adminCancelTransfer(id(m)),
                done: 'Transfer cancelled',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Audit extends ConsumerStatefulWidget {
  const _Audit();

  @override
  ConsumerState<_Audit> createState() => _AuditState();
}

class _AuditState extends ConsumerState<_Audit> {
  final _action = TextEditingController();
  String? _applied;

  @override
  void dispose() {
    _action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DeveloperRepository repo = ref.read(developerRepositoryProvider);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: <Widget>[
              Expanded(child: PTextField(label: 'Action', controller: _action, optional: true, hint: 'APP_SUSPENDED', prefixIcon: Icons.filter_alt_outlined)),
              const SizedBox(width: 10),
              PButton(label: 'Filter', small: true, onPressed: () => setState(() => _applied = _action.text.trim().isEmpty ? null : _action.text.trim())),
            ],
          ),
        ),
        Expanded(
          child: ResourceSection(
            refreshKey: _applied,
            load: () => repo.adminAudit(action: _applied),
            emptyTitle: 'No audit entries',
            emptyIcon: Icons.history_rounded,
            row: RowView(
              icon: Icons.history_rounded,
              title: (m) => sentence(pick(m, <String>['action'], 'Event')),
              subtitle: (m) => '${displayValue(m['createdAt'] ?? m['at'])}  ${pick(m, <String>['actorId'])}  ${pick(m, <String>['targetId'])}'.trim(),
            ),
          ),
        ),
      ],
    );
  }
}
