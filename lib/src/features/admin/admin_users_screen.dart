import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/brand.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/user_model.dart';
import '../../state/data_providers.dart';
import '../../state/providers.dart';
import '../../core/theme/palette.dart';

enum _UserFilter { all, active, inactive, unverified, archived }

extension on _UserFilter {
  String get label {
    switch (this) {
      case _UserFilter.all:
        return 'All';
      case _UserFilter.active:
        return 'Active';
      case _UserFilter.inactive:
        return 'Inactive';
      case _UserFilter.unverified:
        return 'Unverified';
      case _UserFilter.archived:
        return 'Archived';
    }
  }

  bool matches(UserModel u) {
    switch (this) {
      case _UserFilter.all:
        return !u.archived;
      case _UserFilter.active:
        return u.active && !u.archived;
      case _UserFilter.inactive:
        return !u.active && !u.archived;
      case _UserFilter.unverified:
        return !u.verified && !u.archived;
      case _UserFilter.archived:
        return u.archived;
    }
  }
}

/// Administrators: browse, search and create accounts.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  _UserFilter _filter = _UserFilter.all;
  Role? _role;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<UserModel> _apply(List<UserModel> all) {
    final q = _search.text.trim().toLowerCase();
    final out = all.where((u) {
      if (!_filter.matches(u)) return false;
      if (_role != null && u.role != _role) return false;
      if (q.isEmpty) return true;
      return u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.phoneNumber.contains(q);
    }).toList();
    out.sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return out;
  }

  Future<void> _create() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreateUserSheet(),
    );
    if (created == true) ref.invalidate(adminUsersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(adminUsersProvider);
    return PScaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('New user'),
      ),
      body: SafeArea(
        child: AsyncBody<List<UserModel>>(
          value: value,
          onRetry: () => ref.invalidate(adminUsersProvider),
          builder: (all) {
            final items = _apply(all);
            final active = all.where((u) => u.active && !u.archived).length;
            return PageBody(
              bottomPadding: 96,
              onRefresh: () async {
                ref.invalidate(adminUsersProvider);
                await ref.read(adminUsersProvider.future);
              },
              children: <Widget>[
                PageTitle(
                  'Users',
                  subtitle: '${plural(all.length, 'account')} · $active active',
                  trailing: IconButton(
                    tooltip: 'Audit trail',
                    icon: const Icon(Icons.fact_check_outlined),
                    onPressed: () => context.push('/admin/audit'),
                  ),
                ),
                PTextField(
                  label: 'Search',
                  controller: _search,
                  hint: 'Name, email, username or phone',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      for (final f in _UserFilter.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f.label),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Any role'),
                          selected: _role == null,
                          onSelected: (_) => setState(() => _role = null),
                        ),
                      ),
                      for (final r in Role.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(r.label),
                            selected: _role == r,
                            onSelected: (v) => setState(() => _role = v ? r : null),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (items.isEmpty)
                  EmptyState(
                    icon: Icons.group_off_outlined,
                    title: 'No users match',
                    message: 'Try another search or filter.',
                    actionLabel: 'Clear filters',
                    onAction: () => setState(() {
                      _search.clear();
                      _filter = _UserFilter.all;
                      _role = null;
                    }),
                  )
                else
                  MenuGroup(
                    children: <Widget>[
                      for (final u in items) _UserTile(user: u, onTap: () => context.push('/admin/users/${u.id}')),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.onTap});

  final UserModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            UserAvatar(initials: user.initials, imageUrl: user.profilePictureUrl, size: 44),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(user.fullName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(user.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: context.mutedColor)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: <Widget>[
                      StatusPill(user.role.label, dense: true, color: context.pal.accent),
                      if (user.archived)
                        const StatusPill('Archived', dense: true, color: Brand.muted)
                      else if (!user.active)
                        const StatusPill('Inactive', dense: true, color: Brand.danger),
                      if (!user.verified) const StatusPill('Unverified', dense: true, color: Brand.warning),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.mutedColor),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ create sheet

class _CreateUserSheet extends ConsumerStatefulWidget {
  const _CreateUserSheet();

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  Role _role = Role.client;
  bool _active = true;
  bool _verified = true;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref.read(adminRepositoryProvider).create(
            username: _username.text,
            firstName: _first.text,
            lastName: _last.text,
            email: _email.text,
            phoneNumber: _phone.text,
            role: _role,
            active: _active,
            verified: _verified,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      showToast(context, 'Account created. A password setup email is on its way.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + inset),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('New user', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: PTextField(label: 'First name', controller: _first, validator: (v) => Validators.required(v, 'First name'), textCapitalization: TextCapitalization.words)),
                  const SizedBox(width: 12),
                  Expanded(child: PTextField(label: 'Last name', controller: _last, validator: (v) => Validators.required(v, 'Last name'), textCapitalization: TextCapitalization.words)),
                ],
              ),
              const SizedBox(height: 14),
              PTextField(label: 'Username', controller: _username, validator: (v) => Validators.required(v, 'Username') ?? Validators.username(v)),
              const SizedBox(height: 14),
              PTextField(label: 'Email', controller: _email, keyboardType: TextInputType.emailAddress, validator: Validators.email),
              const SizedBox(height: 14),
              PTextField(label: 'Phone', controller: _phone, keyboardType: TextInputType.phone, validator: Validators.phone, hint: '+254 700 000000'),
              const SizedBox(height: 14),
              PSelectField<Role>(
                label: 'Role',
                value: _role,
                options: <PChoice<Role>>[for (final r in Role.values) PChoice<Role>(r, r.label)],
                onChanged: (r) => setState(() => _role = r ?? _role),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Active'), value: _active, onChanged: (v) => setState(() => _active = v)),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Email already verified'),
                subtitle: const Text('Turn off to make them confirm their email first'),
                value: _verified,
                onChanged: (v) => setState(() => _verified = v),
              ),
              const SizedBox(height: 12),
              PButton(label: 'Create account', expand: true, loading: _busy, onPressed: _busy ? null : _submit),
            ],
          ),
        ),
      ),
    );
  }
}
